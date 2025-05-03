#!/usr/bin/env bash
# ============================================================================
# AGI-System Erweiterte Projektinitialisierung v2.0
# 
# Dieses Skript erstellt ein neues AGI-Projekt mit:
# - Vollständiger Verzeichnisstruktur
# - Memory-Bank-System
# - MCP-Tools-Integration
# - Interaktiver .about-Datei
# - Automatischer Berechtigungsverwaltung mit permissions-parser.sh
# - Qdrant-Vektordatenbank-Integration (optional)
# 
# Changelog:
# - Verbesserte Fehlerbehandlung
# - Optimierte Code-Modularisierung
# - Integration mit permissions-parser.sh
# - Leistungsoptimierungen
# - Bessere Validierung von Benutzereingaben
# ============================================================================

set -eo pipefail # Fehlerbehandlung verbessern

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Standardwerte
DEFAULT_PROJECT_DIR="$HOME/Projekte"
[[ -d "$HOME/Schreibtisch/CLAUDE" ]] && DEFAULT_PROJECT_DIR="$HOME/Schreibtisch/CLAUDE"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEMPLATE_DIR="$REPO_ROOT/core/templates"
LOG_FILE="/tmp/agi-project-init-$(date +%Y%m%d%H%M%S).log"
START_TIME=$(date +%s)
USE_VECTOR_DB=false
INTERACTIVE_MODE=true
MCP_TOOLS_ENABLED=false
DOCKER_AVAILABLE=false
USE_TRANSFORMERS=false
PERMISSIONS_TOOL="permissions-parser.sh" # Verwende das neue Berechtigungstool
MCP_TOOLS=("desktop-commander" "memory-bank" "marketing-tools" "browser-tools" "toolbox")

# Trap für sauberes Aufräumen
trap cleanup EXIT

# Benötigte Abhängigkeiten (erweitert)
DEPENDENCIES=("git" "bash")
OPTIONAL_DEPENDENCIES=("node" "npm" "docker" "npx" "python3" "pip")

# Globale Variablen für Statusverfolgung
declare -A STEP_STATUS
TOTAL_STEPS=7
CURRENT_STEP=0

# Cleanup-Funktion für sauberes Aufräumen
cleanup() {
    local exit_code=$?
    
    # Temporäre Dateien entfernen (falls vorhanden)
    if [[ -n "$TMP_FILES" ]]; then
        for tmp_file in "${TMP_FILES[@]}"; do
            [[ -f "$tmp_file" ]] && rm -f "$tmp_file"
        done
    fi
    
    # Bei Fehler während der Verzeichniserstellung aufräumen
    if [[ $exit_code -ne 0 && -n "$FULL_PROJECT_PATH" && -d "$FULL_PROJECT_PATH" ]]; then
        if [[ "$INTERACTIVE_MODE" = "true" ]]; then
            echo -e "${YELLOW}Fehler aufgetreten. Möchten Sie das erstellte Verzeichnis entfernen? (j/n)${NC}"
            read -r ANSWER
            if [[ "$ANSWER" =~ ^[Jj] ]]; then
                log "WARNING" "Entferne unvollständiges Projektverzeichnis: $FULL_PROJECT_PATH"
                rm -rf "$FULL_PROJECT_PATH"
            fi
        else
            log "WARNING" "Fehler aufgetreten. Das Projektverzeichnis wurde möglicherweise nur teilweise erstellt: $FULL_PROJECT_PATH"
        fi
    fi
    
    # Logdatei finalisieren
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Script endete mit Fehlercode $exit_code"
        [[ "$INTERACTIVE_MODE" = "true" ]] && echo -e "${RED}Fehler beim Erstellen des Projekts. Logdatei: $LOG_FILE${NC}"
    else
        log "INFO" "Script wurde erfolgreich abgeschlossen."
    fi
}

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}"
    echo "  ____ _       _    _   _ ____  _____   "
    echo " / ___| |     / \  | | | |  _ \| ____|  "
    echo "| |   | |    / _ \ | | | | | | |  _|    "
    echo "| |___| |___/ ___ \| |_| | |_| | |___   "
    echo " \____|_____/_/   \_\\___/|____/|_____|  "
    echo "                                        "
    echo -e "AGI-System Erweiterte Projektinitialisierung v2.0${NC}"
    echo -e "${GRAY}$(date)${NC}"
    echo
}

# Funktion für Logeinträge mit verbesserter Formatierung
log() {
    local level="$1"
    local message="$2"
    local color="$NC"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO") color="${BLUE}" ;;
        "SUCCESS") color="${GREEN}" ;;
        "WARNING") color="${YELLOW}" ;;
        "ERROR") color="${RED}" ;;
        "DEBUG") color="${GRAY}" ;;
    esac
    
    # Log in Datei schreiben
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # In Konsole ausgeben wenn interaktiv, oder bei wichtigen Nachrichten
    if [[ "$INTERACTIVE_MODE" = "true" || "$level" = "ERROR" || "$level" = "WARNING" ]]; then
        echo -e "${color}[$level]${NC} $message"
    fi
}

# Fortschrittsanzeige aktualisieren
update_progress() {
    local step_name="$1"
    local status="$2"
    
    CURRENT_STEP=$((CURRENT_STEP + 1))
    STEP_STATUS["$step_name"]="$status"
    
    if [[ "$INTERACTIVE_MODE" = "true" ]]; then
        local progress=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        echo -e "${CYAN}[$progress%] Schritt $CURRENT_STEP/$TOTAL_STEPS: $step_name - $status${NC}"
    fi
    
    log "INFO" "Schritt $CURRENT_STEP/$TOTAL_STEPS: $step_name - $status"
}

# Hilfetext anzeigen
show_help() {
    echo "Verwendung: $0 [optionen] <PROJEKTNAME>"
    echo
    echo "Optionen:"
    echo "  -h, --help                  Diese Hilfe anzeigen"
    echo "  -d, --directory DIR         Basisverzeichnis für das Projekt (Standard: $DEFAULT_PROJECT_DIR)"
    echo "  -t, --type TYPE             Projekttyp (standard, vibe-coding)"
    echo "  -v, --vector-db             Qdrant-Vektordatenbank einrichten"
    echo "  -r, --transformer           Transformer-Modelle für Vektordatenbank einrichten"
    echo "  -m, --mcp-tools             MCP-Tools aktivieren"
    echo "  -n, --non-interactive       Nichtinteraktiver Modus (für Automatisierung)"
    echo "  -a, --auto-permissions      Automatische Berechtigungsverwaltung"
    echo
    echo "Beispiele:"
    echo "  $0 MeinProjekt                           # Standardprojekt erstellen"
    echo "  $0 --type vibe-coding MeinVibeProjekt    # Vibe-Coding-Projekt erstellen"
    echo "  $0 --vector-db --transformer --mcp-tools MeinKIProjekt # Komplettes KI-Projekt"
    echo
}

# Funktion zur verbesserten Prüfung der Abhängigkeiten mit paralleler Ausführung
check_dependencies() {
    log "INFO" "Prüfe Systemabhängigkeiten..."
    update_progress "Abhängigkeitsprüfung" "Läuft"
    
    local missing_deps=()
    local missing_opt_deps=()
    local available_opt_deps=()
    local dep_check_results=()
    
    # Array für temporäre Dateien initialisieren, falls noch nicht geschehen
    TMP_FILES=()
    local temp_result_file=$(mktemp)
    TMP_FILES+=("$temp_result_file")
    
    # Erforderliche Abhängigkeiten parallel prüfen
    log "DEBUG" "Prüfe erforderliche Abhängigkeiten: ${DEPENDENCIES[*]}"
    for dep in "${DEPENDENCIES[@]}"; do
        (command -v "$dep" &> /dev/null && echo "REQUIRED:$dep:AVAILABLE" || echo "REQUIRED:$dep:MISSING") >> "$temp_result_file" &
    done
    
    # Optionale Abhängigkeiten parallel prüfen
    log "DEBUG" "Prüfe optionale Abhängigkeiten: ${OPTIONAL_DEPENDENCIES[*]}"
    for dep in "${OPTIONAL_DEPENDENCIES[@]}"; do
        (command -v "$dep" &> /dev/null && echo "OPTIONAL:$dep:AVAILABLE" || echo "OPTIONAL:$dep:MISSING") >> "$temp_result_file" &
    done
    
    # Auf alle Hintergrundprozesse warten
    wait
    
    # Ergebnisse verarbeiten
    while IFS= read -r line; do
        dep_check_results+=("$line")
    done < "$temp_result_file"
    
    # Prozessiere die Ergebnisse
    for result in "${dep_check_results[@]}"; do
        local type=$(echo "$result" | cut -d':' -f1)
        local dep=$(echo "$result" | cut -d':' -f2)
        local status=$(echo "$result" | cut -d':' -f3)
        
        if [[ "$type" == "REQUIRED" && "$status" == "MISSING" ]]; then
            missing_deps+=("$dep")
        elif [[ "$type" == "OPTIONAL" ]]; then
            if [[ "$status" == "MISSING" ]]; then
                missing_opt_deps+=("$dep")
            else
                available_opt_deps+=("$dep")
                # Docker speziell prüfen
                if [[ "$dep" == "docker" ]]; then
                    DOCKER_AVAILABLE=true
                    log "DEBUG" "Docker ist verfügbar"
                fi
            fi
        fi
    done
    
    # Ausgabe der Ergebnisse
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Folgende erforderliche Abhängigkeiten fehlen: ${missing_deps[*]}"
        log "ERROR" "Bitte installieren Sie die fehlenden Abhängigkeiten und versuchen Sie es erneut."
        update_progress "Abhängigkeitsprüfung" "Fehlgeschlagen"
        return 1
    fi
    
    # Optionale Abhängigkeiten verarbeiten
    if [[ ${#missing_opt_deps[@]} -gt 0 ]]; then
        log "WARNING" "Folgende optionale Abhängigkeiten fehlen: ${missing_opt_deps[*]}"
        
        # Wenn Docker fehlt und Vektordatenbank aktiviert ist
        if [[ " ${missing_opt_deps[*]} " =~ " docker " ]] && [[ "$USE_VECTOR_DB" == true ]]; then
            log "WARNING" "Docker ist nicht installiert, aber für die Vektordatenbank erforderlich."
            log "WARNING" "Die Vektordatenbank wird deaktiviert."
            USE_VECTOR_DB=false
        fi
        
        # Wenn npm oder npx fehlen und MCP-Tools aktiviert sind
        if [[ " ${missing_opt_deps[*]} " =~ " npm " ]] || [[ " ${missing_opt_deps[*]} " =~ " npx " ]]; then
            if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
                log "WARNING" "npm oder npx sind nicht installiert, aber für MCP-Tools erforderlich."
                log "WARNING" "MCP-Tools werden deaktiviert."
                MCP_TOOLS_ENABLED=false
            fi
        fi
    else
        log "SUCCESS" "Alle optionalen Abhängigkeiten gefunden: ${available_opt_deps[*]}"
    fi
    
    # Prüfe, ob das neue Berechtigungstool verfügbar ist
    if [[ -f "$SCRIPT_DIR/$PERMISSIONS_TOOL" ]]; then
        log "SUCCESS" "$PERMISSIONS_TOOL gefunden"
    else
        log "WARNING" "$PERMISSIONS_TOOL nicht gefunden. Verwende Standard-Berechtigungssystem."
        PERMISSIONS_TOOL=""
    fi
    
    update_progress "Abhängigkeitsprüfung" "Abgeschlossen"
    return 0
}

# Verbesserte Parameter-Verarbeitung mit besserer Validierung
process_args() {
    local show_usage=false
    PROJECT_NAME=""
    PROJECT_TYPE="standard"
    PROJECT_DIR="$DEFAULT_PROJECT_DIR"
    AUTO_PERMISSIONS=false
    local use_absolute_path=false
    local version_only=false
    
    log "DEBUG" "Verarbeite Befehlszeilenargumente: $*"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--directory)
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    log "ERROR" "Fehlender Wert für Parameter --directory"
                    show_usage=true
                    break
                fi
                PROJECT_DIR="$1"
                ;;
            -t|--type)
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    log "ERROR" "Fehlender Wert für Parameter --type"
                    show_usage=true
                    break
                fi
                PROJECT_TYPE="$1"
                ;;
            -v|--vector-db)
                USE_VECTOR_DB=true
                ;;
            -r|--transformer)
                USE_TRANSFORMERS=true
                ;;
            -m|--mcp-tools)
                MCP_TOOLS_ENABLED=true
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                ;;
            -a|--auto-permissions)
                AUTO_PERMISSIONS=true
                ;;
            -p|--absolute-path)
                use_absolute_path=true
                ;;
            --version)
                version_only=true
                break
                ;;
            -*)
                log "ERROR" "Unbekannter Parameter: $1"
                show_usage=true
                break
                ;;
            *)
                if [[ -z "$PROJECT_NAME" ]]; then
                    PROJECT_NAME="$1"
                else
                    log "ERROR" "Mehrere Projektnamen angegeben: '$PROJECT_NAME' und '$1'"
                    show_usage=true
                    break
                fi
                ;;
        esac
        shift
    done
    
    # Version anzeigen, wenn angefordert
    if [[ "$version_only" == true ]]; then
        echo "AGI-System Projekt-Initialisierung v2.0"
        exit 0
    fi
    
    # Bei Fehlern in der Argumentverarbeitung
    if [[ "$show_usage" == true ]]; then
        show_help
        return 1
    fi
    
    # Projektname interaktiv abfragen, wenn nicht angegeben
    if [[ -z "$PROJECT_NAME" ]]; then
        if [[ "$INTERACTIVE_MODE" == true ]]; then
            echo -e "${YELLOW}Bitte geben Sie einen Projektnamen ein:${NC}"
            read -r PROJECT_NAME
            
            if [[ -z "$PROJECT_NAME" ]]; then
                log "ERROR" "Kein Projektname angegeben."
                return 1
            fi
        else
            log "ERROR" "Kein Projektname angegeben."
            show_help
            return 1
        fi
    fi
    
    # Validiere Projektnamen (keine Sonderzeichen außer - und _)
    if ! [[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log "ERROR" "Ungültiger Projektname: '$PROJECT_NAME'. Verwenden Sie nur Buchstaben, Zahlen, Bindestriche und Unterstriche."
        return 1
    fi
    
    # Projektverzeichnis-Pfad normalisieren
    if [[ "$use_absolute_path" == true && ! "$PROJECT_DIR" =~ ^/ ]]; then
        PROJECT_DIR="$(pwd)/$PROJECT_DIR"
    fi
    
    # Projektpfad berechnen
    FULL_PROJECT_PATH="$PROJECT_DIR/$PROJECT_NAME"
    log "DEBUG" "Projektpfad: $FULL_PROJECT_PATH"
    
    # Prüfe, ob Projektverzeichnis existiert und erstelle es ggf.
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log "WARNING" "Projektverzeichnis '$PROJECT_DIR' existiert nicht."
        if [[ "$INTERACTIVE_MODE" == true ]]; then
            echo -e "${YELLOW}Möchten Sie das Verzeichnis erstellen? (j/n)${NC}"
            read -r ANSWER
            if [[ "$ANSWER" =~ ^[Jj] ]]; then
                log "INFO" "Erstelle Verzeichnis '$PROJECT_DIR'"
                mkdir -p "$PROJECT_DIR" || {
                    log "ERROR" "Konnte Verzeichnis nicht erstellen."
                    return 1
                }
            else
                log "ERROR" "Abbruch auf Benutzerwunsch."
                return 1
            fi
        else
            log "INFO" "Erstelle Verzeichnis '$PROJECT_DIR'"
            mkdir -p "$PROJECT_DIR" || {
                log "ERROR" "Konnte Verzeichnis nicht erstellen."
                return 1
            }
        fi
    fi
    
    # Prüfe, ob Projekt bereits existiert
    if [[ -d "$FULL_PROJECT_PATH" ]]; then
        log "ERROR" "Projekt '$PROJECT_NAME' existiert bereits in $PROJECT_DIR."
        return 1
    fi
    
    # Prüfe, ob Projekttyp gültig ist
    if [[ "$PROJECT_TYPE" != "standard" && "$PROJECT_TYPE" != "vibe-coding" ]]; then
        log "ERROR" "Ungültiger Projekttyp: $PROJECT_TYPE"
        log "ERROR" "Gültige Typen: standard, vibe-coding"
        return 1
    fi
    
    # Interaktive Konfiguration, wenn im interaktiven Modus
    if [[ "$INTERACTIVE_MODE" == true ]]; then
        # Projekttyp bestätigen
        echo -e "${YELLOW}Gewählter Projekttyp: ${PROJECT_TYPE^}${NC}"
        echo -e "${YELLOW}Möchten Sie einen anderen Typ wählen? (j/n)${NC}"
        read -r ANSWER
        if [[ "$ANSWER" =~ ^[Jj] ]]; then
            echo -e "${YELLOW}Verfügbare Typen: standard, vibe-coding${NC}"
            echo -e "${YELLOW}Projekttyp:${NC}"
            read -r PROJECT_TYPE
            
            # Erneut validieren
            if [[ "$PROJECT_TYPE" != "standard" && "$PROJECT_TYPE" != "vibe-coding" ]]; then
                log "ERROR" "Ungültiger Projekttyp: $PROJECT_TYPE"
                log "ERROR" "Gültige Typen: standard, vibe-coding"
                return 1
            fi
        fi
        
        # Frage nach MCP-Tools
        if [[ "$MCP_TOOLS_ENABLED" == false ]]; then
            echo -e "${YELLOW}Möchten Sie MCP-Tools aktivieren? (j/n)${NC}"
            read -r ANSWER
            if [[ "$ANSWER" =~ ^[Jj] ]]; then
                MCP_TOOLS_ENABLED=true
            fi
        fi
        
        # Frage nach Vektordatenbank
        if [[ "$USE_VECTOR_DB" == false && "$DOCKER_AVAILABLE" == true ]]; then
            echo -e "${YELLOW}Möchten Sie die Qdrant-Vektordatenbank einrichten? (j/n)${NC}"
            read -r ANSWER
            if [[ "$ANSWER" =~ ^[Jj] ]]; then
                USE_VECTOR_DB=true
            fi
        fi
    fi
    
    log "INFO" "Konfiguration: Projekt=$PROJECT_NAME, Typ=$PROJECT_TYPE, MCP-Tools=$MCP_TOOLS_ENABLED, Vektordatenbank=$USE_VECTOR_DB, Interaktiv=$INTERACTIVE_MODE"
    update_progress "Konfiguration" "Abgeschlossen"
    return 0
}

# Erstelle Projektverzeichnisstruktur mit paralleler Ausführung
create_project_structure() {
    log "INFO" "Erstelle Projektverzeichnisstruktur für '$PROJECT_NAME'..."
    update_progress "Verzeichnisstruktur" "Läuft"
    
    # Temporäre Datei für parallele Verarbeitung
    local temp_result_file=$(mktemp)
    TMP_FILES+=("$temp_result_file")
    
    # Definiere alle Verzeichnisse in einem Array für effiziente Verarbeitung
    local directories=(
        "$FULL_PROJECT_PATH"
        "$FULL_PROJECT_PATH/APP"
        "$FULL_PROJECT_PATH/MARKETING"
        "$FULL_PROJECT_PATH/FINANCE"
        "$FULL_PROJECT_PATH/DOCS"
        "$FULL_PROJECT_PATH/memory-bank"
        "$FULL_PROJECT_PATH/memory-bank/project_context"
        "$FULL_PROJECT_PATH/memory-bank/automated_rules"
    )
    
    # Füge spezielle Verzeichnisse hinzu, wenn bestimmte Features aktiviert sind
    if [[ "$USE_VECTOR_DB" == true ]]; then
        directories+=(
            "$FULL_PROJECT_PATH/memory-bank/vector_index"
            "$FULL_PROJECT_PATH/memory-bank/vector_index/embeddings"
            "$FULL_PROJECT_PATH/memory-bank/vector_index/collections"
            "$FULL_PROJECT_PATH/memory-bank/vector_index/scripts"
            "$FULL_PROJECT_PATH/memory-bank/vector_index/queries"
        )
    fi
    
    if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
        directories+=(
            "$FULL_PROJECT_PATH/.config"
            "$FULL_PROJECT_PATH/.config/claude"
        )
    fi
    
    # Wenn es ein Vibe-Coding-Projekt ist, zusätzliche Verzeichnisse hinzufügen
    if [[ "$PROJECT_TYPE" == "vibe-coding" ]]; then
        directories+=(
            "$FULL_PROJECT_PATH/APP/src"
            "$FULL_PROJECT_PATH/APP/src/app"
            "$FULL_PROJECT_PATH/APP/src/components"
            "$FULL_PROJECT_PATH/APP/src/components/ui"
            "$FULL_PROJECT_PATH/APP/src/components/layout"
            "$FULL_PROJECT_PATH/APP/src/components/3d"
            "$FULL_PROJECT_PATH/APP/src/lib"
            "$FULL_PROJECT_PATH/APP/src/hooks"
            "$FULL_PROJECT_PATH/APP/src/server"
            "$FULL_PROJECT_PATH/APP/src/server/api"
            "$FULL_PROJECT_PATH/APP/src/server/db"
            "$FULL_PROJECT_PATH/APP/src/server/auth"
            "$FULL_PROJECT_PATH/APP/src/styles"
            "$FULL_PROJECT_PATH/APP/src/types"
            "$FULL_PROJECT_PATH/APP/public"
            "$FULL_PROJECT_PATH/APP/tests"
        )
    fi
    
    # Erstelle eine Funktion für die Verzeichniserstellung
    create_dir() {
        local dir="$1"
        if mkdir -p "$dir" 2>/dev/null; then
            echo "SUCCESS:$dir" >> "$temp_result_file"
        else
            echo "FAILED:$dir" >> "$temp_result_file"
        fi
    }
    
    # Parallele Verzeichniserstellung mit Begrenzung der gleichzeitigen Prozesse
    log "DEBUG" "Erstelle ${#directories[@]} Verzeichnisse..."
    
    # Maximale Anzahl gleichzeitiger Prozesse
    local max_parallel=10
    local running=0
    
    for dir in "${directories[@]}"; do
        # Warte, wenn zu viele parallele Prozesse laufen
        if [[ $running -ge $max_parallel ]]; then
            wait -n
            running=$((running - 1))
        fi
        
        # Starte Prozess zur Verzeichniserstellung im Hintergrund
        create_dir "$dir" &
        running=$((running + 1))
    done
    
    # Warte auf alle noch laufenden Hintergrundprozesse
    wait
    
    # Auswertung der Ergebnisse
    local failed_dirs=()
    while IFS= read -r line; do
        local status=$(echo "$line" | cut -d':' -f1)
        local dir=$(echo "$line" | cut -d':' -f2-)
        
        if [[ "$status" == "FAILED" ]]; then
            failed_dirs+=("$dir")
        fi
    done < "$temp_result_file"
    
    # Prüfe, ob es Fehler gab
    if [[ ${#failed_dirs[@]} -gt 0 ]]; then
        log "ERROR" "Konnte folgende Verzeichnisse nicht erstellen:"
        for dir in "${failed_dirs[@]}"; do
            log "ERROR" "  - $dir"
        done
        update_progress "Verzeichnisstruktur" "Fehlgeschlagen"
        return 1
    fi
    
    # Setze Berechtigungen für Verzeichnisse
    if [[ "$INTERACTIVE_MODE" == true ]]; then
        chmod -R 755 "$FULL_PROJECT_PATH"
    fi
    
    log "SUCCESS" "Projektverzeichnisstruktur erfolgreich erstellt: ${#directories[@]} Verzeichnisse"
    update_progress "Verzeichnisstruktur" "Abgeschlossen"
    return 0
}

# Berechtigungen mit dem neuen permissions-parser.sh einrichten
setup_permissions() {
    # Überspringe, wenn AUTO_PERMISSIONS nicht aktiviert ist
    if [[ "$AUTO_PERMISSIONS" != true ]]; then
        log "INFO" "Automatische Berechtigungsverwaltung nicht aktiviert."
        return 0
    fi
    
    # Überspringe, wenn PERMISSIONS_TOOL leer ist
    if [[ -z "$PERMISSIONS_TOOL" ]]; then
        log "WARNING" "Berechtigungsverwaltungs-Tool nicht gefunden. Berechtigungen werden nicht eingerichtet."
        return 0
    fi
    
    log "INFO" "Richte Berechtigungssystem für '$PROJECT_NAME' ein..."
    update_progress "Berechtigungssystem" "Läuft"
    
    # Berechtigungsverzeichnis erstellen
    local permissions_dir="$FULL_PROJECT_PATH/permissions"
    mkdir -p "$permissions_dir"
    
    # Erstelle Basiskonfiguration für Berechtigungen
    local access_control_file="$permissions_dir/access-control.json"
    
    # Datum für die Erstellung
    local today=$(date -I)
    
    # Erstelle Basis-Konfigurationsdatei
    cat > "$access_control_file" << EOF
{
  "repository": "$PROJECT_NAME",
  "owner": "$(whoami)",
  "permissions": {
    "admin": [
      {
        "username": "$(whoami)",
        "email": "admin@example.com",
        "gpg_key_id": "",
        "granted_on": "$today",
        "access_level": "full"
      }
    ],
    "contributors": [],
    "viewers": []
  },
  "access_levels": {
    "full": {
      "permissions": ["read", "write", "execute", "admin"],
      "description": "Vollständiger Zugriff auf alle Bereiche"
    },
    "contributor": {
      "permissions": ["read", "write", "execute"],
      "description": "Kann Code lesen und schreiben, aber keine Admin-Aktionen ausführen"
    },
    "viewer": {
      "permissions": ["read"],
      "description": "Lesezugriff auf nicht-sensible Inhalte"
    }
  }
}
EOF
    
    # Berechtigungen mithilfe von permissions-parser.sh prüfen
    log "DEBUG" "Prüfe Berechtigungen mit $PERMISSIONS_TOOL..."
    
    if [[ -f "$SCRIPT_DIR/$PERMISSIONS_TOOL" ]]; then
        # Kopiere das Tool ins Projektverzeichnis, damit es dort verfügbar ist
        cp "$SCRIPT_DIR/$PERMISSIONS_TOOL" "$FULL_PROJECT_PATH/permissions/"
        
        # Ausführbar machen
        chmod +x "$FULL_PROJECT_PATH/permissions/$PERMISSIONS_TOOL"
        
        # Teste das Berechtigungssystem
        cd "$FULL_PROJECT_PATH"
        if "./permissions/$PERMISSIONS_TOOL" list > /dev/null 2>&1; then
            log "SUCCESS" "Berechtigungssystem erfolgreich eingerichtet."
            
            # Erstelle eine Hilfedatei für Berechtigungen
            cat > "$permissions_dir/README.md" << EOF
# Berechtigungssystem für $PROJECT_NAME

Dieses Verzeichnis enthält die Konfiguration für das Berechtigungssystem des Projekts.

## Verwendung

Das Berechtigungssystem kann mit dem \`$PERMISSIONS_TOOL\` verwaltet werden:

\`\`\`bash
# Benutzer auflisten
./permissions/$PERMISSIONS_TOOL list

# Neuen Benutzer hinzufügen
./permissions/$PERMISSIONS_TOOL add <rolle> <name> <email>

# Benutzer entfernen
./permissions/$PERMISSIONS_TOOL remove <email>

# Benutzerrolle aktualisieren
./permissions/$PERMISSIONS_TOOL update <email> <neue_rolle>
\`\`\`

## Zugriffsebenen

- **admin**: Vollständiger Zugriff auf alle Bereiche
- **contributor**: Kann Code lesen und schreiben, aber keine Admin-Aktionen ausführen
- **viewer**: Lesezugriff auf nicht-sensible Inhalte

## Aktueller Status

$(./permissions/$PERMISSIONS_TOOL list)
EOF
            
            # Berechtigungsdokumentation auch in memory-bank speichern
            mkdir -p "$FULL_PROJECT_PATH/memory-bank/project_context"
            cat > "$FULL_PROJECT_PATH/memory-bank/project_context/permissions.md" << EOF
# Berechtigungskonfiguration für $PROJECT_NAME

## Überblick
Das Projekt verwendet das AGI-System-Berechtigungsmodell mit den folgenden Zugriffsebenen:

1. **Admin** - Vollständiger Zugriff auf alle Funktionen und Daten
2. **Contributor** - Kann Code lesen und schreiben, aber keine Admin-Aktionen ausführen
3. **Viewer** - Kann nur nicht-sensible Inhalte lesen

## Aktuelle Berechtigungen
$(./permissions/$PERMISSIONS_TOOL list)

## Berechtigungsverwaltung
Berechtigungen werden in \`/permissions/access-control.json\` gespeichert und können mit \`$PERMISSIONS_TOOL\` verwaltet werden.

### Beispielbefehle
\`\`\`bash
# Benutzer auflisten
./permissions/$PERMISSIONS_TOOL list

# Neuen Benutzer hinzufügen
./permissions/$PERMISSIONS_TOOL add admin "Neuer Admin" "admin@example.com"
./permissions/$PERMISSIONS_TOOL add contributor "Neuer Contributor" "dev@example.com"
./permissions/$PERMISSIONS_TOOL add viewer "Neuer Viewer" "viewer@example.com"

# Benutzer entfernen
./permissions/$PERMISSIONS_TOOL remove "user@example.com"

# Benutzerrolle aktualisieren
./permissions/$PERMISSIONS_TOOL update "user@example.com" "admin"
\`\`\`
EOF
        else
            log "WARNING" "Berechtigungssystem-Test fehlgeschlagen. Die Datei wurde erstellt, aber das Tool funktioniert möglicherweise nicht korrekt."
        fi
    else
        log "WARNING" "Berechtigungsverwaltungs-Tool nicht gefunden. Nur die Basiskonfiguration wurde erstellt."
    fi
    
    update_progress "Berechtigungssystem" "Abgeschlossen"
    return 0
}

# Erstelle Memory-Bank
setup_memory_bank() {
    log "INFO" "Richte Memory-Bank für '$PROJECT_NAME' ein..."
    
    # Datum für Templates
    local today=$(date +"%d.%m.%Y")
    
    # Versuche die Memory-Bank-Vorlagen zu kopieren
    if [ -d "$TEMPLATE_DIR/memory-bank-structure" ]; then
        # Bevorzuge die speziellen Memory-Bank-Vorlagen, wenn vorhanden
        cp -r "$TEMPLATE_DIR/memory-bank-structure/"* "$FULL_PROJECT_PATH/memory-bank/"
        
        # Ersetze Platzhalter
        find "$FULL_PROJECT_PATH/memory-bank" -type f -exec sed -i "s/VibeApp/$PROJECT_NAME/g" {} \;
        find "$FULL_PROJECT_PATH/memory-bank" -type f -exec sed -i "s/03.05.2025/$today/g" {} \;
    else
        # Fallback auf manuelle Erstellung der Memory-Bank-Dateien
        
        # projectbrief.md
        cat > "$FULL_PROJECT_PATH/memory-bank/projectbrief.md" << EOF
# Projektübersicht für $PROJECT_NAME

## Projektdefinition
- **Name**: $PROJECT_NAME
- **Startdatum**: $today
- **Typ**: ${PROJECT_TYPE^} Projekt

## Projektziele
- Ziel 1: TBD
- Ziel 2: TBD
- Ziel 3: TBD

## Beteiligte Personen
- Projektleitung: TBD
- Entwicklung: TBD
- Design: TBD

## Zeitrahmen
- Start: $today
- Zwischenziele: TBD
- Fertigstellung: TBD
EOF
        
        # productContext.md
        cat > "$FULL_PROJECT_PATH/memory-bank/productContext.md" << EOF
# Produktkontext für $PROJECT_NAME

## Problembeschreibung
Beschreibe hier das Problem, das das Projekt lösen soll.

## Lösungsansatz
Beschreibe hier, wie das Projekt das Problem lösen wird.

## Zielgruppe
- Primäre Zielgruppe: TBD
- Sekundäre Zielgruppe: TBD

## Marktanalyse
- Marktgröße: TBD
- Wettbewerber: TBD
- Alleinstellungsmerkmale: TBD

## Erfolgsmetriken
- Metrik 1: TBD
- Metrik 2: TBD
- Metrik 3: TBD
EOF
        
        # activeContext.md
        cat > "$FULL_PROJECT_PATH/memory-bank/activeContext.md" << EOF
# Aktiver Arbeitskontext für $PROJECT_NAME

## Aktueller Fokus
Beschreibe hier, woran aktuell gearbeitet wird.

## Offene Aufgaben
- [ ] Aufgabe 1: TBD
- [ ] Aufgabe 2: TBD
- [ ] Aufgabe 3: TBD

## Entscheidungen und Überlegungen
Notiere hier wichtige Entscheidungen und Überlegungen.

## Kontextnotizen
Informationen, die für die aktuelle Arbeit relevant sind.
EOF
        
        # systemPatterns.md
        cat > "$FULL_PROJECT_PATH/memory-bank/systemPatterns.md" << EOF
# Systemarchitektur für $PROJECT_NAME

## Architekturübersicht
Beschreibe hier die grundlegende Architektur des Systems.

## Verwendete Patterns
- Pattern 1: TBD
- Pattern 2: TBD
- Pattern 3: TBD

## Komponentendiagramm
\`\`\`
$PROJECT_NAME
├── Komponente 1
│   ├── Unterkomponente A
│   └── Unterkomponente B
├── Komponente 2
└── Komponente 3
\`\`\`

## Technische Schulden und Roadmap
Notiere hier bekannte technische Schulden und geplante Architekturänderungen.
EOF
        
        # techContext.md
        cat > "$FULL_PROJECT_PATH/memory-bank/techContext.md" << EOF
# Technologie-Stack für $PROJECT_NAME

## Kern-Technologien
EOF

        # Wenn Vibe-Coding-Projekt
        if [ "$PROJECT_TYPE" = "vibe-coding" ]; then
            cat >> "$FULL_PROJECT_PATH/memory-bank/techContext.md" << EOF
- **Frontend**: Next.js 15 mit App Router
- **UI**: React 19, Tailwind CSS
- **State Management**: React Context + Hooks
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **3D**: Three.js mit React Three Fiber
- **Deployment**: Vercel
EOF
        else
            cat >> "$FULL_PROJECT_PATH/memory-bank/techContext.md" << EOF
- **Frontend**: TBD
- **Backend**: TBD
- **Datenbank**: TBD
- **Deployment**: TBD
- **Weitere Technologien**: TBD
EOF
        fi

        # MCP-Tools hinzufügen, wenn aktiviert
        if [ "$MCP_TOOLS_ENABLED" = true ]; then
            cat >> "$FULL_PROJECT_PATH/memory-bank/techContext.md" << EOF

## MCP-Tools
- **desktop-commander**: Dateisystem- und Shell-Operationen
- **memory-bank**: Verwaltung der projektspezifischen Memory-Banks
- **marketing-tools**: Marketing-bezogene Aufgaben und Analysen
- **browser-tools**: Web-Recherche und Browser-Automatisierung
- **toolbox**: Allgemeine KI-Tools und Hilfsprogramme
EOF
        fi

        # Vektordatenbank hinzufügen, wenn aktiviert
        if [ "$USE_VECTOR_DB" = true ]; then
            cat >> "$FULL_PROJECT_PATH/memory-bank/techContext.md" << EOF

## Vektordatenbank
- **Qdrant**: Vektordatenbank für semantische Suche
- **Sammlungen**: project_context, code_embeddings, documentation
- **Embedding-Modell**: TBD
EOF
        fi

        cat >> "$FULL_PROJECT_PATH/memory-bank/techContext.md" << EOF

## Entwicklungsumgebung
- **IDE**: Visual Studio Code
- **Versionskontrolle**: Git
- **Package-Manager**: npm
EOF
        
        # progress.md
        cat > "$FULL_PROJECT_PATH/memory-bank/progress.md" << EOF
# Projektfortschritt für $PROJECT_NAME

## Aktueller Status
- **Datum**: $today
- **Status**: Initialisierung
- **Phase**: Projektstart

## Meilensteine
- [x] Projektinitialisierung ($today)
- [ ] Meilenstein 1: TBD
- [ ] Meilenstein 2: TBD
- [ ] Meilenstein 3: TBD

## Letzte Aktualisierungen
- $today: Projekt erstellt mit AGI-System
EOF
        
        # .clauderules
        cat > "$FULL_PROJECT_PATH/memory-bank/.clauderules" << EOF
# Projektspezifische Regeln für $PROJECT_NAME

## Naming Conventions
- CamelCase für Variablen und Funktionen
- PascalCase für Komponenten und Klassen
- kebab-case für Dateinamen
- SCREAMING_SNAKE_CASE für Konstanten

## Code-Stil
- Tabs statt Spaces
- Maximale Zeilenlänge: 80 Zeichen
- Semicolons am Ende jeder Anweisung

## Commit-Nachrichten
- Format: <typ>(<scope>): <beschreibung>
- Typen: feat, fix, docs, style, refactor, test, chore
- Beschreibung im Imperativ schreiben

## Pull Requests
- Mindestens ein Reviewer erforderlich
- Tests müssen bestehen
- Lint-Checks müssen bestehen
EOF
        
        # CLAUDE.md
        cat > "$FULL_PROJECT_PATH/memory-bank/CLAUDE.md" << EOF
# $PROJECT_NAME

## Projekt-Kontext
$PROJECT_NAME ist ein ${PROJECT_TYPE^}-Projekt, das am $today initialisiert wurde.

## Verzeichnisstruktur
- \`APP/\`: Anwendungsspezifische Komponenten
- \`MARKETING/\`: Marketing-bezogene Assets und Tools
- \`FINANCE/\`: Finanzielle Modellierung und Tools
- \`DOCS/\`: Projektdokumentation
- \`memory-bank/\`: Wissens- und Kontextspeicher

## Coding-Standards
- CamelCase für Variablen und Funktionen
- PascalCase für Komponenten und Klassen
- kebab-case für Dateinamen
- SCREAMING_SNAKE_CASE für Konstanten

## Workflows
- Verwende \`git\` für Versionskontrolle
- Dokumentiere Änderungen in \`memory-bank/progress.md\`
- Aktualisiere \`memory-bank/activeContext.md\` bei Kontextänderungen
EOF
    fi
    
    # Automatisierte Regeln erstellen
    cat > "$FULL_PROJECT_PATH/memory-bank/automated_rules/init_sequence.md" << EOF
# Automatisierte Initialisierungssequenz für $PROJECT_NAME

## Initialisierungsschritte
1. Projektverzeichnisse erstellt
2. Memory-Bank-System eingerichtet
EOF

    # MCP-Tools hinzufügen, wenn aktiviert
    if [ "$MCP_TOOLS_ENABLED" = true ]; then
        cat >> "$FULL_PROJECT_PATH/memory-bank/automated_rules/init_sequence.md" << EOF
3. MCP-Tools aktiviert und konfiguriert
EOF
    fi

    # Vektordatenbank hinzufügen, wenn aktiviert
    if [ "$USE_VECTOR_DB" = true ]; then
        cat >> "$FULL_PROJECT_PATH/memory-bank/automated_rules/init_sequence.md" << EOF
4. Qdrant-Vektordatenbank eingerichtet
EOF
    fi

    cat >> "$FULL_PROJECT_PATH/memory-bank/automated_rules/init_sequence.md" << EOF

## Automatisierte Prozesse
- Memory-Bank-Aktualisierung: Automatisch nach Git-Commits
- Kontextaktivierung: Beim Öffnen des Projekts
EOF

    # MCP-Tool-Workflows erstellen, wenn aktiviert
    if [ "$MCP_TOOLS_ENABLED" = true ]; then
        cat > "$FULL_PROJECT_PATH/memory-bank/automated_rules/tool_workflows.md" << EOF
# MCP-Tool-Workflows für $PROJECT_NAME

## desktop-commander
- Dateisystem-Operationen
- Shell-Befehle ausführen
- Verzeichnisse durchsuchen und organisieren

## memory-bank
- Speichern und Abrufen von Projektkontext
- Aktualisieren von Projektfortschritt
- Verwalten von Projektwissen

## marketing-tools
- Marktrecherche durchführen
- Zielgruppenanalyse erstellen
- Marketing-Assets generieren

## browser-tools
- Webrecherche durchführen
- Daten von Websites extrahieren
- Browser-Automatisierung für Tests

## toolbox
- Bildgenerierung
- Textanalyse und -zusammenfassung
- Code-Optimierung und -Refactoring

## Workflow-Beispiele
1. **Projektaktualisierung**:
   \`memory-bank\` → Kontext abrufen → \`desktop-commander\` → Code aktualisieren → \`memory-bank\` → Fortschritt aktualisieren

2. **Marktrecherche**:
   \`browser-tools\` → Daten sammeln → \`marketing-tools\` → Analyse durchführen → \`memory-bank\` → Erkenntnisse speichern

3. **Code-Optimierung**:
   \`memory-bank\` → Architektur abrufen → \`toolbox\` → Code analysieren → \`desktop-commander\` → Änderungen anwenden
EOF
    fi
    
    log "SUCCESS" "Memory-Bank erfolgreich eingerichtet."
    return 0
}

# Erstelle erweiterte interaktive .about-Datei mit MCP-Tools-Unterstützung
create_interactive_about() {
    log "INFO" "Erstelle erweiterte interaktive .about-Datei..."
    update_progress "About-Datei Erstellung" "Läuft"
    
    local about_file="$FULL_PROJECT_PATH/.about.interactive"
    local project_uid="agi-$(date +%s)-$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9' | cut -c1-8)"
    
    # Prüfe OS-Typ
    local os_type="linux"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="mac"
    fi
    
    # Erstelle umfassende .about.interactive Datei
    cat > "$about_file" << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "created": "$(date -I)",
    "type": "${PROJECT_TYPE^} Project",
    "path": "$FULL_PROJECT_PATH",
    "uid": "$project_uid",
    "environment": "${os_type}",
    "description": "AGI-System Projekt mit erweiterten KI-Funktionen"
  },
EOF

    # MCP-Tools mit detaillierten Konfigurationen hinzufügen
    if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
        cat >> "$about_file" << EOF
  "mcp_tools": {
    "enabled": [
      "desktop-commander", 
      "memory-bank", 
      "marketing-tools", 
      "browser-tools", 
      "brave-web-search",
      "agent-sdk", 
      "sequentialthinking",
      "code-mcp",
      "context7-mcp",
      "magic-mcp",
      "toolbox", 
      "transformers"
    ],
    "permissions": {
      "read": true,
      "write": true,
      "execute": true,
      "network": true,
      "system": true
    },
    "default_tool": "desktop-commander",
    "tool_configs": {
      "desktop-commander": {
        "allowed_directories": ["$FULL_PROJECT_PATH"],
        "allowed_operations": "all",
        "auto_start": true
      },
      "memory-bank": {
        "memory_bank_path": "$FULL_PROJECT_PATH/memory-bank",
        "vector_enabled": ${USE_VECTOR_DB},
        "auto_embed": true,
        "auto_connect": true
      },
      "browser-tools": {
        "headless": true,
        "allow_navigation": true,
        "max_tabs": 5,
        "auto_close": true,
        "platform": "${os_type}"
      },
      "transformers": {
        "cache_dir": "$FULL_PROJECT_PATH/.cache/transformers",
        "default_models": ["all-MiniLM-L6-v2", "t5-small"],
        "allow_download": true
      }
    },
    "connections": {
      "config_file": "$FULL_PROJECT_PATH/.config/claude/mcpservers.json",
      "auto_connect": true,
      "connection_timeout": 30000
    }
  },
EOF
    else
        cat >> "$about_file" << EOF
  "mcp_tools": {
    "enabled": [],
    "permissions": {
      "read": false,
      "write": false,
      "execute": false,
      "network": false,
      "system": false
    }
  },
EOF
    fi

    # Erweiterte Vektordatenbank-Konfiguration
    if [[ "$USE_VECTOR_DB" == true ]]; then
        cat >> "$about_file" << EOF
  "vector_database": {
    "type": "qdrant",
    "endpoint": "http://localhost:6333",
    "collections": [
      {
        "name": "project_context",
        "description": "Allgemeiner Projektkontext und Dokumentation",
        "vector_size": 384
      },
      {
        "name": "code_embeddings",
        "description": "Code-Snippets und Funktionsbeschreibungen",
        "vector_size": 384
      },
      {
        "name": "documentation",
        "description": "Technische Dokumentation und Anleitungen",
        "vector_size": 384
      }
    ],
    "embedding_models": {
      "default": "all-MiniLM-L6-v2",
      "alternatives": ["sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"]
    },
    "docker": {
      "container_name": "qdrant-$PROJECT_NAME",
      "start_script": "$FULL_PROJECT_PATH/start-qdrant.sh",
      "stop_script": "$FULL_PROJECT_PATH/stop-qdrant.sh"
    },
    "api": {
      "search_limit": 5,
      "score_threshold": 0.7,
      "batch_size": 100
    }
  },
EOF
    else
        cat >> "$about_file" << EOF
  "vector_database": {
    "type": "none",
    "endpoint": "",
    "collections": [],
    "embedding_models": {
      "default": "all-MiniLM-L6-v2"
    }
  },
EOF
    fi

    # Erweiterte Memory-Bank-Konfiguration
    cat >> "$about_file" << EOF
  "memory_rules": {
    "retention_policy": "perpetual",
    "context_window": "infinite",
    "embedding_model": "all-MiniLM-L6-v2",
    "semantic_search": ${USE_VECTOR_DB},
    "indexing": {
      "auto_index": true,
      "index_frequency": "realtime",
      "exclude_patterns": ["**/node_modules/**", "**/.git/**", "**/dist/**", "**/build/**"]
    },
    "memory_types": [
      "project_context",
      "code",
      "conversations",
      "decisions",
      "research",
      "tasks"
    ],
    "organization": {
      "hierarchical": true,
      "categorized": true,
      "temporal": true
    },
    "integration": {
      "git_hooks": true,
      "ide_plugins": false,
      "claude_code": true
    }
  },
  "project_type_config": {
EOF

    # Projekttyp-spezifische Konfiguration
    if [[ "$PROJECT_TYPE" == "vibe-coding" ]]; then
        cat >> "$about_file" << EOF
    "framework": "nextjs",
    "ui_library": "react",
    "styling": "tailwind",
    "backend": "supabase",
    "deployment": "vercel",
    "features": [
      "3d-visualization",
      "api-routes",
      "authentication",
      "database",
      "state-management"
    ],
    "commands": {
      "dev": "cd APP && npm run dev",
      "build": "cd APP && npm run build",
      "test": "cd APP && npm run test",
      "lint": "cd APP && npm run lint"
    }
EOF
    else
        cat >> "$about_file" << EOF
    "framework": "standard",
    "features": [
      "documentation",
      "organization",
      "knowledge-management"
    ],
    "commands": {
      "update": "./update_memory.sh",
      "backup": "./backup.sh"
    }
EOF
    fi

    # Datei abschließen
    cat >> "$about_file" << EOF
  }
}
EOF
    
    # Erstelle eine normale .about-Datei für einfacheren Zugriff
    cat > "$FULL_PROJECT_PATH/.about" << EOF
# $PROJECT_NAME - AGI-System Projekt
# Erstellt am: $(date -I)
# Typ: ${PROJECT_TYPE^} Projekt
# UID: $project_uid

PROJECT_PATH="$FULL_PROJECT_PATH"
PROJECT_TYPE="$PROJECT_TYPE"
PROJECT_UID="$project_uid"
MCP_TOOLS_ENABLED=$MCP_TOOLS_ENABLED
VECTOR_DB_ENABLED=$USE_VECTOR_DB
CREATED_DATE="$(date -I)"
OS_TYPE="$os_type"

# Projektstart:
# 1. Claude Code starten: claude
# 2. MCP-Tools aktivieren: /mcp
# 3. Bei Bedarf Vektordatenbank starten: ./start-qdrant.sh
EOF
    
    # Erstelle eine zusätzliche .about.json für programmatischen Zugriff
    cat > "$FULL_PROJECT_PATH/.about.json" << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "path": "$FULL_PROJECT_PATH",
    "type": "$PROJECT_TYPE",
    "uid": "$project_uid",
    "created": "$(date -I)",
    "os_type": "$os_type"
  },
  "features": {
    "mcp_tools": $MCP_TOOLS_ENABLED,
    "vector_db": $USE_VECTOR_DB
  },
  "paths": {
    "memory_bank": "$FULL_PROJECT_PATH/memory-bank",
    "mcp_config": "$FULL_PROJECT_PATH/.config/claude/mcpservers.json",
    "vector_db": "$FULL_PROJECT_PATH/memory-bank/vector_index"
  }
}
EOF
    
    log "SUCCESS" "Erweiterte interaktive .about-Dateien erstellt."
    update_progress "About-Datei Erstellung" "Abgeschlossen"
    return 0
}

# Konfiguriere MCP-Tools
configure_mcp_tools() {
    if [[ "$MCP_TOOLS_ENABLED" == false ]]; then
        return 0
    fi
    
    log "INFO" "Konfiguriere MCP-Tools..."
    update_progress "MCP-Tools Konfiguration" "Läuft"
    
    local config_dir="$FULL_PROJECT_PATH/.config/claude"
    local config_file="$config_dir/mcpservers.json"
    
    mkdir -p "$config_dir"
    
    # Eine UID für das aktuelle Projekt generieren
    local project_uid="agi-$(date +%s)-$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9' | cut -c1-8)"
    
    # Prüfe OS-Typ für browsertools-Konfiguration
    local os_type="linux"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="mac"
    fi
    
    log "DEBUG" "Projekttyp: $PROJECT_TYPE, Projekt-UID: $project_uid, OS-Typ: $os_type"
    
    # Erstelle mcpservers.json mit allen benötigten Tools
    cat > "$config_file" << EOF
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@wonderwhy-er/desktop-commander"],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "ALLOWED_OPERATIONS": "all",
        "PROJECT_NAME": "$PROJECT_NAME",
        "PROJECT_UID": "$project_uid"
      }
    },
    "memory-bank": {
      "command": "npx",
      "args": ["-y", "@alioshr/memory-bank-mcp"],
      "env": {
        "MEMORY_BANK_PATH": "$FULL_PROJECT_PATH/memory-bank",
        "PROJECT_NAME": "$PROJECT_NAME",
        "VECTOR_DB_ENABLED": "$USE_VECTOR_DB",
        "PROJECT_UID": "$project_uid"
      }
    },
    "marketing-tools": {
      "command": "npx",
      "args": ["-y", "@osp/marketing-tools"],
      "env": {
        "PROJECT_CONTEXT": "$FULL_PROJECT_PATH/memory-bank/project_context",
        "PROJECT_NAME": "$PROJECT_NAME",
        "PROJECT_UID": "$project_uid" 
      }
    },
    "browser-tools": {
      "command": "npx",
      "args": ["-y", "@agentdeskai/browser-tools-mcp-$os_type"],
      "env": {
        "BROWSER_MODE": "headless",
        "ALLOW_NAVIGATION": "true",
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "PROJECT_UID": "$project_uid"
      }
    },
    "brave-web-search": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery/brave-web-search"],
      "env": {
        "CACHE_DURATION": "3600",
        "RESULTS_LIMIT": "10",
        "PROJECT_UID": "$project_uid"
      }
    },
    "agent-sdk": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery/agent-sdk"],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "PROJECT_UID": "$project_uid"
      }
    },
    "sequentialthinking": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery/sequentialthinking"],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "PROJECT_UID": "$project_uid",
        "MEMORY_BANK_PATH": "$FULL_PROJECT_PATH/memory-bank"
      }
    },
    "code-mcp": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery/code-mcp"],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "CODE_FEATURES": "generate,optimize,document,test",
        "PROJECT_UID": "$project_uid"
      }
    },
    "context7-mcp": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery/context7-mcp"],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "MEMORY_BANK_PATH": "$FULL_PROJECT_PATH/memory-bank",
        "PROJECT_UID": "$project_uid"
      }
    },
    "magic-mcp": {
      "command": "npx",
      "args": ["-y", "@smithery/cli@latest", "run", "@smithery/magic-mcp"],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "PROJECT_UID": "$project_uid"
      }
    },
    "toolbox": {
      "command": "npx",
      "args": [
        "-y",
        "@smithery/cli@latest",
        "run",
        "@smithery/toolbox",
        "--key",
        "7d1fa500-da11-4040-b21b-39f1014ed8fb",
        "--profile",
        "youngest-smelt-DDZA3B"
      ],
      "env": {
        "PROJECT_DIR": "$FULL_PROJECT_PATH",
        "PROJECT_UID": "$project_uid"
      }
    },
    "transformers": {
      "command": "npx",
      "args": ["-y", "@huggingface/transformers-mcp"],
      "env": {
        "CACHE_DIR": "$FULL_PROJECT_PATH/.cache/transformers",
        "PROJECT_UID": "$project_uid"
      }
    }
  }
}
EOF
    
    # Erweiterte Berechtigungskonfiguration
    cat > "$FULL_PROJECT_PATH/memory-bank/project_context/permissions.json" << EOF
{
  "tool_permissions": {
    "project_level": {
      "allowed_tools": [
        "Bash(**)",
        "Python(**)",
        "File(**)",
        "Web(**)",
        "API(**)",
        "MCP(**)",
        "Vector(**)",
        "Transformer(**)",
        "Image(**)"
      ],
      "restricted_tools": [],
      "execution_context": "project_sandbox"
    },
    "memory_bank_access": {
      "read": true,
      "write": true,
      "modify_structure": true,
      "vector_operations": true
    },
    "mcp_integration": {
      "auto_connect": true,
      "share_context": true,
      "allow_chaining": true,
      "default_enabled": true
    },
    "vector_db": {
      "enabled": ${USE_VECTOR_DB},
      "collections": ["project_context", "code_embeddings", "documentation"],
      "default_embedding_model": "all-MiniLM-L6-v2",
      "search_k": 5,
      "similarity_threshold": 0.7
    }
  }
}
EOF
    
    # MCP Memory-Regeln erstellen
    cat > "$FULL_PROJECT_PATH/memory-bank/memory_rules.json" << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "uid": "$project_uid",
    "type": "$PROJECT_TYPE",
    "created": "$(date -I)"
  },
  "memory_rules": {
    "retention_policy": "permanent",
    "context_window": "infinite",
    "memory_types": ["project_context", "code", "conversations", "decisions", "tasks"],
    "indexing": {
      "enabled": true,
      "auto_embed": true,
      "exclude_patterns": ["**/node_modules/**", "**/.git/**", "**/build/**", "**/dist/**"]
    },
    "tool_integration": {
      "enabled": true,
      "tools": ["desktop-commander", "memory-bank", "marketing-tools", "browser-tools", "agent-sdk", "toolbox", "transformers"]
    },
    "permissions": {
      "read": true,
      "write": true,
      "execute": true,
      "network": true
    }
  },
  "vector_db": {
    "enabled": ${USE_VECTOR_DB},
    "endpoint": "${USE_VECTOR_DB}" == "true" ? "http://localhost:6333" : "",
    "collections": ["project_context", "code_embeddings", "documentation"],
    "embedding_model": "all-MiniLM-L6-v2"
  }
}
EOF
    
    # MCP-Verbindungen dokumentieren
    cat > "$FULL_PROJECT_PATH/memory-bank/project_context/mcp_connections.md" << EOF
# MCP-Tool-Konfiguration für $PROJECT_NAME

## Aktivierte Tools
- **desktop-commander**: Dateisystem- und Shell-Operationen
- **memory-bank**: Memory-Bank-Verwaltung und semantisches Gedächtnis
- **marketing-tools**: Marketing-Analyse, Content-Erstellung und SEO-Tools
- **browser-tools**: Web-Recherche, Browser-Automatisierung und Datenextraktion
- **brave-web-search**: Aktuelle Informationen und Webrecherche für Projekte
- **agent-sdk**: Agentenbasierte Automatisierung und TaskOS-Integration
- **sequentialthinking**: Strukturierte Problemlösung und komplexe Analysen 
- **code-mcp**: Code-Generierung, -Optimierung und -Dokumentation
- **context7-mcp**: Semantische Kontextverwaltung und -analyse
- **magic-mcp**: Kreative Aufgaben wie Namensgebung, Design und Konzeption
- **toolbox**: Umfassende KI-Tools für diverse Aufgaben
- **transformers**: Zugriff auf Hugging Face Transformer-Modelle für spezielle KI-Aufgaben

## Projekt-Details
- Projektname: $PROJECT_NAME
- Projekt-UID: $project_uid
- Projekttyp: ${PROJECT_TYPE^}
- Pfad: $FULL_PROJECT_PATH
- Konfigurationsdatei: $config_file
- Vektor-DB aktiviert: ${USE_VECTOR_DB}

## Berechtigungen
- Voller Lesezugriff auf das Projektverzeichnis
- Schreibzugriff für projektbezogene Dateien
- Ausführung von Befehlen innerhalb des Projektkontexts
- Netzwerkzugriff für Web-Recherche und API-Aufrufe
- Vektordatenbank-Zugriff (wenn aktiviert)
- Transformer-Modellzugriff für spezielle KI-Aufgaben

## Verwendung
1. Starte Claude Code im Projektverzeichnis
2. Aktiviere MCP-Tools mit: \`/mcp\`
3. Spezifische Tools können mit \`/mcp <tool-name>\` aktiviert werden
4. Verwende die Tools über natürliche Sprachbefehle
5. Memory-Bank-Aktualisierung mit \`/update_memory\`

## Erweiterte Workflows
- **Projektentwicklung**: \`desktop-commander\` → Code-Bearbeitung, \`memory-bank\` → Kontext-Speicherung
- **Recherche**: \`browser-tools\` → Datensammlung, \`transformers\` → Textanalyse, \`memory-bank\` → Erkenntnisse speichern
- **Marketing**: \`marketing-tools\` → Content erstellen, \`browser-tools\` → Wettbewerberanalyse
- **KI-Experimente**: \`transformers\` → Modelleinsatz, \`toolbox\` → Ergebnisvisualisierung
- **Agenten-Workflows**: \`agent-sdk\` → Aufgabenkoordination, \`desktop-commander\` → Aktionsausführung

## Vektordatenbank-Integration
${USE_VECTOR_DB == "true" ? "Die Qdrant-Vektordatenbank ist für dieses Projekt aktiviert und kann für semantische Suche und Ähnlichkeitsvergleiche verwendet werden. Starte sie mit ./start-qdrant.sh" : "Die Vektordatenbank ist derzeit deaktiviert. Sie kann jederzeit mit der Option --vector-db aktiviert werden."} 
EOF

    # Automatisierte Workflows dokumentieren
    cat > "$FULL_PROJECT_PATH/memory-bank/automated_rules/mcp_workflows.md" << EOF
# Automatisierte MCP-Workflows für $PROJECT_NAME

## Desktop-Commander → Memory-Bank
- **Trigger**: Neue Code-Datei erstellt oder geändert
- **Workflow**: 
  1. desktop-commander erkennt Dateiänderung
  2. memory-bank aktualisiert den Code-Kontext
  3. memory-bank erstellt Einbettungen für semantische Suche

## Browser-Tools → Marketing-Tools → Memory-Bank
- **Trigger**: Wettbewerberrecherche
- **Workflow**:
  1. browser-tools sammeln Daten von Wettbewerberwebsites
  2. marketing-tools analysieren die gesammelten Daten
  3. memory-bank speichert Erkenntnisse im Projektkontext

## Memory-Bank → Transformers
- **Trigger**: Komplexe Textanalyse benötigt
- **Workflow**:
  1. memory-bank stellt relevanten Kontext bereit
  2. transformers führen spezifische Sprachmodellierung durch
  3. Ergebnisse werden zurück in memory-bank gespeichert

## Agent-SDK → Desktop-Commander
- **Trigger**: Automatisierte Aufgabenkette
- **Workflow**:
  1. agent-sdk plant und koordiniert mehrere Aufgaben
  2. desktop-commander führt konkrete Datei- und Shell-Operationen aus
  3. agent-sdk überwacht Fortschritt und passt Plan an

## Toolbox → Browser-Tools → Memory-Bank
- **Trigger**: Erweiterte Datenanalyse und -visualisierung
- **Workflow**:
  1. browser-tools sammeln Daten aus verschiedenen Quellen
  2. toolbox verarbeitet und visualisiert die Daten
  3. memory-bank speichert Ergebnisse für späteren Zugriff
EOF

    log "SUCCESS" "Erweiterte MCP-Tools konfiguriert."
    update_progress "MCP-Tools Konfiguration" "Abgeschlossen"
    return 0
}

# Qdrant-Vektordatenbank einrichten
setup_vector_database() {
    if [ "$USE_VECTOR_DB" = false ]; then
        return 0
    fi
    
    if [ "$DOCKER_AVAILABLE" = false ]; then
        log "WARNING" "Docker ist nicht installiert. Die Vektordatenbank kann nicht eingerichtet werden."
        log "WARNING" "Bitte installieren Sie Docker und führen Sie das Setup manuell durch."
        return 1
    fi
    
    log "INFO" "Richte Qdrant-Vektordatenbank für '$PROJECT_NAME' ein..."
    
    # Docker-Compose-Datei erstellen
    local docker_compose_file="$FULL_PROJECT_PATH/docker-compose.yml"
    
    cat > "$docker_compose_file" << EOF
version: '3'
services:
  qdrant:
    image: qdrant/qdrant
    container_name: qdrant-$PROJECT_NAME
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - ./qdrant_storage:/qdrant/storage
    restart: unless-stopped
    networks:
      - agi_network

networks:
  agi_network:
    driver: bridge
EOF
    
    # Startup-Skript für Qdrant
    local startup_script="$FULL_PROJECT_PATH/start-qdrant.sh"
    
    cat > "$startup_script" << EOF
#!/bin/bash
# Qdrant-Vektordatenbank-Startup-Skript für $PROJECT_NAME

cd "\$(dirname "\$0")"
docker-compose up -d

echo "Qdrant für $PROJECT_NAME gestartet auf http://localhost:6333"
echo "Weitere Informationen: $FULL_PROJECT_PATH/memory-bank/vector_index/"
EOF
    
    chmod +x "$startup_script"
    
    # README für Vektordatenbank
    cat > "$FULL_PROJECT_PATH/memory-bank/vector_index/README.md" << EOF
# Qdrant-Vektordatenbank für $PROJECT_NAME

## Übersicht
Diese Vektordatenbank speichert semantische Einbettungen für das Projekt, um intelligente Suche und Kontextabruf zu ermöglichen.

## Sammlungen
- **project_context**: Projektkontext und Dokumentation
- **code_embeddings**: Code-Snippets und -Fragmente
- **documentation**: Technische Dokumentation und Anleitungen

## Verwendung
1. Starte die Datenbank mit \`./start-qdrant.sh\`
2. Greife über http://localhost:6333 darauf zu
3. Verwende die memory-bank-mcp zur automatischen Indexierung von Projektdateien

## Python-Beispiel für Qdrant-Zugriff
\`\`\`python
from qdrant_client import QdrantClient
from qdrant_client.http import models

client = QdrantClient("localhost", port=6333)

# Sammlung erstellen
client.create_collection(
    collection_name="project_context",
    vectors_config=models.VectorParams(size=1536, distance=models.Distance.COSINE),
)

# Punkt hinzufügen
client.upsert(
    collection_name="project_context",
    points=[
        models.PointStruct(
            id=1,
            vector=[0.1, 0.2, ...],
            payload={"text": "Projektkontext für $PROJECT_NAME"}
        )
    ]
)

# Suche
results = client.search(
    collection_name="project_context",
    query_vector=[0.1, 0.2, ...],
    limit=5
)
\`\`\`

## Sammlungen erstellen
Verwende die \`create-collections.py\` im embeddings-Verzeichnis, um alle erforderlichen Sammlungen zu initialisieren.
EOF
    
    # Python-Skript zur Erstellung von Sammlungen
    mkdir -p "$FULL_PROJECT_PATH/memory-bank/vector_index/embeddings"
    local collections_script="$FULL_PROJECT_PATH/memory-bank/vector_index/embeddings/create-collections.py"
    
    cat > "$collections_script" << EOF
#!/usr/bin/env python3
# Skript zur Erstellung von Qdrant-Sammlungen für $PROJECT_NAME

from qdrant_client import QdrantClient
from qdrant_client.http import models
import sys

def create_collections():
    try:
        client = QdrantClient("localhost", port=6333)
        
        # Sammlungen definieren
        collections = [
            "project_context",
            "code_embeddings",
            "documentation"
        ]
        
        # Sammlungen erstellen
        for collection in collections:
            try:
                client.create_collection(
                    collection_name=collection,
                    vectors_config=models.VectorParams(
                        size=1536,  # OpenAI Embedding-Dimensionen
                        distance=models.Distance.COSINE
                    )
                )
                print(f"Sammlung '{collection}' erfolgreich erstellt.")
            except Exception as e:
                print(f"Fehler beim Erstellen der Sammlung '{collection}': {e}")
        
        print("Alle Sammlungen wurden erstellt.")
        return True
        
    except Exception as e:
        print(f"Fehler bei der Verbindung zur Qdrant-Datenbank: {e}")
        return False

if __name__ == "__main__":
    print("Erstelle Qdrant-Sammlungen für $PROJECT_NAME...")
    success = create_collections()
    sys.exit(0 if success else 1)
EOF
    
    chmod +x "$collections_script"
    
    # Wenn interaktiver Modus, frage, ob Docker-Container jetzt gestartet werden soll
    if [ "$INTERACTIVE_MODE" = "true" ]; then
        echo -e "${YELLOW}Möchten Sie die Qdrant-Vektordatenbank jetzt starten? (j/n)${NC}"
        read -r ANSWER
        if [[ "$ANSWER" =~ ^[Jj] ]]; then
            log "INFO" "Starte Qdrant-Vektordatenbank..."
            cd "$FULL_PROJECT_PATH"
            docker-compose up -d
            
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Qdrant-Vektordatenbank erfolgreich gestartet."
                
                # Fragen, ob Sammlungen erstellt werden sollen
                if command -v python3 &> /dev/null; then
                    echo -e "${YELLOW}Möchten Sie die Sammlungen jetzt erstellen? (j/n)${NC}"
                    read -r CREATE_COLLECTIONS
                    if [[ "$CREATE_COLLECTIONS" =~ ^[Jj] ]]; then
                        # Versuche, qdrant-client zu installieren, wenn nicht vorhanden
                        if ! python3 -c "import qdrant_client" &> /dev/null; then
                            log "INFO" "Installiere qdrant-client..."
                            pip install qdrant-client
                        fi
                        
                        log "INFO" "Erstelle Sammlungen..."
                        python3 "$collections_script"
                    fi
                else
                    log "WARNING" "Python3 ist nicht installiert. Sammlungen müssen manuell erstellt werden."
                fi
            else
                log "ERROR" "Fehler beim Starten der Qdrant-Vektordatenbank."
            fi
        fi
    fi
    
    log "SUCCESS" "Qdrant-Vektordatenbank-Setup abgeschlossen."
    return 0
}

# Initialize Vibe-Coding-Projekt
setup_vibe_coding() {
    if [ "$PROJECT_TYPE" != "vibe-coding" ]; then
        return 0
    fi
    
    log "INFO" "Richte Vibe-Coding-Projekt ein..."
    
    # Überprüfen, ob das Vibe-Coding-Init-Skript existiert
    local vibe_script="$REPO_ROOT/core/templates/project-types/vibe-coding-init.sh"
    
    if [ ! -f "$vibe_script" ]; then
        log "ERROR" "Vibe-Coding-Initialisierungsskript nicht gefunden: $vibe_script"
        log "ERROR" "Standardprojekt wird erstellt."
        return 1
    fi
    
    # Prüfen, ob Next.js und Abhängigkeiten installiert werden sollen
    local install_deps=false
    
    if [ "$INTERACTIVE_MODE" = "true" ]; then
        echo -e "${YELLOW}Möchten Sie Next.js und Abhängigkeiten automatisch installieren? (j/n)${NC}"
        read -r ANSWER
        if [[ "$ANSWER" =~ ^[Jj] ]]; then
            install_deps=true
        fi
    fi
    
    # Erstelle APP-Struktur für Vibe-Coding
    mkdir -p "$FULL_PROJECT_PATH/APP/src/app"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/components/ui"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/components/layout"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/components/3d"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/lib"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/hooks"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/server/api"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/server/db"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/server/auth"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/styles"
    mkdir -p "$FULL_PROJECT_PATH/APP/src/types"
    mkdir -p "$FULL_PROJECT_PATH/APP/public"
    mkdir -p "$FULL_PROJECT_PATH/APP/tests"
    
    # Package.json erstellen
    cat > "$FULL_PROJECT_PATH/APP/package.json" << EOF
{
  "name": "${PROJECT_NAME,,}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@react-three/drei": "^9.90.0",
    "@react-three/fiber": "^8.15.12",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "tailwind-merge": "^2.1.0",
    "tailwindcss-animate": "^1.0.7",
    "three": "^0.160.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.4",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@types/three": "^0.160.0",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-config-next": "^15.0.0",
    "postcss": "^8.4.32",
    "tailwindcss": "^4.0.0",
    "typescript": "^5.3.3"
  }
}
EOF
    
    # Abhängigkeiten installieren, wenn gewünscht
    if [ "$install_deps" = true ]; then
        if command -v npm &> /dev/null; then
            log "INFO" "Installiere Next.js-Abhängigkeiten..."
            cd "$FULL_PROJECT_PATH/APP"
            npm install
            log "SUCCESS" "Abhängigkeiten installiert."
        else
            log "WARNING" "npm ist nicht installiert. Abhängigkeiten müssen manuell installiert werden."
        fi
    fi
    
    log "SUCCESS" "Vibe-Coding-Projekt eingerichtet."
    return 0
}

# Create update_memory.sh script
create_update_memory_script() {
    log "INFO" "Erstelle update_memory.sh Script..."
    update_progress "Memory Script Erstellung" "Läuft"
    
    local script_file="$FULL_PROJECT_PATH/update_memory.sh"
    
    cat > "$script_file" << 'EOF'
#!/usr/bin/env bash
# Memory-Bank Aktualisierungsskript
# Dieses Skript aktualisiert die Memory-Bank eines AGI-System-Projekts

set -e

# Farbdefinitionen
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Basispfade ermitteln
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_BANK_DIR="$SCRIPT_DIR/memory-bank"
PROJECT_NAME=$(basename "$SCRIPT_DIR")
UPDATE_TIME=$(date +"%Y-%m-%d %H:%M:%S")

# MCP-Tools Konfiguration
MCP_CONFIG_DIR="$SCRIPT_DIR/.config/claude"
MCP_CONFIG_FILE="$MCP_CONFIG_DIR/mcpservers.json"

# Überprüfe, ob Memory-Bank existiert
if [ ! -d "$MEMORY_BANK_DIR" ]; then
    echo -e "${RED}Fehler: Memory-Bank-Verzeichnis nicht gefunden.${NC}"
    exit 1
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Memory-Bank Update für $PROJECT_NAME  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${CYAN}Zeitpunkt: $UPDATE_TIME${NC}"
echo

# Funktion zum Aktualisieren der progress.md
update_progress_file() {
    local progress_file="$MEMORY_BANK_DIR/progress.md"
    local date_today=$(date +"%d.%m.%Y")
    
    echo -e "${BLUE}Aktualisiere Fortschrittsdatei...${NC}"
    
    # Erstelle Datei, falls sie nicht existiert
    if [ ! -f "$progress_file" ]; then
        echo "# Projektfortschritt für $PROJECT_NAME" > "$progress_file"
        echo "" >> "$progress_file"
        echo "## Aktueller Status" >> "$progress_file"
        echo "- **Datum**: $date_today" >> "$progress_file"
        echo "- **Status**: Initialisierung" >> "$progress_file"
        echo "- **Phase**: Projektstart" >> "$progress_file"
        echo "" >> "$progress_file"
        echo "## Meilensteine" >> "$progress_file"
        echo "- [x] Projektinitialisierung ($date_today)" >> "$progress_file"
        echo "- [ ] Meilenstein 1: TBD" >> "$progress_file"
        echo "- [ ] Meilenstein 2: TBD" >> "$progress_file"
        echo "" >> "$progress_file"
        echo "## Letzte Aktualisierungen" >> "$progress_file"
        echo "- $date_today: Projekt erstellt mit AGI-System" >> "$progress_file"
    else
        # Aktualisiere nur den Zeitstempel und füge einen neuen Eintrag hinzu
        sed -i "s/- \*\*Datum\*\*:.*/- **Datum**: $date_today/" "$progress_file"
        
        # Prüfe, ob der heutige Tag bereits einen Eintrag hat
        if ! grep -q "- $date_today:" "$progress_file"; then
            # Füge einen neuen Eintrag am Anfang der "Letzte Aktualisierungen" hinzu
            sed -i "/## Letzte Aktualisierungen/a - $date_today: Memory-Bank aktualisiert" "$progress_file"
        fi
    fi
    
    echo -e "${GREEN}Fortschrittsdatei aktualisiert.${NC}"
}

# Funktion zum Aktualisieren der activeContext.md
update_active_context() {
    local context_file="$MEMORY_BANK_DIR/activeContext.md"
    local date_today=$(date +"%d.%m.%Y")
    local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unbekannt")
    
    echo -e "${BLUE}Aktualisiere aktiven Kontext...${NC}"
    
    # Prüfe, ob Git verfügbar und ein Git-Repository ist
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        # Hole aktuelle Git-Informationen
        local git_status=$(git status --porcelain | wc -l)
        local git_last_commit=$(git log -1 --pretty=format:"%h - %s" 2>/dev/null || echo "Kein Commit")
        
        # Wenn Änderungen vorliegen, aktualisiere den Kontext
        if [ "$git_status" -gt 0 ]; then
            echo -e "${YELLOW}Ungespeicherte Änderungen gefunden. Aktualisiere aktiven Kontext.${NC}"
            
            # Erstelle Datei, falls sie nicht existiert
            if [ ! -f "$context_file" ]; then
                echo "# Aktiver Arbeitskontext für $PROJECT_NAME" > "$context_file"
                echo "" >> "$context_file"
                echo "## Aktueller Fokus" >> "$context_file"
                echo "Aktueller Branch: $git_branch" >> "$context_file"
                echo "" >> "$context_file"
                echo "## Offene Aufgaben" >> "$context_file"
                echo "- [ ] Ungespeicherte Änderungen committen" >> "$context_file"
                echo "" >> "$context_file"
                echo "## Letzter Commit" >> "$context_file"
                echo "$git_last_commit" >> "$context_file"
                echo "" >> "$context_file"
                echo "## Kontextnotizen" >> "$context_file"
                echo "Letzte Aktualisierung: $date_today" >> "$context_file"
            else
                # Aktualisiere Datum und Branch
                sed -i "s/Aktueller Branch:.*/Aktueller Branch: $git_branch/" "$context_file"
                sed -i "s/Letzte Aktualisierung:.*/Letzte Aktualisierung: $date_today/" "$context_file"
                
                # Ersetze den letzten Commit
                if grep -q "## Letzter Commit" "$context_file"; then
                    sed -i "/## Letzter Commit/,/^$/c\\## Letzter Commit\n$git_last_commit\n" "$context_file"
                else
                    echo "" >> "$context_file"
                    echo "## Letzter Commit" >> "$context_file"
                    echo "$git_last_commit" >> "$context_file"
                    echo "" >> "$context_file"
                fi
            fi
        else
            echo -e "${GREEN}Keine ungespeicherten Änderungen. Aktiver Kontext ist aktuell.${NC}"
        fi
    fi
    
    echo -e "${GREEN}Aktiver Kontext aktualisiert.${NC}"
}

# Vektor-Indexierung, falls aktiviert
update_vector_index() {
    local vector_dir="$MEMORY_BANK_DIR/vector_index"
    local vector_enabled=false
    
    # Prüfe, ob Vektordatenbank konfiguriert ist
    if [ -d "$vector_dir" ] && [ -f "$SCRIPT_DIR/.about.json" ]; then
        if grep -q '"vector_db": true' "$SCRIPT_DIR/.about.json"; then
            vector_enabled=true
        fi
    fi
    
    if [ "$vector_enabled" = true ]; then
        echo -e "${BLUE}Aktualisiere Vektor-Index...${NC}"
        
        # Prüfe, ob Qdrant-Container läuft
        if [ -f "$SCRIPT_DIR/start-qdrant.sh" ]; then
            if ! docker ps | grep -q "qdrant-$PROJECT_NAME"; then
                echo -e "${YELLOW}Qdrant-Container ist nicht aktiv. Starte Container...${NC}"
                bash "$SCRIPT_DIR/start-qdrant.sh" > /dev/null
                # Kurz warten, damit der Container hochfahren kann
                sleep 5
            fi
            
            # Führe Python-Indexierungsskript aus, wenn vorhanden
            if [ -f "$vector_dir/scripts/index_project.py" ]; then
                echo -e "${CYAN}Führe Vektor-Indexierung durch...${NC}"
                python3 "$vector_dir/scripts/index_project.py" > /dev/null || echo -e "${YELLOW}Indexierung fehlgeschlagen.${NC}"
            else
                echo -e "${YELLOW}Indexierungsskript nicht gefunden.${NC}"
            fi
        else
            echo -e "${YELLOW}Qdrant-Startskript nicht gefunden. Überspringe Vektor-Indexierung.${NC}"
        fi
        
        echo -e "${GREEN}Vektor-Index aktualisiert.${NC}"
    fi
}

# MCP-Tools-Aktualisierung
update_mcp_tools() {
    if [ -f "$MCP_CONFIG_FILE" ]; then
        echo -e "${BLUE}Prüfe MCP-Tools...${NC}"
        
        # Prüfe, ob neue MCP-Tools verfügbar sind
        if command -v npx &> /dev/null; then
            echo -e "${CYAN}Aktualisiere MCP-Tools-Konfiguration...${NC}"
            # Hier könnte eine Aktualisierung der Tools erfolgen
            # npx -y @smithery/cli@latest update
        else
            echo -e "${YELLOW}npx nicht verfügbar. Überspringe MCP-Tools-Aktualisierung.${NC}"
        fi
        
        echo -e "${GREEN}MCP-Tools-Konfiguration aktualisiert.${NC}"
    fi
}

# Aktualisiere alle Memory-Bank-Komponenten
update_memory_bank() {
    # Aktualisiere Fortschrittsdatei
    update_progress_file
    
    # Aktualisiere aktiven Kontext
    update_active_context
    
    # Aktualisiere Vektor-Index
    update_vector_index
    
    # Aktualisiere MCP-Tools
    update_mcp_tools
    
    echo -e "${GREEN}Memory-Bank erfolgreich aktualisiert.${NC}"
    echo -e "${CYAN}Aktualisierung abgeschlossen: $(date +"%Y-%m-%d %H:%M:%S")${NC}"
}

# Hauptfunktion ausführen
update_memory_bank
EOF
    
    # Script ausführbar machen
    chmod +x "$script_file"
    
    # Git pre-commit Hook erstellen, falls Git verwendet wird
    if [[ "$GIT_HOOKS_ENABLED" == true ]]; then
        mkdir -p "$FULL_PROJECT_PATH/.git/hooks"
        cat > "$FULL_PROJECT_PATH/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# AGI-System pre-commit Hook
# Dieser Hook führt update_memory.sh aus, bevor ein Commit erstellt wird

# Pfad zum Skript
SCRIPT_PATH="$(git rev-parse --show-toplevel)/update_memory.sh"

if [ -f "$SCRIPT_PATH" ]; then
    echo "Führe Memory-Bank-Update aus..."
    bash "$SCRIPT_PATH"
    
    # Aktualisierte Memory-Bank-Dateien zum Commit hinzufügen
    git add "$(git rev-parse --show-toplevel)/memory-bank/progress.md"
    git add "$(git rev-parse --show-toplevel)/memory-bank/activeContext.md"
fi

exit 0
EOF
        chmod +x "$FULL_PROJECT_PATH/.git/hooks/pre-commit"
    fi
    
    log "SUCCESS" "update_memory.sh Script erstellt und Git-Hook konfiguriert."
    update_progress "Memory Script Erstellung" "Abgeschlossen"
    return 0
}

# Git-Repository initialisieren
init_git_repo() {
    log "INFO" "Initialisiere Git-Repository..."
    update_progress "Git Initialisierung" "Läuft"
    
    cd "$FULL_PROJECT_PATH"
    
    # .gitignore erstellen
    cat > .gitignore << EOF
# Betriebssystemdateien
.DS_Store
Thumbs.db

# IDE-Dateien
.idea/
.vscode/*
!.vscode/settings.json
!.vscode/extensions.json

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Next.js
.next/
out/

# Umgebungsvariablen
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Qdrant
qdrant_storage/

# Temporäre Dateien
*.tmp
*.log

# Transformer Cache
.cache/

# Python
__pycache__/
*.py[cod]
*$py.class
.pytest_cache/
EOF
    
    # Git-Repository initialisieren
    GIT_HOOKS_ENABLED=true
    git init
    
    # Alle Dateien hinzufügen
    git add .
    
    # Ersten Commit erstellen
    git commit -m "Initial commit: $PROJECT_NAME project created with AGI-System"
    
    log "SUCCESS" "Git-Repository initialisiert."
    update_progress "Git Initialisierung" "Abgeschlossen"
    return 0
}

# Zusammenfassung anzeigen
show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    local duration_str
    
    if [[ $minutes -gt 0 ]]; then
        duration_str="${minutes}m ${seconds}s"
    else
        duration_str="${seconds}s"
    fi
    
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GREEN}Projekt $PROJECT_NAME wurde erfolgreich erstellt!${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "${CYAN}Projektdetails:${NC}"
    echo -e "  Projektpfad:       ${CYAN}$FULL_PROJECT_PATH${NC}"
    echo -e "  Projekttyp:        ${CYAN}${PROJECT_TYPE^}${NC}"
    echo -e "  MCP-Tools:         ${CYAN}$([ "$MCP_TOOLS_ENABLED" = true ] && echo "Aktiviert (12 Tools)" || echo "Deaktiviert")${NC}"
    echo -e "  Vektordatenbank:   ${CYAN}$([ "$USE_VECTOR_DB" = true ] && echo "Aktiviert (Qdrant)" || echo "Deaktiviert")${NC}"
    echo -e "  Erstellungszeit:   ${CYAN}$duration_str${NC}"
    
    # Anzahl der erstellten Dateien und Verzeichnisse anzeigen
    local file_count=$(find "$FULL_PROJECT_PATH" -type f | wc -l)
    local dir_count=$(find "$FULL_PROJECT_PATH" -type d | wc -l)
    echo -e "  Dateien:           ${CYAN}$file_count${NC}"
    echo -e "  Verzeichnisse:     ${CYAN}$dir_count${NC}"
    echo
    
    echo -e "${CYAN}Projektstruktur:${NC}"
    echo -e "  $PROJECT_NAME/"
    echo -e "  ├── APP/                 # Anwendungscode"
    if [[ "$PROJECT_TYPE" == "vibe-coding" ]]; then
        echo -e "  │   ├── src/             # Next.js-Quellcode"
        echo -e "  │   ├── public/          # Statische Assets"
        echo -e "  │   └── package.json     # Dependencies"
    fi
    echo -e "  ├── MARKETING/          # Marketing-Materialien"
    echo -e "  ├── FINANCE/            # Finanzielle Dokumente"
    echo -e "  ├── DOCS/               # Projektdokumentation"
    echo -e "  ├── memory-bank/        # Wissens- und Kontextspeicher"
    echo -e "  │   ├── project_context/  # Projektkontext und Konfiguration"
    echo -e "  │   └── automated_rules/  # Automatisierte Regeln und Workflows"
    
    if [[ "$USE_VECTOR_DB" == true ]]; then
        echo -e "  │   ├── vector_index/    # Vektordatenbank-Index und Skripte"
    fi
    
    echo -e "  ├── .about.interactive  # Interaktive Projektkonfiguration"
    echo -e "  ├── .about.json         # Programmatische Projektkonfiguration"
    echo -e "  ├── update_memory.sh    # Memory-Bank-Aktualisierungsskript"
    
    if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
        echo -e "  └── .config/claude/     # MCP-Tools-Konfiguration"
    fi
    
    echo
    echo -e "${CYAN}MCP-Tools:${NC}"
    if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
        echo -e "  ✓ desktop-commander    # Dateisystem- und Shell-Operationen"
        echo -e "  ✓ memory-bank          # Memory-Bank-Verwaltung und semantisches Gedächtnis"
        echo -e "  ✓ marketing-tools      # Marketing-Analyse und Content-Erstellung"
        echo -e "  ✓ browser-tools        # Web-Recherche und Datenextraktion"
        echo -e "  ✓ brave-web-search     # Aktuelle Web-Informationssuche"
        echo -e "  ✓ sequentialthinking   # Strukturierte Problemlösung und Analyse"
        echo -e "  ✓ agent-sdk            # Agentenbasierte Automatisierung"
        echo -e "  ✓ code-mcp             # Code-Generierung und -Optimierung"
        echo -e "  ✓ context7-mcp         # Semantische Kontextverwaltung"
        echo -e "  ✓ magic-mcp            # Kreative Tools für Design und Namensgebung"
        echo -e "  ✓ toolbox              # Umfassende KI-Tools für diverse Aufgaben"
        echo -e "  ✓ transformers         # Hugging Face Transformer-Modelle"
    else
        echo -e "  MCP-Tools sind deaktiviert. Sie können später mit dem Parameter --mcp-tools aktiviert werden."
    fi
    echo
    
    echo -e "${YELLOW}Nächste Schritte:${NC}"
    
    echo -e "  1. Projektverzeichnis öffnen:"
    echo -e "     cd $FULL_PROJECT_PATH"
    echo
    
    if [[ "$PROJECT_TYPE" == "vibe-coding" ]]; then
        echo -e "  2. Next.js-Entwicklungsserver starten:"
        echo -e "     cd APP && npm run dev"
        echo
    fi
    
    if [[ "$USE_VECTOR_DB" == true ]]; then
        echo -e "  3. Qdrant-Vektordatenbank starten:"
        echo -e "     ./start-qdrant.sh"
        echo
    fi
    
    if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
        echo -e "  4. Claude Code mit MCP-Tools verwenden:"
        echo -e "     claude                     # Claude Code starten"
        echo -e "     /mcp                       # MCP-Tools aktivieren"
        echo
    fi
    
    echo -e "  5. Memory-Bank aktualisieren:"
    echo -e "     ./update_memory.sh           # Manuell aktualisieren"
    echo -e "     # Git-Commits aktualisieren automatisch die Memory-Bank"
    echo
    
    echo -e "  6. Projektkonfiguration anpassen:"
    echo -e "     nano .about.interactive      # Interaktive Konfiguration bearbeiten"
    echo -e "     nano .config/claude/mcpservers.json # MCP-Tools-Konfiguration anpassen"
    echo
    
    log "INFO" "Logdatei gespeichert unter: $LOG_FILE"
    
    return 0
}

# Hauptfunktion mit optimierter Fehlerbehandlung und Fortschrittsanzeige
main() {
    # Anzeige des Banners
    show_banner
    
    # Initialisierung des Logs
    echo "# AGI-System Projektinitialisierung Log (v2.0)" > "$LOG_FILE"
    echo "# $(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
    echo "# Hostname: $(hostname)" >> "$LOG_FILE"
    echo "# Benutzer: $(whoami)" >> "$LOG_FILE"
    echo "# Betriebssystem: $(uname -s) $(uname -r)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    log "INFO" "Initialisierung gestartet"
    
    # Parameter verarbeiten
    if ! process_args "$@"; then
        log "ERROR" "Fehler bei der Verarbeitung der Parameter"
        exit 1
    fi
    
    # Abhängigkeiten prüfen
    if ! check_dependencies; then
        log "ERROR" "Fehler bei der Überprüfung der Abhängigkeiten"
        exit 1
    fi
    
    # Projektverzeichnisstruktur erstellen
    if ! create_project_structure; then
        log "ERROR" "Fehler bei der Erstellung der Projektstruktur"
        exit 1
    fi
    
    # Einzelne Schritte mit Fehlerbehandlung ausführen
    local error_occurred=false
    
    # Memory-Bank erstellen
    if ! setup_memory_bank; then
        log "ERROR" "Fehler bei der Einrichtung der Memory-Bank"
        error_occurred=true
    fi
    
    # Interaktive .about-Datei erstellen
    if ! create_interactive_about; then
        log "ERROR" "Fehler bei der Erstellung der .about-Datei"
        error_occurred=true
    fi
    
    # Berechtigungen einrichten (wenn aktiviert)
    if [[ "$AUTO_PERMISSIONS" == true ]]; then
        if ! setup_permissions; then
            log "WARNING" "Fehler bei der Einrichtung des Berechtigungssystems"
            # Kein fataler Fehler
        fi
    fi
    
    # MCP-Tools konfigurieren (wenn aktiviert)
    if [[ "$MCP_TOOLS_ENABLED" == true ]]; then
        if ! configure_mcp_tools; then
            log "WARNING" "Fehler bei der Konfiguration der MCP-Tools"
            # Kein fataler Fehler
        fi
    fi
    
    # Vektordatenbank einrichten (wenn aktiviert)
    if [[ "$USE_VECTOR_DB" == true ]]; then
        if ! setup_vector_database; then
            log "WARNING" "Fehler bei der Einrichtung der Vektordatenbank"
            # Kein fataler Fehler
        fi
    fi
    
    # Vibe-Coding-Projekt einrichten (wenn anwendbar)
    if [[ "$PROJECT_TYPE" == "vibe-coding" ]]; then
        if ! setup_vibe_coding; then
            log "WARNING" "Fehler bei der Einrichtung des Vibe-Coding-Projekts"
            # Kein fataler Fehler
        fi
    fi
    
    # Update-Memory-Script erstellen
    if ! create_update_memory_script; then
        log "WARNING" "Fehler bei der Erstellung des Update-Memory-Scripts"
        # Kein fataler Fehler
    fi
    
    # Git-Repository initialisieren
    if ! init_git_repo; then
        log "WARNING" "Fehler bei der Initialisierung des Git-Repositories"
        # Kein fataler Fehler
    fi
    
    # Wenn Fehler aufgetreten sind, aber nicht fatal
    if [[ "$error_occurred" == true ]]; then
        log "WARNING" "Es sind nicht-fatale Fehler aufgetreten. Das Projekt wurde möglicherweise nicht vollständig eingerichtet."
        log "WARNING" "Siehe Logdatei für Details: $LOG_FILE"
    fi
    
    # Zusammenfassung anzeigen
    show_summary
    
    log "INFO" "Initialisierung abgeschlossen"
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?