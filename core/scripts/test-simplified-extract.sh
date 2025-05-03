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
    
    # Vereinfachte Methode: Verwende grep und awk
    grep -A4 "\"$section\":" "$file" | grep "{\"name\":" | while read -r line; do
        # Die Zeile enthält alle Daten, jetzt extrahieren
        name=$(echo "$line" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
        email=$(echo "$line" | grep -o '"email": "[^"]*"' | cut -d'"' -f4)
        added=$(echo "$line" | grep -o '"added": "[^"]*"' | cut -d'"' -f4)
        
        # Ausgeben
        if [ -n "$name" ] && [ -n "$email" ] && [ -n "$added" ]; then
            echo "  - $name ($email) [seit $added]"
        fi
    done
    
    # Prüfen, ob keine Ausgabe erzeugt wurde
    if [ $(grep -A4 "\"$section\":" "$file" | grep -c "{\"name\":") -eq 0 ]; then
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