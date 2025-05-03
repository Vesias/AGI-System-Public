#!/bin/bash
# AGI-System Berechtigungsprüfung

set -e

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktion für Benutzerabgleich
function check_user() {
    local USERNAME="$1"
    local EMAIL="$2"
    
    # Prüfe Username
    if grep -q "\"username\": \"$USERNAME\"" ../permissions/access-control.json; then
        echo -e "${GREEN}Berechtigung für Benutzer $USERNAME gefunden.${NC}"
        return 0
    fi
    
    # Prüfe E-Mail, falls angegeben
    if [ -n "$EMAIL" ] && grep -q "\"email\": \"$EMAIL\"" ../permissions/access-control.json; then
        echo -e "${GREEN}Berechtigung für E-Mail $EMAIL gefunden.${NC}"
        return 0
    fi
    
    # Keine Berechtigung gefunden
    return 1
}

# Funktion für Berechtigungsdetails
function get_access_level() {
    local IDENTIFIER="$1"
    local TYPE="$2" # "username" oder "email"
    
    # Prüfe Admin
    if grep -q "\"admin\".*\"$TYPE\": \"$IDENTIFIER\"" ../permissions/access-control.json; then
        echo "admin"
        return 0
    fi
    
    # Prüfe Contributor
    if grep -q "\"contributors\".*\"$TYPE\": \"$IDENTIFIER\"" ../permissions/access-control.json; then
        echo "contributor"
        return 0
    fi
    
    # Prüfe Viewer
    if grep -q "\"viewers\".*\"$TYPE\": \"$IDENTIFIER\"" ../permissions/access-control.json; then
        echo "viewer"
        return 0
    fi
    
    # Keine Berechtigung gefunden
    echo "none"
    return 1
}

# Hauptfunktion
function main() {
    # Parameter auswerten
    local USERNAME="$1"
    local EMAIL="$2"
    
    # Prüfen, ob Berechtigungsdatei existiert
    if [ ! -f "../permissions/access-control.json" ]; then
        echo -e "${RED}Fehler: Berechtigungsdatei nicht gefunden.${NC}"
        return 1
    fi
    
    # Prüfen, ob Parameter angegeben wurden
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}Fehler: Kein Benutzername angegeben.${NC}"
        echo "Verwendung: $0 <username> [email]"
        return 1
    fi
    
    # Benutzer prüfen
    if check_user "$USERNAME" "$EMAIL"; then
        # Berechtigungsdetails ausgeben
        if [ -n "$EMAIL" ]; then
            ACCESS_LEVEL=$(get_access_level "$EMAIL" "email")
        else
            ACCESS_LEVEL=$(get_access_level "$USERNAME" "username")
        fi
        
        echo -e "${BLUE}Zugriffsebene: $ACCESS_LEVEL${NC}"
        return 0
    else
        echo -e "${RED}Keine Berechtigung für Benutzer $USERNAME gefunden.${NC}"
        return 1
    fi
}

# Skript ausführen oder als Funktion importieren
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi