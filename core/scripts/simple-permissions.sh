#!/usr/bin/env bash

# Simple permissions management test script
PERMISSIONS_FILE="/tmp/test-permissions/access-control.json"

# Check if file exists
if [ ! -f "$PERMISSIONS_FILE" ]; then
    echo "Error: Permissions file not found: $PERMISSIONS_FILE"
    exit 1
fi

# Read existing file
echo "Current permissions file content:"
cat "$PERMISSIONS_FILE"
echo

# Add a new user
echo "Adding new user..."

# Get the current content
content=$(cat "$PERMISSIONS_FILE")

# Create a new user object
user_object="{\"name\": \"Test User\", \"email\": \"test@example.com\", \"added\": \"$(date -I)\"}"

# Add to contributors
content=$(echo "$content" | sed "s/\"contributors\": \[/\"contributors\": \[$user_object, /")

# Fix empty array case
content=$(echo "$content" | sed "s/, \]/]/g")

# Update date
content=$(echo "$content" | sed "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$(date -I)\"/")

# Write back to file
echo "$content" > "$PERMISSIONS_FILE"

# Verify the change
echo "Updated permissions file content:"
cat "$PERMISSIONS_FILE"
echo

echo "Done!"