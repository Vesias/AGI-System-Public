#!/usr/bin/env bash

# Force not using jq
function command() {
  if [ "$2" = "jq" ]; then
    return 1
  fi
  /usr/bin/command "$@"
}

PERMISSIONS_FILE="/tmp/test-permissions/access-control.json"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Funktion zum Extrahieren von Benutzerdaten ohne jq
extract_user_data() {
    local section="$1"
    local file="$2"
    
    # Nach leerer Sektion prüfen
    if grep -q "\"$section\": \[\]" "$file"; then
        echo "  Keine Einträge gefunden."
        return
    fi
    
    # Extrahiere die Benutzerinformationen
    # Wir verwenden eine einfachere Herangehensweise, indem wir nach kompletten Benutzerblöcken suchen
    local in_section=false
    local user_block=""
    local name=""
    local email=""
    local added=""
    
    while IFS= read -r line; do
        # Entferne Leerzeichen
        line=$(echo "$line" | tr -d '[:space:]')
        
        # Beginn der Sektion erkennen
        if [[ "$line" == *"\"$section\":"* ]]; then
            in_section=true
            continue
        fi
        
        # Ende der Sektion erkennen
        if [[ "$in_section" == true && "$line" == "],"* ]]; then
            in_section=false
            continue
        fi
        
        # Nur innerhalb der Sektion verarbeiten
        if [[ "$in_section" == true ]]; then
            # Benutzerobjekt-Ende
            if [[ "$line" == "}"* && -n "$name" && -n "$email" && -n "$added" ]]; then
                echo "  - $name ($email) [seit $added]"
                name=""
                email=""
                added=""
                continue
            fi
            
            # Benutzerdaten extrahieren
            if [[ "$line" == *"\"name\":\""* ]]; then
                name=$(echo "$line" | sed 's/.*"name":"//g' | sed 's/".*//g')
            fi
            
            if [[ "$line" == *"\"email\":\""* ]]; then
                email=$(echo "$line" | sed 's/.*"email":"//g' | sed 's/".*//g')
            fi
            
            if [[ "$line" == *"\"added\":\""* ]]; then
                added=$(echo "$line" | sed 's/.*"added":"//g' | sed 's/".*//g')
            fi
        fi
    done < "$file"
    
    # Falls keine Benutzer gefunden wurden
    if [ "$in_section" == true ] && [ -z "$name" ] && [ -z "$email" ] && [ -z "$added" ]; then
        echo "  Keine Einträge gefunden."
    fi
}

# Test verschiedene Benutzergruppen
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Benutzer in $PERMISSIONS_FILE ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo

echo -e "${CYAN}Administratoren:${NC}"
extract_user_data "admin" "$PERMISSIONS_FILE"
echo

echo -e "${CYAN}Mitwirkende:${NC}"
extract_user_data "contributors" "$PERMISSIONS_FILE"
echo

echo -e "${CYAN}Betrachter:${NC}"
extract_user_data "viewers" "$PERMISSIONS_FILE"
echo