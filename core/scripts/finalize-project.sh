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

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}  MCP-Tools-Integrator - Projektfinalisierung        ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo
}

# Nutzung anzeigen
show_usage() {
    echo "Nutzung: $(basename "$0") [OPTIONEN]"
    echo
    echo "Optionen:"
    echo "  -r, --remote URL     Git Remote URL festlegen (z.B. https://github.com/Vesias/AGI-System-Public.git)"
    echo "  -b, --branch NAME    Branch-Namen festlegen (Standard: main)"
    echo "  -m, --message TEXT   Commit-Nachricht festlegen"
    echo "  -h, --help           Diese Hilfe anzeigen"
    echo
    echo "Beispiel:"
    echo "  $(basename "$0") --remote https://github.com/Vesias/AGI-System-Public.git --message \"Finalisiere MCP-Tools-Integrator\""
    echo
}

# Git Remote URL Setup
setup_git_remote() {
    local remote_url=$1
    local branch_name=$2
    
    log "INFO" "Konfiguriere Git Remote URL..."
    
    # Prüfen, ob dies ein Git Repository ist
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        log "ERROR" "Das aktuelle Verzeichnis ist kein Git Repository."
        log "INFO" "Führen Sie 'git init' aus, um ein Repository zu erstellen."
        return 1
    fi
    
    # Remote URL festlegen
    if git remote | grep -q "^origin$"; then
        # Remote existiert bereits, URL aktualisieren
        local current_url=$(git remote get-url origin)
        log "INFO" "Remote 'origin' existiert bereits mit URL: $current_url"
        
        if [ "$current_url" != "$remote_url" ]; then
            log "INFO" "Aktualisiere Remote URL auf: $remote_url"
            git remote set-url origin "$remote_url"
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Remote URL aktualisiert."
            else
                log "ERROR" "Fehler beim Aktualisieren der Remote URL."
                return 1
            fi
        else
            log "SUCCESS" "Remote URL ist bereits korrekt konfiguriert."
        fi
    else
        # Remote existiert nicht, neu erstellen
        log "INFO" "Füge neues Remote 'origin' hinzu mit URL: $remote_url"
        git remote add origin "$remote_url"
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Remote 'origin' hinzugefügt."
        else
            log "ERROR" "Fehler beim Hinzufügen des Remote 'origin'."
            return 1
        fi
    fi
    
    # Branch prüfen und ggf. erstellen
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log "INFO" "Branch '$branch_name' existiert nicht. Erstelle ihn..."
        git checkout -b "$branch_name"
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Branch '$branch_name' erstellt und aktiviert."
        else
            log "ERROR" "Fehler beim Erstellen des Branch '$branch_name'."
            return 1
        fi
    else
        # Branch existiert, sicherstellen dass er ausgewählt ist
        local current_branch=$(git branch --show-current)
        if [ "$current_branch" != "$branch_name" ]; then
            log "INFO" "Wechsle zu Branch '$branch_name'..."
            git checkout "$branch_name"
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Zu Branch '$branch_name' gewechselt."
            else
                log "ERROR" "Fehler beim Wechseln zu Branch '$branch_name'."
                return 1
            fi
        else
            log "SUCCESS" "Bereits auf Branch '$branch_name'."
        fi
    fi
    
    return 0
}

# Git-Status prüfen
check_git_status() {
    log "INFO" "Prüfe Git-Status..."
    
    if git diff --quiet HEAD &> /dev/null; then
        log "INFO" "Keine ungespeicherten Änderungen gefunden."
        log "INFO" "Prüfe auf ungetrackte Dateien..."
        
        if [ -z "$(git ls-files --others --exclude-standard)" ]; then
            log "SUCCESS" "Keine ungetrackten Dateien gefunden."
            return 0
        else
            log "INFO" "Ungetrackte Dateien gefunden:"
            git ls-files --others --exclude-standard | sed 's/^/  /'
            return 2  # Ungetrackte Dateien vorhanden
        fi
    else
        log "INFO" "Ungespeicherte Änderungen gefunden:"
        git status -s | sed 's/^/  /'
        return 1  # Ungespeicherte Änderungen vorhanden
    fi
}

# Änderungen committen
commit_changes() {
    local commit_message=$1
    
    log "INFO" "Bereite Commit vor..."
    
    # Prüfen, ob es Änderungen gibt
    if check_git_status; then
        log "WARNING" "Keine Änderungen zum Committen verfügbar."
        return 0
    fi
    
    # Alle Änderungen zur Staging-Area hinzufügen
    log "INFO" "Füge alle Änderungen zum Commit hinzu..."
    git add .
    if [ $? -ne 0 ]; then
        log "ERROR" "Fehler beim Hinzufügen der Änderungen."
        return 1
    fi
    
    # Änderungen committen
    log "INFO" "Committe Änderungen mit Nachricht: \"$commit_message\""
    git commit -m "$commit_message"
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Änderungen erfolgreich committed."
    else
        log "ERROR" "Fehler beim Committen der Änderungen."
        return 1
    fi
    
    return 0
}

# Änderungen pushen
push_changes() {
    local branch_name=$1
    
    log "INFO" "Pushe Änderungen zum Remote-Repository..."
    
    # Prüfen, ob Remote erreichbar ist
    if ! git ls-remote --exit-code origin &> /dev/null; then
        log "ERROR" "Remote 'origin' ist nicht erreichbar."
        log "INFO" "Stellen Sie sicher, dass die URL korrekt ist und Sie Zugriff haben."
        return 1
    fi
    
    # Versuchen zu pushen
    git push -u origin "$branch_name"
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Änderungen erfolgreich gepusht."
    else
        # Fehler beim Pushen, versuchen mit force-Pushing nach Bestätigung
        log "WARNING" "Fehler beim Pushen. Es könnte ein Problem mit divergierenden Historien geben."
        
        read -p "Möchten Sie versuchen, mit '--force-with-lease' zu pushen? (j/n): " force_push
        if [[ "$force_push" =~ ^[Jj]$ ]]; then
            log "INFO" "Versuche Force-Push mit '--force-with-lease'..."
            git push --force-with-lease origin "$branch_name"
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Änderungen erfolgreich mit Force-Push gepusht."
            else
                log "ERROR" "Fehler beim Force-Push."
                return 1
            fi
        else
            # Alternative Strategie: Pull mit rebase
            log "INFO" "Versuche Pull mit Rebase-Strategie..."
            git pull --rebase origin "$branch_name"
            if [ $? -eq 0 ]; then
                log "SUCCESS" "Pull mit Rebase erfolgreich."
                log "INFO" "Versuche erneut zu pushen..."
                git push -u origin "$branch_name"
                if [ $? -eq 0 ]; then
                    log "SUCCESS" "Änderungen erfolgreich gepusht."
                else
                    log "ERROR" "Fehler beim Pushen nach Pull mit Rebase."
                    return 1
                fi
            else
                log "ERROR" "Fehler beim Pull mit Rebase."
                log "INFO" "Sie müssen die Konflikte manuell lösen und dann erneut pushen."
                return 1
            fi
        fi
    fi
    
    return 0
}

# Zusammenfassung anzeigen
show_summary() {
    echo
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}  Zusammenfassung                                   ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo
    log "SUCCESS" "Projekt erfolgreich finalisiert!"
    echo
    log "INFO" "Installation:"
    echo "  curl -sSfL https://github.com/Vesias/AGI-System-Public/raw/main/core/scripts/master-init.sh | bash -s -- --project MeinProjekt"
    echo
    log "INFO" "Nächste Schritte:"
    echo "  1. Test auf Produktionsumgebung durchführen."
    echo "  2. Claude Desktop nach Installation neu starten."
    echo "  3. Automatischen /init Prozess validieren."
    echo
    log "SUCCESS" "Das System ist vollständig einsatzbereit und alle Funktionalitäten sind konfiguriert!"
    echo
}

# Parameter parsen
parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
            -h | --help)
                show_usage
                exit 0
                ;;
            -r | --remote)
                if [ -n "$1" ]; then
                    REMOTE_URL="$1"
                    shift
                else
                    log "ERROR" "Fehlender Wert für Parameter $param"
                    show_usage
                    exit 1
                fi
                ;;
            -b | --branch)
                if [ -n "$1" ]; then
                    BRANCH_NAME="$1"
                    shift
                else
                    log "ERROR" "Fehlender Wert für Parameter $param"
                    show_usage
                    exit 1
                fi
                ;;
            -m | --message)
                if [ -n "$1" ]; then
                    COMMIT_MESSAGE="$1"
                    shift
                else
                    log "ERROR" "Fehlender Wert für Parameter $param"
                    show_usage
                    exit 1
                fi
                ;;
            *)
                log "ERROR" "Unbekannter Parameter: $param"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Hauptfunktion
main() {
    local REMOTE_URL=""
    local BRANCH_NAME="main"
    local COMMIT_MESSAGE="Finalisiere MCP-Tools-Integrator System"
    
    # Parameter parsen
    parse_params "$@"
    
    # Prüfen, ob Remote URL angegeben wurde
    if [ -z "$REMOTE_URL" ]; then
        log "ERROR" "Keine Remote URL angegeben."
        show_usage
        exit 1
    fi
    
    show_banner
    
    # Git Remote konfigurieren
    if ! setup_git_remote "$REMOTE_URL" "$BRANCH_NAME"; then
        log "ERROR" "Fehler beim Konfigurieren des Git Remote."
        exit 1
    fi
    
    # Änderungen committen
    if ! commit_changes "$COMMIT_MESSAGE"; then
        log "ERROR" "Fehler beim Committen der Änderungen."
        exit 1
    fi
    
    # Änderungen pushen
    if ! push_changes "$BRANCH_NAME"; then
        log "ERROR" "Fehler beim Pushen der Änderungen."
        exit 1
    fi
    
    # Zusammenfassung anzeigen
    show_summary
}

# Skript ausführen
main "$@"