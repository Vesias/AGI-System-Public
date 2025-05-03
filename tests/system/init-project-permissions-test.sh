#!/usr/bin/env bash
# System-Test für init-project-full.sh mit permissions-parser.sh Integration

# Test-Informationen
TEST_NAME="Init-Project mit Permissions-Parser System-Test"
TEST_DESCRIPTION="Überprüft die Integration von permissions-parser.sh in init-project-full.sh"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    local REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    local TEST_DIR="${AGI_TEST_DIR:-/tmp/init-project-permissions-test-$(date +%s)}"
    local PROJECT_NAME="TestProject-$(date +%s)"
    local EXIT_CODE=0
    
    echo "Führe System-Test für init-project-full.sh mit permissions-parser.sh Integration aus..."
    
    # Testverzeichnis erstellen
    mkdir -p "$TEST_DIR"
    
    # Script-Pfade
    local INIT_SCRIPT="$REPO_ROOT/core/scripts/init-project-full.sh"
    local PERMISSIONS_SCRIPT="$REPO_ROOT/core/scripts/permissions-parser.sh"
    
    # Prüfen, ob beide Skripte existieren
    if [ ! -f "$INIT_SCRIPT" ]; then
        echo "FEHLER: init-project-full.sh nicht gefunden"
        return 1
    fi
    
    if [ ! -f "$PERMISSIONS_SCRIPT" ]; then
        echo "FEHLER: permissions-parser.sh nicht gefunden"
        return 1
    fi
    
    # Test ausführen: Projekt mit aktivierter Auto-Permissions erstellen
    echo "Erstelle Testprojekt mit aktivierter Auto-Permissions-Option..."
    
    # Init-Script im nicht-interaktiven Modus mit Auto-Permissions ausführen
    "$INIT_SCRIPT" --directory "$TEST_DIR" --non-interactive --auto-permissions "$PROJECT_NAME"
    
    if [ $? -ne 0 ]; then
        echo "FEHLER: init-project-full.sh Ausführung fehlgeschlagen"
        return 1
    fi
    
    # Prüfen, ob das Projekt erstellt wurde
    if [ ! -d "$TEST_DIR/$PROJECT_NAME" ]; then
        echo "FEHLER: Projektverzeichnis wurde nicht erstellt"
        return 1
    fi
    
    # Prüfen, ob das Berechtigungsverzeichnis erstellt wurde
    if [ ! -d "$TEST_DIR/$PROJECT_NAME/permissions" ]; then
        echo "FEHLER: Berechtigungsverzeichnis wurde nicht erstellt"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob die access-control.json Datei erstellt wurde
    if [ ! -f "$TEST_DIR/$PROJECT_NAME/permissions/access-control.json" ]; then
        echo "FEHLER: access-control.json wurde nicht erstellt"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob permissions-parser.sh in das Projektverzeichnis kopiert wurde
    if [ ! -f "$TEST_DIR/$PROJECT_NAME/permissions/permissions-parser.sh" ]; then
        echo "FEHLER: permissions-parser.sh wurde nicht in das Projektverzeichnis kopiert"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob permissions-parser.sh ausführbar ist
    if [ ! -x "$TEST_DIR/$PROJECT_NAME/permissions/permissions-parser.sh" ]; then
        echo "FEHLER: permissions-parser.sh im Projektverzeichnis ist nicht ausführbar"
        EXIT_CODE=1
    fi
    
    # Testen, ob das Berechtigungssystem funktioniert
    if [ -f "$TEST_DIR/$PROJECT_NAME/permissions/permissions-parser.sh" ]; then
        cd "$TEST_DIR/$PROJECT_NAME"
        
        # Benutzer auflisten
        ./permissions/permissions-parser.sh list > "$TEST_DIR/permissions_list.txt"
        
        if [ $? -ne 0 ]; then
            echo "FEHLER: Ausführen von permissions-parser.sh list fehlgeschlagen"
            EXIT_CODE=1
        fi
        
        # Prüfen, ob ein Admin-Benutzer vorhanden ist
        if ! grep -q "admin" "$TEST_DIR/permissions_list.txt"; then
            echo "FEHLER: Kein Admin-Benutzer in der Ausgabe gefunden"
            EXIT_CODE=1
        fi
    fi
    
    # Prüfen, ob die Memory-Bank-Permissions-Dokumentation erstellt wurde
    if [ ! -f "$TEST_DIR/$PROJECT_NAME/memory-bank/project_context/permissions.md" ]; then
        echo "FEHLER: Memory-Bank Permissions-Dokumentation wurde nicht erstellt"
        EXIT_CODE=1
    fi
    
    # Prüfen auf README.md für das Berechtigungssystem
    if [ ! -f "$TEST_DIR/$PROJECT_NAME/permissions/README.md" ]; then
        echo "FEHLER: README.md für das Berechtigungssystem wurde nicht erstellt"
        EXIT_CODE=1
    fi
    
    # Aufräumen
    rm -rf "$TEST_DIR"
    
    # Alle Tests bestanden?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Alle System-Tests für init-project-full.sh mit permissions-parser.sh Integration bestanden."
    else
        echo "Ein oder mehrere System-Tests für init-project-full.sh mit permissions-parser.sh Integration fehlgeschlagen."
    fi
    
    return $EXIT_CODE
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?