#!/usr/bin/env bash
# ============================================================================
# MCP-Tools-Setup für AGI-Projekte
# 
# Dieses Skript richtet Model Context Protocol (MCP) Tools für AGI-Projekte ein.
# Es installiert und konfiguriert:
# - desktop-commander: Dateisystem- und Shell-Operationen
# - memory-bank-mcp: Wissens- und Kontextspeicherverwaltung
# - marketing-tools: Marketing-bezogene Analyse und Tools
# - browser-tools: Web-Recherche und Browser-Automatisierung
# - toolbox: Allgemeine KI-Tools und Hilfsprogramme
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
PROJECT_DIR=""
CONFIG_DIR=""
LOG_FILE="/tmp/mcp-tools-setup-$(date +%Y%m%d%H%M%S).log"
INTERACTIVE_MODE=true
SELECTED_TOOLS=("desktop-commander" "memory-bank" "browser-tools" "toolbox" "marketing-tools")
INSTALL_DEPENDENCIES=true

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}"
    echo "   __  __  ____ ____    _____           _     "
    echo "  |  \/  |/ ___|  _ \  |_   _|__   ___ | |___ "
    echo "  | |\/| | |   | |_) |   | |/ _ \ / _ \| / __|"
    echo "  | |  | | |___|  __/    | | (_) | (_) | \__ \\"
    echo "  |_|  |_|\____|_|       |_|\___/ \___/|_|___/"
    echo "                                              "
    echo -e "MCP-Tools-Setup für AGI-Projekte${NC}"
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
    if [ "$INTERACTIVE_MODE" = "true" ]; then
        echo -e "${color}[$level]${NC} $message"
    fi
}

# Hilfetext anzeigen
show_help() {
    echo "Verwendung: $0 [optionen] <PROJEKTVERZEICHNIS>"
    echo
    echo "Optionen:"
    echo "  -h, --help                  Diese Hilfe anzeigen"
    echo "  -n, --non-interactive       Nichtinteraktiver Modus (für Automatisierung)"
    echo "  -t, --tools TOOLS           Kommagetrennte Liste der zu installierenden Tools"
    echo "                              Verfügbare Tools: desktop-commander,memory-bank,browser-tools,toolbox,marketing-tools"
    echo "  -c, --config-dir DIR        Verzeichnis für Konfigurationsdateien (Standard: <PROJEKTVERZEICHNIS>/.config/claude)"
    echo "  --no-dependencies           Abhängigkeiten nicht installieren"
    echo
    echo "Beispiele:"
    echo "  $0 /path/to/project                          # Alle MCP-Tools installieren"
    echo "  $0 --tools desktop-commander,memory-bank /path/to/project   # Nur ausgewählte Tools installieren"
    echo "  $0 --non-interactive /path/to/project        # Für Skript-Integration"
    echo
}

# Funktion zur Prüfung der Abhängigkeiten
check_dependencies() {
    log "INFO" "Prüfe Abhängigkeiten..."
    
    # Prüfe Node.js und npm
    if ! command -v node &> /dev/null; then
        log "WARNING" "Node.js ist nicht installiert."
        
        if [ "$INSTALL_DEPENDENCIES" = true ] && [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${YELLOW}Node.js ist für MCP-Tools erforderlich. Möchten Sie es installieren? (j/n)${NC}"
            read -r INSTALL_NODE
            
            if [[ "$INSTALL_NODE" =~ ^[Jj] ]]; then
                log "INFO" "Installiere Node.js..."
                
                # OS erkennen und entsprechende Installation durchführen
                if [ -f /etc/debian_version ]; then
                    # Debian/Ubuntu
                    sudo apt update
                    sudo apt install -y nodejs npm
                elif [ -f /etc/redhat-release ]; then
                    # RHEL/CentOS/Fedora
                    sudo dnf install -y nodejs npm
                elif [ -f /etc/arch-release ]; then
                    # Arch Linux
                    sudo pacman -S --noconfirm nodejs npm
                elif [ "$(uname)" == "Darwin" ]; then
                    # macOS
                    brew install node
                else
                    log "ERROR" "Automatische Installation auf diesem Betriebssystem nicht unterstützt."
                    log "ERROR" "Bitte installieren Sie Node.js manuell und führen Sie das Skript erneut aus."
                    return 1
                fi
                
                log "SUCCESS" "Node.js installiert."
            else
                log "ERROR" "Node.js ist für MCP-Tools erforderlich. Installation abgebrochen."
                return 1
            fi
        else
            log "ERROR" "Node.js ist für MCP-Tools erforderlich. Bitte installieren Sie es manuell."
            return 1
        fi
    fi
    
    # Prüfe npx
    if ! command -v npx &> /dev/null; then
        log "WARNING" "npx ist nicht installiert."
        
        if [ "$INSTALL_DEPENDENCIES" = true ]; then
            log "INFO" "Installiere npx..."
            npm install -g npx
            log "SUCCESS" "npx installiert."
        else
            log "ERROR" "npx ist für MCP-Tools erforderlich. Bitte installieren Sie es manuell."
            return 1
        fi
    fi
    
    log "SUCCESS" "Alle Abhängigkeiten vorhanden."
    return 0
}

# Funktion zur Verarbeitung der Kommandozeilenargumente
process_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                ;;
            -t|--tools)
                shift
                IFS=',' read -ra SELECTED_TOOLS <<< "$1"
                ;;
            -c|--config-dir)
                shift
                CONFIG_DIR="$1"
                ;;
            --no-dependencies)
                INSTALL_DEPENDENCIES=false
                ;;
            *)
                if [ -z "$PROJECT_DIR" ]; then
                    PROJECT_DIR="$1"
                else
                    log "ERROR" "Unbekannter Parameter: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
        shift
    done
    
    # Prüfe, ob Projektverzeichnis angegeben wurde
    if [ -z "$PROJECT_DIR" ]; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            read -p "Projektverzeichnis: " PROJECT_DIR
            
            if [ -z "$PROJECT_DIR" ]; then
                log "ERROR" "Kein Projektverzeichnis angegeben."
                exit 1
            fi
        else
            log "ERROR" "Kein Projektverzeichnis angegeben."
            show_help
            exit 1
        fi
    fi
    
    # Prüfe, ob Projektverzeichnis existiert
    if [ ! -d "$PROJECT_DIR" ]; then
        log "ERROR" "Projektverzeichnis existiert nicht: $PROJECT_DIR"
        exit 1
    fi
    
    # Standardwerte für CONFIG_DIR setzen, falls nicht angegeben
    if [ -z "$CONFIG_DIR" ]; then
        CONFIG_DIR="$PROJECT_DIR/.config/claude"
    fi
    
    # Tool-Auswahl im interaktiven Modus
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${BLUE}Welche MCP-Tools möchten Sie installieren?${NC}"
        
        local all_tools=("desktop-commander" "memory-bank" "browser-tools" "toolbox" "marketing-tools")
        local selected=()
        
        for tool in "${all_tools[@]}"; do
            local is_selected=false
            
            for selected_tool in "${SELECTED_TOOLS[@]}"; do
                if [ "$tool" = "$selected_tool" ]; then
                    is_selected=true
                    break
                fi
            done
            
            if [ "$is_selected" = true ]; then
                echo -e "  ${GREEN}✓${NC} $tool"
                selected+=("$tool")
            else
                echo -e "  [ ] $tool"
            fi
        done
        
        echo -e "${YELLOW}Möchten Sie diese Tools installieren? (j/n/a für anpassen)${NC}"
        read -r ANSWER
        
        if [[ "$ANSWER" =~ ^[Aa] ]]; then
            # Anpassen der Tool-Auswahl
            SELECTED_TOOLS=()
            
            for tool in "${all_tools[@]}"; do
                echo -e "${YELLOW}$tool installieren? (j/n)${NC}"
                read -r INSTALL_TOOL
                
                if [[ "$INSTALL_TOOL" =~ ^[Jj] ]]; then
                    SELECTED_TOOLS+=("$tool")
                fi
            done
        elif [[ ! "$ANSWER" =~ ^[Jj] ]]; then
            log "ERROR" "Installation abgebrochen."
            exit 1
        else
            SELECTED_TOOLS=("${selected[@]}")
        fi
    fi
    
    return 0
}

# Konfigurationsverzeichnis erstellen
create_config_dir() {
    log "INFO" "Erstelle Konfigurationsverzeichnis..."
    
    mkdir -p "$CONFIG_DIR"
    
    log "SUCCESS" "Konfigurationsverzeichnis erstellt: $CONFIG_DIR"
    return 0
}

# MCP-Server-Konfiguration erstellen
create_mcp_config() {
    log "INFO" "Erstelle MCP-Server-Konfiguration..."
    
    local config_file="$CONFIG_DIR/mcpservers.json"
    local project_name=$(basename "$PROJECT_DIR")
    
    # Projektspezifische Verzeichnisse
    local memory_bank_path="$PROJECT_DIR/memory-bank"
    
    # Falls memory-bank nicht existiert, erstellen
    if [ ! -d "$memory_bank_path" ]; then
        mkdir -p "$memory_bank_path"
    fi
    
    # Konfigurationsdatei erstellen
    cat > "$config_file" << EOL
{
  "mcpServers": {
EOL
    
    # desktop-commander hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " desktop-commander " ]]; then
        cat >> "$config_file" << EOL
    "desktop-commander": {
      "command": "npx",
      "args": ["-y", "commander-cli", "run"],
      "env": {
        "PROJECT_DIR": "$PROJECT_DIR",
        "ALLOWED_OPERATIONS": "all"
      }
    },
EOL
    fi
    
    # memory-bank hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]]; then
        cat >> "$config_file" << EOL
    "memory-bank": {
      "command": "npx",
      "args": ["-y", "memory-store"],
      "env": {
        "MEMORY_BANK_PATH": "$memory_bank_path",
        "PROJECT_NAME": "$project_name"
      }
    },
EOL
    fi
    
    # marketing-tools hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " marketing-tools " ]]; then
        cat >> "$config_file" << EOL
    "marketing-tools": {
      "command": "npx",
      "args": ["-y", "marketing-analytics"],
      "env": {
        "PROJECT_CONTEXT": "$PROJECT_DIR/.context"
      }
    },
EOL
    fi
    
    # browser-tools hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " browser-tools " ]]; then
        cat >> "$config_file" << EOL
    "browser-tools": {
      "command": "npx",
      "args": ["-y", "puppeteer"],
      "env": {
        "BROWSER_MODE": "headless",
        "ALLOW_NAVIGATION": "true"
      }
    },
EOL
    fi
    
    # toolbox hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " toolbox " ]]; then
        cat >> "$config_file" << EOL
    "toolbox": {
      "command": "npx",
      "args": [
        "-y",
        "cli-toolbox",
        "run",
        "--no-interactive"
      ]
    }
EOL
    else
        # Entferne das letzte Komma, wenn toolbox nicht das letzte Tool ist
        sed -i '$ s/,$//' "$config_file"
    fi
    
    # Konfigurationsdatei abschließen
    cat >> "$config_file" << EOL
  }
}
EOL
    
    log "SUCCESS" "MCP-Server-Konfiguration erstellt: $config_file"
    return 0
}

# Berechtigungskonfiguration erstellen
create_permissions_config() {
    log "INFO" "Erstelle Berechtigungskonfiguration..."
    
    local permissions_dir="$PROJECT_DIR/memory-bank/project_context"
    local permissions_file="$permissions_dir/permissions.json"
    
    # Verzeichnis erstellen, falls es nicht existiert
    mkdir -p "$permissions_dir"
    
    # Berechtigungskonfiguration erstellen
    cat > "$permissions_file" << EOL
{
  "tool_permissions": {
    "project_level": {
      "allowed_tools": [
        "Bash(**)",
        "Python(**)",
        "File(**)",
        "Web(**)",
        "API(**)"
      ],
      "restricted_tools": [],
      "execution_context": "project_sandbox"
    },
    "memory_bank_access": {
      "read": true,
      "write": true,
      "modify_structure": true
    },
    "mcp_integration": {
      "auto_connect": true,
      "share_context": true,
      "allow_chaining": true
    }
  }
}
EOL
    
    log "SUCCESS" "Berechtigungskonfiguration erstellt: $permissions_file"
    return 0
}

# Dokumentation für MCP-Tools erstellen
create_mcp_documentation() {
    log "INFO" "Erstelle Dokumentation für MCP-Tools..."
    
    local doc_dir="$PROJECT_DIR/memory-bank/project_context"
    local doc_file="$doc_dir/mcp_connections.md"
    local project_name=$(basename "$PROJECT_DIR")
    
    # Verzeichnis erstellen, falls es nicht existiert
    mkdir -p "$doc_dir"
    
    # Dokumentation erstellen
    cat > "$doc_file" << EOL
# MCP-Tool-Konfiguration für $project_name

## Aktivierte Tools
EOL
    
    # Liste der aktivierten Tools hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " desktop-commander " ]]; then
        echo -e "- **desktop-commander**: Dateisystem- und Shell-Operationen" >> "$doc_file"
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]]; then
        echo -e "- **memory-bank**: Memory-Bank-Verwaltung" >> "$doc_file"
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " marketing-tools " ]]; then
        echo -e "- **marketing-tools**: Marketing-Analyse und -Tools" >> "$doc_file"
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " browser-tools " ]]; then
        echo -e "- **browser-tools**: Web-Recherche und -Automatisierung" >> "$doc_file"
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " toolbox " ]]; then
        echo -e "- **toolbox**: Allgemeine KI-Tools und Hilfsprogramme" >> "$doc_file"
    fi
    
    # Weitere Informationen hinzufügen
    cat >> "$doc_file" << EOL

## Verbindungsdetails
- Alle Tools sind für das Projekt "$project_name" konfiguriert
- Pfad: $PROJECT_DIR
- Konfigurationsdatei: $CONFIG_DIR/mcpservers.json

## Berechtigungen
- Voller Lesezugriff auf das Projektverzeichnis
- Schreibzugriff für projektbezogene Dateien
- Ausführung von sicheren Befehlen innerhalb des Projekts
- Netzwerkzugriff für Web-Recherche und API-Aufrufe

## Verwendung
1. Starte Claude Code im Projektverzeichnis
2. Aktiviere MCP-Tools mit: \`/mcp\`
3. Verwende die Tools über natürliche Sprachbefehle

## Beispielworkflows
- "Durchsuche das Projektverzeichnis nach JavaScript-Dateien" → desktop-commander
- "Aktualisiere den Projektkontext mit neuem Feature XYZ" → memory-bank
- "Recherchiere Wettbewerber für unser Produkt" → browser-tools

## Technische Details
Die MCP-Tools werden über npx gestartet und kommunizieren über das Model Context Protocol mit Claude. 
Jedes Tool hat einen eigenen Zuständigkeitsbereich und spezifische Fähigkeiten, die es Claude ermöglichen, 
komplexe Aufgaben auszuführen, die über seine inhärenten Fähigkeiten hinausgehen.
EOL
    
    log "SUCCESS" "Dokumentation für MCP-Tools erstellt: $doc_file"
    return 0
}

# Automatisierte Workflows erstellen
create_automated_workflows() {
    log "INFO" "Erstelle automatisierte Workflows..."
    
    local workflows_dir="$PROJECT_DIR/memory-bank/automated_rules"
    local workflows_file="$workflows_dir/tool_workflows.md"
    
    # Verzeichnis erstellen, falls es nicht existiert
    mkdir -p "$workflows_dir"
    
    # Nur erstellen, wenn mindestens 2 Tools ausgewählt sind
    if [ ${#SELECTED_TOOLS[@]} -lt 2 ]; then
        log "INFO" "Automatisierte Workflows werden übersprungen (weniger als 2 Tools ausgewählt)."
        return 0
    fi
    
    # Workflows erstellen
    cat > "$workflows_file" << EOL
# MCP-Tool-Workflows

## Verfügbare Tools
EOL
    
    # Tool-Beschreibungen hinzufügen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " desktop-commander " ]]; then
        cat >> "$workflows_file" << EOL
### desktop-commander
- Dateisystem-Operationen
- Shell-Befehle ausführen
- Verzeichnisse durchsuchen und organisieren
EOL
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]]; then
        cat >> "$workflows_file" << EOL
### memory-bank
- Speichern und Abrufen von Projektkontext
- Aktualisieren von Projektfortschritt
- Verwalten von Projektwissen
EOL
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " marketing-tools " ]]; then
        cat >> "$workflows_file" << EOL
### marketing-tools
- Marktrecherche durchführen
- Zielgruppenanalyse erstellen
- Marketing-Assets generieren
EOL
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " browser-tools " ]]; then
        cat >> "$workflows_file" << EOL
### browser-tools
- Webrecherche durchführen
- Daten von Websites extrahieren
- Browser-Automatisierung für Tests
EOL
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " toolbox " ]]; then
        cat >> "$workflows_file" << EOL
### toolbox
- Bildgenerierung
- Textanalyse und -zusammenfassung
- Code-Optimierung und -Refactoring
EOL
    fi
    
    # Workflow-Beispiele hinzufügen
    cat >> "$workflows_file" << EOL

## Workflow-Beispiele
EOL
    
    # Dynamisch Workflows basierend auf ausgewählten Tools erstellen
    if [[ " ${SELECTED_TOOLS[*]} " =~ " desktop-commander " ]] && [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]]; then
        cat >> "$workflows_file" << EOL
1. **Projektaktualisierung**:
   \`memory-bank\` → Kontext abrufen → \`desktop-commander\` → Code aktualisieren → \`memory-bank\` → Fortschritt aktualisieren
EOL
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " browser-tools " ]] && [[ " ${SELECTED_TOOLS[*]} " =~ " marketing-tools " ]] && [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]]; then
        cat >> "$workflows_file" << EOL
2. **Marktrecherche**:
   \`browser-tools\` → Daten sammeln → \`marketing-tools\` → Analyse durchführen → \`memory-bank\` → Erkenntnisse speichern
EOL
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]] && [[ " ${SELECTED_TOOLS[*]} " =~ " toolbox " ]] && [[ " ${SELECTED_TOOLS[*]} " =~ " desktop-commander " ]]; then
        cat >> "$workflows_file" << EOL
3. **Code-Optimierung**:
   \`memory-bank\` → Architektur abrufen → \`toolbox\` → Code analysieren → \`desktop-commander\` → Änderungen anwenden
EOL
    fi
    
    log "SUCCESS" "Automatisierte Workflows erstellt: $workflows_file"
    return 0
}

# Abhängikeiten vom NPM installieren
install_npm_dependencies() {
    if [ "$INSTALL_DEPENDENCIES" = false ]; then
        log "INFO" "Installation von NPM-Abhängigkeiten übersprungen."
        return 0
    fi
    
    log "INFO" "Installiere NPM-Abhängigkeiten..."
    
    # Prüfen, ob package.json existiert, sonst erstellen
    if [ ! -f "$PROJECT_DIR/package.json" ]; then
        log "INFO" "Erstelle package.json..."
        
        local project_name=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
        
        cat > "$PROJECT_DIR/package.json" << EOL
{
  "name": "${project_name}",
  "version": "0.1.0",
  "private": true,
  "description": "AGI-Projekt mit MCP-Tools",
  "scripts": {
    "mcp:start": "echo 'MCP-Tools sind konfiguriert und können mit Claude verwendet werden.'"
  },
  "dependencies": {}
}
EOL
    fi
    
    # NPM-Abhängigkeiten installieren
    cd "$PROJECT_DIR"
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${YELLOW}Möchten Sie jetzt die NPM-Abhängigkeiten für MCP-Tools installieren? (j/n)${NC}"
        echo -e "${GRAY}Hinweis: Dies ist optional. Claude kann die Tools auch bei Bedarf automatisch installieren.${NC}"
        read -r INSTALL_NPM
        
        if [[ ! "$INSTALL_NPM" =~ ^[Jj] ]]; then
            log "INFO" "Installation von NPM-Abhängigkeiten übersprungen."
            return 0
        fi
    fi
    
    # Abhängigkeiten basierend auf ausgewählten Tools installieren
    local dependencies=()
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " desktop-commander " ]]; then
        dependencies+=("commander-cli")
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " memory-bank " ]]; then
        dependencies+=("memory-store")
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " marketing-tools " ]]; then
        dependencies+=("marketing-analytics")
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " browser-tools " ]]; then
        dependencies+=("puppeteer")
    fi
    
    if [[ " ${SELECTED_TOOLS[*]} " =~ " toolbox " ]]; then
        dependencies+=("cli-toolbox")
    fi
    
    if [ ${#dependencies[@]} -gt 0 ]; then
        log "INFO" "Installiere Abhängigkeiten: ${dependencies[*]}"
        npm install --save "${dependencies[@]}"
    fi
    
    log "SUCCESS" "NPM-Abhängigkeiten installiert."
    return 0
}

# Erstelle ein Startup-Skript
create_startup_script() {
    log "INFO" "Erstelle Startup-Skript..."
    
    local script_file="$PROJECT_DIR/start-mcp-tools.sh"
    local project_name=$(basename "$PROJECT_DIR")
    
    cat > "$script_file" << EOL
#!/bin/bash
# MCP-Tools Startup-Skript für $project_name

# Verzeichnis des Skripts ermitteln
SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"

# Claude Code mit MCP-Tools starten
cd "\$SCRIPT_DIR"
claude << EOF
/mcp
EOF

echo "MCP-Tools für $project_name aktiviert. Claude ist bereit für die Verwendung mit MCP-Tools."
echo "Verfügbare Tools: ${SELECTED_TOOLS[*]}"
EOL
    
    chmod +x "$script_file"
    
    log "SUCCESS" "Startup-Skript erstellt: $script_file"
    return 0
}

# Zusammenfassung anzeigen
show_summary() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GREEN}MCP-Tools erfolgreich eingerichtet!${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "${CYAN}Konfigurationsdetails:${NC}"
    echo -e "  Projektverzeichnis:     ${CYAN}$PROJECT_DIR${NC}"
    echo -e "  Konfigurationsverzeichnis: ${CYAN}$CONFIG_DIR${NC}"
    echo -e "  Installierte Tools:     ${CYAN}${SELECTED_TOOLS[*]}${NC}"
    echo
    echo -e "${YELLOW}Nächste Schritte:${NC}"
    echo -e "  1. Starte Claude Code im Projektverzeichnis:"
    echo -e "     cd $PROJECT_DIR && claude"
    echo
    echo -e "  2. Aktiviere MCP-Tools in Claude Code:"
    echo -e "     /mcp"
    echo
    echo -e "  3. Oder verwende das Startup-Skript:"
    echo -e "     $PROJECT_DIR/start-mcp-tools.sh"
    echo
    echo -e "${GRAY}Die vollständige Dokumentation befindet sich in:${NC}"
    echo -e "${GRAY}$PROJECT_DIR/memory-bank/project_context/mcp_connections.md${NC}"
    echo
    
    return 0
}

# Hauptfunktion
main() {
    # Anzeige des Banners
    show_banner
    
    # Initialisierung des Logs
    echo "# MCP-Tools-Setup Log" > "$LOG_FILE"
    echo "# $(date)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    # Parameter verarbeiten
    process_args "$@"
    
    # Abhängigkeiten prüfen
    check_dependencies || exit 1
    
    # Konfigurationsverzeichnis erstellen
    create_config_dir || exit 1
    
    # MCP-Server-Konfiguration erstellen
    create_mcp_config || exit 1
    
    # Berechtigungskonfiguration erstellen
    create_permissions_config
    
    # Dokumentation für MCP-Tools erstellen
    create_mcp_documentation
    
    # Automatisierte Workflows erstellen
    create_automated_workflows
    
    # NPM-Abhängigkeiten installieren
    install_npm_dependencies
    
    # Startup-Skript erstellen
    create_startup_script
    
    # Zusammenfassung anzeigen
    show_summary
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?