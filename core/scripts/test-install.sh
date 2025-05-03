#!/usr/bin/env bash
# ============================================================================
# AGI-System Installation-Tester
# 
# Dieses Skript testet die Installation eines AGI-System-Projekts mit dem 
# Master-Initialisierer ohne externe Server zu benötigen.
# ============================================================================

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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
MASTER_INIT="$SCRIPT_DIR/master-init.sh"
TEST_DIR="/tmp/agi-system-test"
PROJECT_NAME="test-project"
TEST_LOG="/tmp/agi-test-install-$(date +%Y%m%d%H%M%S).log"
CLEANUP=true
SKIP_MCP=false
SKIP_VECTOR=false
SKIP_DOCKER=false

# Funktion zur Anzeige der Verwendung
usage() {
    cat << EOF
Verwendung: $0 [Optionen]

Optionen:
  -h, --help                  Diese Hilfe anzeigen
  -d, --test-dir DIR          Testverzeichnis (Standard: $TEST_DIR)
  -p, --project PROJEKT       Projektname (Standard: $PROJECT_NAME)
  --no-cleanup                Keine Aufräumarbeiten nach dem Test
  --skip-mcp                  MCP-Tools-Integration überspringen
  --skip-vector               Vektordatenbank-Integration überspringen
  --skip-docker               Docker-Integration überspringen

Beispiel:
  $0 --project mein-test-projekt
  $0 --test-dir ~/test --skip-docker
EOF
}

# Argumente verarbeiten
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--test-dir)
                shift
                TEST_DIR="$1"
                ;;
            -p|--project)
                shift
                PROJECT_NAME="$1"
                ;;
            --no-cleanup)
                CLEANUP=false
                ;;
            --skip-mcp)
                SKIP_MCP=true
                ;;
            --skip-vector)
                SKIP_VECTOR=true
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                ;;
            *)
                echo -e "${RED}Fehler: Unbekannte Option $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# Überprüfen, ob der Master-Initialisierer existiert
check_master_init() {
    if [ ! -f "$MASTER_INIT" ]; then
        echo -e "${RED}Fehler: Master-Initialisierer nicht gefunden: $MASTER_INIT${NC}" >&2
        exit 1
    fi
    
    # Executable machen
    chmod +x "$MASTER_INIT"
}

# Testumgebung vorbereiten
prepare_test_env() {
    echo -e "${BLUE}Bereite Testumgebung vor...${NC}"
    
    # Testverzeichnis erstellen (falls es nicht existiert)
    if [ -d "$TEST_DIR" ]; then
        if [ "$CLEANUP" = true ]; then
            echo -e "${YELLOW}Testverzeichnis existiert bereits. Lösche...${NC}"
            rm -rf "$TEST_DIR"
            mkdir -p "$TEST_DIR"
        fi
    else
        mkdir -p "$TEST_DIR"
    fi
    
    echo -e "${GREEN}Testumgebung vorbereitet: $TEST_DIR${NC}"
}

# Master-Initialisierer ausführen
run_master_init() {
    echo -e "${BLUE}Führe Master-Initialisierer aus...${NC}"
    
    # Optionen für den Master-Initialisierer
    local options="--project $PROJECT_NAME --dir $TEST_DIR"
    
    if [ "$SKIP_MCP" = true ]; then
        options="$options --no-mcp-tools"
    fi
    
    if [ "$SKIP_VECTOR" = true ]; then
        options="$options --no-vector-db"
    fi
    
    if [ "$SKIP_DOCKER" = true ]; then
        options="$options --no-docker"
    fi
    
    # In nicht-interaktivem Modus ausführen
    options="$options --non-interactive"
    
    # Master-Initialisierer ausführen
    echo -e "${YELLOW}Ausführen: $MASTER_INIT $options${NC}"
    bash "$MASTER_INIT" $options > "$TEST_LOG" 2>&1
    
    # Prüfen, ob die Installation erfolgreich war
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Master-Initialisierer erfolgreich ausgeführt.${NC}"
    else
        echo -e "${RED}Fehler bei der Ausführung des Master-Initialisierers.${NC}"
        echo -e "${RED}Siehe Logdatei: $TEST_LOG${NC}"
        exit 1
    fi
}

# Testergebnisse prüfen
verify_installation() {
    echo -e "${BLUE}Überprüfe Installation...${NC}"
    
    local project_path="$TEST_DIR/$PROJECT_NAME"
    local success=true
    
    # Prüfen, ob das Projektverzeichnis existiert
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}FEHLGESCHLAGEN: Projektverzeichnis existiert nicht: $project_path${NC}"
        success=false
    else
        echo -e "${GREEN}OK: Projektverzeichnis existiert: $project_path${NC}"
    fi
    
    # Prüfen, ob die .about.interactive-Datei existiert
    if [ ! -f "$project_path/.about.interactive" ]; then
        echo -e "${RED}FEHLGESCHLAGEN: .about.interactive-Datei existiert nicht${NC}"
        success=false
    else
        echo -e "${GREEN}OK: .about.interactive-Datei existiert${NC}"
    fi
    
    # Prüfen, ob die Memory-Bank-Struktur existiert
    if [ ! -d "$project_path/memory-bank" ]; then
        echo -e "${RED}FEHLGESCHLAGEN: Memory-Bank-Verzeichnis existiert nicht${NC}"
        success=false
    else
        echo -e "${GREEN}OK: Memory-Bank-Verzeichnis existiert${NC}"
        
        # Wichtige Memory-Bank-Dateien prüfen
        local memory_files=("projectbrief.md" "productContext.md" "activeContext.md" "systemPatterns.md" "techContext.md" "progress.md" ".clauderules")
        
        for file in "${memory_files[@]}"; do
            if [ ! -f "$project_path/memory-bank/$file" ]; then
                echo -e "${RED}FEHLGESCHLAGEN: Memory-Bank-Datei fehlt: $file${NC}"
                success=false
            else
                echo -e "${GREEN}OK: Memory-Bank-Datei existiert: $file${NC}"
            fi
        done
    fi
    
    # MCP-Tools-Konfiguration prüfen (falls aktiviert)
    if [ "$SKIP_MCP" = false ]; then
        if [ ! -f "$project_path/.config/claude/mcpservers.json" ]; then
            echo -e "${RED}FEHLGESCHLAGEN: MCP-Tools-Konfiguration existiert nicht${NC}"
            success=false
        else
            echo -e "${GREEN}OK: MCP-Tools-Konfiguration existiert${NC}"
        fi
        
        if [ ! -f "$project_path/start-mcp-tools.sh" ]; then
            echo -e "${RED}FEHLGESCHLAGEN: MCP-Tools-Startskript existiert nicht${NC}"
            success=false
        else
            echo -e "${GREEN}OK: MCP-Tools-Startskript existiert${NC}"
        fi
    fi
    
    # Qdrant-Konfiguration prüfen (falls aktiviert)
    if [ "$SKIP_VECTOR" = false ]; then
        if [ ! -f "$project_path/docker-compose.yml" ]; then
            echo -e "${RED}FEHLGESCHLAGEN: Docker-Compose-Datei existiert nicht${NC}"
            success=false
        else
            echo -e "${GREEN}OK: Docker-Compose-Datei existiert${NC}"
        fi
        
        if [ ! -f "$project_path/start-qdrant.sh" ] || [ ! -f "$project_path/stop-qdrant.sh" ]; then
            echo -e "${RED}FEHLGESCHLAGEN: Qdrant-Skripte existieren nicht${NC}"
            success=false
        else
            echo -e "${GREEN}OK: Qdrant-Skripte existieren${NC}"
        fi
        
        if [ ! -f "$project_path/memory-bank/vector_index/scripts/vector_utils.py" ]; then
            echo -e "${RED}FEHLGESCHLAGEN: Vektor-Utilities existieren nicht${NC}"
            success=false
        else
            echo -e "${GREEN}OK: Vektor-Utilities existieren${NC}"
        fi
    fi
    
    # Initialisierungsskript prüfen
    if [ ! -f "$project_path/init-project.sh" ]; then
        echo -e "${RED}FEHLGESCHLAGEN: Initialisierungsskript existiert nicht${NC}"
        success=false
    else
        echo -e "${GREEN}OK: Initialisierungsskript existiert${NC}"
    fi
    
    # Berechtigungen prüfen
    if [ ! -f "$project_path/setup-permissions.sh" ]; then
        echo -e "${RED}FEHLGESCHLAGEN: Berechtigungsskript existiert nicht${NC}"
        success=false
    else
        echo -e "${GREEN}OK: Berechtigungsskript existiert${NC}"
    fi
    
    # Gesamtergebnis
    if [ "$success" = true ]; then
        echo -e "${GREEN}Alle Tests erfolgreich: Installation wurde korrekt durchgeführt.${NC}"
    else
        echo -e "${RED}Einige Tests sind fehlgeschlagen. Siehe oben für Details.${NC}"
        exit 1
    fi
}

# Aufräumarbeiten
cleanup() {
    if [ "$CLEANUP" = true ]; then
        echo -e "${BLUE}Aufräumen...${NC}"
        rm -rf "$TEST_DIR"
        echo -e "${GREEN}Aufräumarbeiten abgeschlossen.${NC}"
    else
        echo -e "${YELLOW}Aufräumarbeiten übersprungen. Testverzeichnis bleibt erhalten: $TEST_DIR/${NC}"
    fi
}

# Hauptfunktion
main() {
    # Banner anzeigen
    echo -e "${BLUE}"
    echo "  _____         _     _           _        _ _           "
    echo " |_   _|__  ___| |_  (_)_ __  ___| |_ __ _| | | ___ _ __ "
    echo "   | |/ _ \/ __| __| | | '_ \/ __| __/ _\` | | |/ _ \ '__|"
    echo "   | |  __/\__ \ |_  | | | | \__ \ || (_| | | |  __/ |   "
    echo "   |_|\___||___/\__| |_|_| |_|___/\__\__,_|_|_|\___|_|   "
    echo ""
    echo -e "AGI-System Installation-Tester${NC}"
    echo -e "${GRAY}$(date)${NC}"
    echo
    
    # Parameter verarbeiten
    parse_args "$@"
    
    # Prüfen, ob der Master-Initialisierer existiert
    check_master_init
    
    # Testumgebung vorbereiten
    prepare_test_env
    
    # Master-Initialisierer ausführen
    run_master_init
    
    # Testergebnisse prüfen
    verify_installation
    
    # Aufräumarbeiten
    cleanup
    
    echo -e "${GREEN}Test erfolgreich abgeschlossen.${NC}"
    echo -e "${GRAY}Logdatei: $TEST_LOG${NC}"
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?