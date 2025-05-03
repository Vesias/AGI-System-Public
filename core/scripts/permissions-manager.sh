#!/usr/bin/env bash
# ============================================================================
# Automatische Berechtigungsverwaltung für AGI-Projekte
# 
# Dieses Skript verwaltet Berechtigungen für Benutzer und Projektverzeichnisse
# und erstellt eine sichere, feingranulare Zugriffssteuerung für AGI-Projekte.
# ============================================================================

set -e

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Standardwerte
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PROJECT_DIR=""
PERMISSIONS_FILE=""
INTERACTIVE_MODE=true
ACTION=""
USER_EMAIL=""
USER_NAME=""
ROLE=""
LOG_FILE="/tmp/permissions-manager-$(date +%Y%m%d%H%M%S).log"

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}" >&1
    echo "  ____               _       _                  " >&1
    echo " |  _ \ ___ _ __ ___| |_ __ (_)___ ___  ___ ___ " >&1
    echo " | |_) / _ \ '__/ __| | '_ \| / __/ __|/ _ \__ \\" >&1
    echo " |  __/  __/ |  \__ \ | | | | \__ \__ \  __/ __/" >&1
    echo " |_|   \___|_|  |___/_|_| |_|_|___/___/\___|___|" >&1
    echo "  __  __                                   " >&1
    echo " |  \/  | __ _ _ __   __ _  __ _  ___ _ __ " >&1
    echo " | |\/| |/ _\` | '_ \ / _\` |/ _\` |/ _ \ '__|" >&1
    echo " | |  | | (_| | | | | (_| | (_| |  __/ |   " >&1
    echo " |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|   " >&1
    echo "                            |___/           " >&1
    echo -e "${NC}" >&1
    echo -e "${GRAY}$(date)${NC}" >&1
    echo >&1
}

# Funktion für Logeinträge
log() {
    local level="$1"
    local message="$2"
    local color="$NC"
    
    case "$level" in
        "INFO") color="${BLUE}" ;;
        "SUCCESS") color="${GREEN}" ;;
        "WARNING") color="${YELLOW}" ;;
        "ERROR") color="${RED}" ;;
    esac
    
    # Log in Datei schreiben
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$level] $message" >> "$LOG_FILE"
    
    # In Konsole ausgeben
    if [ "$INTERACTIVE_MODE" = "true" ]; then
        echo -e "${color}[$level]${NC} $message" >&2
    fi
}

# Hilfetext anzeigen
show_help() {
    echo "Verwendung: $0 [optionen] <AKTION> [PARAMETER]"
    echo
    echo "Aktionen:"
    echo "  add-user <EMAIL> <n> <ROLLE>   Benutzer hinzufügen"
    echo "  remove-user <EMAIL>               Benutzer entfernen"
    echo "  update-role <EMAIL> <ROLLE>       Benutzerrolle aktualisieren"
    echo "  list-users                        Alle Benutzer auflisten"
    echo "  check-access <EMAIL> <PROJEKT>    Zugriff überprüfen"
    echo "  create-config <PROJEKT>           Berechtigungskonfiguration erstellen"
    echo
    echo "Optionen:"
    echo "  -h, --help                  Diese Hilfe anzeigen"
    echo "  -f, --file FILE             Berechtigungsdatei (Standard: <REPO_ROOT>/permissions/access-control.json)"
    echo "  -n, --non-interactive       Nichtinteraktiver Modus (für Automatisierung)"
    echo
    echo "Rollen:"
    echo "  admin                       Voller Zugriff auf alle Funktionen"
    echo "  contributor                 Schreib- und Lesezugriff auf Projekte"
    echo "  viewer                      Nur Lesezugriff auf Projekte"
    echo
    echo "Beispiele:"
    echo "  $0 add-user user@example.com \"Max Mustermann\" contributor"
    echo "  $0 list-users"
    echo "  $0 check-access user@example.com /path/to/project"
    echo
}

# Funktion zur Prüfung der JSON-Abhängigkeiten
check_json_dependencies() {
    # Prüfen, ob jq installiert ist
    if ! command -v jq &> /dev/null; then
        log "WARNING" "jq ist nicht installiert. Dies wird für die JSON-Verarbeitung empfohlen."
        
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${YELLOW}jq ist für die JSON-Verarbeitung erforderlich. Möchten Sie es installieren? (j/n)${NC}"
            read -r INSTALL_JQ
            
            if [[ "$INSTALL_JQ" =~ ^[Jj] ]]; then
                log "INFO" "Installiere jq..."
                
                if [ -f /etc/debian_version ]; then
                    # Debian/Ubuntu
                    sudo apt update
                    sudo apt install -y jq
                elif [ -f /etc/redhat-release ]; then
                    # RHEL/CentOS/Fedora
                    sudo dnf install -y jq
                elif [ -f /etc/arch-release ]; then
                    # Arch Linux
                    sudo pacman -S --noconfirm jq
                elif [ "$(uname)" == "Darwin" ]; then
                    # macOS
                    brew install jq
                else
                    log "ERROR" "Automatische Installation auf diesem Betriebssystem nicht unterstützt."
                    log "ERROR" "Bitte installieren Sie jq manuell und führen Sie das Skript erneut aus."
                    return 1
                fi
                
                log "SUCCESS" "jq installiert."
            else
                log "WARNING" "Fallback auf grundlegende JSON-Verarbeitung mit Bash."
            fi
        else
            log "WARNING" "Fallback auf grundlegende JSON-Verarbeitung mit Bash."
        fi
    fi
    
    return 0
}

# Funktion zur Verarbeitung der Kommandozeilenargumente
process_args() {
    # Standardwert für Berechtigungsdatei
    PERMISSIONS_FILE="$REPO_ROOT/permissions/access-control.json"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--file)
                shift
                PERMISSIONS_FILE="$1"
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                ;;
            add-user|remove-user|update-role|list-users|check-access|create-config)
                ACTION="$1"
                shift
                
                case "$ACTION" in
                    add-user)
                        if [ $# -ge 3 ]; then
                            USER_EMAIL="$1"
                            USER_NAME="$2"
                            ROLE="$3"
                            shift 3
                        else
                            log "ERROR" "Unvollständige Parameter für add-user."
                            show_help
                            exit 1
                        fi
                        ;;
                    remove-user)
                        if [ $# -ge 1 ]; then
                            USER_EMAIL="$1"
                            shift
                        else
                            log "ERROR" "E-Mail für remove-user fehlt."
                            show_help
                            exit 1
                        fi
                        ;;
                    update-role)
                        if [ $# -ge 2 ]; then
                            USER_EMAIL="$1"
                            ROLE="$2"
                            shift 2
                        else
                            log "ERROR" "Unvollständige Parameter für update-role."
                            show_help
                            exit 1
                        fi
                        ;;
                    check-access)
                        if [ $# -ge 2 ]; then
                            USER_EMAIL="$1"
                            PROJECT_DIR="$2"
                            shift 2
                        else
                            log "ERROR" "Unvollständige Parameter für check-access."
                            show_help
                            exit 1
                        fi
                        ;;
                    create-config)
                        if [ $# -ge 1 ]; then
                            PROJECT_DIR="$1"
                            shift
                        else
                            log "ERROR" "Projektverzeichnis für create-config fehlt."
                            show_help
                            exit 1
                        fi
                        ;;
                    list-users)
                        # Keine weiteren Parameter erforderlich
                        ;;
                esac
                ;;
            *)
                log "ERROR" "Unbekannter Parameter oder Aktion: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    # Prüfen, ob eine Aktion angegeben wurde
    if [ -z "$ACTION" ]; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${YELLOW}Welche Aktion möchten Sie ausführen?${NC}"
            echo "  1. Benutzer hinzufügen"
            echo "  2. Benutzer entfernen"
            echo "  3. Benutzerrolle aktualisieren"
            echo "  4. Alle Benutzer auflisten"
            echo "  5. Zugriff überprüfen"
            echo "  6. Berechtigungskonfiguration erstellen"
            read -p "Auswahl (1-6): " selection
            
            case "$selection" in
                1)
                    ACTION="add-user"
                    read -p "E-Mail: " USER_EMAIL
                    read -p "Name: " USER_NAME
                    read -p "Rolle (admin, contributor, viewer): " ROLE
                    ;;
                2)
                    ACTION="remove-user"
                    read -p "E-Mail: " USER_EMAIL
                    ;;
                3)
                    ACTION="update-role"
                    read -p "E-Mail: " USER_EMAIL
                    read -p "Neue Rolle (admin, contributor, viewer): " ROLE
                    ;;
                4)
                    ACTION="list-users"
                    ;;
                5)
                    ACTION="check-access"
                    read -p "E-Mail: " USER_EMAIL
                    read -p "Projektverzeichnis: " PROJECT_DIR
                    ;;
                6)
                    ACTION="create-config"
                    read -p "Projektverzeichnis: " PROJECT_DIR
                    ;;
                *)
                    log "ERROR" "Ungültige Auswahl."
                    exit 1
                    ;;
            esac
        else
            log "ERROR" "Keine Aktion angegeben."
            show_help
            exit 1
        fi
    fi
    
    # Prüfen, ob die erforderlichen Parameter für die jeweilige Aktion angegeben wurden
    case "$ACTION" in
        add-user)
            if [ -z "$USER_EMAIL" ] || [ -z "$USER_NAME" ] || [ -z "$ROLE" ]; then
                log "ERROR" "Unvollständige Parameter für add-user."
                exit 1
            fi
            
            # Rollenvalidierung
            if [ "$ROLE" != "admin" ] && [ "$ROLE" != "contributor" ] && [ "$ROLE" != "viewer" ]; then
                log "ERROR" "Ungültige Rolle: $ROLE"
                log "ERROR" "Gültige Rollen: admin, contributor, viewer"
                exit 1
            fi
            ;;
        remove-user|update-role)
            if [ -z "$USER_EMAIL" ]; then
                log "ERROR" "E-Mail fehlt."
                exit 1
            fi
            ;;
        check-access)
            if [ -z "$USER_EMAIL" ] || [ -z "$PROJECT_DIR" ]; then
                log "ERROR" "Unvollständige Parameter für check-access."
                exit 1
            fi
            ;;
        create-config)
            if [ -z "$PROJECT_DIR" ]; then
                log "ERROR" "Projektverzeichnis fehlt."
                exit 1
            fi
            ;;
    esac
    
    return 0
}

# Berechtigungsdatei initialisieren oder prüfen
init_permissions_file() {
    local permissions_dir=$(dirname "$PERMISSIONS_FILE")
    
    # Verzeichnis erstellen, falls es nicht existiert
    if [ ! -d "$permissions_dir" ]; then
        mkdir -p "$permissions_dir"
    fi
    
    # Datei erstellen, falls sie nicht existiert
    if [ ! -f "$PERMISSIONS_FILE" ]; then
        log "INFO" "Berechtigungsdatei existiert nicht. Erstelle neue Datei: $PERMISSIONS_FILE"
        
        cat > "$PERMISSIONS_FILE" << EOL
{
  "admin": [],
  "contributors": [],
  "viewers": [],
  "last_updated": "$(date -I)"
}
EOL
    fi
    
    # Datei auf Gültigkeit prüfen
    if command -v jq &> /dev/null; then
        if ! jq . "$PERMISSIONS_FILE" > /dev/null 2>&1; then
            log "ERROR" "Berechtigungsdatei ist kein gültiges JSON: $PERMISSIONS_FILE"
            exit 1
        fi
    else
        # Einfache Validierung ohne jq
        if ! grep -q "{" "$PERMISSIONS_FILE" || ! grep -q "}" "$PERMISSIONS_FILE"; then
            log "ERROR" "Berechtigungsdatei scheint kein gültiges JSON zu sein: $PERMISSIONS_FILE"
            exit 1
        fi
    fi
    
    return 0
}

# Benutzer hinzufügen
add_user() {
    log "INFO" "Füge Benutzer hinzu: $USER_EMAIL ($USER_NAME) als $ROLE..."
    echo "DEBUG: Füge hinzu: $USER_EMAIL als $ROLE" >&2
    
    # Prüfen, ob Benutzer bereits existiert
    if grep -q "\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        log "WARNING" "Benutzer mit E-Mail $USER_EMAIL existiert bereits."
        echo "DEBUG: Benutzer existiert bereits" >&2
        
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${YELLOW}Benutzer existiert bereits. Möchten Sie die Rolle aktualisieren? (j/n)${NC}"
            read -r UPDATE_ROLE
            
            if [[ "$UPDATE_ROLE" =~ ^[Jj] ]]; then
                update_user_role
                return $?
            else
                log "INFO" "Keine Änderungen vorgenommen."
                return 0
            fi
        else
            log "ERROR" "Benutzer existiert bereits. Verwenden Sie update-role, um die Rolle zu ändern."
            return 1
        fi
    fi
    
    # Neuen Benutzer hinzufügen
    if command -v jq &> /dev/null; then
        # Mit jq
        echo "DEBUG: JQ verfügbar, verwende JQ für das Hinzufügen" >&2
        local temp_file=$(mktemp)
        echo "DEBUG: Temp Datei: $temp_file" >&2
        local user_object="{\"name\": \"$USER_NAME\", \"email\": \"$USER_EMAIL\", \"added\": \"$(date -I)\"}"
        echo "DEBUG: User Object: $user_object" >&2
        
        case "$ROLE" in
            admin)
                echo "DEBUG: Füge zu Admin hinzu" >&2
                jq ".admin += [$user_object]" "$PERMISSIONS_FILE" > "$temp_file"
                ;;
            contributor)
                echo "DEBUG: Füge zu Contributors hinzu" >&2
                jq ".contributors += [$user_object]" "$PERMISSIONS_FILE" > "$temp_file"
                ;;
            viewer)
                echo "DEBUG: Füge zu Viewers hinzu" >&2
                jq ".viewers += [$user_object]" "$PERMISSIONS_FILE" > "$temp_file"
                ;;
        esac
        
        echo "DEBUG: Aktualisiere last_updated" >&2
        jq ".last_updated = \"$(date -I)\"" "$temp_file" > "$PERMISSIONS_FILE"
        echo "DEBUG: Lösche temp file" >&2
        rm "$temp_file"
        echo "DEBUG: Benutzer hinzugefügt mit JQ" >&2
    else
        # Ohne jq (einfache Ersetzung)
        local user_object="{\"name\": \"$USER_NAME\", \"email\": \"$USER_EMAIL\", \"added\": \"$(date -I)\"}"
        local content=$(cat "$PERMISSIONS_FILE")
        
        # Aktuelles Datum
        local today=$(date -I)
        
        # Benutzer hinzufügen
        case "$ROLE" in
            admin)
                content=$(echo "$content" | sed "s/\"admin\": \[/\"admin\": \[$user_object, /")
                ;;
            contributor)
                content=$(echo "$content" | sed "s/\"contributors\": \[/\"contributors\": \[$user_object, /")
                ;;
            viewer)
                content=$(echo "$content" | sed "s/\"viewers\": \[/\"viewers\": \[$user_object, /")
                ;;
        esac
        
        # Wenn kein Benutzer existiert, Nachbearbeitung
        content=$(echo "$content" | sed "s/, \]/]/g")
        
        # Datum aktualisieren
        content=$(echo "$content" | sed "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$today\"/")
        
        # In Datei schreiben
        echo "$content" > "$PERMISSIONS_FILE"
    fi
    
    log "SUCCESS" "Benutzer $USER_EMAIL ($USER_NAME) als $ROLE hinzugefügt."
    return 0
}

# Benutzer entfernen
remove_user() {
    log "INFO" "Entferne Benutzer: $USER_EMAIL..."
    
    # Prüfen, ob Benutzer existiert
    if ! grep -q "\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        log "ERROR" "Benutzer mit E-Mail $USER_EMAIL existiert nicht."
        return 1
    fi
    
    # Benutzer entfernen
    if command -v jq &> /dev/null; then
        # Mit jq
        local temp_file=$(mktemp)
        
        jq ".admin = [.admin[] | select(.email != \"$USER_EMAIL\")]" "$PERMISSIONS_FILE" > "$temp_file"
        jq ".contributors = [.contributors[] | select(.email != \"$USER_EMAIL\")]" "$temp_file" > "$PERMISSIONS_FILE"
        jq ".viewers = [.viewers[] | select(.email != \"$USER_EMAIL\")]" "$PERMISSIONS_FILE" > "$temp_file"
        jq ".last_updated = \"$(date -I)\"" "$temp_file" > "$PERMISSIONS_FILE"
        
        rm "$temp_file"
    else
        # Einfaches Filtern mit temp-Datei
        local temp_file=$(mktemp)
        
        # Zeilenweise kopieren und Benutzer ausfiltern
        while IFS= read -r line; do
            if ! echo "$line" | grep -q "\"email\": \"$USER_EMAIL\""; then
                # Wenn die nächste Zeile ein Komma enthält und die aktuelle eine schließende Klammer
                if echo "$line" | grep -q "}," && grep -A1 "$line" "$PERMISSIONS_FILE" | tail -n1 | grep -q "\"email\": \"$USER_EMAIL\""; then
                    # Entferne das Komma
                    echo "$line" | sed 's/},/}/g' >> "$temp_file"
                else
                    echo "$line" >> "$temp_file"
                fi
            else
                # Überspringe diese und die nächsten 3 Zeilen (name, email, added)
                read -r line
                read -r line
                read -r line
            fi
        done < "$PERMISSIONS_FILE"
        
        # Datum aktualisieren
        local today=$(date -I)
        sed -i "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$today\"/" "$temp_file"
        
        # In Datei schreiben
        mv "$temp_file" "$PERMISSIONS_FILE"
    fi
    
    log "SUCCESS" "Benutzer $USER_EMAIL entfernt."
    return 0
}

# Benutzerrolle aktualisieren
update_user_role() {
    log "INFO" "Aktualisiere Rolle für Benutzer $USER_EMAIL auf $ROLE..."
    
    # Prüfen, ob Benutzer existiert
    if ! grep -q "\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        log "ERROR" "Benutzer mit E-Mail $USER_EMAIL existiert nicht."
        return 1
    fi
    
    # Aktuelle Rolle ermitteln
    local current_role=""
    if grep -q "\"admin\".*\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        current_role="admin"
    elif grep -q "\"contributors\".*\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        current_role="contributor"
    else
        current_role="viewer"
    fi
    
    # Wenn die Rolle gleich bleibt, nichts tun
    if [ "$current_role" = "$ROLE" ]; then
        log "INFO" "Benutzer $USER_EMAIL hat bereits die Rolle $ROLE. Keine Änderung erforderlich."
        return 0
    fi
    
    # Benutzer temporär entfernen und mit neuer Rolle hinzufügen
    local user_name=$(grep -A1 "\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE" | grep "\"name\"" | cut -d'"' -f4)
    
    # Benutzer entfernen
    USER_EMAIL="$USER_EMAIL"
    remove_user
    
    # Benutzer mit neuer Rolle hinzufügen
    USER_EMAIL="$USER_EMAIL"
    USER_NAME="$user_name"
    ROLE="$ROLE"
    add_user
    
    log "SUCCESS" "Rolle für Benutzer $USER_EMAIL auf $ROLE aktualisiert."
    return 0
}

# Alle Benutzer auflisten
list_users() {
    log "INFO" "Liste alle Benutzer auf..."
    
    echo -e "${BLUE}=============================================${NC}" >&1
    echo -e "${BLUE}  Benutzer in $PERMISSIONS_FILE ${NC}" >&1
    echo -e "${BLUE}=============================================${NC}" >&1
    echo >&1
    
    # Helper-Funktion zum Extrahieren von Benutzerdaten ohne jq
    parse_user_section() {
        local section="$1"
        local file="$2"
        
        # Prüfen ob die Sektion leer ist
        if grep -q "\"$section\": \[\]" "$file"; then
            echo "  Keine Einträge gefunden."
            return
        fi
        
        # Extrahiere jeden Benutzerblock mit grep und awk
        awk -v section="$section" '
        BEGIN { in_section = 0; has_output = 0; }
        $0 ~ "\"" section "\"[[:space:]]*:" { in_section = 1; next; }
        in_section && $0 ~ /}/ {
            # Erfasse alle Namen, E-Mails und Hinzufügedaten in einem Block
            if (name != "" && email != "" && added != "") {
                print "  - " name " (" email ") [seit " added "]";
                has_output = 1;
            }
            name = ""; email = ""; added = "";
            
            # Prüfen, ob wir das Ende der Sektion erreicht haben
            if ($0 ~ /],/) { in_section = 0; }
        }
        in_section && $0 ~ /"name"/ { gsub(/"name":[[:space:]]*"|",?/, ""); name = $2; }
        in_section && $0 ~ /"email"/ { gsub(/"email":[[:space:]]*"|",?/, ""); email = $2; }
        in_section && $0 ~ /"added"/ { gsub(/"added":[[:space:]]*"|",?/, ""); added = $2; }
        END { if (!has_output) print "  Keine Einträge gefunden."; }
        ' "$file"
    }
    
    # Admins auflisten
    echo -e "${CYAN}Administratoren:${NC}" >&1
    if command -v jq &> /dev/null; then
        # Mit jq
        jq -r '.admin[] | "  - \(.name) (\(.email)) [seit \(.added)]"' "$PERMISSIONS_FILE" 2>/dev/null >&1 || echo "  Keine Administratoren gefunden." >&1
    else
        # Ohne jq mit der neuen simplen Methode
        grep -A3 "\"admin\":" "$PERMISSIONS_FILE" | grep -o '{"name": "[^"]*", "email": "[^"]*", "added": "[^"]*"}' | while read -r line; do
            name=$(echo "$line" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
            email=$(echo "$line" | grep -o '"email": "[^"]*"' | cut -d'"' -f4)
            added=$(echo "$line" | grep -o '"added": "[^"]*"' | cut -d'"' -f4)
            echo "  - $name ($email) [seit $added]" >&1
        done
        
        # Wenn keine Admins gefunden wurden
        if ! grep -q '{"name":' <(grep -A3 "\"admin\":" "$PERMISSIONS_FILE"); then
            echo "  Keine Administratoren gefunden." >&1
        fi
    fi
    
    echo >&1
    
    # Contributors auflisten
    echo -e "${CYAN}Mitwirkende:${NC}" >&1
    if command -v jq &> /dev/null; then
        # Mit jq
        jq -r '.contributors[] | "  - \(.name) (\(.email)) [seit \(.added)]"' "$PERMISSIONS_FILE" 2>/dev/null >&1 || echo "  Keine Mitwirkenden gefunden." >&1
    else
        # Ohne jq mit der neuen simplen Methode
        grep -A3 "\"contributors\":" "$PERMISSIONS_FILE" | grep -o '{"name": "[^"]*", "email": "[^"]*", "added": "[^"]*"}' | while read -r line; do
            name=$(echo "$line" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
            email=$(echo "$line" | grep -o '"email": "[^"]*"' | cut -d'"' -f4)
            added=$(echo "$line" | grep -o '"added": "[^"]*"' | cut -d'"' -f4)
            echo "  - $name ($email) [seit $added]" >&1
        done
        
        # Wenn keine Contributors gefunden wurden
        if ! grep -q '{"name":' <(grep -A3 "\"contributors\":" "$PERMISSIONS_FILE"); then
            echo "  Keine Mitwirkenden gefunden." >&1
        fi
    fi
    
    echo >&1
    
    # Viewers auflisten
    echo -e "${CYAN}Betrachter:${NC}" >&1
    if command -v jq &> /dev/null; then
        # Mit jq
        jq -r '.viewers[] | "  - \(.name) (\(.email)) [seit \(.added)]"' "$PERMISSIONS_FILE" 2>/dev/null >&1 || echo "  Keine Betrachter gefunden." >&1
    else
        # Ohne jq mit der neuen simplen Methode
        grep -A3 "\"viewers\":" "$PERMISSIONS_FILE" | grep -o '{"name": "[^"]*", "email": "[^"]*", "added": "[^"]*"}' | while read -r line; do
            name=$(echo "$line" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
            email=$(echo "$line" | grep -o '"email": "[^"]*"' | cut -d'"' -f4)
            added=$(echo "$line" | grep -o '"added": "[^"]*"' | cut -d'"' -f4)
            echo "  - $name ($email) [seit $added]" >&1
        done
        
        # Wenn keine Viewers gefunden wurden
        if ! grep -q '{"name":' <(grep -A3 "\"viewers\":" "$PERMISSIONS_FILE"); then
            echo "  Keine Betrachter gefunden." >&1
        fi
    fi
    
    echo >&1
    
    # Letzte Aktualisierung
    local last_updated=""
    if command -v jq &> /dev/null; then
        # Mit jq
        last_updated=$(jq -r '.last_updated' "$PERMISSIONS_FILE")
    else
        # Ohne jq
        last_updated=$(grep "\"last_updated\"" "$PERMISSIONS_FILE" | cut -d'"' -f4)
    fi
    
    echo -e "${GRAY}Letzte Aktualisierung: $last_updated${NC}" >&1
    
    return 0
}

# Zugriff überprüfen
check_access() {
    log "INFO" "Überprüfe Zugriff für Benutzer $USER_EMAIL auf Projekt $PROJECT_DIR..."
    
    # Prüfen, ob Projektverzeichnis existiert
    if [ ! -d "$PROJECT_DIR" ]; then
        log "ERROR" "Projektverzeichnis existiert nicht: $PROJECT_DIR"
        return 1
    fi
    
    # Prüfen, ob Benutzer existiert
    if ! grep -q "\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        log "ERROR" "Benutzer mit E-Mail $USER_EMAIL existiert nicht."
        return 1
    fi
    
    # Rolle des Benutzers ermitteln
    local role=""
    if grep -q "\"admin\".*\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        role="admin"
    elif grep -q "\"contributors\".*\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE"; then
        role="contributor"
    else
        role="viewer"
    fi
    
    # Zugriffsprüfung basierend auf Rolle
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Zugriffsüberprüfung ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "${CYAN}Benutzer:${NC} $(grep -A1 "\"email\": \"$USER_EMAIL\"" "$PERMISSIONS_FILE" | grep "\"name\"" | cut -d'"' -f4) ($USER_EMAIL)"
    echo -e "${CYAN}Rolle:${NC} $role"
    echo -e "${CYAN}Projekt:${NC} $PROJECT_DIR"
    echo
    
    local project_name=$(basename "$PROJECT_DIR")
    
    case "$role" in
        admin)
            echo -e "${GREEN}Voller Zugriff${NC}"
            echo -e "  - Lesezugriff: ${GREEN}JA${NC}"
            echo -e "  - Schreibzugriff: ${GREEN}JA${NC}"
            echo -e "  - Konfigurationszugriff: ${GREEN}JA${NC}"
            echo -e "  - Administrationszugriff: ${GREEN}JA${NC}"
            ;;
        contributor)
            echo -e "${YELLOW}Eingeschränkter Zugriff${NC}"
            echo -e "  - Lesezugriff: ${GREEN}JA${NC}"
            echo -e "  - Schreibzugriff: ${GREEN}JA${NC}"
            echo -e "  - Konfigurationszugriff: ${YELLOW}EINGESCHRÄNKT${NC}"
            echo -e "  - Administrationszugriff: ${RED}NEIN${NC}"
            ;;
        viewer)
            echo -e "${RED}Nur Lesezugriff${NC}"
            echo -e "  - Lesezugriff: ${GREEN}JA${NC}"
            echo -e "  - Schreibzugriff: ${RED}NEIN${NC}"
            echo -e "  - Konfigurationszugriff: ${RED}NEIN${NC}"
            echo -e "  - Administrationszugriff: ${RED}NEIN${NC}"
            ;;
    esac
    
    echo
    
    # Spezifische Verzeichnisberechtigungen
    echo -e "${CYAN}Verzeichnisberechtigungen:${NC}"
    echo -e "  - APP/: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] && echo "${GREEN}Schreiben${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - MARKETING/: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] && echo "${GREEN}Schreiben${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - FINANCE/: $([ "$role" = "admin" ] && echo "${GREEN}Schreiben${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - DOCS/: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] && echo "${GREEN}Schreiben${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - memory-bank/: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] && echo "${GREEN}Schreiben${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - .config/: $([ "$role" = "admin" ] && echo "${GREEN}Schreiben${NC}" || echo "${RED}Kein Zugriff${NC}")"
    echo
    
    # MCP-Tools-Berechtigungen
    echo -e "${CYAN}MCP-Tools-Berechtigungen:${NC}"
    echo -e "  - desktop-commander: $([ "$role" = "admin" ] && echo "${GREEN}Voll${NC}" || [ "$role" = "contributor" ] && echo "${YELLOW}Eingeschränkt${NC}" || echo "${RED}Keine${NC}")"
    echo -e "  - memory-bank: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] && echo "${GREEN}Voll${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - marketing-tools: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] && echo "${GREEN}Voll${NC}" || echo "${YELLOW}Lesen${NC}")"
    echo -e "  - browser-tools: $([ "$role" = "admin" ] || [ "$role" = "contributor" ] || [ "$role" = "viewer" ] && echo "${GREEN}Voll${NC}" || echo "${RED}Keine${NC}")"
    echo -e "  - toolbox: $([ "$role" = "admin" ] && echo "${GREEN}Voll${NC}" || [ "$role" = "contributor" ] && echo "${YELLOW}Eingeschränkt${NC}" || echo "${RED}Keine${NC}")"
    
    return 0
}

# Berechtigungskonfiguration erstellen
create_config() {
    log "INFO" "Erstelle Berechtigungskonfiguration für Projekt $PROJECT_DIR..."
    
    # Prüfen, ob Projektverzeichnis existiert
    if [ ! -d "$PROJECT_DIR" ]; then
        log "ERROR" "Projektverzeichnis existiert nicht: $PROJECT_DIR"
        return 1
    fi
    
    # Prüfen, ob memory-bank existiert, andernfalls erstellen
    local memory_bank_dir="$PROJECT_DIR/memory-bank"
    if [ ! -d "$memory_bank_dir" ]; then
        mkdir -p "$memory_bank_dir"
    fi
    
    # Prüfen, ob project_context existiert, andernfalls erstellen
    local project_context_dir="$memory_bank_dir/project_context"
    if [ ! -d "$project_context_dir" ]; then
        mkdir -p "$project_context_dir"
    fi
    
    # Berechtigungskonfiguration erstellen
    local permissions_file="$project_context_dir/permissions.json"
    
    local admin_users=()
    local contributor_users=()
    local viewer_users=()
    
    # Benutzer aus access-control.json auslesen
    if command -v jq &> /dev/null; then
        # Mit jq
        admin_users=($(jq -r '.admin[].email' "$PERMISSIONS_FILE"))
        contributor_users=($(jq -r '.contributors[].email' "$PERMISSIONS_FILE"))
        viewer_users=($(jq -r '.viewers[].email' "$PERMISSIONS_FILE"))
    else
        # Ohne jq
        admin_users=($(grep -A1 "\"admin\"" "$PERMISSIONS_FILE" | grep "\"email\"" | cut -d'"' -f4))
        contributor_users=($(grep -A1 "\"contributors\"" "$PERMISSIONS_FILE" | grep "\"email\"" | cut -d'"' -f4))
        viewer_users=($(grep -A1 "\"viewers\"" "$PERMISSIONS_FILE" | grep "\"email\"" | cut -d'"' -f4))
    fi
    
    # Berechtigungskonfiguration erstellen
    cat > "$permissions_file" << EOL
{
  "project_permissions": {
    "name": "$(basename "$PROJECT_DIR")",
    "path": "$PROJECT_DIR",
    "created": "$(date -I)",
    "users": {
      "admin": [
EOL
    
    # Admins hinzufügen
    for email in "${admin_users[@]}"; do
        echo "        \"$email\"," >> "$permissions_file"
    done
    
    # Letztes Komma entfernen
    sed -i '$ s/,$//' "$permissions_file"
    
    # Contributors hinzufügen
    cat >> "$permissions_file" << EOL
      ],
      "contributors": [
EOL
    
    for email in "${contributor_users[@]}"; do
        echo "        \"$email\"," >> "$permissions_file"
    done
    
    # Letztes Komma entfernen
    sed -i '$ s/,$//' "$permissions_file"
    
    # Viewers hinzufügen
    cat >> "$permissions_file" << EOL
      ],
      "viewers": [
EOL
    
    for email in "${viewer_users[@]}"; do
        echo "        \"$email\"," >> "$permissions_file"
    done
    
    # Letztes Komma entfernen
    sed -i '$ s/,$//' "$permissions_file"
    
    # Rest der Konfiguration
    cat >> "$permissions_file" << EOL
      ]
    }
  },
  "tool_permissions": {
    "project_level": {
      "allowed_tools": [
        "Bash(**)",
        "Python(**)",
        "File(**)",
        "Web(**)",
        "API(**)"
      ],
      "restricted_tools": [],
      "execution_context": "project_sandbox"
    },
    "memory_bank_access": {
      "read": true,
      "write": true,
      "modify_structure": true
    },
    "mcp_integration": {
      "auto_connect": true,
      "share_context": true,
      "allow_chaining": true
    }
  },
  "directory_permissions": {
    "APP": {
      "admin": ["read", "write", "execute"],
      "contributors": ["read", "write", "execute"],
      "viewers": ["read"]
    },
    "MARKETING": {
      "admin": ["read", "write", "execute"],
      "contributors": ["read", "write", "execute"],
      "viewers": ["read"]
    },
    "FINANCE": {
      "admin": ["read", "write", "execute"],
      "contributors": ["read"],
      "viewers": ["read"]
    },
    "DOCS": {
      "admin": ["read", "write", "execute"],
      "contributors": ["read", "write"],
      "viewers": ["read"]
    },
    "memory-bank": {
      "admin": ["read", "write", "execute"],
      "contributors": ["read", "write"],
      "viewers": ["read"]
    },
    ".config": {
      "admin": ["read", "write", "execute"],
      "contributors": [],
      "viewers": []
    }
  },
  "mcp_tool_permissions": {
    "desktop-commander": {
      "admin": ["full"],
      "contributors": ["restricted"],
      "viewers": []
    },
    "memory-bank": {
      "admin": ["full"],
      "contributors": ["full"],
      "viewers": ["read"]
    },
    "marketing-tools": {
      "admin": ["full"],
      "contributors": ["full"],
      "viewers": ["read"]
    },
    "browser-tools": {
      "admin": ["full"],
      "contributors": ["full"],
      "viewers": ["full"]
    },
    "toolbox": {
      "admin": ["full"],
      "contributors": ["restricted"],
      "viewers": []
    }
  },
  "metadata": {
    "created_by": "permissions-manager.sh",
    "version": "1.0.0",
    "last_updated": "$(date -I)"
  }
}
EOL
    
    log "SUCCESS" "Berechtigungskonfiguration erstellt: $permissions_file"
    
    # Zusätzliche Dokumentation erstellen
    local docs_file="$project_context_dir/permissions_doc.md"
    
    cat > "$docs_file" << EOL
# Berechtigungsdokumentation für $(basename "$PROJECT_DIR")

Diese Dokumentation beschreibt die Berechtigungsstruktur für dieses Projekt und definiert, welche Benutzer welche Zugriffsebenen haben.

## Benutzerrollen

### Administratoren
Administratoren haben vollen Zugriff auf alle Projektkomponenten, einschließlich Konfiguration und sensible Bereiche.

**Berechtigte Benutzer:**
EOL
    
    # Admins auflisten
    for email in "${admin_users[@]}"; do
        # Name aus access-control.json extrahieren
        local name=""
        if command -v jq &> /dev/null; then
            name=$(jq -r ".admin[] | select(.email == \"$email\") | .name" "$PERMISSIONS_FILE")
        else
            name=$(grep -A1 "\"email\": \"$email\"" "$PERMISSIONS_FILE" | grep "\"name\"" | cut -d'"' -f4)
        fi
        echo "- $name ($email)" >> "$docs_file"
    done
    
    cat >> "$docs_file" << EOL

### Mitwirkende
Mitwirkende haben Lese- und Schreibzugriff auf die meisten Projektbereiche, jedoch eingeschränkten Zugriff auf Konfiguration und sensible Daten.

**Berechtigte Benutzer:**
EOL
    
    # Contributors auflisten
    for email in "${contributor_users[@]}"; do
        # Name aus access-control.json extrahieren
        local name=""
        if command -v jq &> /dev/null; then
            name=$(jq -r ".contributors[] | select(.email == \"$email\") | .name" "$PERMISSIONS_FILE")
        else
            name=$(grep -A1 "\"email\": \"$email\"" "$PERMISSIONS_FILE" | grep "\"name\"" | cut -d'"' -f4)
        fi
        echo "- $name ($email)" >> "$docs_file"
    done
    
    cat >> "$docs_file" << EOL

### Betrachter
Betrachter haben nur Lesezugriff auf die meisten Projektbereiche und keinen Schreib- oder Konfigurationszugriff.

**Berechtigte Benutzer:**
EOL
    
    # Viewers auflisten
    for email in "${viewer_users[@]}"; do
        # Name aus access-control.json extrahieren
        local name=""
        if command -v jq &> /dev/null; then
            name=$(jq -r ".viewers[] | select(.email == \"$email\") | .name" "$PERMISSIONS_FILE")
        else
            name=$(grep -A1 "\"email\": \"$email\"" "$PERMISSIONS_FILE" | grep "\"name\"" | cut -d'"' -f4)
        fi
        echo "- $name ($email)" >> "$docs_file"
    done
    
    cat >> "$docs_file" << EOL

## Verzeichnisberechtigungen

| Verzeichnis | Administratoren | Mitwirkende | Betrachter |
|-------------|-----------------|-------------|------------|
| APP/        | Voll            | Voll        | Lesen      |
| MARKETING/  | Voll            | Voll        | Lesen      |
| FINANCE/    | Voll            | Lesen       | Lesen      |
| DOCS/       | Voll            | Schreiben   | Lesen      |
| memory-bank/| Voll            | Schreiben   | Lesen      |
| .config/    | Voll            | Kein Zugriff| Kein Zugriff|

## MCP-Tools-Berechtigungen

| Tool              | Administratoren | Mitwirkende  | Betrachter |
|-------------------|-----------------|--------------|------------|
| desktop-commander | Voll            | Eingeschränkt| Kein Zugriff|
| memory-bank       | Voll            | Voll         | Lesen      |
| marketing-tools   | Voll            | Voll         | Lesen      |
| browser-tools     | Voll            | Voll         | Voll       |
| toolbox           | Voll            | Eingeschränkt| Kein Zugriff|

## Zugriffsverwaltung

Um Berechtigungen zu ändern oder neue Benutzer hinzuzufügen, verwenden Sie das Berechtigungsverwaltungsskript:

\`\`\`bash
/path/to/permissions-manager.sh add-user user@example.com "Benutzername" rolle
\`\`\`

Diese Änderungen werden automatisch auf das Projekt angewendet, wenn die Berechtigungskonfiguration aktualisiert wird.

## Letzte Aktualisierung

Diese Berechtigungsdokumentation wurde zuletzt aktualisiert am: $(date -I)
EOL
    
    log "SUCCESS" "Berechtigungsdokumentation erstellt: $docs_file"
    
    return 0
}

# Hauptfunktion
main() {
    # Anzeige des Banners
    show_banner
    
    # Initialisierung des Logs
    echo "# Berechtigungsverwaltung Log" > "$LOG_FILE"
    echo "# $(date)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    # JSON-Abhängigkeiten prüfen
    check_json_dependencies
    
    # Parameter verarbeiten
    process_args "$@"
    
    # Berechtigungsdatei initialisieren oder prüfen
    init_permissions_file
    
    # Aktion ausführen
    case "$ACTION" in
        add-user)
            add_user
            ;;
        remove-user)
            remove_user
            ;;
        update-role)
            update_user_role
            ;;
        list-users)
            list_users
            ;;
        check-access)
            check_access
            ;;
        create-config)
            create_config
            ;;
    esac
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?