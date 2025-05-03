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
INTERACTIVE_MODE=true

list_users() {
    echo "INFO: Liste alle Benutzer auf (ohne jq)..."
    
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Benutzer in $PERMISSIONS_FILE ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    
    # Admins auflisten
    echo -e "${CYAN}Administratoren:${NC}"
    if grep -q "\"admin\": \[\]" "$PERMISSIONS_FILE"; then
        echo "  Keine Administratoren gefunden."
    else
        echo "Debug: Admin section processing..."
        grep -A10 "\"admin\":" "$PERMISSIONS_FILE"
        echo "---"
        grep -A3 "\"admin\": \[" "$PERMISSIONS_FILE" | grep -A2 "\"name\"" | grep -v "\]" | sed 's/.*"name": "\(.*\)",/  - \1/g' | sed 's/.*"email": "\(.*\)",/    (\1)/g' | sed 's/.*"added": "\(.*\)",/    [seit \1]/g' | paste -d " " - - -
    fi
    
    echo
    
    # Contributors auflisten
    echo -e "${CYAN}Mitwirkende:${NC}"
    if grep -q "\"contributors\": \[\]" "$PERMISSIONS_FILE"; then
        echo "  Keine Mitwirkenden gefunden."
    else
        echo "Debug: Contributors section processing..."
        grep -A10 "\"contributors\":" "$PERMISSIONS_FILE"
        echo "---"
        grep -A3 "\"contributors\": \[" "$PERMISSIONS_FILE" | grep -A2 "\"name\"" | grep -v "\]" | sed 's/.*"name": "\(.*\)",/  - \1/g' | sed 's/.*"email": "\(.*\)",/    (\1)/g' | sed 's/.*"added": "\(.*\)",/    [seit \1]/g' | paste -d " " - - -
    fi
    
    echo
    
    # Viewers auflisten
    echo -e "${CYAN}Betrachter:${NC}"
    if grep -q "\"viewers\": \[\]" "$PERMISSIONS_FILE"; then
        echo "  Keine Betrachter gefunden."
    else
        echo "Debug: Viewers section processing..."
        grep -A10 "\"viewers\":" "$PERMISSIONS_FILE"
        echo "---"
        grep -A3 "\"viewers\": \[" "$PERMISSIONS_FILE" | grep -A2 "\"name\"" | grep -v "\]" | sed 's/.*"name": "\(.*\)",/  - \1/g' | sed 's/.*"email": "\(.*\)",/    (\1)/g' | sed 's/.*"added": "\(.*\)",/    [seit \1]/g' | paste -d " " - - -
    fi
    
    echo
    
    # Letzte Aktualisierung
    local last_updated=$(grep "\"last_updated\"" "$PERMISSIONS_FILE" | cut -d'"' -f4)
    echo -e "${GRAY}Letzte Aktualisierung: $last_updated${NC}"
    
    return 0
}

# Run the function
list_users