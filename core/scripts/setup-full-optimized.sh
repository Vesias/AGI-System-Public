#!/usr/bin/env bash
# AGI-System Installations-Skript (Optimierte Vollversion)
# 
# Performance-Optimiertes Setup-Skript mit folgenden Verbesserungen:
# - Parallele Ausführung von I/O-intensiven Operationen
# - Verbesserte Abhängigkeitsprüfung
# - Intelligente Aktualisierung (nur bei Bedarf)
# - Fortschrittsanzeige
# - Zusammenfassung der ausgeführten Operationen

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
INSTALL_DIR=${INSTALL_DIR:-~/Schreibtisch/CLAUDE}
CLAUDE_DIR=${CLAUDE_DIR:-~/.claude}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEST_MODE=${TEST_MODE:-false}
LOG_FILE="/tmp/agi-system-setup-full-$(date +%Y%m%d%H%M%S).log"
START_TIME=$(date +%s)

# Benötigte Abhängigkeiten
DEPENDENCIES=("git" "bash" "git-crypt")
OPTIONAL_DEPENDENCIES=("node" "npm" "gpg")

# Funktion zur Anzeige des Banners
show_banner() {
    echo -e "${BLUE}"
    echo "  ____ _       _    _   _ ____  _____   "
    echo " / ___| |     / \  | | | |  _ \| ____|  "
    echo "| |   | |    / _ \ | | | | | | |  _|    "
    echo "| |___| |___/ ___ \| |_| | |_| | |___   "
    echo " \____|_____/_/   \_\\___/|____/|_____|  "
    echo "                                        "
    echo -e "AGI-System Installation (Optimierte Vollversion)${NC}"
    echo -e "${GRAY}$(date)${NC}"
    echo
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
    if [ "$TEST_MODE" = "false" ]; then
        echo -e "${color}[$level]${NC} $message"
    fi
}

# Fortschrittsanzeige
progress_bar() {
    local progress=$1
    local total=$2
    local width=50
    local percentage=$((progress * 100 / total))
    local completed=$((width * progress / total))
    local remaining=$((width - completed))
    
    # Fortschrittsbalken zeichnen
    printf "\r[${BLUE}"
    if [ $completed -gt 0 ]; then
        for ((i=0; i<completed; i++)); do
            printf "="
        done
    fi
    printf ">${NC}"
    if [ $remaining -gt 0 ]; then
        for ((i=0; i<remaining; i++)); do
            printf " "
        done
    fi
    printf "] %d%% " "$percentage"
}

# Funktion zur Prüfung der Abhängigkeiten
check_dependencies() {
    log "INFO" "Prüfe erforderliche Abhängigkeiten..."
    local missing_deps=()
    local missing_opt_deps=()
    
    # Prüfe erforderliche Abhängigkeiten
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Prüfe optionale Abhängigkeiten
    for dep in "${OPTIONAL_DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_opt_deps+=("$dep")
        fi
    done
    
    # Ausgabe der Ergebnisse
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "Folgende erforderliche Abhängigkeiten fehlen: ${missing_deps[*]}"
        log "ERROR" "Bitte installieren Sie die fehlenden Abhängigkeiten und versuchen Sie es erneut."
        return 1
    fi
    
    if [ ${#missing_opt_deps[@]} -gt 0 ]; then
        log "WARNING" "Folgende optionale Abhängigkeiten fehlen: ${missing_opt_deps[*]}"
        log "WARNING" "Die Installation wird fortgesetzt, aber einige Funktionen werden eingeschränkt sein."
    fi
    
    return 0
}

# Funktion zur Prüfung der git-crypt-Entschlüsselung
check_decryption() {
    log "INFO" "Prüfe, ob verschlüsselte Inhalte entschlüsselt wurden..."
    
    if [ ! -f "$REPO_ROOT/.git-crypt/example-decrypted.txt" ] || ! grep -q "Erfolgreich entschlüsselt" "$REPO_ROOT/.git-crypt/example-decrypted.txt"; then
        log "ERROR" "Verschlüsselte Inhalte wurden nicht entschlüsselt."
        log "ERROR" "Bitte führen Sie zuerst 'git-crypt unlock' aus."
        return 1
    fi
    
    log "SUCCESS" "Verschlüsselte Inhalte wurden entschlüsselt."
    return 0
}

# Funktion zur Berechtigungsprüfung
check_permissions() {
    local email="$1"
    local permission_file="$REPO_ROOT/permissions/access-control.json"
    
    if [[ -z "$email" ]]; then
        log "ERROR" "Keine E-Mail angegeben. Die Vollversion erfordert eine gültige E-Mail."
        return 1
    fi
    
    log "INFO" "Prüfe Berechtigungen für $email..."
    
    if [[ ! -f "$permission_file" ]]; then
        log "ERROR" "Keine Berechtigungsdatei gefunden."
        return 1
    fi
    
    # Prüfe, ob Benutzer vorhanden ist
    if ! grep -q "\"email\": \"$email\"" "$permission_file"; then
        log "ERROR" "Keine Berechtigung für E-Mail $email gefunden."
        log "ERROR" "Kontaktieren Sie den Repository-Eigentümer für Zugriff."
        return 1
    fi
    
    # Bestimme Zugriffsebene
    if grep -q "\"admin\".*\"email\": \"$email\"" "$permission_file"; then
        export USER_ACCESS_LEVEL="admin"
    elif grep -q "\"contributors\".*\"email\": \"$email\"" "$permission_file"; then
        export USER_ACCESS_LEVEL="contributor"
    else
        export USER_ACCESS_LEVEL="viewer"
    fi
    
    log "SUCCESS" "Benutzer mit E-Mail $email gefunden. Zugriffsebene: $USER_ACCESS_LEVEL"
    return 0
}

# Funktion zum Erstellen der Verzeichnisstruktur
create_directories() {
    log "INFO" "Erstelle Systemverzeichnisse..."
    
    # Array mit zu erstellenden Verzeichnissen
    local dirs=(
        "$CLAUDE_DIR"
        "$CLAUDE_DIR/backups"
        "$CLAUDE_DIR/logs"
        "$CLAUDE_DIR/memory_storage"
        "$CLAUDE_DIR/todos"
        "$CLAUDE_DIR/templates"
        "$CLAUDE_DIR/private"
        "$INSTALL_DIR"
    )
    
    # Verzeichnisse parallel erstellen
    (
        for dir in "${dirs[@]}"; do
            mkdir -p "$dir" &
        done
        wait
    )
    
    log "SUCCESS" "Verzeichnisstruktur erstellt."
    return 0
}

# Funktion zum Kopieren der Dateien
copy_files() {
    log "INFO" "Kopiere Konfigurationsdateien..."
    
    # Erstelle Arrays mit Quell- und Zielverzeichnissen
    local sources=(
        "$REPO_ROOT/core/config"
        "$REPO_ROOT/core/scripts"
        "$REPO_ROOT/core/templates"
    )
    
    local destinations=(
        "$CLAUDE_DIR"
        "$CLAUDE_DIR"
        "$CLAUDE_DIR/templates"
    )
    
    # Fortschrittsbalken initialisieren
    local total=${#sources[@]}
    local current=0
    
    # Dateien parallel kopieren und Fortschritt anzeigen
    for ((i=0; i<${#sources[@]}; i++)); do
        local source="${sources[$i]}"
        local dest="${destinations[$i]}"
        
        # Prüfen, ob Quellverzeichnis existiert
        if [[ ! -d "$source" ]]; then
            log "WARNING" "Quellverzeichnis $source nicht gefunden, überspringe..."
            current=$((current+1))
            progress_bar $current $total
            continue
        fi
        
        # Prüfe, ob ein Update notwendig ist
        local update_needed=false
        
        # Überprüfe, ob Zielverzeichnis existiert
        if [[ ! -d "$dest" ]]; then
            update_needed=true
        else
            # Vergleiche Dateizeit der neuesten Datei in Quelle und Ziel
            local newest_source=$(find "$source" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1)
            local newest_dest=$(find "$dest" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1)
            
            if [[ -n "$newest_source" && (-z "$newest_dest" || $(echo "$newest_source" | cut -d' ' -f1) > $(echo "$newest_dest" | cut -d' ' -f1)) ]]; then
                update_needed=true
            fi
        fi
        
        # Aktualisiere nur wenn nötig
        if [[ "$update_needed" = true ]]; then
            cp -r "$source"/* "$dest"/ 2>/dev/null || true
            log "INFO" "Dateien von $source nach $dest kopiert."
        else
            log "INFO" "Keine Aktualisierung für $dest notwendig."
        fi
        
        current=$((current+1))
        progress_bar $current $total
    done
    
    echo # Neue Zeile nach Fortschrittsbalken
    log "SUCCESS" "Konfigurationsdateien kopiert."
    return 0
}

# Funktion zum Import der verschlüsselten Daten
import_encrypted_data() {
    log "INFO" "Importiere verschlüsselte Daten..."
    
    # Nutzerprofilimport
    local email="$1"
    if [[ -f "$REPO_ROOT/.git-crypt/user-profiles/$email.about" ]]; then
        log "INFO" "Importiere Benutzerprofil für $email..."
        cp "$REPO_ROOT/.git-crypt/user-profiles/$email.about" "$CLAUDE_DIR/.about"
        chmod 600 "$CLAUDE_DIR/.about"
    else
        # Erstelle neues Benutzerprofil
        local name="$2"
        local access_level="${USER_ACCESS_LEVEL:-viewer}"
        
        log "INFO" "Erstelle neues Benutzerprofil für $email..."
        cat > "$CLAUDE_DIR/.about" << EOF
# Vertrauliche Nutzerinformationen
# Diese Datei enthält sensible Informationen, die nicht öffentlich zugänglich sein sollten

## Nutzer
USER_NAME="$name"
USER_EMAIL="$email"
USER_LOCATION=""
USER_ACCESS_LEVEL="$access_level"
USER_SETUP_DATE="$(date -I)"

## API Keys
# Diese werden aus der .env-Datei geladen
EOF
        chmod 600 "$CLAUDE_DIR/.about"
    fi
    
    # API-Schlüssel importieren
    if [[ -f "$REPO_ROOT/.git-crypt/api-keys.env" ]]; then
        log "INFO" "Importiere API-Schlüssel..."
        cp "$REPO_ROOT/.git-crypt/api-keys.env" "$CLAUDE_DIR/.env"
        chmod 600 "$CLAUDE_DIR/.env"
    else
        log "WARNING" "Keine API-Schlüssel-Datei gefunden. Erstelle leere .env-Datei..."
        cat > "$CLAUDE_DIR/.env" << EOF
# API Keys - Do not commit this file
MCP_API_KEY=""
EOF
        chmod 600 "$CLAUDE_DIR/.env"
    fi
    
    # MCP-Server-Konfiguration importieren
    if [[ -f "$REPO_ROOT/.git-crypt/mcpservers-full.json" ]]; then
        log "INFO" "Importiere MCP-Server-Konfiguration..."
        cp "$REPO_ROOT/.git-crypt/mcpservers-full.json" "$CLAUDE_DIR/mcpservers.json"
    fi
    
    # Weitere verschlüsselte Konfigurationsdateien importieren
    if [[ -d "$REPO_ROOT/.git-crypt/config" ]]; then
        log "INFO" "Importiere zusätzliche Konfigurationsdateien..."
        cp -r "$REPO_ROOT/.git-crypt/config"/* "$CLAUDE_DIR/" 2>/dev/null || true
    fi
    
    log "SUCCESS" "Verschlüsselte Daten importiert."
    return 0
}

# Funktion zum Setzen der Berechtigungen
set_permissions() {
    log "INFO" "Setze Berechtigungen für Skripte..."
    
    # Finde alle Skripte und setze Ausführbarkeit
    find "$CLAUDE_DIR" -name "*.sh" -exec chmod +x {} \; &
    wait
    
    log "SUCCESS" "Berechtigungen gesetzt."
    return 0
}

# Funktion zur Zusammenfassung der Installation
summarize_installation() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GREEN}Vollständige Installation abgeschlossen!${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "AGI-System wurde installiert in: ${CYAN}$CLAUDE_DIR${NC}"
    echo -e "Projekte werden gespeichert in: ${CYAN}$INSTALL_DIR${NC}"
    echo -e "Zugriffsebene: ${CYAN}$USER_ACCESS_LEVEL${NC}"
    echo -e "Installationszeit: ${CYAN}$duration Sekunden${NC}"
    echo -e "Installationslog: ${CYAN}$LOG_FILE${NC}"
    echo
    echo -e "${BLUE}Nächste Schritte:${NC}"
    echo -e "  1. API-Schlüssel in ${CYAN}$CLAUDE_DIR/.env${NC} prüfen und ggf. ergänzen"
    echo -e "  2. Erstellen Sie ein neues Projekt mit: ${CYAN}$CLAUDE_DIR/init_project.sh MeinProjekt${NC}"
    
    return 0
}

# Hauptinstallationsfunktion
main_installation() {
    local name="$1"
    local email="$2"
    
    # Anzeige des Banners
    show_banner
    
    # Initialisierung des Logs
    echo "# AGI-System Vollständige Installation Log" > "$LOG_FILE"
    echo "# $(date)" >> "$LOG_FILE"
    echo "# User: $name ($email)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    # Abhängigkeiten prüfen
    check_dependencies || return 1
    
    # Git-crypt-Entschlüsselung prüfen
    check_decryption || return 1
    
    # Berechtigungen prüfen
    check_permissions "$email" || return 1
    
    # Verzeichnisse erstellen und Dateien kopieren (parallel)
    create_directories &
    local dir_pid=$!
    wait $dir_pid
    
    copy_files
    
    # Importiere verschlüsselte Daten
    import_encrypted_data "$email" "$name"
    
    # Berechtigungen setzen
    set_permissions
    
    # Zusammenfassung anzeigen
    summarize_installation
    
    return 0
}

# Wenn im Test-Modus, überspringen wir die Benutzereingabe
if [ "$TEST_MODE" = "true" ]; then
    log "INFO" "Test-Modus aktiviert. Verwende Standardwerte."
    main_installation "Test User" "test@example.com"
    exit $?
fi

# Benutzerinformationen erfassen
read -p "Name: " USER_NAME
read -p "E-Mail: " USER_EMAIL
read -p "Installationsverzeichnis [$INSTALL_DIR]: " USER_INSTALL_DIR
INSTALL_DIR=${USER_INSTALL_DIR:-$INSTALL_DIR}

# Hauptinstallation starten
main_installation "$USER_NAME" "$USER_EMAIL"

exit $?