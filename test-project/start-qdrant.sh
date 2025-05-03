#!/bin/bash
# Qdrant-Vektordatenbank-Startup-Skript

cd "$(dirname "$0")"

# Prüfen, ob Docker-Compose verfügbar ist
if command -v docker-compose &> /dev/null; then
    echo "Starte Qdrant mit docker-compose..."
    docker-compose up -d
elif docker compose version &> /dev/null; then
    echo "Starte Qdrant mit Docker Compose Plugin..."
    docker compose up -d
else
    echo "Docker Compose ist nicht verfügbar. Verwende Docker-Container..."
    ./memory-bank/vector_index/scripts/start-qdrant.sh
fi

echo "Qdrant für test-project gestartet auf http://localhost:6333"
echo "API-Endpunkt: http://localhost:6333"
echo "Dashboard: http://localhost:6333/dashboard"
echo "Weitere Informationen: /home/jan/AGI-System-Public/test-project/memory-bank/vector_index"
