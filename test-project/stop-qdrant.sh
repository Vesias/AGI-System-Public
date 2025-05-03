#!/bin/bash
# Qdrant-Vektordatenbank-Stopp-Skript

cd "$(dirname "$0")"

# Prüfen, ob Docker-Compose verfügbar ist
if command -v docker-compose &> /dev/null; then
    echo "Stoppe Qdrant mit docker-compose..."
    docker-compose down
elif docker compose version &> /dev/null; then
    echo "Stoppe Qdrant mit Docker Compose Plugin..."
    docker compose down
else
    echo "Docker Compose ist nicht verfügbar. Stoppe Docker-Container..."
    docker stop qdrant-test-project 2>/dev/null || true
fi

echo "Qdrant für test-project gestoppt."
