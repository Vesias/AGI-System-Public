#!/usr/bin/env bash
# ============================================================================
# Skript zum Erstellen einer interaktiven .about-Datei für AGI-Projekte
# 
# Dieses Skript generiert eine interaktive .about-Datei im JSON-Format,
# die Projekteinstellungen, Präferenzen und Integrationen definiert.
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
TEMPLATE_PATH="$REPO_ROOT/core/templates/interactive-about-template.json"
OUTPUT_FILE=""
INTERACTIVE_MODE=true
DEFAULTS_ONLY=false
LOG_FILE="/tmp/interactive-about-$(date +%Y%m%d%H%M%S).log"

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}"
    echo " _       _                      _   _            "
    echo "(_)_ __ | |_ ___ _ __ __ _  ___| |_(_)_   _____  "
    echo "| | '_ \| __/ _ \ '__/ _\` |/ __| __| \ \ / / _ \ "
    echo "| | | | | ||  __/ | | (_| | (__| |_| |\ V /  __/ "
    echo "|_|_| |_|\__\___|_|  \__,_|\___|\__|_| \_/ \___| "
    echo -e "                  _           _                  "
    echo -e "  __ _  ___ _   _| |_    __ _| |__   ___  _   _ | |_"
    echo -e " / _\` |/ _ \ | | | __|  / _\` | '_ \ / _ \| | | || __|"
    echo -e "| (_| |  __/ |_| | |_  | (_| | |_) | (_) | |_| || |_"
    echo -e " \__,_|\___|\__,_|\__|  \__,_|_.__/ \___/ \__,_| \__|"
    echo -e "${NC}"
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
    echo "  -o, --output FILE           Ausgabedatei (Standard: <PROJEKTVERZEICHNIS>/.about.interactive)"
    echo "  -t, --template FILE         Template-Datei (Standard: $TEMPLATE_PATH)"
    echo "  -n, --non-interactive       Nichtinteraktiver Modus (für Automatisierung)"
    echo "  -d, --defaults              Nur Standardwerte verwenden (keine Benutzerabfragen)"
    echo
    echo "Beispiele:"
    echo "  $0 /path/to/project                          # Interaktive .about-Datei erstellen"
    echo "  $0 --non-interactive --defaults /path/to/project  # Automatisierte Erstellung mit Standardwerten"
    echo
}

# Funktion zur Verarbeitung der Kommandozeilenargumente
process_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                shift
                OUTPUT_FILE="$1"
                ;;
            -t|--template)
                shift
                TEMPLATE_PATH="$1"
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                ;;
            -d|--defaults)
                DEFAULTS_ONLY=true
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
    
    # Standardausgabedatei, falls nicht angegeben
    if [ -z "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="$PROJECT_DIR/.about.interactive"
    fi
    
    # Prüfe, ob Template-Datei existiert
    if [ ! -f "$TEMPLATE_PATH" ]; then
        log "ERROR" "Template-Datei existiert nicht: $TEMPLATE_PATH"
        exit 1
    fi
    
    return 0
}

# Frage Benutzer nach einem Wert
ask_value() {
    local prompt="$1"
    local default="$2"
    local value=""
    
    if [ "$INTERACTIVE_MODE" = false ] || [ "$DEFAULTS_ONLY" = true ]; then
        echo "$default"
        return
    fi
    
    read -p "${prompt} [${default}]: " value
    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Frage Benutzer nach einem booleschen Wert
ask_boolean() {
    local prompt="$1"
    local default="$2"
    local response=""
    
    if [ "$INTERACTIVE_MODE" = false ] || [ "$DEFAULTS_ONLY" = true ]; then
        echo "$default"
        return
    fi
    
    default_prompt=""
    if [ "$default" = true ]; then
        default_prompt="J/n"
    else
        default_prompt="j/N"
    fi
    
    read -p "${prompt} [${default_prompt}]: " response
    
    if [ -z "$response" ]; then
        echo "$default"
    elif [[ "$response" =~ ^[Jj] ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Frage Benutzer nach einer Auswahl
ask_selection() {
    local prompt="$1"
    local options="$2"
    local default="$3"
    local selection=""
    
    if [ "$INTERACTIVE_MODE" = false ] || [ "$DEFAULTS_ONLY" = true ]; then
        echo "$default"
        return
    fi
    
    echo "$prompt"
    IFS=',' read -ra options_array <<< "$options"
    for i in "${!options_array[@]}"; do
        echo "  $((i+1)). ${options_array[$i]}"
    done
    
    # Standardwert-Index finden
    default_index=0
    for i in "${!options_array[@]}"; do
        if [ "${options_array[$i]}" = "$default" ]; then
            default_index=$((i+1))
            break
        fi
    done
    
    read -p "Auswahl [${default_index}]: " selection
    
    if [ -z "$selection" ]; then
        echo "$default"
    elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options_array[@]}" ]; then
        echo "${options_array[$((selection-1))]}"
    else
        echo "$default"
    fi
}

# Projektinformationen sammeln
gather_project_info() {
    log "INFO" "Sammle Projektinformationen..."
    
    local project_name=$(basename "$PROJECT_DIR")
    local project_type=$(ask_selection "Projekttyp:" "standard,vibe-coding,enterprise,research" "standard")
    local date_today=$(date -I)
    
    # Prüfe, ob memory-bank existiert
    local memory_bank_exists=false
    if [ -d "$PROJECT_DIR/memory-bank" ]; then
        memory_bank_exists=true
    fi
    
    # Prüfe, ob .config/claude existiert
    local mcp_config_exists=false
    if [ -d "$PROJECT_DIR/.config/claude" ]; then
        mcp_config_exists=true
    fi
    
    # MCP-Tools-Einstellungen
    local mcp_tools_enabled="false"
    local mcp_read_permission="false"
    local mcp_write_permission="false"
    local mcp_execute_permission="false"
    local mcp_network_permission="false"
    
    if [ "$mcp_config_exists" = true ]; then
        mcp_tools_enabled="true"
        
        if [ "$INTERACTIVE_MODE" = true ] && [ "$DEFAULTS_ONLY" = false ]; then
            echo -e "${YELLOW}MCP-Tools-Konfiguration gefunden.${NC}"
        fi
        
        mcp_read_permission=$(ask_boolean "Lesezugriff für MCP-Tools aktivieren?" true)
        mcp_write_permission=$(ask_boolean "Schreibzugriff für MCP-Tools aktivieren?" true)
        mcp_execute_permission=$(ask_boolean "Ausführungszugriff für MCP-Tools aktivieren?" true)
        mcp_network_permission=$(ask_boolean "Netzwerkzugriff für MCP-Tools aktivieren?" true)
    else
        mcp_tools_enabled=$(ask_boolean "MCP-Tools aktivieren?" false)
        
        if [ "$mcp_tools_enabled" = "true" ]; then
            mcp_read_permission=$(ask_boolean "Lesezugriff für MCP-Tools aktivieren?" true)
            mcp_write_permission=$(ask_boolean "Schreibzugriff für MCP-Tools aktivieren?" true)
            mcp_execute_permission=$(ask_boolean "Ausführungszugriff für MCP-Tools aktivieren?" true)
            mcp_network_permission=$(ask_boolean "Netzwerkzugriff für MCP-Tools aktivieren?" true)
        fi
    fi
    
    # Vektordatenbank-Einstellungen
    local vector_db_type="none"
    local vector_db_endpoint=""
    local vector_db_collections="[]"
    local semantic_search_enabled="false"
    
    # Qdrant-Prüfung
    local qdrant_exists=false
    if [ -f "$PROJECT_DIR/docker-compose.yml" ] && grep -q "qdrant" "$PROJECT_DIR/docker-compose.yml"; then
        qdrant_exists=true
    fi
    
    if [ "$qdrant_exists" = true ]; then
        if [ "$INTERACTIVE_MODE" = true ] && [ "$DEFAULTS_ONLY" = false ]; then
            echo -e "${YELLOW}Qdrant-Konfiguration gefunden.${NC}"
        fi
        
        vector_db_type="qdrant"
        vector_db_endpoint="http://localhost:6333"
        vector_db_collections='["project_context", "code_embeddings", "documentation"]'
        semantic_search_enabled="true"
    else
        local use_vector_db=$(ask_boolean "Vektordatenbank aktivieren?" false)
        
        if [ "$use_vector_db" = "true" ]; then
            vector_db_type=$(ask_selection "Vektordatenbank-Typ:" "qdrant,pinecone,milvus,none" "qdrant")
            
            if [ "$vector_db_type" != "none" ]; then
                vector_db_endpoint=$(ask_value "Vektordatenbank-Endpunkt:" "http://localhost:6333")
                semantic_search_enabled="true"
                
                if [ "$vector_db_type" = "qdrant" ]; then
                    vector_db_collections='["project_context", "code_embeddings", "documentation"]'
                else
                    vector_db_collections='[]'
                fi
            fi
        fi
    fi
    
    # Einbettungsmodell
    local embedding_model=$(ask_selection "Einbettungsmodell:" "claude-3-haiku,claude-3-sonnet,claude-3-opus,text-embedding-ada-002" "claude-3-haiku")
    
    # Benutzereinstellungen
    local indentation_style=$(ask_selection "Einrückungsstil:" "spaces,tabs" "spaces")
    local naming_convention=$(ask_selection "Namenskonvention:" "camelCase,snake_case,PascalCase,kebab-case" "camelCase")
    local max_line_length=$(ask_value "Maximale Zeilenlänge:" "80")
    local documentation_language=$(ask_selection "Dokumentationssprache:" "de,en,fr,es" "de")
    local documentation_format=$(ask_selection "Dokumentationsformat:" "markdown,jsdoc,javadoc,restructuredtext" "markdown")
    
    # AI-Interaktionseinstellungen
    local ai_verbosity=$(ask_selection "AI-Ausführlichkeit:" "minimal,moderate,detailed" "moderate")
    local code_explanation_level=$(ask_selection "Code-Erklärungsebene:" "none,basic,detailed" "basic")
    local autonomy_level=$(ask_selection "Autonomielevel:" "low,medium,high" "medium")
    
    # Automatisierungseinstellungen
    local memory_bank_sync_enabled=$(ask_boolean "Memory-Bank-Synchronisierung aktivieren?" true)
    local code_formatting_enabled=$(ask_boolean "Code-Formatierung aktivieren?" true)
    local git_hooks_enabled=$(ask_boolean "Git-Hooks aktivieren?" true)
    local test_automation_enabled=$(ask_boolean "Testautomatisierung aktivieren?" true)
    
    # Integrationseinstellungen
    local git_enabled=$(ask_boolean "Git-Integration aktivieren?" true)
    local git_repository=$(ask_value "Git-Repository:" "")
    local git_branch=$(ask_value "Git-Branch:" "main")
    
    local ci_cd_enabled=$(ask_boolean "CI/CD-Integration aktivieren?" false)
    local ci_cd_provider=$(ask_selection "CI/CD-Provider:" "github-actions,gitlab-ci,jenkins,none" "github-actions")
    local ci_cd_config_path=$(ask_value "CI/CD-Konfigurationspfad:" ".github/workflows")
    
    local cloud_enabled=$(ask_boolean "Cloud-Integration aktivieren?" false)
    local cloud_provider=$(ask_selection "Cloud-Provider:" "aws,azure,gcp,vercel,none" "vercel")
    local cloud_region=$(ask_value "Cloud-Region:" "eu-central-1")
    
    # AGI-System-Version
    local agi_system_version=$(ask_value "AGI-System-Version:" "1.0.0")
    
    # Ergebnisse zurückgeben
    cat << EOF
{
  "PROJECT_NAME": "$project_name",
  "PROJECT_TYPE": "$project_type",
  "PROJECT_PATH": "$PROJECT_DIR",
  "DATE": "$date_today",
  "MCP_TOOLS_ENABLED": $mcp_tools_enabled,
  "MCP_READ_PERMISSION": $mcp_read_permission,
  "MCP_WRITE_PERMISSION": $mcp_write_permission,
  "MCP_EXECUTE_PERMISSION": $mcp_execute_permission,
  "MCP_NETWORK_PERMISSION": $mcp_network_permission,
  "VECTOR_DB_TYPE": "$vector_db_type",
  "VECTOR_DB_ENDPOINT": "$vector_db_endpoint",
  "VECTOR_DB_COLLECTIONS": $vector_db_collections,
  "SEMANTIC_SEARCH_ENABLED": $semantic_search_enabled,
  "EMBEDDING_MODEL": "$embedding_model",
  "INDENTATION_STYLE": "$indentation_style",
  "NAMING_CONVENTION": "$naming_convention",
  "MAX_LINE_LENGTH": $max_line_length,
  "DOCUMENTATION_LANGUAGE": "$documentation_language",
  "DOCUMENTATION_FORMAT": "$documentation_format",
  "AI_VERBOSITY": "$ai_verbosity",
  "CODE_EXPLANATION_LEVEL": "$code_explanation_level",
  "AUTONOMY_LEVEL": "$autonomy_level",
  "MEMORY_BANK_SYNC_ENABLED": $memory_bank_sync_enabled,
  "CODE_FORMATTING_ENABLED": $code_formatting_enabled,
  "GIT_HOOKS_ENABLED": $git_hooks_enabled,
  "TEST_AUTOMATION_ENABLED": $test_automation_enabled,
  "GIT_ENABLED": $git_enabled,
  "GIT_REPOSITORY": "$git_repository",
  "GIT_BRANCH": "$git_branch",
  "CI_CD_ENABLED": $ci_cd_enabled,
  "CI_CD_PROVIDER": "$ci_cd_provider",
  "CI_CD_CONFIG_PATH": "$ci_cd_config_path",
  "CLOUD_ENABLED": $cloud_enabled,
  "CLOUD_PROVIDER": "$cloud_provider",
  "CLOUD_REGION": "$cloud_region",
  "AGI_SYSTEM_VERSION": "$agi_system_version"
}
EOF
}

# .about-Datei erstellen
create_about_file() {
    log "INFO" "Erstelle interaktive .about-Datei..."
    
    # Projektinformationen sammeln
    local project_info=$(gather_project_info)
    
    # Template laden
    local template=$(cat "$TEMPLATE_PATH")
    
    # Projektinformationen parsen
    local project_name=$(echo "$project_info" | grep -o '"PROJECT_NAME": "[^"]*"' | cut -d'"' -f4)
    local project_type=$(echo "$project_info" | grep -o '"PROJECT_TYPE": "[^"]*"' | cut -d'"' -f4)
    local project_path=$(echo "$project_info" | grep -o '"PROJECT_PATH": "[^"]*"' | cut -d'"' -f4)
    local date_today=$(echo "$project_info" | grep -o '"DATE": "[^"]*"' | cut -d'"' -f4)
    
    # Template-Werte ersetzen
    while IFS=":" read -r key value; do
        key=$(echo "$key" | tr -d '" ')
        value=$(echo "$value" | tr -d '," ')
        
        if [ -n "$key" ] && [ -n "$value" ]; then
            # Wert in Template ersetzen mit sicherem Trennzeichen
            template=$(echo "$template" | sed "s|{{$key}}|$value|g")
        fi
    done < <(echo "$project_info" | grep -o '"[^"]*": "[^"]*"' | sed 's/":/:/g')
    
    # Arrays und boolesche Werte ersetzen
    while IFS=":" read -r key value; do
        key=$(echo "$key" | tr -d '" ')
        
        # Bei Arrays die Kommas erhalten
        if [[ "$value" == *"["* ]]; then
            # Bei Arrays nur führende und abschließende Anführungszeichen entfernen
            value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
        else
            # Bei anderen Werten alle Anführungszeichen und Kommas entfernen
            value=$(echo "$value" | tr -d ', "')
        fi
        
        if [ -n "$key" ] && [ -n "$value" ]; then
            if [[ "$value" == "["* || "$value" == "true" || "$value" == "false" || "$value" =~ ^[0-9]+$ ]]; then
                # Wert in Template ersetzen mit sicherem Trennzeichen
                template=$(echo "$template" | sed "s|{{$key}}|$value|g")
            fi
        fi
    done < <(echo "$project_info" | grep -v '": "[^"]*"')
    
    # .about-Datei erstellen
    echo "$template" > "$OUTPUT_FILE"
    
    log "SUCCESS" "Interaktive .about-Datei erstellt: $OUTPUT_FILE"
    return 0
}

# Hauptfunktion
main() {
    # Anzeige des Banners
    show_banner
    
    # Initialisierung des Logs
    echo "# Interaktive .about-Datei Erstellung Log" > "$LOG_FILE"
    echo "# $(date)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    # Parameter verarbeiten
    process_args "$@"
    
    # .about-Datei erstellen
    create_about_file
    
    # Erfolgsmeldung
    echo -e "${GREEN}Interaktive .about-Datei wurde erfolgreich erstellt!${NC}"
    echo -e "Datei: ${CYAN}$OUTPUT_FILE${NC}"
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?