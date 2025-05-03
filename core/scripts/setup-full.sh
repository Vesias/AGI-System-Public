#!/bin/bash
# AGI-System Installations-Skript (Vollversion mit verschlüsselten Inhalten)

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
echo -e "AGI-System Installation (Vollversion)${NC}"
echo

# Prüfe, ob git-crypt entschlüsselt wurde
if [ ! -f "../.git-crypt/example-decrypted.txt" ] || ! grep -q "Erfolgreich entschlüsselt" "../.git-crypt/example-decrypted.txt"; then
    echo -e "${RED}Fehler: Verschlüsselte Inhalte wurden nicht entschlüsselt.${NC}"
    echo -e "Bitte führen Sie zuerst 'git-crypt unlock' aus."
    exit 1
fi

# Benutzerinformationen erfassen
read -p "Name: " USER_NAME
read -p "E-Mail: " USER_EMAIL
read -p "Installationsverzeichnis [~/Schreibtisch/CLAUDE]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-~/Schreibtisch/CLAUDE}

# Berechtigungsprüfung
echo -e "${YELLOW}Prüfe Berechtigungen...${NC}"
if ! grep -q "\"email\": \"$USER_EMAIL\"" ../permissions/access-control.json; then
    echo -e "${RED}Fehler: Keine Berechtigung für E-Mail $USER_EMAIL gefunden.${NC}"
    echo -e "Kontaktieren Sie den Repository-Eigentümer für Zugriff."
    exit 1
fi

# Bestimme Zugriffsebene
if grep -q "\"admin\".*\"email\": \"$USER_EMAIL\"" ../permissions/access-control.json; then
    ACCESS_LEVEL="admin"
elif grep -q "\"contributors\".*\"email\": \"$USER_EMAIL\"" ../permissions/access-control.json; then
    ACCESS_LEVEL="contributor"
else
    ACCESS_LEVEL="viewer"
fi

echo -e "${GREEN}Benutzer mit E-Mail $USER_EMAIL gefunden. Zugriffsebene: $ACCESS_LEVEL${NC}"

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

# Kopiere API-Schlüssel aus dem entschlüsselten Bereich
if [ -f "../.git-crypt/api-keys.env" ]; then
    echo -e "${YELLOW}Importiere API-Schlüssel...${NC}"
    cp "../.git-crypt/api-keys.env" ~/.claude/.env
    chmod 600 ~/.claude/.env
else
    # Erstelle leere .env-Datei
    cat > ~/.claude/.env << EOF
# API Keys - Do not commit this file
MCP_API_KEY=""
EOF
    chmod 600 ~/.claude/.env
fi

# Kopiere Benutzerprofilinformationen
if [ -f "../.git-crypt/user-profiles/$USER_EMAIL.about" ]; then
    echo -e "${YELLOW}Importiere Benutzerprofil...${NC}"
    cp "../.git-crypt/user-profiles/$USER_EMAIL.about" ~/.claude/.about
    chmod 600 ~/.claude/.about
else
    # Erstelle neues Benutzerprofil
    cat > ~/.claude/.about << EOF
# Vertrauliche Nutzerinformationen
# Diese Datei enthält sensible Informationen, die nicht öffentlich zugänglich sein sollten

## Nutzer
USER_NAME="$USER_NAME"
USER_LOCATION=""
USER_ACCESS_LEVEL="$ACCESS_LEVEL"
USER_SETUP_DATE="$(date -I)"

## API Keys
# Diese werden aus der .env-Datei geladen
EOF
    chmod 600 ~/.claude/.about
fi

# Kopiere verschlüsselte MCP-Server-Konfiguration
if [ -f "../.git-crypt/mcpservers-full.json" ]; then
    echo -e "${YELLOW}Importiere MCP-Server-Konfiguration...${NC}"
    cp "../.git-crypt/mcpservers-full.json" ~/.claude/mcpservers.json
fi

# Ausführbarkeit für Skripte
find ~/.claude -name "*.sh" -exec chmod +x {} \;

echo -e "${GREEN}Installation abgeschlossen!${NC}"
echo -e "AGI-System wurde installiert in: ~/.claude"
echo -e "Projekte werden gespeichert in: $INSTALL_DIR"
echo -e "Zugriffebene: $ACCESS_LEVEL"
echo -e "Nächste Schritte:"
echo -e "  1. API-Schlüssel in ~/.claude/.env prüfen und ggf. ergänzen"
echo -e "  2. Erstellen Sie ein neues Projekt mit: ~/.claude/init_project.sh MeinProjekt"