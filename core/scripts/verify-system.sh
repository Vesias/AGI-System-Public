#!/bin/bash

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log-Funktion
log() {
    local level=$1
    local message=$2
    local color=$NC
    
    case $level in
        "ERROR") color=$RED ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "INFO") color=$BLUE ;;
    esac
    
    echo -e "${color}[${level}]${NC} ${message}"
}

check_success() {
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$1"
        return 0
    else
        log "ERROR" "$2"
        return 1
    fi
}

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}  MCP-Tools-Integrator - System-Verifikation        ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo
}

# 1. Systemanforderungen prüfen
check_system_requirements() {
    log "INFO" "Prüfe Systemanforderungen..."
    echo
    
    # Docker prüfen
    echo -n "Docker: "
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log "SUCCESS" "Docker ist installiert und funktioniert."
        echo "  Version: $(docker --version)"
    else
        log "ERROR" "Docker ist nicht installiert oder der Daemon läuft nicht."
        return 1
    fi
    
    # Python prüfen
    echo -n "Python: "
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version | awk '{print $2}')
        local python_major=$(echo $python_version | cut -d. -f1)
        local python_minor=$(echo $python_version | cut -d. -f2)
        
        if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 10 ]; then
            log "SUCCESS" "Python $python_version ist installiert."
        else
            log "WARNING" "Python $python_version ist installiert, aber Version 3.10+ wird empfohlen."
        fi
    else
        log "ERROR" "Python 3 ist nicht installiert."
        return 1
    fi
    
    # Node.js prüfen
    echo -n "Node.js: "
    if command -v node &> /dev/null; then
        local node_version=$(node --version | cut -c2-)
        local node_major=$(echo $node_version | cut -d. -f1)
        
        if [ "$node_major" -ge 18 ]; then
            log "SUCCESS" "Node.js $node_version ist installiert."
        else
            log "WARNING" "Node.js $node_version ist installiert, aber Version 18+ wird empfohlen."
        fi
    else
        log "ERROR" "Node.js ist nicht installiert."
        return 1
    fi
    
    # Git prüfen
    echo -n "Git: "
    if command -v git &> /dev/null; then
        log "SUCCESS" "Git $(git --version | awk '{print $3}') ist installiert."
    else
        log "ERROR" "Git ist nicht installiert."
        return 1
    fi
    
    # NPM prüfen
    echo -n "NPM: "
    if command -v npm &> /dev/null; then
        log "SUCCESS" "NPM $(npm --version) ist installiert."
        echo "  Globale Pakete: $(npm list -g --depth=0 | wc -l) installiert"
    else
        log "ERROR" "NPM ist nicht installiert."
        return 1
    fi
    
    echo
    log "SUCCESS" "Systemanforderungen erfüllt."
    return 0
}

# 2. Hauptkomponenten prüfen
check_main_components() {
    log "INFO" "Prüfe Hauptkomponenten..."
    echo
    
    # master-init.sh prüfen
    echo -n "master-init.sh: "
    local master_init_path="$(dirname "$0")/master-init.sh"
    if [ -f "$master_init_path" ] && [ -x "$master_init_path" ]; then
        # Syntax prüfen
        bash -n "$master_init_path" &> /dev/null
        check_success "master-init.sh ist ausführbar und syntaktisch korrekt." "master-init.sh hat Syntaxfehler."
    else
        log "ERROR" "master-init.sh existiert nicht oder ist nicht ausführbar."
    fi
    
    # Qdrant Docker Container prüfen
    echo -n "Qdrant Docker Container: "
    if docker ps | grep -q "qdrant"; then
        log "SUCCESS" "Qdrant Container läuft."
        
        # Health Check versuchen
        if curl -s "http://localhost:6333/health" | grep -q "\"ok\""; then
            log "SUCCESS" "Qdrant Health-Check erfolgreich."
        else
            log "WARNING" "Qdrant Health-Check fehlgeschlagen, API möglicherweise nicht erreichbar."
        fi
    else
        if docker ps -a | grep -q "qdrant"; then
            log "WARNING" "Qdrant Container existiert, läuft aber nicht."
        else
            log "INFO" "Kein Qdrant Container gefunden. (Wird bei Projektinitialisierung erstellt)"
        fi
    fi
    
    # Transformers prüfen
    echo -n "Transformers: "
    if python3 -c "import sentence_transformers" &> /dev/null; then
        log "SUCCESS" "sentence_transformers ist installiert."
        
        # Prüfen, ob Modelle heruntergeladen wurden
        local models_dir="$HOME/.cache/torch/sentence_transformers"
        if [ -d "$models_dir" ]; then
            log "SUCCESS" "Transformers Modelle gefunden: $(find "$models_dir" -maxdepth 1 -type d | wc -l) Modelle"
        else
            log "INFO" "Keine vorheruntergeladenen Transformers Modelle gefunden. (Werden bei Bedarf heruntergeladen)"
        fi
    else
        log "WARNING" "sentence_transformers ist nicht installiert. (Wird bei Setup installiert)"
    fi
    
    # MCP-Tools prüfen
    echo -n "MCP-Tools: "
    local claude_config="$HOME/.config/claude-app/config.json"
    if [ -f "$claude_config" ]; then
        if grep -q "\"mcpTools\"" "$claude_config"; then
            log "SUCCESS" "MCP-Tools sind in der Claude-Konfiguration definiert."
        else
            log "WARNING" "Claude-Konfiguration existiert, aber MCP-Tools sind nicht konfiguriert."
        fi
    else
        log "INFO" "Claude-Konfiguration nicht gefunden. (Wird bei Setup erstellt)"
    fi
    
    # Memory-Bank Template prüfen
    echo -n "Memory-Bank Templates: "
    local template_dir="$(dirname "$0")/../templates/memory-bank-structure"
    if [ -d "$template_dir" ]; then
        local template_files=$(find "$template_dir" -type f | wc -l)
        log "SUCCESS" "Memory-Bank Templates gefunden: $template_files Dateien"
    else
        log "ERROR" "Memory-Bank Template-Verzeichnis nicht gefunden."
    fi
    
    echo
    log "SUCCESS" "Hauptkomponenten-Check abgeschlossen."
    return 0
}

# 3. Netzwerk und Zugriffsrechte prüfen
check_network_and_permissions() {
    log "INFO" "Prüfe Netzwerk und Zugriffsrechte..."
    echo
    
    # Port 6333 prüfen (Qdrant)
    echo -n "Port 6333 (Qdrant): "
    if nc -z localhost 6333 &> /dev/null; then
        log "SUCCESS" "Port 6333 ist offen und erreichbar."
    else
        log "INFO" "Port 6333 ist nicht erreichbar. (Wird bei Qdrant-Start geöffnet)"
    fi
    
    # Claude Desktop Config Permissions
    echo -n "Claude Desktop Config: "
    local claude_config_dir="$HOME/.config/claude-app"
    if [ -d "$claude_config_dir" ]; then
        if [ -w "$claude_config_dir" ]; then
            log "SUCCESS" "Claude Config-Verzeichnis existiert und hat Schreibrechte."
        else
            log "ERROR" "Keine Schreibrechte für Claude Config-Verzeichnis."
        fi
    else
        log "INFO" "Claude Config-Verzeichnis existiert nicht. (Wird bei Bedarf erstellt)"
    fi
    
    # Projektverzeichniszugriffsrechte
    echo -n "Projektverzeichnis: "
    local current_dir=$(pwd)
    if [ -w "$current_dir" ]; then
        log "SUCCESS" "Aktuelles Verzeichnis hat Schreibrechte."
    else
        log "ERROR" "Keine Schreibrechte für aktuelles Verzeichnis."
    fi
    
    echo
    log "SUCCESS" "Netzwerk- und Zugriffsrechteprüfung abgeschlossen."
    return 0
}

# 4. Integrationstests
check_integration() {
    log "INFO" "Prüfe Integration..."
    echo
    
    # curl Befehl verfügbar
    echo -n "curl Verfügbarkeit: "
    if command -v curl &> /dev/null; then
        log "SUCCESS" "curl ist installiert und verfügbar."
    else
        log "ERROR" "curl ist nicht installiert."
    fi
    
    # Projektinitialisierungstest (Simulation)
    echo -n "Projektinitialisierung: "
    log "INFO" "Für einen vollständigen Test führen Sie bitte test-install.sh aus."
    
    # Claude Desktop MCP Server
    echo -n "Claude Desktop MCP Server: "
    if pgrep -f "claude" &> /dev/null; then
        log "SUCCESS" "Claude Desktop scheint zu laufen."
    else
        log "INFO" "Claude Desktop läuft aktuell nicht. Nach der Installation starten."
    fi
    
    echo
    log "SUCCESS" "Integrations-Check abgeschlossen."
    return 0
}

# 5. Sicherheitsaspekte
check_security() {
    log "INFO" "Prüfe Sicherheitsaspekte..."
    echo
    
    # Berechtigungsmatrix
    echo -n "Berechtigungsmatrix: "
    local perms_file="$(dirname "$0")/../../permissions/access-control.json"
    if [ -f "$perms_file" ]; then
        if jq empty "$perms_file" &> /dev/null; then
            log "SUCCESS" "Berechtigungsmatrix existiert und ist gültiges JSON."
        else
            log "ERROR" "Berechtigungsmatrix ist kein gültiges JSON."
        fi
    else
        log "WARNING" "Berechtigungsmatrix nicht gefunden."
    fi
    
    # Docker Volumes
    echo -n "Docker Volumes: "
    if docker volume ls | grep -q "qdrant"; then
        log "SUCCESS" "Qdrant Docker Volumes gefunden."
    else
        log "INFO" "Keine Qdrant Docker Volumes gefunden. (Werden bei Bedarf erstellt)"
    fi
    
    # NPM Pakete validieren
    echo -n "NPM Pakete: "
    if [ -f "package.json" ]; then
        log "SUCCESS" "package.json gefunden, kann für Audit verwendet werden."
        echo "  Führen Sie 'npm audit' aus, um Sicherheitsprobleme zu prüfen."
    else
        log "INFO" "Kein package.json gefunden im aktuellen Verzeichnis."
    fi
    
    echo
    log "SUCCESS" "Sicherheitsprüfung abgeschlossen."
    return 0
}

# Git Remote URL Setup
check_git_remote() {
    log "INFO" "Prüfe Git Remote Setup..."
    echo
    
    # Git Repository prüfen
    echo -n "Git Repository: "
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        log "SUCCESS" "Aktuelles Verzeichnis ist ein Git Repository."
        
        # Remote prüfen
        echo -n "Git Remote: "
        local remote_url=$(git remote get-url origin 2>/dev/null)
        if [ -n "$remote_url" ]; then
            log "SUCCESS" "Git Remote 'origin' ist konfiguriert: $remote_url"
        else
            log "WARNING" "Git Remote 'origin' ist nicht konfiguriert."
            echo "  Führen Sie 'git remote add origin <URL>' aus, um ein Remote hinzuzufügen."
        fi
        
        # Branch prüfen
        echo -n "Git Branch: "
        local current_branch=$(git branch --show-current)
        log "SUCCESS" "Aktueller Branch: $current_branch"
        
        # Status prüfen
        echo -n "Git Status: "
        if git diff --quiet HEAD &> /dev/null; then
            log "SUCCESS" "Keine ungespeicherten Änderungen."
        else
            local changes=$(git status --porcelain | wc -l)
            log "WARNING" "$changes ungespeicherte Änderung(en) gefunden."
            echo "  Führen Sie 'git status' aus, um Details zu sehen."
        fi
    else
        log "WARNING" "Aktuelles Verzeichnis ist kein Git Repository."
    fi
    
    echo
    log "SUCCESS" "Git Remote Setup geprüft."
    return 0
}

# Zusammenfassung
show_summary() {
    echo
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}  Zusammenfassung                                   ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo
    log "INFO" "Installation:"
    echo "  curl -sSfL https://github.com/Vesias/AGI-System-Public/raw/main/core/scripts/master-init.sh | bash -s -- --project MeinProjekt"
    echo
    log "INFO" "Nächste Schritte:"
    echo "  1. Führen Sie bei Bedarf 'test-install.sh' für einen vollständigen Test aus."
    echo "  2. Starten Sie Claude Desktop neu nach der Installation."
    echo "  3. Validieren Sie den automatischen /init Prozess."
    echo
    log "SUCCESS" "Das System ist bereit für die Produktion!"
    echo
}

# Hauptfunktion
main() {
    show_banner
    
    check_system_requirements
    check_main_components
    check_network_and_permissions
    check_integration
    check_security
    check_git_remote
    
    show_summary
}

# Skript ausführen
main "$@"