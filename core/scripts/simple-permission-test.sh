#!/usr/bin/env bash

# Test Script für Benutzer hinzufügen mit jq
TEMPDIR="/tmp/test-permissions-simple"
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

echo "=== Original JSON ==="
cat "$TESTFILE"
echo

# Hinzufügen eines Contributors mit jq
echo "=== Füge Contributor hinzu ==="
USER_EMAIL="contrib@example.com"
USER_NAME="Contrib User"
ADDED_DATE=$(date -I)
user_object="{\"name\": \"$USER_NAME\", \"email\": \"$USER_EMAIL\", \"added\": \"$ADDED_DATE\"}"

jq ".contributors += [$user_object]" "$TESTFILE" > "$TEMPDIR/temp.json"
jq ".last_updated = \"$ADDED_DATE\"" "$TEMPDIR/temp.json" > "$TESTFILE"
cat "$TESTFILE"
echo 

# Aktualisieren der Rolle des Benutzers (von contributor zu viewer)
echo "=== Aktualisiere Rolle zu Viewer ==="
# Entferne den Benutzer aus Contributors
jq ".contributors = [.contributors[] | select(.email != \"$USER_EMAIL\")]" "$TESTFILE" > "$TEMPDIR/temp.json"
# Füge den Benutzer zu Viewers hinzu
jq ".viewers += [$user_object]" "$TEMPDIR/temp.json" > "$TESTFILE"
# Aktualisiere das Datum
jq ".last_updated = \"$ADDED_DATE\"" "$TESTFILE" > "$TEMPDIR/temp.json"
mv "$TEMPDIR/temp.json" "$TESTFILE"
cat "$TESTFILE"
echo

# Entferne den Benutzer
echo "=== Entferne Benutzer ==="
jq ".viewers = [.viewers[] | select(.email != \"$USER_EMAIL\")]" "$TESTFILE" > "$TEMPDIR/temp.json"
jq ".last_updated = \"$ADDED_DATE\"" "$TEMPDIR/temp.json" > "$TESTFILE"
cat "$TESTFILE"
echo

echo "=== Aufräumen ==="
rm -rf "$TEMPDIR"
echo "Bereinigung abgeschlossen"