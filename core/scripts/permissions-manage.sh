#!/bin/bash
# AGI-System Berechtigungsverwaltung

set -e

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktion: Benutzer hinzufügen
function add_user() {
    local USERNAME="$1"
    local EMAIL="$2"
    local ROLE="$3"
    
    # Prüfe, ob Benutzer bereits existiert
    if grep -q "\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        echo -e "${YELLOW}Benutzer mit E-Mail $EMAIL existiert bereits.${NC}"
        return 1
    fi
    
    # Prüfe Rolle
    if [[ "$ROLE" != "admin" && "$ROLE" != "contributor" && "$ROLE" != "viewer" ]]; then
        echo -e "${RED}Ungültige Rolle: $ROLE. Erlaubt sind: admin, contributor, viewer${NC}"
        return 1
    fi
    
    # Füge Benutzer hinzu
    if [ "$ROLE" = "admin" ]; then
        SECTION="admin"
    elif [ "$ROLE" = "contributor" ]; then
        SECTION="contributors"
    else
        SECTION="viewers"
    fi
    
    # Verwende temporäre Datei für die Bearbeitung
    TEMP_FILE=$(mktemp)
    jq ".permissions.$SECTION += [{
        \"username\": \"$USERNAME\",
        \"email\": \"$EMAIL\",
        \"gpg_key_id\": \"\",
        \"granted_on\": \"$(date -I)\",
        \"access_level\": \"$ROLE\"
    }]" ../permissions/access-control.json > "$TEMP_FILE"
    
    # Prüfe, ob jq erfolgreich war
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler bei der JSON-Verarbeitung.${NC}"
        rm "$TEMP_FILE"
        return 1
    fi
    
    # Ersetze die originale Datei
    mv "$TEMP_FILE" ../permissions/access-control.json
    
    echo -e "${GREEN}Benutzer $USERNAME ($EMAIL) erfolgreich als $ROLE hinzugefügt.${NC}"
    return 0
}

# Funktion: Benutzer entfernen
function remove_user() {
    local EMAIL="$1"
    
    # Prüfe, ob Benutzer existiert
    if ! grep -q "\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        echo -e "${RED}Benutzer mit E-Mail $EMAIL existiert nicht.${NC}"
        return 1
    fi
    
    # Bestimme die Sektion
    local SECTION=""
    if grep -q "\"admin\".*\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        SECTION="admin"
    elif grep -q "\"contributors\".*\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        SECTION="contributors"
    elif grep -q "\"viewers\".*\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        SECTION="viewers"
    else
        echo -e "${RED}Konnte Sektion für Benutzer $EMAIL nicht bestimmen.${NC}"
        return 1
    fi
    
    # Entferne Benutzer
    TEMP_FILE=$(mktemp)
    jq ".permissions.$SECTION |= map(select(.email != \"$EMAIL\"))" ../permissions/access-control.json > "$TEMP_FILE"
    
    # Prüfe, ob jq erfolgreich war
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler bei der JSON-Verarbeitung.${NC}"
        rm "$TEMP_FILE"
        return 1
    fi
    
    # Ersetze die originale Datei
    mv "$TEMP_FILE" ../permissions/access-control.json
    
    echo -e "${GREEN}Benutzer mit E-Mail $EMAIL erfolgreich entfernt.${NC}"
    return 0
}

# Funktion: GPG-Schlüssel hinzufügen
function add_gpg_key() {
    local EMAIL="$1"
    local GPG_KEY_ID="$2"
    
    # Prüfe, ob Benutzer existiert
    if ! grep -q "\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        echo -e "${RED}Benutzer mit E-Mail $EMAIL existiert nicht.${NC}"
        return 1
    fi
    
    # Bestimme die Sektion
    local SECTION=""
    if grep -q "\"admin\".*\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        SECTION="admin"
    elif grep -q "\"contributors\".*\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        SECTION="contributors"
    elif grep -q "\"viewers\".*\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        SECTION="viewers"
    else
        echo -e "${RED}Konnte Sektion für Benutzer $EMAIL nicht bestimmen.${NC}"
        return 1
    fi
    
    # Update GPG-Schlüssel
    TEMP_FILE=$(mktemp)
    jq ".permissions.$SECTION |= map(if .email == \"$EMAIL\" then .gpg_key_id = \"$GPG_KEY_ID\" else . end)" ../permissions/access-control.json > "$TEMP_FILE"
    
    # Prüfe, ob jq erfolgreich war
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler bei der JSON-Verarbeitung.${NC}"
        rm "$TEMP_FILE"
        return 1
    fi
    
    # Ersetze die originale Datei
    mv "$TEMP_FILE" ../permissions/access-control.json
    
    echo -e "${GREEN}GPG-Schlüssel für Benutzer mit E-Mail $EMAIL aktualisiert.${NC}"
    return 0
}

# Funktion: Alle Benutzer auflisten
function list_users() {
    echo -e "${BLUE}=== Berechtigte Benutzer ===${NC}"
    
    echo -e "${BLUE}Administratoren:${NC}"
    jq -r '.permissions.admin[] | "  \(.username) (\(.email)) - GPG: \(.gpg_key_id) - Seit: \(.granted_on)"' ../permissions/access-control.json 2>/dev/null
    
    echo -e "${BLUE}Contributor:${NC}"
    jq -r '.permissions.contributors[] | "  \(.username) (\(.email)) - GPG: \(.gpg_key_id) - Seit: \(.granted_on)"' ../permissions/access-control.json 2>/dev/null
    
    echo -e "${BLUE}Viewer:${NC}"
    jq -r '.permissions.viewers[] | "  \(.username) (\(.email)) - GPG: \(.gpg_key_id) - Seit: \(.granted_on)"' ../permissions/access-control.json 2>/dev/null
    
    return 0
}

# Hauptfunktion
function main() {
    # Prüfe, ob jq installiert ist
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Fehler: jq ist nicht installiert. Bitte installieren Sie jq.${NC}"
        echo "Auf Debian/Ubuntu: sudo apt install jq"
        exit 1
    fi
    
    # Prüfe, ob Berechtigungsdatei existiert
    if [ ! -f "../permissions/access-control.json" ]; then
        echo -e "${RED}Fehler: Berechtigungsdatei nicht gefunden.${NC}"
        exit 1
    fi
    
    # Parameter auswerten
    local COMMAND="$1"
    
    case "$COMMAND" in
        add)
            if [ $# -lt 4 ]; then
                echo "Verwendung: $0 add <username> <email> <role>"
                echo "Rollen: admin, contributor, viewer"
                exit 1
            fi
            add_user "$2" "$3" "$4"
            ;;
        remove)
            if [ $# -lt 2 ]; then
                echo "Verwendung: $0 remove <email>"
                exit 1
            fi
            remove_user "$2"
            ;;
        gpg)
            if [ $# -lt 3 ]; then
                echo "Verwendung: $0 gpg <email> <gpg_key_id>"
                exit 1
            fi
            add_gpg_key "$2" "$3"
            ;;
        list)
            list_users
            ;;
        *)
            echo "Verwendung: $0 {add|remove|gpg|list}"
            echo "  add <username> <email> <role> - Benutzer hinzufügen"
            echo "  remove <email> - Benutzer entfernen"
            echo "  gpg <email> <gpg_key_id> - GPG-Schlüssel setzen"
            echo "  list - Alle Benutzer anzeigen"
            exit 1
            ;;
    esac
    
    exit $?
}

# Skript ausführen oder als Funktion importieren
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi