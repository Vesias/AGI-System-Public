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
        # Direkte Extraktion von Namen, E-Mail und Datum aus dem JSON
        admin_data=$(grep -A3 "\"admin\":" "$PERMISSIONS_FILE" | grep -A2 "{\"name\":" | grep -v "\]" | tr -d '[:space:]' | sed 's/{//g' | sed 's/}//g')
        
        # Zeilen ausgeben
        while IFS= read -r line; do
            if [[ "$line" == *"\"name\":"* ]]; then
                name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                email=$(echo "$line" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
                added=$(echo "$line" | grep -o '"added":"[^"]*"' | cut -d'"' -f4)
                
                if [ -n "$name" ] && [ -n "$email" ] && [ -n "$added" ]; then
                    echo "  - $name ($email) [seit $added]"
                fi
            fi
        done < <(echo "$admin_data" | tr ',' '\n')
    fi
    
    echo
    
    # Contributors auflisten
    echo -e "${CYAN}Mitwirkende:${NC}"
    if grep -q "\"contributors\": \[\]" "$PERMISSIONS_FILE"; then
        echo "  Keine Mitwirkenden gefunden."
    else
        # Direkte Extraktion von Namen, E-Mail und Datum aus dem JSON
        contrib_data=$(grep -A3 "\"contributors\":" "$PERMISSIONS_FILE" | grep -A2 "{\"name\":" | grep -v "\]" | tr -d '[:space:]' | sed 's/{//g' | sed 's/}//g')
        
        # Zeilen ausgeben
        while IFS= read -r line; do
            if [[ "$line" == *"\"name\":"* ]]; then
                name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                email=$(echo "$line" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
                added=$(echo "$line" | grep -o '"added":"[^"]*"' | cut -d'"' -f4)
                
                if [ -n "$name" ] && [ -n "$email" ] && [ -n "$added" ]; then
                    echo "  - $name ($email) [seit $added]"
                fi
            fi
        done < <(echo "$contrib_data" | tr ',' '\n')
    fi
    
    echo
    
    # Viewers auflisten
    echo -e "${CYAN}Betrachter:${NC}"
    if grep -q "\"viewers\": \[\]" "$PERMISSIONS_FILE"; then
        echo "  Keine Betrachter gefunden."
    else
        # Direkte Extraktion von Namen, E-Mail und Datum aus dem JSON
        viewer_data=$(grep -A3 "\"viewers\":" "$PERMISSIONS_FILE" | grep -A2 "{\"name\":" | grep -v "\]" | tr -d '[:space:]' | sed 's/{//g' | sed 's/}//g')
        
        # Zeilen ausgeben
        while IFS= read -r line; do
            if [[ "$line" == *"\"name\":"* ]]; then
                name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                email=$(echo "$line" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
                added=$(echo "$line" | grep -o '"added":"[^"]*"' | cut -d'"' -f4)
                
                if [ -n "$name" ] && [ -n "$email" ] && [ -n "$added" ]; then
                    echo "  - $name ($email) [seit $added]"
                fi
            fi
        done < <(echo "$viewer_data" | tr ',' '\n')
    fi
    
    echo
    
    # Letzte Aktualisierung
    local last_updated=$(grep "\"last_updated\"" "$PERMISSIONS_FILE" | cut -d'"' -f4)
    echo -e "${GRAY}Letzte Aktualisierung: $last_updated${NC}"
    
    return 0
}

# Run the function
list_users