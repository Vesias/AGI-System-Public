#!/usr/bin/env bash

# Test script für permissions-manager.sh
TEMPDIR="/tmp/test-permissions-verify"
TESTFILE="$TEMPDIR/access-control.json"

# Testverzeichnis erstellen
mkdir -p "$TEMPDIR"

# Testdatei erstellen
cat > "$TESTFILE" << EOF
{
  "admin": [
    {"name": "Admin User", "email": "admin@example.com", "added": "2025-03-05"}
  ],
  "contributors": [],
  "viewers": [],
  "last_updated": "2025-03-05"
}
EOF

echo "=== TEST START ==="
echo "Testverwaltungsdatei erstellt: $TESTFILE"
echo

# 1. Liste Benutzer testen
echo "=== TEST 1: list-users ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" list-users
echo

# 2. Benutzer hinzufügen testen
echo "=== TEST 2: add-user ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" add-user "contrib@example.com" "Contrib User" contributor
echo
cat "$TESTFILE"
echo

# 3. Liste Benutzer testen nach Hinzufügen
echo "=== TEST 3: list-users nach Hinzufügen ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" list-users
echo

# 4. Rolle aktualisieren testen
echo "=== TEST 4: update-role ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" update-role "contrib@example.com" "viewer"
echo
cat "$TESTFILE"
echo

# 5. Liste Benutzer testen nach Rollenaktualisierung
echo "=== TEST 5: list-users nach Rollenaktualisierung ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" list-users
echo

# 6. Benutzer entfernen testen
echo "=== TEST 6: remove-user ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" remove-user "contrib@example.com"
echo
cat "$TESTFILE"
echo

# 7. Abschließende Benutzerliste
echo "=== TEST 7: Abschließende list-users ==="
cd /home/jan/AGI-System-Public/core/scripts && ./permissions-manager.sh -f "$TESTFILE" list-users
echo

echo "=== TEST ENDE ==="
echo "Bereinige Testdateien..."
rm -rf "$TEMPDIR"
echo "Bereinigung abgeschlossen!"