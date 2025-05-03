#!/bin/bash
# AGI-System Installations-Skript (Öffentliche Version)

set -e

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner anzeigen
echo -e "${BLUE}"
echo "  ____ _       _    _   _ ____  _____   "
echo " / ___| |     / \  | | | |  _ \| ____|  "
echo "| |   | |    / _ \ | | | | | | |  _|    "
echo "| |___| |___/ ___ \| |_| | |_| | |___   "
echo " \____|_____/_/   \_\\___/|____/|_____|  "
echo "                                        "
echo -e "AGI-System Installation (Standard)${NC}"
echo

# Benutzerinformationen erfassen
read -p "Name: " USER_NAME
read -p "E-Mail: " USER_EMAIL
read -p "Installationsverzeichnis [~/Schreibtisch/CLAUDE]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-~/Schreibtisch/CLAUDE}

# Berechtigungsprüfung
echo -e "${YELLOW}Prüfe Berechtigungen...${NC}"
if [ -f "../permissions/access-control.json" ]; then
    if grep -q "\"email\": \"$USER_EMAIL\"" ../permissions/access-control.json; then
        echo -e "${GREEN}Benutzer mit E-Mail $USER_EMAIL gefunden.${NC}"
        HAS_PERMISSIONS=true
    else
        echo -e "${YELLOW}Hinweis: Ihre E-Mail ist nicht in den Berechtigungen gelistet.${NC}"
        echo -e "${YELLOW}Sie erhalten die öffentliche Standardinstallation.${NC}"
        HAS_PERMISSIONS=false
    fi
else
    echo -e "${YELLOW}Keine Berechtigungsdatei gefunden. Standard-Installation wird durchgeführt.${NC}"
    HAS_PERMISSIONS=false
fi

# Systemverzeichnisse erstellen
echo -e "${YELLOW}Erstelle Systemverzeichnisse...${NC}"
mkdir -p ~/.claude/{backups,logs,memory_storage,todos,templates}
mkdir -p "$INSTALL_DIR"

# Konfigurationsdateien kopieren
echo -e "${YELLOW}Kopiere Konfigurationsdateien...${NC}"
cp -r ../core/config/* ~/.claude/ 2>/dev/null || true
cp -r ../core/scripts/* ~/.claude/ 2>/dev/null || true
cp -r ../core/templates/* ~/.claude/templates/ 2>/dev/null || true

# Benutzerinformationen speichern
echo -e "${YELLOW}Erstelle Benutzerprofil...${NC}"
mkdir -p ~/.claude/private
cat > ~/.claude/.about << EOF
# Vertrauliche Nutzerinformationen
# Diese Datei enthält sensible Informationen, die nicht öffentlich zugänglich sein sollten

## Nutzer
USER_NAME="$USER_NAME"
USER_LOCATION=""

## API Keys
MCP_API_KEY=""
EOF

# Umgebungsvariablen einrichten
cat > ~/.claude/.env << EOF
# API Keys - Do not commit this file
MCP_API_KEY=""
EOF

# Berechtigungen setzen
chmod 600 ~/.claude/.about
chmod 600 ~/.claude/.env

# Ausführbarkeit für Skripte
find ~/.claude -name "*.sh" -exec chmod +x {} \;

echo -e "${GREEN}Installation abgeschlossen!${NC}"
echo -e "AGI-System wurde installiert in: ~/.claude"
echo -e "Projekte werden gespeichert in: $INSTALL_DIR"
echo -e "Nächste Schritte:"
echo -e "  1. Fügen Sie Ihre API-Schlüssel in ~/.claude/.env hinzu"
echo -e "  2. Erstellen Sie ein neues Projekt mit: ~/.claude/init_project.sh MeinProjekt"

if [ "$HAS_PERMISSIONS" = false ]; then
    echo
    echo -e "${YELLOW}Für erweiterte Funktionen und Zugriff auf verschlüsselte Inhalte, kontaktieren Sie:${NC}"
    echo -e "E-Mail: vesiassr@gmail.com"
fi