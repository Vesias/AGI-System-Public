#!/usr/bin/env bash
# ============================================================================
# run-tests.sh
# 
# Ausführliches Test-Framework für das AGI-System
# Führt alle Tests aus und liefert detaillierte Berichte
# ============================================================================

set -e

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Globale Variablen
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEST_DIR="$REPO_ROOT/tests"
TEMP_DIR="/tmp/agi-system-tests-$(date +%s)"
LOG_DIR="${LOG_DIR:-$TEMP_DIR/logs}"
REPORT_FILE="$TEMP_DIR/test-report-$(date +%Y%m%d%H%M%S).html"
START_TIME=$(date +%s)
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Testarten
TEST_TYPES=("unit" "integration" "system")

# Optionen
VERBOSE=false
QUICK_MODE=false
SKIP_CLEANUP=false
HTML_REPORT=true

# Überschrift anzeigen
show_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  AGI-System Test Framework                 ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GRAY}$(date)${NC}"
    echo
    echo -e "Test-Verzeichnis: $TEST_DIR"
    echo -e "Temporäres Verzeichnis: $TEMP_DIR"
    echo -e "Log-Verzeichnis: $LOG_DIR"
    echo
}

# Hilfetext anzeigen
show_help() {
    echo "Verwendung: $0 [optionen]"
    echo
    echo "Optionen:"
    echo "  -h, --help       Diese Hilfe anzeigen"
    echo "  -v, --verbose    Ausführliche Ausgabe"
    echo "  -q, --quick      Schnellmodus (nur kritische Tests)"
    echo "  -s, --skip-cleanup  Temporäre Dateien nicht löschen"
    echo "  -n, --no-report  Keinen HTML-Bericht erstellen"
    echo "  -t, --test-type TYPE  Nur Tests eines bestimmten Typs ausführen (unit, integration, system)"
    echo
    echo "Beispiele:"
    echo "  $0 --verbose             # Alle Tests mit ausführlicher Ausgabe"
    echo "  $0 --quick --no-report   # Schnellmodus ohne HTML-Bericht"
    echo "  $0 --test-type unit      # Nur Unit-Tests ausführen"
    echo
}

# Ausgabefunktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Umgebung vorbereiten
prepare_environment() {
    log_info "Bereite Testumgebung vor..."
    
    # Temporäre Verzeichnisse erstellen
    mkdir -p "$TEMP_DIR"
    mkdir -p "$LOG_DIR"
    
    # Tests-Verzeichnis erstellen, falls es noch nicht existiert
    if [ ! -d "$TEST_DIR" ]; then
        mkdir -p "$TEST_DIR"
        mkdir -p "$TEST_DIR/unit"
        mkdir -p "$TEST_DIR/integration"
        mkdir -p "$TEST_DIR/system"
        
        # Beispiel-Tests erstellen
        cat > "$TEST_DIR/unit/template-test.sh" << 'EOF'
#!/usr/bin/env bash
# Unit-Test-Vorlage

# Test-Informationen
TEST_NAME="Vorlage Unit-Test"
TEST_DESCRIPTION="Beispiel für einen Unit-Test"
TEST_PRIORITY="medium"  # high, medium, low

# Test-Funktion
run_test() {
    # Zu testende Funktion oder Code
    return 0  # 0 = Erfolg, andere Werte = Fehler
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
        chmod +x "$TEST_DIR/unit/template-test.sh"
        
        cat > "$TEST_DIR/integration/template-test.sh" << 'EOF'
#!/usr/bin/env bash
# Integrations-Test-Vorlage

# Test-Informationen
TEST_NAME="Vorlage Integrations-Test"
TEST_DESCRIPTION="Beispiel für einen Integrations-Test"
TEST_PRIORITY="medium"  # high, medium, low

# Test-Funktion
run_test() {
    # Zu testende Komponenten-Integration
    return 0  # 0 = Erfolg, andere Werte = Fehler
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
        chmod +x "$TEST_DIR/integration/template-test.sh"
        
        cat > "$TEST_DIR/system/template-test.sh" << 'EOF'
#!/usr/bin/env bash
# System-Test-Vorlage

# Test-Informationen
TEST_NAME="Vorlage System-Test"
TEST_DESCRIPTION="Beispiel für einen System-Test"
TEST_PRIORITY="medium"  # high, medium, low

# Test-Funktion
run_test() {
    # Zu testendes Gesamtsystem oder Teilsystem
    return 0  # 0 = Erfolg, andere Werte = Fehler
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
        chmod +x "$TEST_DIR/system/template-test.sh"
        
        log_warning "Test-Verzeichnis wurde neu erstellt. Vorlagen für Tests wurden hinzugefügt."
    fi
    
    log_success "Testumgebung bereit."
}

# Test-Runner für einen einzelnen Test
run_single_test() {
    local test_file="$1"
    local test_type="$2"
    local test_name
    local test_description
    local test_priority
    local result=0
    local log_file="$LOG_DIR/$(basename "$test_file").log"
    
    # Test-Informationen aus Datei extrahieren
    test_name=$(grep -o 'TEST_NAME="[^"]*"' "$test_file" | cut -d'"' -f2)
    test_description=$(grep -o 'TEST_DESCRIPTION="[^"]*"' "$test_file" | cut -d'"' -f2)
    test_priority=$(grep -o 'TEST_PRIORITY="[^"]*"' "$test_file" | cut -d'"' -f2)
    
    # Im Schnellmodus Tests mit niedriger Priorität überspringen
    if [ "$QUICK_MODE" = true ] && [ "$test_priority" = "low" ]; then
        TESTS_SKIPPED=$((TESTS_SKIPPED+1))
        if [ "$VERBOSE" = true ]; then
            log_warning "Test übersprungen (niedrige Priorität): $test_name"
        fi
        return 0
    fi
    
    TESTS_TOTAL=$((TESTS_TOTAL+1))
    
    if [ "$VERBOSE" = true ]; then
        echo
        log_info "Führe Test aus: $test_name"
        log_info "Typ: $test_type, Priorität: $test_priority"
        log_info "Beschreibung: $test_description"
    else
        echo -ne "Test: ${CYAN}$test_name${NC}... "
    fi
    
    # Test in Subshell ausführen und Ausgabe in Logdatei speichern
    (
        # Umgebungsvariablen für den Test setzen
        export AGI_TEST=true
        export AGI_TEST_DIR="$TEMP_DIR"
        export AGI_REPO_ROOT="$REPO_ROOT"
        
        # Test ausführen
        "$test_file"
    ) > "$log_file" 2>&1
    
    result=$?
    
    # Ergebnis auswerten
    if [ $result -eq 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED+1))
        if [ "$VERBOSE" = true ]; then
            log_success "Test bestanden: $test_name"
        else
            echo -e "${GREEN}Bestanden${NC}"
        fi
    else
        TESTS_FAILED=$((TESTS_FAILED+1))
        if [ "$VERBOSE" = true ]; then
            log_error "Test fehlgeschlagen: $test_name"
            echo -e "${RED}Fehlerdetails:${NC}"
            cat "$log_file"
        else
            echo -e "${RED}Fehlgeschlagen${NC}"
        fi
    fi
    
    return $result
}

# Tests eines bestimmten Typs ausführen
run_tests_by_type() {
    local test_type="$1"
    local test_dir="$TEST_DIR/$test_type"
    local tests_found=0
    
    # Prüfen, ob Verzeichnis existiert
    if [ ! -d "$test_dir" ]; then
        log_warning "Keine $test_type-Tests gefunden. Verzeichnis $test_dir existiert nicht."
        return 0
    fi
    
    # Zählen, wie viele Tests gefunden wurden
    tests_found=$(find "$test_dir" -name "*.sh" -type f -executable | wc -l)
    
    if [ $tests_found -eq 0 ]; then
        log_warning "Keine ausführbaren $test_type-Tests in $test_dir gefunden."
        return 0
    fi
    
    log_info "Führe $tests_found $test_type-Tests aus..."
    
    # Tests ausführen
    find "$test_dir" -name "*.sh" -type f -executable | sort | while read -r test_file; do
        run_single_test "$test_file" "$test_type"
    done
    
    return 0
}

# Alle Tests ausführen
run_all_tests() {
    log_info "Starte Tests..."
    
    local selected_types=("${TEST_TYPES[@]}")
    
    # Wenn ein bestimmter Test-Typ ausgewählt wurde, nur diesen ausführen
    if [ -n "$SELECTED_TYPE" ]; then
        if [[ " ${TEST_TYPES[*]} " =~ " ${SELECTED_TYPE} " ]]; then
            selected_types=("$SELECTED_TYPE")
        else
            log_error "Ungültiger Test-Typ: $SELECTED_TYPE"
            log_info "Gültige Typen: ${TEST_TYPES[*]}"
            exit 1
        fi
    fi
    
    # Tests nach Typ ausführen
    for test_type in "${selected_types[@]}"; do
        echo -e "${BLUE}=============================================${NC}"
        echo -e "${BLUE}  $test_type-Tests                           ${NC}"
        echo -e "${BLUE}=============================================${NC}"
        
        run_tests_by_type "$test_type"
    done
    
    return 0
}

# HTML-Bericht erstellen
generate_html_report() {
    if [ "$HTML_REPORT" = false ]; then
        return 0
    fi
    
    log_info "Erstelle HTML-Bericht..."
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    local duration_str
    
    if [ $minutes -gt 0 ]; then
        duration_str="${minutes}m ${seconds}s"
    else
        duration_str="${seconds}s"
    fi
    
    # HTML-Bericht erstellen
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AGI-System Test-Bericht</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 5px 5px 0 0;
        }
        header h1 {
            margin: 0;
        }
        .summary {
            display: flex;
            justify-content: space-between;
            padding: 20px;
            background-color: #f5f5f5;
            border-radius: 0 0 5px 5px;
            margin-bottom: 20px;
        }
        .summary-item {
            text-align: center;
            padding: 10px;
        }
        .summary-item .count {
            font-size: 24px;
            font-weight: bold;
        }
        .success { color: #27ae60; }
        .warning { color: #f39c12; }
        .danger { color: #c0392b; }
        .info { color: #2980b9; }
        .test-details {
            margin-top: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #2c3e50;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .footer {
            margin-top: 20px;
            text-align: center;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>AGI-System Test-Bericht</h1>
            <p>Erstellt am $(date '+%d.%m.%Y um %H:%M:%S')</p>
        </header>
        
        <div class="summary">
            <div class="summary-item">
                <div class="count info">$TESTS_TOTAL</div>
                <div>Gesamttests</div>
            </div>
            <div class="summary-item">
                <div class="count success">$TESTS_PASSED</div>
                <div>Bestanden</div>
            </div>
            <div class="summary-item">
                <div class="count danger">$TESTS_FAILED</div>
                <div>Fehlgeschlagen</div>
            </div>
            <div class="summary-item">
                <div class="count warning">$TESTS_SKIPPED</div>
                <div>Übersprungen</div>
            </div>
            <div class="summary-item">
                <div class="count">$duration_str</div>
                <div>Testdauer</div>
            </div>
        </div>
        
        <div class="test-details">
            <h2>Detaillierte Testergebnisse</h2>
            
            <table>
                <thead>
                    <tr>
                        <th>Test-Name</th>
                        <th>Typ</th>
                        <th>Priorität</th>
                        <th>Ergebnis</th>
                    </tr>
                </thead>
                <tbody>
EOF
    
    # Testergebnisse sammeln
    for test_type in "${TEST_TYPES[@]}"; do
        local test_dir="$TEST_DIR/$test_type"
        
        if [ ! -d "$test_dir" ]; then
            continue
        fi
        
        find "$test_dir" -name "*.sh" -type f -executable | sort | while read -r test_file; do
            local test_name
            local test_priority
            local log_file="$LOG_DIR/$(basename "$test_file").log"
            local result_class
            local result_text
            
            # Test-Informationen extrahieren
            test_name=$(grep -o 'TEST_NAME="[^"]*"' "$test_file" | cut -d'"' -f2)
            test_priority=$(grep -o 'TEST_PRIORITY="[^"]*"' "$test_file" | cut -d'"' -f2)
            
            # Ergebnis bestimmen
            if [ -f "$log_file" ]; then
                if grep -q "exit status: 0" "$log_file" 2>/dev/null; then
                    result_class="success"
                    result_text="Bestanden"
                else
                    result_class="danger"
                    result_text="Fehlgeschlagen"
                fi
            else
                result_class="warning"
                result_text="Übersprungen"
            fi
            
            # In HTML-Tabelle einfügen
            cat >> "$REPORT_FILE" << EOF
                    <tr>
                        <td>$test_name</td>
                        <td>$test_type</td>
                        <td>$test_priority</td>
                        <td class="$result_class">$result_text</td>
                    </tr>
EOF
        done
    done
    
    # HTML-Bericht abschließen
    cat >> "$REPORT_FILE" << EOF
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>AGI-System Test Framework © $(date +%Y)</p>
        </div>
    </div>
</body>
</html>
EOF
    
    log_success "HTML-Bericht erstellt: $REPORT_FILE"
    
    # Bericht im Browser öffnen (optional)
    if command -v xdg-open &>/dev/null; then
        xdg-open "$REPORT_FILE" &>/dev/null
    fi
    
    return 0
}

# Aufräumen
cleanup() {
    if [ "$SKIP_CLEANUP" = true ]; then
        log_info "Aufräumen übersprungen. Temporäre Dateien bleiben erhalten: $TEMP_DIR"
        return 0
    fi
    
    log_info "Räume auf..."
    
    # Temporäre Dateien löschen, aber Bericht und Logs behalten
    find "$TEMP_DIR" -type f -not -path "$LOG_DIR/*" -not -path "$REPORT_FILE" -delete
    
    log_success "Aufräumen abgeschlossen."
    
    return 0
}

# Zusammenfassung anzeigen
show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Testzusammenfassung                       ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "Gesamttests:    ${CYAN}$TESTS_TOTAL${NC}"
    echo -e "Bestanden:      ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Fehlgeschlagen: ${RED}$TESTS_FAILED${NC}"
    echo -e "Übersprungen:   ${YELLOW}$TESTS_SKIPPED${NC}"
    echo
    
    if [ $minutes -gt 0 ]; then
        echo -e "Testdauer:      ${CYAN}${minutes}m ${seconds}s${NC}"
    else
        echo -e "Testdauer:      ${CYAN}${seconds}s${NC}"
    fi
    
    if [ "$HTML_REPORT" = true ]; then
        echo -e "Bericht:        ${CYAN}$REPORT_FILE${NC}"
    fi
    
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "Alle Tests bestanden!"
        EXIT_CODE=0
    else
        log_error "$TESTS_FAILED Tests fehlgeschlagen."
        EXIT_CODE=1
    fi
    
    return $EXIT_CODE
}

# Kommandozeilenargumente verarbeiten
process_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -q|--quick)
                QUICK_MODE=true
                ;;
            -s|--skip-cleanup)
                SKIP_CLEANUP=true
                ;;
            -n|--no-report)
                HTML_REPORT=false
                ;;
            -t|--test-type)
                shift
                SELECTED_TYPE="$1"
                ;;
            *)
                log_error "Unbekannte Option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# Standardtests erstellen, falls keine vorhanden sind
create_standard_tests() {
    # Unit-Tests
    mkdir -p "$TEST_DIR/unit"
    
    # Setup-Script Test
    cat > "$TEST_DIR/unit/setup-script-test.sh" << 'EOF'
#!/usr/bin/env bash
# Test der Setup-Skripts

# Test-Informationen
TEST_NAME="Setup-Skript Test"
TEST_DESCRIPTION="Überprüft die Grundfunktionalität der Setup-Skripte"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    
    # Prüfen, ob Setup-Skript existiert
    if [ ! -f "$REPO_ROOT/core/scripts/setup.sh" ]; then
        echo "FEHLER: Setup-Skript nicht gefunden"
        return 1
    fi
    
    # Prüfen, ob Setup-Skript ausführbar ist
    if [ ! -x "$REPO_ROOT/core/scripts/setup.sh" ]; then
        echo "FEHLER: Setup-Skript ist nicht ausführbar"
        return 1
    fi
    
    # Prüfen, ob das optimierte Setup-Skript existiert
    if [ ! -f "$REPO_ROOT/core/scripts/setup-optimized.sh" ]; then
        echo "FEHLER: Optimiertes Setup-Skript nicht gefunden"
        return 1
    fi
    
    # Prüfen, ob das optimierte Setup-Skript ausführbar ist
    if [ ! -x "$REPO_ROOT/core/scripts/setup-optimized.sh" ]; then
        echo "FEHLER: Optimiertes Setup-Skript ist nicht ausführbar"
        return 1
    }
    
    # Syntax-Check für Setup-Skript
    bash -n "$REPO_ROOT/core/scripts/setup.sh"
    if [ $? -ne 0 ]; then
        echo "FEHLER: Setup-Skript hat Syntax-Fehler"
        return 1
    fi
    
    # Syntax-Check für optimiertes Setup-Skript
    bash -n "$REPO_ROOT/core/scripts/setup-optimized.sh"
    if [ $? -ne 0 ]; then
        echo "FEHLER: Optimiertes Setup-Skript hat Syntax-Fehler"
        return 1
    fi
    
    return 0
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
    chmod +x "$TEST_DIR/unit/setup-script-test.sh"
    
    # Struktur-Test
    cat > "$TEST_DIR/unit/structure-test.sh" << 'EOF'
#!/usr/bin/env bash
# Test der Verzeichnisstruktur

# Test-Informationen
TEST_NAME="Verzeichnisstruktur Test"
TEST_DESCRIPTION="Überprüft die Grundstruktur des AGI-Systems"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    
    # Prüfen, ob wichtige Verzeichnisse existieren
    for dir in "core" "docs" "permissions"; do
        if [ ! -d "$REPO_ROOT/$dir" ]; then
            echo "FEHLER: Verzeichnis $dir nicht gefunden"
            return 1
        fi
    done
    
    # Prüfen, ob wichtige Unterverzeichnisse existieren
    for dir in "config" "scripts" "templates"; do
        if [ ! -d "$REPO_ROOT/core/$dir" ]; then
            echo "FEHLER: Verzeichnis core/$dir nicht gefunden"
            return 1
        fi
    done
    
    # Prüfen, ob wichtige Dateien existieren
    for file in "README.md" "SECURITY.md"; do
        if [ ! -f "$REPO_ROOT/$file" ]; then
            echo "FEHLER: Datei $file nicht gefunden"
            return 1
        fi
    done
    
    return 0
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
    chmod +x "$TEST_DIR/unit/structure-test.sh"
    
    # Dokumentations-Test
    cat > "$TEST_DIR/unit/documentation-test.sh" << 'EOF'
#!/usr/bin/env bash
# Test der Dokumentation

# Test-Informationen
TEST_NAME="Dokumentations-Test"
TEST_DESCRIPTION="Überprüft die Vollständigkeit der Dokumentation"
TEST_PRIORITY="medium"

# Test-Funktion
run_test() {
    REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    
    # Prüfen, ob wichtige Dokumentationsdateien existieren
    essential_docs=(
        "README.md"
        "SECURITY.md"
        "docs/README.md"
        "docs/GETTING_STARTED.md"
        "docs/MEMORY_BANK_GUIDE.md"
        "docs/MCP_TOOLS_GUIDE.md"
        "docs/CLAUDE_CODE_INTEGRATION.md"
        "docs/ONBOARDING_GUIDE.md"
    )
    
    for doc in "${essential_docs[@]}"; do
        if [ ! -f "$REPO_ROOT/$doc" ]; then
            echo "FEHLER: Dokumentationsdatei $doc nicht gefunden"
            return 1
        fi
    done
    
    return 0
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
    chmod +x "$TEST_DIR/unit/documentation-test.sh"
    
    # Integrationstest für Claude Code
    mkdir -p "$TEST_DIR/integration"
    cat > "$TEST_DIR/integration/claude-code-integration-test.sh" << 'EOF'
#!/usr/bin/env bash
# Test der Claude Code Integration

# Test-Informationen
TEST_NAME="Claude Code Integration Test"
TEST_DESCRIPTION="Überprüft die Integration von Claude Code mit dem AGI-System"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    
    # Prüfen, ob Claude Code Setup-Skript existiert
    if [ ! -f "$REPO_ROOT/core/scripts/setup-claude-code.sh" ]; then
        echo "FEHLER: Claude Code Setup-Skript nicht gefunden"
        return 1
    fi
    
    # Prüfen, ob Claude Code Setup-Skript ausführbar ist
    if [ ! -x "$REPO_ROOT/core/scripts/setup-claude-code.sh" ]; then
        echo "FEHLER: Claude Code Setup-Skript ist nicht ausführbar"
        return 1
    fi
    
    # Syntax-Check für Claude Code Setup-Skript
    bash -n "$REPO_ROOT/core/scripts/setup-claude-code.sh"
    if [ $? -ne 0 ]; then
        echo "FEHLER: Claude Code Setup-Skript hat Syntax-Fehler"
        return 1
    fi
    
    # Prüfen, ob Claude Code Dokumentation existiert
    if [ ! -f "$REPO_ROOT/docs/CLAUDE_CODE_INTEGRATION.md" ]; then
        echo "FEHLER: Claude Code Dokumentation nicht gefunden"
        return 1
    fi
    
    return 0
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
    chmod +x "$TEST_DIR/integration/claude-code-integration-test.sh"
    
    # Systemtest für End-to-End-Installation
    mkdir -p "$TEST_DIR/system"
    cat > "$TEST_DIR/system/installation-test.sh" << 'EOF'
#!/usr/bin/env bash
# End-to-End-Installationstest

# Test-Informationen
TEST_NAME="End-to-End Installation Test"
TEST_DESCRIPTION="Überprüft den vollständigen Installationsprozess"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    TEST_DIR="${AGI_TEST_DIR:-/tmp/agi-system-e2e-test-$(date +%s)}"
    
    # Temporäres Testverzeichnis erstellen
    mkdir -p "$TEST_DIR"
    
    # Repository in Testverzeichnis kopieren
    cp -r "$REPO_ROOT" "$TEST_DIR/AGI-System-Public"
    
    # In Testmodus ausführen (ohne Benutzerinteraktion)
    export TEST_MODE=true
    
    # Installationsskript ausführen
    "$TEST_DIR/AGI-System-Public/core/scripts/setup-optimized.sh"
    result=$?
    
    # Aufräumen
    rm -rf "$TEST_DIR"
    
    return $result
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
EOF
    chmod +x "$TEST_DIR/system/installation-test.sh"
}

# Hauptfunktion
main() {
    # Kommandozeilenargumente verarbeiten
    process_args "$@"
    
    # Kopf anzeigen
    show_header
    
    # Umgebung vorbereiten
    prepare_environment
    
    # Standardtests erstellen, falls keine vorhanden sind
    create_standard_tests
    
    # Tests ausführen
    run_all_tests
    
    # HTML-Bericht erstellen
    generate_html_report
    
    # Zusammenfassung anzeigen
    show_summary
    EXIT_CODE=$?
    
    # Aufräumen
    cleanup
    
    return $EXIT_CODE
}

# Hauptfunktion aufrufen
main "$@"
exit $?