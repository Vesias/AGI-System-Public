#!/usr/bin/env bash
# Unit-Test für permissions-parser.sh

# Test-Informationen
TEST_NAME="Permissions-Parser Unit-Test"
TEST_DESCRIPTION="Überprüft die Grundfunktionalität des permissions-parser.sh Skripts"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    local REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    local TEST_DIR="${AGI_TEST_DIR:-/tmp/permissions-parser-test-$(date +%s)}"
    local SCRIPT_PATH="$REPO_ROOT/core/scripts/permissions-parser.sh"
    local EXIT_CODE=0
    
    # Test-Ausgabe
    echo "Teste permissions-parser.sh..."
    
    # 1. Prüfen, ob das Skript existiert
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "FEHLER: permissions-parser.sh nicht gefunden unter $SCRIPT_PATH"
        return 1
    fi
    
    # 2. Prüfen, ob das Skript ausführbar ist
    if [ ! -x "$SCRIPT_PATH" ]; then
        echo "FEHLER: permissions-parser.sh ist nicht ausführbar"
        return 1
    fi
    
    # 3. Syntax-Check
    bash -n "$SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        echo "FEHLER: permissions-parser.sh hat Syntax-Fehler"
        return 1
    fi
    
    # 4. Prüfen, ob die erforderlichen Funktionen vorhanden sind
    grep -q "function list_users" "$SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        echo "FEHLER: list_users-Funktion nicht gefunden"
        EXIT_CODE=1
    fi
    
    grep -q "function add_user" "$SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        echo "FEHLER: add_user-Funktion nicht gefunden"
        EXIT_CODE=1
    fi
    
    grep -q "function remove_user" "$SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        echo "FEHLER: remove_user-Funktion nicht gefunden"
        EXIT_CODE=1
    fi
    
    grep -q "function update_user" "$SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        echo "FEHLER: update_user-Funktion nicht gefunden"
        EXIT_CODE=1
    fi
    
    # 5. Hilfetext-Prüfung
    if ! grep -q "Verwendung:" "$SCRIPT_PATH"; then
        echo "FEHLER: Hilfetext nicht gefunden"
        EXIT_CODE=1
    fi
    
    # Alle Prüfungen bestanden?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "permissions-parser.sh Basis-Prüfungen bestanden."
    else
        echo "permissions-parser.sh Basis-Prüfungen fehlgeschlagen."
    fi
    
    return $EXIT_CODE
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?