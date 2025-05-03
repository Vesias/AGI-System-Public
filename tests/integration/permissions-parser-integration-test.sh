#!/usr/bin/env bash
# Integrations-Test für permissions-parser.sh

# Test-Informationen
TEST_NAME="Permissions-Parser Integration Test"
TEST_DESCRIPTION="Überprüft die Integration und Funktionalität des permissions-parser.sh Skripts"
TEST_PRIORITY="high"

# Test-Funktion
run_test() {
    local REPO_ROOT="${AGI_REPO_ROOT:-$(dirname $(dirname $(dirname $0)))}"
    local TEST_DIR="${AGI_TEST_DIR:-/tmp/permissions-parser-int-test-$(date +%s)}"
    local SCRIPT_PATH="$REPO_ROOT/core/scripts/permissions-parser.sh"
    local EXIT_CODE=0
    
    # Test-Ausgabe
    echo "Führe Integrations-Test für permissions-parser.sh aus..."
    
    # Testverzeichnis erstellen
    mkdir -p "$TEST_DIR/permissions"
    
    # Test-JSON-Datei erstellen
    cat > "$TEST_DIR/permissions/access-control.json" << 'EOF'
{
  "repository": "Test-Repo",
  "owner": "testuser",
  "permissions": {
    "admin": [
      {
        "username": "admin1",
        "email": "admin1@example.com",
        "gpg_key_id": "admin_key",
        "granted_on": "2025-05-03",
        "access_level": "full"
      }
    ],
    "contributors": [
      {
        "username": "contrib1",
        "email": "contrib1@example.com",
        "gpg_key_id": "contrib_key",
        "granted_on": "2025-05-03",
        "access_level": "contributor"
      }
    ],
    "viewers": [
      {
        "username": "viewer1",
        "email": "viewer1@example.com",
        "gpg_key_id": "",
        "granted_on": "2025-05-03",
        "access_level": "viewer"
      }
    ]
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
    
    # Skript ins Testverzeichnis kopieren
    cp "$SCRIPT_PATH" "$TEST_DIR/permissions/"
    chmod +x "$TEST_DIR/permissions/permissions-parser.sh"
    
    # Ins Testverzeichnis wechseln
    cd "$TEST_DIR"
    
    # Test 1: list_users Funktion testen
    echo "Test 1: Benutzer auflisten"
    ./permissions/permissions-parser.sh list > "$TEST_DIR/list_output.txt"
    if [ $? -ne 0 ]; then
        echo "FEHLER: list Befehl fehlgeschlagen"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob alle Benutzer aufgelistet wurden
    if ! grep -q "admin1" "$TEST_DIR/list_output.txt" || \
       ! grep -q "contrib1" "$TEST_DIR/list_output.txt" || \
       ! grep -q "viewer1" "$TEST_DIR/list_output.txt"; then
        echo "FEHLER: Nicht alle Benutzer wurden aufgelistet"
        EXIT_CODE=1
    fi
    
    # Test 2: add_user Funktion testen
    echo "Test 2: Benutzer hinzufügen"
    ./permissions/permissions-parser.sh add "admin" "neuerAdmin" "neueradmin@example.com"
    if [ $? -ne 0 ]; then
        echo "FEHLER: add Befehl fehlgeschlagen"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob der neue Benutzer hinzugefügt wurde
    ./permissions/permissions-parser.sh list > "$TEST_DIR/list_after_add.txt"
    if ! grep -q "neueradmin@example.com" "$TEST_DIR/list_after_add.txt"; then
        echo "FEHLER: Neuer Benutzer wurde nicht hinzugefügt"
        EXIT_CODE=1
    fi
    
    # Test 3: update_user Funktion testen
    echo "Test 3: Benutzer aktualisieren"
    ./permissions/permissions-parser.sh update "contrib1@example.com" "admin"
    if [ $? -ne 0 ]; then
        echo "FEHLER: update Befehl fehlgeschlagen"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob der Benutzer aktualisiert wurde
    ./permissions/permissions-parser.sh list > "$TEST_DIR/list_after_update.txt"
    if grep -q "contributors.*contrib1" "$TEST_DIR/list_after_update.txt"; then
        echo "FEHLER: Benutzer wurde nicht aktualisiert"
        EXIT_CODE=1
    fi
    
    if ! grep -q "admin.*contrib1" "$TEST_DIR/list_after_update.txt"; then
        echo "FEHLER: Benutzer wurde nicht zur Admin-Gruppe hinzugefügt"
        EXIT_CODE=1
    fi
    
    # Test 4: remove_user Funktion testen
    echo "Test 4: Benutzer entfernen"
    ./permissions/permissions-parser.sh remove "viewer1@example.com"
    if [ $? -ne 0 ]; then
        echo "FEHLER: remove Befehl fehlgeschlagen"
        EXIT_CODE=1
    fi
    
    # Prüfen, ob der Benutzer entfernt wurde
    ./permissions/permissions-parser.sh list > "$TEST_DIR/list_after_remove.txt"
    if grep -q "viewer1@example.com" "$TEST_DIR/list_after_remove.txt"; then
        echo "FEHLER: Benutzer wurde nicht entfernt"
        EXIT_CODE=1
    fi
    
    # Test 5: Fehlerbedingungen testen
    echo "Test 5: Fehlerbedingungen testen"
    
    # Test mit nicht existierendem Benutzer
    ./permissions/permissions-parser.sh remove "nichtexistent@example.com" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "FEHLER: Entfernen eines nicht vorhandenen Benutzers sollte fehlschlagen"
        EXIT_CODE=1
    fi
    
    # Test mit ungültiger Rolle
    ./permissions/permissions-parser.sh add "ungueltige_rolle" "fehlerbenutzer" "fehler@example.com" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "FEHLER: Hinzufügen mit ungültiger Rolle sollte fehlschlagen"
        EXIT_CODE=1
    fi
    
    # Aufräumen
    rm -rf "$TEST_DIR"
    
    # Alle Tests bestanden?
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Alle Integrationstests für permissions-parser.sh bestanden."
    else
        echo "Ein oder mehrere Integrationstests für permissions-parser.sh fehlgeschlagen."
    fi
    
    return $EXIT_CODE
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?