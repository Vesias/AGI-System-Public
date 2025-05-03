#!/usr/bin/env bash

# Dieses Skript bietet einfache Funktionen für die Benutzerverwaltung
# und Anzeige von Berechtigungen in JSON-Dateien.

# Farbdefinitionen
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Benutzer auflisten
list_users() {
    local file="$1"
    
    echo -e "${BLUE}============================================="
    echo -e "  Benutzer in $file "
    echo -e "=============================================${NC}"
    echo
    
    # Admins anzeigen
    echo -e "${CYAN}Administratoren:${NC}"
    if jq -e '.admin | length > 0' "$file" > /dev/null 2>&1; then
        jq -r '.admin[] | "  - \(.name) (\(.email)) [seit \(.added)]"' "$file"
    else
        echo "  Keine Administratoren gefunden."
    fi
    echo
    
    # Contributors anzeigen
    echo -e "${CYAN}Mitwirkende:${NC}"
    if jq -e '.contributors | length > 0' "$file" > /dev/null 2>&1; then
        jq -r '.contributors[] | "  - \(.name) (\(.email)) [seit \(.added)]"' "$file"
    else
        echo "  Keine Mitwirkenden gefunden."
    fi
    echo
    
    # Viewers anzeigen
    echo -e "${CYAN}Betrachter:${NC}"
    if jq -e '.viewers | length > 0' "$file" > /dev/null 2>&1; then
        jq -r '.viewers[] | "  - \(.name) (\(.email)) [seit \(.added)]"' "$file"
    else
        echo "  Keine Betrachter gefunden."
    fi
    echo
    
    # Letzte Aktualisierung anzeigen
    local last_updated=$(jq -r '.last_updated' "$file")
    echo -e "${GRAY}Letzte Aktualisierung: $last_updated${NC}"
}

# Benutzer hinzufügen
add_user() {
    local file="$1"
    local email="$2"
    local name="$3"
    local role="$4"
    local temp_file=$(mktemp)
    
    # Prüfen, ob Benutzer bereits existiert
    if jq -e ".admin[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1 ||
       jq -e ".contributors[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1 ||
       jq -e ".viewers[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1; then
        echo -e "${YELLOW}Benutzer $email existiert bereits.${NC}"
        return 1
    fi
    
    # Benutzer hinzufügen
    local user_object="{\"name\": \"$name\", \"email\": \"$email\", \"added\": \"$(date -I)\"}"
    case "$role" in
        admin)
            jq ".admin += [$user_object]" "$file" > "$temp_file"
            ;;
        contributor)
            jq ".contributors += [$user_object]" "$file" > "$temp_file"
            ;;
        viewer)
            jq ".viewers += [$user_object]" "$file" > "$temp_file"
            ;;
        *)
            echo -e "${RED}Ungültige Rolle: $role${NC}"
            rm "$temp_file"
            return 1
            ;;
    esac
    
    # Datum aktualisieren
    jq ".last_updated = \"$(date -I)\"" "$temp_file" > "$file"
    rm "$temp_file"
    
    echo -e "${GREEN}Benutzer $email ($name) als $role hinzugefügt.${NC}"
    return 0
}

# Benutzerrolle aktualisieren
update_role() {
    local file="$1"
    local email="$2"
    local new_role="$3"
    local temp_file=$(mktemp)
    
    # Benutzer finden
    local current_role=""
    local user_data=""
    
    # Prüfen in admin
    if jq -e ".admin[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1; then
        current_role="admin"
        user_data=$(jq -c ".admin[] | select(.email == \"$email\")" "$file")
    # Prüfen in contributors
    elif jq -e ".contributors[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1; then
        current_role="contributor"
        user_data=$(jq -c ".contributors[] | select(.email == \"$email\")" "$file")
    # Prüfen in viewers
    elif jq -e ".viewers[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1; then
        current_role="viewer"
        user_data=$(jq -c ".viewers[] | select(.email == \"$email\")" "$file")
    else
        echo -e "${RED}Benutzer $email nicht gefunden.${NC}"
        rm "$temp_file"
        return 1
    fi
    
    # Wenn die Rolle gleich ist, nichts tun
    if [ "$current_role" = "$new_role" ]; then
        echo -e "${YELLOW}Rolle ist bereits $new_role.${NC}"
        rm "$temp_file"
        return 0
    fi
    
    # Zuerst Benutzer aus aktueller Rolle entfernen
    case "$current_role" in
        admin)
            jq ".admin = [.admin[] | select(.email != \"$email\")]" "$file" > "$temp_file"
            ;;
        contributor)
            jq ".contributors = [.contributors[] | select(.email != \"$email\")]" "$file" > "$temp_file"
            ;;
        viewer)
            jq ".viewers = [.viewers[] | select(.email != \"$email\")]" "$file" > "$temp_file"
            ;;
    esac
    
    cp "$temp_file" "$file"
    
    # Dann zu neuer Rolle hinzufügen
    case "$new_role" in
        admin)
            jq ".admin += [$user_data]" "$file" > "$temp_file"
            ;;
        contributor)
            jq ".contributors += [$user_data]" "$file" > "$temp_file"
            ;;
        viewer)
            jq ".viewers += [$user_data]" "$file" > "$temp_file"
            ;;
        *)
            echo -e "${RED}Ungültige Rolle: $new_role${NC}"
            rm "$temp_file"
            return 1
            ;;
    esac
    
    # Datum aktualisieren
    jq ".last_updated = \"$(date -I)\"" "$temp_file" > "$file"
    rm "$temp_file"
    
    echo -e "${GREEN}Rolle des Benutzers $email aktualisiert von $current_role zu $new_role.${NC}"
    return 0
}

# Benutzer entfernen
remove_user() {
    local file="$1"
    local email="$2"
    local temp_file=$(mktemp)
    
    # Benutzer finden
    local found=false
    
    # Prüfen in allen Rollen
    if jq -e ".admin[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1 ||
       jq -e ".contributors[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1 ||
       jq -e ".viewers[] | select(.email == \"$email\") | length > 0" "$file" > /dev/null 2>&1; then
        found=true
    else
        echo -e "${RED}Benutzer $email nicht gefunden.${NC}"
        rm "$temp_file"
        return 1
    fi
    
    # Benutzer aus allen Rollen entfernen
    jq ".admin = [.admin[] | select(.email != \"$email\")]" "$file" > "$temp_file"
    cp "$temp_file" "$file"
    jq ".contributors = [.contributors[] | select(.email != \"$email\")]" "$file" > "$temp_file"
    cp "$temp_file" "$file"
    jq ".viewers = [.viewers[] | select(.email != \"$email\")]" "$file" > "$temp_file"
    
    # Datum aktualisieren
    jq ".last_updated = \"$(date -I)\"" "$temp_file" > "$file"
    rm "$temp_file"
    
    echo -e "${GREEN}Benutzer $email wurde entfernt.${NC}"
    return 0
}

# Hauptfunktion
main() {
    local command="$1"
    local file="$2"
    
    # Prüfen, ob Datei existiert
    if [ ! -f "$file" ]; then
        echo -e "${RED}Datei nicht gefunden: $file${NC}"
        return 1
    fi
    
    # Befehl ausführen
    case "$command" in
        list)
            list_users "$file"
            ;;
        add)
            if [ $# -lt 5 ]; then
                echo -e "${RED}Verwendung: $0 add <file> <email> <name> <role>${NC}"
                return 1
            fi
            add_user "$file" "$3" "$4" "$5"
            ;;
        update)
            if [ $# -lt 5 ]; then
                echo -e "${RED}Verwendung: $0 update <file> <email> <new-role>${NC}"
                return 1
            fi
            update_role "$file" "$3" "$4"
            ;;
        remove)
            if [ $# -lt 3 ]; then
                echo -e "${RED}Verwendung: $0 remove <file> <email>${NC}"
                return 1
            fi
            remove_user "$file" "$3"
            ;;
        *)
            echo -e "${RED}Ungültiger Befehl: $command${NC}"
            echo -e "Verfügbare Befehle: list, add, update, remove"
            return 1
            ;;
    esac
    
    return 0
}

# Skript als Ganzes ausführen oder als Bibliothek importieren
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -lt 2 ]; then
        echo -e "${RED}Verwendung: $0 <Befehl> <Datei> [Argumente...]${NC}"
        echo -e "Befehle:"
        echo -e "  list <Datei>                    Alle Benutzer auflisten"
        echo -e "  add <Datei> <Email> <Name> <Rolle>   Benutzer hinzufügen"
        echo -e "  update <Datei> <Email> <Neue-Rolle>  Benutzerrolle aktualisieren"
        echo -e "  remove <Datei> <Email>          Benutzer entfernen"
        exit 1
    fi
    
    main "$@"
    exit $?
fi