#!/usr/bin/env bash

# ============================================================================
# test-installation.sh
# 
# Dieses Skript testet alle Komponenten des AGI-Systems auf ordnungsgemäße
# Installation und Konfiguration. Es identifiziert und berichtet Probleme
# und stellt sicher, dass alle Komponenten korrekt funktionieren.
# ============================================================================

set -e

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Skript-Verzeichnis ermitteln
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AGI_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Temporäres Testverzeichnis
TEST_DIR="/tmp/agi-system-test-$(date +%s)"

# Zähler für Tests
PASSED=0
FAILED=0
WARNINGS=0

# Banner anzeigen
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  AGI-System Installations-Test             ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "Datum: $(date)"
echo -e "AGI-System-Pfad: ${AGI_ROOT}"
echo -e "Test-Verzeichnis: ${TEST_DIR}"
echo ""

# Funktion für bestandene Tests
pass_test() {
    echo -e "${GREEN}[✓] PASS:${NC} $1"
    PASSED=$((PASSED+1))
}

# Funktion für fehlgeschlagene Tests
fail_test() {
    echo -e "${RED}[✗] FAIL:${NC} $1"
    echo -e "     ${RED}$2${NC}"
    FAILED=$((FAILED+1))
}

# Funktion für Warnungen
warn_test() {
    echo -e "${YELLOW}[!] WARN:${NC} $1"
    echo -e "     ${YELLOW}$2${NC}"
    WARNINGS=$((WARNINGS+1))
}

# Funktion zum Testen eines Befehls
test_command() {
    local cmd="$1"
    local name="$2"
    
    echo -e "${BLUE}[TEST]${NC} Überprüfe $name..."
    
    if command -v $cmd &> /dev/null; then
        pass_test "$name ist installiert."
    else
        fail_test "$name ist nicht installiert." "Bitte installiere $name, um volles Funktionalität zu gewährleisten."
    fi
}

# Funktion zum Testen einer Datei
test_file_exists() {
    local file="$1"
    local name="$2"
    local required="$3"
    
    echo -e "${BLUE}[TEST]${NC} Überprüfe $name..."
    
    if [ -f "$file" ]; then
        pass_test "$name existiert."
    else
        if [ "$required" = "true" ]; then
            fail_test "$name fehlt." "Die Datei $file wurde nicht gefunden."
        else
            warn_test "$name fehlt." "Die Datei $file wurde nicht gefunden, ist aber optional."
        fi
    fi
}

# Funktion zum Testen eines Verzeichnisses
test_dir_exists() {
    local dir="$1"
    local name="$2"
    local required="$3"
    
    echo -e "${BLUE}[TEST]${NC} Überprüfe $name..."
    
    if [ -d "$dir" ]; then
        pass_test "$name existiert."
    else
        if [ "$required" = "true" ]; then
            fail_test "$name fehlt." "Das Verzeichnis $dir wurde nicht gefunden."
        else
            warn_test "$name fehlt." "Das Verzeichnis $dir wurde nicht gefunden, ist aber optional."
        fi
    fi
}

# Funktion zum Testen eines Skripts
test_script_executable() {
    local script="$1"
    local name="$2"
    
    echo -e "${BLUE}[TEST]${NC} Überprüfe Ausführbarkeit von $name..."
    
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            pass_test "$name ist ausführbar."
        else
            fail_test "$name ist nicht ausführbar." "Bitte Berechtigungen anpassen mit: chmod +x $script"
        fi
    else
        fail_test "$name existiert nicht." "Die Datei $script wurde nicht gefunden."
    fi
}

# Testen der Abhängigkeiten
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Systemabhängigkeiten                      ${NC}"
echo -e "${BLUE}=============================================${NC}"

test_command "git" "Git"
test_command "node" "Node.js"
test_command "npm" "NPM"

# Optional: Git-Crypt
if command -v git-crypt &> /dev/null; then
    pass_test "Git-Crypt ist installiert."
else
    warn_test "Git-Crypt ist nicht installiert." "Git-Crypt wird für verschlüsselte Inhalte benötigt, ist aber für die Basisfunktionalität optional."
fi

# Testen der Core-Verzeichnisse
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Core-Verzeichnisstruktur                  ${NC}"
echo -e "${BLUE}=============================================${NC}"

test_dir_exists "$AGI_ROOT/core" "Core-Verzeichnis" "true"
test_dir_exists "$AGI_ROOT/core/config" "Konfigurations-Verzeichnis" "true"
test_dir_exists "$AGI_ROOT/core/scripts" "Skript-Verzeichnis" "true"
test_dir_exists "$AGI_ROOT/core/templates" "Vorlagen-Verzeichnis" "true"
test_dir_exists "$AGI_ROOT/docs" "Dokumentations-Verzeichnis" "true"
test_dir_exists "$AGI_ROOT/permissions" "Berechtigungs-Verzeichnis" "true"

# Testen der Haupt-Skripte
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Haupt-Skripte                             ${NC}"
echo -e "${BLUE}=============================================${NC}"

test_script_executable "$AGI_ROOT/core/scripts/setup.sh" "Setup-Skript"
test_script_executable "$AGI_ROOT/core/scripts/setup-full.sh" "Vollständiges Setup-Skript"
test_script_executable "$AGI_ROOT/core/scripts/permissions-check.sh" "Berechtigungsprüfungs-Skript"
test_script_executable "$AGI_ROOT/core/scripts/permissions-manage.sh" "Berechtigungsverwaltungs-Skript"
test_script_executable "$AGI_ROOT/core/scripts/setup-claude-code.sh" "Claude Code Setup-Skript"

# Testen der Konfigurationsdateien
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Konfigurationsdateien                     ${NC}"
echo -e "${BLUE}=============================================${NC}"

test_file_exists "$AGI_ROOT/core/config/base-config.json" "Basis-Konfiguration" "true"
test_file_exists "$AGI_ROOT/core/config/mcp-template.json" "MCP-Vorlagen-Konfiguration" "true"
test_file_exists "$AGI_ROOT/permissions/access-control.json" "Zugriffssteuerungskonfiguration" "true"

# Testen der Vorlagen
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Vorlagen                                  ${NC}"
echo -e "${BLUE}=============================================${NC}"

test_dir_exists "$AGI_ROOT/core/templates/memory-bank-structure" "Memory-Bank-Struktur" "true"
test_dir_exists "$AGI_ROOT/core/templates/project-templates" "Projekt-Vorlagen" "true"
test_dir_exists "$AGI_ROOT/core/templates/project-types" "Projekt-Typen" "true"

# Testen der Dokumentation
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Dokumentation                             ${NC}"
echo -e "${BLUE}=============================================${NC}"

test_file_exists "$AGI_ROOT/README.md" "Haupt-README" "true"
test_file_exists "$AGI_ROOT/SECURITY.md" "Sicherheitsdokumentation" "true"
test_file_exists "$AGI_ROOT/docs/GETTING_STARTED.md" "Erste-Schritte-Dokumentation" "true"
test_file_exists "$AGI_ROOT/docs/MEMORY_BANK_GUIDE.md" "Memory-Bank-Anleitung" "true"
test_file_exists "$AGI_ROOT/docs/MCP_TOOLS_GUIDE.md" "MCP-Tools-Anleitung" "true"
test_file_exists "$AGI_ROOT/docs/VIBE_CODING_GUIDE.md" "Vibe-Coding-Anleitung" "true"
test_file_exists "$AGI_ROOT/docs/CLAUDE_CODE_INTEGRATION.md" "Claude-Code-Integration" "true"

# Funktionaler Test: Erstellen eines Test-Projekts
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Funktionaler Test: Projekterstellung       ${NC}"
echo -e "${BLUE}=============================================${NC}"

echo -e "${BLUE}[TEST]${NC} Erstelle Test-Verzeichnis: ${TEST_DIR}..."
mkdir -p "$TEST_DIR"

if [ -d "$TEST_DIR" ]; then
    pass_test "Test-Verzeichnis erstellt."
    
    # Kopiere nur essenzielle Dateien für den Test
    echo -e "${BLUE}[TEST]${NC} Kopiere AGI-System für Test..."
    cp -r "$AGI_ROOT" "$TEST_DIR/AGI-System-Public"
    
    if [ -d "$TEST_DIR/AGI-System-Public" ]; then
        pass_test "AGI-System für Test kopiert."
        
        # Ausführen des Setup-Skripts im Test-Modus
        echo -e "${BLUE}[TEST]${NC} Führe Setup-Skript im Test-Modus aus..."
        if TEST_MODE=true "$TEST_DIR/AGI-System-Public/core/scripts/setup.sh" > /dev/null 2>&1; then
            pass_test "Setup-Skript erfolgreich ausgeführt."
        else
            fail_test "Setup-Skript fehlgeschlagen." "Das Setup-Skript konnte nicht ausgeführt werden oder gab einen Fehler zurück."
        fi
        
        # Prüfen, ob Benutzerverzeichnisse erstellt wurden
        if [ -d "$HOME/.claude" ] || [ -L "$HOME/.claude" ]; then
            pass_test "Claude Verzeichnis existiert oder wurde erstellt."
        else
            fail_test "Claude Verzeichnis wurde nicht erstellt." "Das Verzeichnis $HOME/.claude fehlt."
        fi
        
        # Bereinigen des Test-Verzeichnisses
        echo -e "${BLUE}[TEST]${NC} Bereinige Test-Verzeichnis..."
        rm -rf "$TEST_DIR"
        pass_test "Test-Verzeichnis bereinigt."
    else
        fail_test "AGI-System konnte nicht für Test kopiert werden." "Fehler beim Kopieren nach $TEST_DIR/AGI-System-Public."
    fi
else
    fail_test "Test-Verzeichnis konnte nicht erstellt werden." "Fehler beim Erstellen von $TEST_DIR."
fi

# Testen der Claude Code Integration
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Claude Code Integration                    ${NC}"
echo -e "${BLUE}=============================================${NC}"

# Prüfe Claude Code Installation (optional)
if command -v claude &> /dev/null; then
    pass_test "Claude Code CLI ist installiert."
    
    # Prüfe Claude Konfigurationsverzeichnis
    if [ -d "$HOME/.config/Claude" ]; then
        pass_test "Claude Konfigurationsverzeichnis existiert."
        
        # Prüfe AGI_SYSTEM_REFERENCE.md Datei
        if [ -f "$HOME/.config/Claude/AGI_SYSTEM_REFERENCE.md" ]; then
            pass_test "AGI System Referenz in Claude Konfiguration gefunden."
        else
            warn_test "AGI System Referenz fehlt in Claude Konfiguration." "Die Datei $HOME/.config/Claude/AGI_SYSTEM_REFERENCE.md wurde nicht gefunden."
        fi
    else
        warn_test "Claude Konfigurationsverzeichnis fehlt." "Das Verzeichnis $HOME/.config/Claude fehlt."
    fi
else
    warn_test "Claude Code CLI ist nicht installiert." "Claude Code ist für erweiterte Funktionalität empfohlen, aber optional."
fi

# Zusammenfassung ausgeben
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Zusammenfassung                           ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "Tests durchgeführt: $((PASSED + FAILED + WARNINGS))"
echo -e "${GREEN}Tests bestanden:${NC} $PASSED"
echo -e "${RED}Tests fehlgeschlagen:${NC} $FAILED"
echo -e "${YELLOW}Warnungen:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}Alle Tests erfolgreich bestanden! Das AGI-System ist korrekt installiert.${NC}"
        exit 0
    else
        echo -e "${YELLOW}Tests mit Warnungen bestanden. Das AGI-System ist grundsätzlich funktionsfähig, aber einige optionale Komponenten fehlen.${NC}"
        exit 0
    fi
else
    echo -e "${RED}Einige Tests sind fehlgeschlagen. Bitte beheben Sie die Probleme, um die volle Funktionalität zu gewährleisten.${NC}"
    exit 1
fi