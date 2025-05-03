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
    
    echo "DEBUG: Dateiinhalt:"
    cat "$PERMISSIONS_FILE"
    echo "---"
    
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Benutzer in $PERMISSIONS_FILE ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    
    # Admins auflisten
    echo -e "${CYAN}Administratoren:${NC}"
    if grep -q "\"admin\": \[\]" "$PERMISSIONS_FILE"; then
        echo "  Keine Administratoren gefunden."
    else
        echo "DEBUG: Admin grep output:"
        grep -A3 "\"admin\":" "$PERMISSIONS_FILE"
        echo "---"
        
        # Direkte Extraktion von Namen, E-Mail und Datum aus dem JSON
        admin_data=$(grep -A3 "\"admin\":" "$PERMISSIONS_FILE" | grep -A2 "{\"name\":" | grep -v "\]" | tr -d '[:space:]')
        echo "DEBUG: admin_data=$admin_data"
        
        admin_data_clean=$(echo "$admin_data" | sed 's/{//g' | sed 's/}//g')
        echo "DEBUG: admin_data_clean=$admin_data_clean"
        
        # Zeilen ausgeben
        echo "DEBUG: Parsing lines:"
        echo "$admin_data_clean" | tr ',' '\n' | while IFS= read -r line; do
            echo "DEBUG: line=$line"
            if [[ "$line" == *"\"name\":"* ]]; then
                echo "DEBUG: line contains name"
                name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                email=$(echo "$line" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
                added=$(echo "$line" | grep -o '"added":"[^"]*"' | cut -d'"' -f4)
                
                echo "DEBUG: name=$name, email=$email, added=$added"
                
                if [ -n "$name" ] && [ -n "$email" ] && [ -n "$added" ]; then
                    echo "  - $name ($email) [seit $added]"
                fi
            fi
        done
    fi
    
    echo
    
    return 0
}

# Run the function
list_users