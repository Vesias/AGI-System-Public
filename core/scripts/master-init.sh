#!/usr/bin/env bash
# ============================================================================
# AGI-System Master-Initialisierer
# 
# Dieses Skript bietet eine umfassende Lösung zur Projektinitialisierung mit:
# - Vollständiger Verzeichnisstruktur
# - Memory-Bank-System
# - MCP-Tools-Integration (Desktop Commander, Memory Bank, Browser Tools, etc.)
# - Qdrant-Vektordatenbank für semantische Suche
# - SentenceTransformers-Integration für Texteinbettungen
# - Automatische Berechtigungsverwaltung
# - Interaktive .about-Datei
# ============================================================================

set -eo pipefail

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Versionsinformation
VERSION="1.0.0"

# Standardwerte
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PROJECT_NAME=""
INSTALL_DIR="$HOME/AGI-Projekte"
MCP_TOOLS_ENABLED=true
VECTOR_DB_ENABLED=true
USE_DOCKER=true
INTERACTIVE_MODE=true
VECTOR_DIM=1536
EMBEDDING_MODEL="claude-3-haiku"
LOG_FILE="/tmp/agi-master-init-$(date +%Y%m%d%H%M%S).log"
START_TIME=$(date +%s)

# Trap für sauberes Aufräumen
trap cleanup EXIT

# Funktion für Aufräumarbeiten bei Beendigung
cleanup() {
    # Bei Fehler aufräumen
    if [ $? -ne 0 ]; then
        echo -e "${RED}Installation wurde mit Fehlern beendet.${NC}"
        echo -e "Fehlerdetails wurden in $LOG_FILE protokolliert."
        
        # Weitere Aufräumarbeiten je nach Bedarf
    fi
}

# Funktion zur Anzeige der Verwendung
usage() {
    cat << EOF
Verwendung: $0 [Optionen]

Optionen:
  -h, --help                Diese Hilfe anzeigen
  -p, --project PROJEKT     Projektname (erforderlich)
  -d, --dir VERZEICHNIS     Installationsverzeichnis (Standard: $INSTALL_DIR)
  -n, --non-interactive     Nichtinteraktiver Modus (für Automatisierung)
  --no-mcp-tools            MCP-Tools-Integration deaktivieren
  --no-vector-db           Vektordatenbank-Integration deaktivieren
  --no-docker              Keine Docker-Container verwenden
  --embedding-model MODELL  Einbettungsmodell (Standard: $EMBEDDING_MODEL)
  --embedding-dim DIM      Einbettungsdimensionen (Standard: $VECTOR_DIM)
  
Beispiel:
  $0 --project MeinProjekt --dir ~/Projekte
EOF
}

# Funktion für Logeinträge
log() {
    local level="$1"
    local message="$2"
    local color="$NC"
    
    case "$level" in
        "INFO") color="${BLUE}" ;;
        "SUCCESS") color="${GREEN}" ;;
        "WARNING") color="${YELLOW}" ;;
        "ERROR") color="${RED}" ;;
    esac
    
    # Log in Datei schreiben
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$level] $message" >> "$LOG_FILE"
    
    # In Konsole ausgeben
    if [ "$INTERACTIVE_MODE" = "true" ]; then
        echo -e "${color}[$level]${NC} $message"
    fi
}

# Argumente verarbeiten
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -p|--project)
                shift
                PROJECT_NAME="$1"
                ;;
            -d|--dir)
                shift
                INSTALL_DIR="$1"
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                ;;
            --no-mcp-tools)
                MCP_TOOLS_ENABLED=false
                ;;
            --no-vector-db)
                VECTOR_DB_ENABLED=false
                ;;
            --no-docker)
                USE_DOCKER=false
                ;;
            --embedding-model)
                shift
                EMBEDDING_MODEL="$1"
                ;;
            --embedding-dim)
                shift
                VECTOR_DIM="$1"
                ;;
            *)
                echo -e "${RED}Fehler: Unbekannte Option $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done

    # Prüfe, ob Projektname angegeben wurde
    if [ -z "$PROJECT_NAME" ]; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            read -p "Projektname: " PROJECT_NAME
            
            if [ -z "$PROJECT_NAME" ]; then
                log "ERROR" "Kein Projektname angegeben."
                exit 1
            fi
        else
            log "ERROR" "Kein Projektname angegeben. Verwenden Sie --project PROJEKTNAME."
            usage
            exit 1
        fi
    fi
}

# Voraussetzungen prüfen
check_prerequisites() {
    log "INFO" "Prüfe Systemvoraussetzungen..."
    
    # Erforderliche Befehle prüfen
    local required_commands=("git" "curl" "node" "npm")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR" "Befehl '$cmd' nicht gefunden. Bitte installieren."
            exit 1
        fi
    done
    
    # Docker prüfen (falls aktiviert)
    if [ "$USE_DOCKER" = true ] && [ "$VECTOR_DB_ENABLED" = true ]; then
        if ! command -v docker &> /dev/null; then
            log "WARNING" "Docker ist nicht installiert, aber für Qdrant empfohlen."
            
            if [ "$INTERACTIVE_MODE" = true ]; then
                echo -e "${YELLOW}Möchten Sie trotzdem fortfahren? (j/n)${NC}"
                read -r CONTINUE
                
                if [[ ! "$CONTINUE" =~ ^[Jj] ]]; then
                    log "ERROR" "Installation abgebrochen."
                    exit 1
                fi
                
                USE_DOCKER=false
            else
                log "WARNING" "Fahre ohne Docker fort."
                USE_DOCKER=false
            fi
        else
            # Prüfe Docker-Zugriff
            if ! docker info &> /dev/null; then
                log "WARNING" "Keine Berechtigungen für Docker. Prüfen Sie Ihre Docker-Konfiguration."
                
                if [ "$INTERACTIVE_MODE" = true ]; then
                    echo -e "${YELLOW}Möchten Sie trotzdem fortfahren? (j/n)${NC}"
                    read -r CONTINUE
                    
                    if [[ ! "$CONTINUE" =~ ^[Jj] ]]; then
                        log "ERROR" "Installation abgebrochen."
                        exit 1
                    fi
                    
                    USE_DOCKER=false
                else
                    log "WARNING" "Fahre ohne Docker fort."
                    USE_DOCKER=false
                fi
            fi
        fi
    fi
    
    # Python-Umgebung prüfen (für Einbettungen)
    if [ "$VECTOR_DB_ENABLED" = true ]; then
        if ! command -v python3 &> /dev/null; then
            log "WARNING" "Python 3 ist nicht installiert, aber für Einbettungen empfohlen."
            
            if [ "$INTERACTIVE_MODE" = true ]; then
                echo -e "${YELLOW}Möchten Sie trotzdem fortfahren? (j/n)${NC}"
                read -r CONTINUE
                
                if [[ ! "$CONTINUE" =~ ^[Jj] ]]; then
                    log "ERROR" "Installation abgebrochen."
                    exit 1
                fi
            fi
        else
            # Prüfe Python-Version (mindestens 3.8)
            local python_version
            python_version=$(python3 --version | cut -d' ' -f2)
            if [[ $(echo "$python_version" | cut -d. -f1,2) < "3.8" ]]; then
                log "WARNING" "Python 3.8 oder höher empfohlen. Installierte Version: $python_version"
            fi
        fi
    fi
    
    # Node.js-Version prüfen (mindestens 14)
    if [ "$MCP_TOOLS_ENABLED" = true ]; then
        local node_version
        node_version=$(node --version | cut -d'v' -f2)
        if [[ $(echo "$node_version" | cut -d. -f1) -lt 14 ]]; then
            log "WARNING" "Node.js 14 oder höher empfohlen. Installierte Version: $node_version"
        fi
    fi
    
    log "SUCCESS" "Systemvoraussetzungen erfüllt."
    return 0
}

# Projektverzeichnisstruktur einrichten
setup_project_structure() {
    log "INFO" "Erstelle Projektverzeichnisstruktur für '$PROJECT_NAME'..."
    
    # Hauptverzeichnisse erstellen
    mkdir -p "$INSTALL_DIR/$PROJECT_NAME"
    cd "$INSTALL_DIR/$PROJECT_NAME"
    
    # Standardunterverzeichnisse erstellen
    mkdir -p APP
    mkdir -p MARKETING
    mkdir -p FINANCE
    mkdir -p DOCS
    
    # Technische Unterverzeichnisse erstellen
    mkdir -p .config/claude
    mkdir -p .claude
    mkdir -p memory-bank/{project_context,vector_index/{collections,embeddings,queries,scripts}}
    
    # Wenn Vektordatenbank aktiviert, zusätzliche Verzeichnisse erstellen
    if [ "$VECTOR_DB_ENABLED" = true ]; then
        mkdir -p data/qdrant
        mkdir -p data/transformers
    fi
    
    log "SUCCESS" "Projektverzeichnisstruktur erstellt."
    return 0
}

# Memory-Bank-Struktur einrichten
setup_memory_bank() {
    log "INFO" "Richte Memory-Bank-Struktur ein..."
    
    # Memory-Bank-Standarddateien erstellen
    cat > memory-bank/projectbrief.md << EOF
# Projektbeschreibung: $PROJECT_NAME

## Übersicht
Eine kurze Beschreibung des Projekts hier einfügen.

## Ziele
- Ziel 1
- Ziel 2
- Ziel 3

## Scope
Was ist im Projektumfang enthalten und was nicht.

## Stakeholder
Wer ist an diesem Projekt beteiligt?

## Timeline
Wichtige Meilensteine und Fristen.
EOF
    
    cat > memory-bank/productContext.md << EOF
# Produktkontext: $PROJECT_NAME

## Problemstellung
Welches Problem löst dieses Projekt?

## Zielgruppe
Wer sind die Hauptnutzer oder Stakeholder?

## Hauptfunktionen
- Funktion 1
- Funktion 2
- Funktion 3

## Abgrenzung zu bestehenden Lösungen
Was macht dieses Projekt einzigartig?

## Erfolgskriterien
Wie wird der Erfolg des Projekts gemessen?
EOF
    
    cat > memory-bank/activeContext.md << EOF
# Aktiver Kontext: $PROJECT_NAME

## Aktueller Fokus
Woran wird momentan gearbeitet?

## Offene Fragen
- Frage 1
- Frage 2

## Nächste Schritte
1. Schritt 1
2. Schritt 2
3. Schritt 3

## Aktuelle Herausforderungen
Welche Probleme müssen gelöst werden?
EOF
    
    cat > memory-bank/systemPatterns.md << EOF
# Systemmuster: $PROJECT_NAME

## Architektur
Beschreibung der Gesamtarchitektur.

## Design-Patterns
Welche Design-Patterns werden verwendet?

## Code-Konventionen
- Einrückung: 2 Leerzeichen
- Namenskonvention: camelCase für Variablen, PascalCase für Klassen
- Max. Zeilenlänge: 80 Zeichen

## Technologiestack
- Frontend: 
- Backend: 
- Datenbank: 
- Hosting: 
EOF
    
    cat > memory-bank/techContext.md << EOF
# Technischer Kontext: $PROJECT_NAME

## Technologien
Liste der verwendeten Technologien und Frameworks.

## API-Dokumentation
Links oder Beschreibungen relevanter APIs.

## Externe Abhängigkeiten
Welche externen Dienste oder Bibliotheken werden verwendet?

## Integrationen
Mit welchen Systemen integriert sich dieses Projekt?

## Entwicklungsumgebung
Setup für die lokale Entwicklung.
EOF
    
    cat > memory-bank/progress.md << EOF
# Projektfortschritt: $PROJECT_NAME

## Meilensteine
- [ ] Meilenstein 1
- [ ] Meilenstein 2
- [ ] Meilenstein 3

## Erledigt
- Aufgabe 1 (Datum)

## In Bearbeitung
- Aufgabe 2

## Geplant
- Aufgabe 3
- Aufgabe 4

## Offene Punkte
- Punkt 1
- Punkt 2
EOF
    
    # Erstelle .clauderules-Datei
    cat > memory-bank/.clauderules << EOF
# Claude-Regeln für $PROJECT_NAME

## Grundsätzliche Richtlinien
- Folge den in systemPatterns.md definierten Code-Konventionen
- Überprüfe Änderungen vor dem Commit auf Sicherheitsprobleme
- Dokumentiere wichtige Entscheidungen in activeContext.md
- Aktualisiere progress.md nach Abschluss von Aufgaben

## Projektspezifische Anweisungen
- Beispielanweisung 1
- Beispielanweisung 2

## Erkenntnisse und Learnings
- Erkenntnis 1
- Erkenntnis 2
EOF
    
    # Erstelle README für memory-bank
    cat > memory-bank/README.md << EOF
# Memory Bank für $PROJECT_NAME

Diese Memory Bank enthält wichtige Kontextinformationen und Dokumentation für das Projekt.

## Struktur

- **projectbrief.md**: Grundlegende Projektdefinition und Ziele
- **productContext.md**: Zweck und Problemlösung des Projekts
- **activeContext.md**: Aktueller Arbeitsfokus und nächste Schritte
- **systemPatterns.md**: Systemarchitektur und Design-Patterns
- **techContext.md**: Verwendete Technologien und technische Details
- **progress.md**: Aktueller Status und Fortschritt
- **.clauderules**: Spezifische Regeln und Erkenntnisse für Claude

## Vector Index

Im Verzeichnis `vector_index` werden Einbettungen und semantische Suchdaten gespeichert.
EOF
    
    # Berechtigungen setzen
    chmod -R 755 memory-bank
    
    log "SUCCESS" "Memory-Bank-Struktur erstellt."
    return 0
}

# Interaktive .about-Datei erstellen
create_interactive_about() {
    log "INFO" "Erstelle interaktive .about-Datei..."
    
    local date_today=$(date -I)
    local vector_db_collections="[]"
    local vector_db_endpoint=""
    local semantic_search_enabled="false"
    
    if [ "$VECTOR_DB_ENABLED" = true ]; then
        vector_db_collections='["project_context", "code_embeddings", "documentation"]'
        vector_db_endpoint="http://localhost:6333"
        semantic_search_enabled="true"
    fi
    
    # .about.interactive-Datei erstellen
    cat > .about.interactive << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "created": "$date_today",
    "type": "AGI-System Project",
    "path": "$INSTALL_DIR/$PROJECT_NAME"
  },
  "mcp_tools": {
    "enabled": $MCP_TOOLS_ENABLED,
    "permissions": {
      "read": true,
      "write": true,
      "execute": true,
      "network": true
    }
  },
  "vector_database": {
    "type": "$( [ "$VECTOR_DB_ENABLED" = true ] && echo "qdrant" || echo "none" )",
    "endpoint": "$vector_db_endpoint",
    "collections": $vector_db_collections
  },
  "memory_rules": {
    "retention_policy": "perpetual",
    "context_window": "infinite",
    "embedding_model": "$EMBEDDING_MODEL",
    "semantic_search": $semantic_search_enabled
  },
  "user_preferences": {
    "coding_style": {
      "indentation": "spaces",
      "naming_convention": "camelCase",
      "max_line_length": 80
    },
    "documentation_style": {
      "language": "de",
      "format": "markdown"
    },
    "ai_interaction": {
      "verbosity": "moderate",
      "code_explanation_level": "basic",
      "autonomy_level": "medium"
    }
  },
  "automation": {
    "memory_bank_sync": true,
    "code_formatting": true,
    "git_hooks": true,
    "test_automation": true
  },
  "integrations": {
    "git": {
      "enabled": true,
      "repository": "",
      "branch": "main"
    },
    "ci_cd": {
      "enabled": false,
      "provider": "github-actions",
      "config_path": ".github/workflows"
    },
    "cloud": {
      "enabled": false,
      "provider": "vercel",
      "region": "eu-central-1"
    }
  },
  "metadata": {
    "created_with": "AGI-System Master-Initialisierer",
    "version": "$VERSION",
    "last_updated": "$date_today"
  }
}
EOF
    
    # CLAUDE.md-Datei erstellen
    cat > .claude/CLAUDE.md << EOF
# CLAUDE.md für $PROJECT_NAME

## Projektüberblick
$PROJECT_NAME ist ein AGI-System-Projekt mit Memory-Bank und MCP-Tools-Integration.

## Code-Standards
- Verwende 2 Leerzeichen für Einrückungen
- Kommentiere komplexen Code
- Schreibe Tests für neue Funktionen
- Halte Funktionen klein und fokussiert

## Workflow
1. Aktualisiere memory-bank/activeContext.md mit deinem aktuellen Fokus
2. Implementiere die Funktionalität
3. Teste deine Änderungen
4. Aktualisiere memory-bank/progress.md
5. Erstelle einen Commit mit aussagekräftiger Nachricht

## AGI-System-Komponenten
- Memory-Bank: Strukturierte Projektdokumentation
- MCP-Tools: Erweiterbare Werkzeuge für Claude
- Vektordatenbank: Semantische Suche und Einbettungen

## Richtlinien
- Halte Dokumentation aktuell
- Verwende die Memory-Bank für wichtige Kontextinformationen
- Folge den in systemPatterns.md definierten Architekturvorgaben
EOF
    
    log "SUCCESS" "Interaktive .about-Datei erstellt."
    return 0
}

# Qdrant-Vektordatenbank einrichten
setup_qdrant() {
    if [ "$VECTOR_DB_ENABLED" = false ]; then
        log "INFO" "Qdrant-Setup übersprungen (Vektordatenbank deaktiviert)."
        return 0
    fi
    
    log "INFO" "Richte Qdrant-Vektordatenbank ein..."
    
    # Nur fortfahren, wenn Docker aktiviert ist
    if [ "$USE_DOCKER" = false ]; then
        log "WARNING" "Qdrant-Setup übersprungen (Docker deaktiviert)."
        return 0
    fi
    
    # Qdrant-Konfigurationsdatei erstellen
    mkdir -p .config/qdrant
    cat > .config/qdrant/config.yaml << EOF
storage:
  storage_path: /qdrant/storage
  
  files:
    maintain_vectors: false
    defer_index_update: true
    
  memmap_threshold_kb: 102400
  
service:
  listen_ip: 0.0.0.0
  http_port: 6333
  grpc_port: 6334
EOF
    
    # Docker-Compose-Datei erstellen
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant-${PROJECT_NAME}
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - ./data/qdrant:/qdrant/storage
      - ./.config/qdrant/config.yaml:/qdrant/config/production.yaml
    networks:
      - agi_network

networks:
  agi_network:
    driver: bridge
EOF
    
    # Startup-Skript für Qdrant erstellen
    cat > start-qdrant.sh << EOF
#!/bin/bash
# Qdrant-Startup-Skript für $PROJECT_NAME

cd "\$(dirname "\$0")"

# Prüfen, ob Docker verfügbar ist
if ! command -v docker &> /dev/null; then
    echo "Fehler: Docker ist nicht installiert."
    exit 1
fi

# Starten mit Docker-Compose, wenn verfügbar
if command -v docker-compose &> /dev/null; then
    echo "Starte Qdrant mit docker-compose..."
    docker-compose up -d
elif docker compose version &> /dev/null; then
    echo "Starte Qdrant mit Docker Compose Plugin..."
    docker compose up -d
else
    echo "Docker Compose ist nicht verfügbar. Verwende Docker-Container..."
    
    # Container stoppen, falls er bereits läuft
    docker stop qdrant-${PROJECT_NAME} 2>/dev/null || true
    docker rm qdrant-${PROJECT_NAME} 2>/dev/null || true
    
    # Container starten
    docker run -d \\
      --name qdrant-${PROJECT_NAME} \\
      -p 6333:6333 \\
      -p 6334:6334 \\
      -v "\$(pwd)/data/qdrant:/qdrant/storage" \\
      -v "\$(pwd)/.config/qdrant/config.yaml:/qdrant/config/production.yaml" \\
      qdrant/qdrant
fi

echo "Qdrant für ${PROJECT_NAME} gestartet auf http://localhost:6333"
echo "Dashboard: http://localhost:6333/dashboard"
EOF
    
    # Stopp-Skript für Qdrant erstellen
    cat > stop-qdrant.sh << EOF
#!/bin/bash
# Qdrant-Stopp-Skript für $PROJECT_NAME

cd "\$(dirname "\$0")"

# Stoppen mit Docker-Compose, wenn verfügbar
if command -v docker-compose &> /dev/null; then
    echo "Stoppe Qdrant mit docker-compose..."
    docker-compose down
elif docker compose version &> /dev/null; then
    echo "Stoppe Qdrant mit Docker Compose Plugin..."
    docker compose down
else
    echo "Docker Compose ist nicht verfügbar. Stoppe Docker-Container..."
    docker stop qdrant-${PROJECT_NAME} 2>/dev/null || true
fi

echo "Qdrant für ${PROJECT_NAME} gestoppt."
EOF
    
    # Skripte ausführbar machen
    chmod +x start-qdrant.sh
    chmod +x stop-qdrant.sh
    
    # Python-Skript für Qdrant-Einbettungen erstellen
    cat > memory-bank/vector_index/scripts/vector_utils.py << EOF
#!/usr/bin/env python3
# Qdrant-Vektor-Utilities für $PROJECT_NAME

import os
import sys
import argparse
import json

# Standardwerte
PROJECT_NAME = "$PROJECT_NAME"
VECTOR_DIM = $VECTOR_DIM
QDRANT_HOST = "localhost"
QDRANT_PORT = 6333

try:
    from sentence_transformers import SentenceTransformer
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
except ImportError:
    print("Erforderliche Pakete nicht installiert.")
    print("Bitte installieren Sie: pip install sentence-transformers qdrant-client")
    sys.exit(1)

# Einbettungsmodell-Name
MODEL_NAME = "all-MiniLM-L6-v2"  # Ein kleineres Modell als Standard

# Modell initialisieren
def get_model():
    try:
        return SentenceTransformer(MODEL_NAME)
    except Exception as e:
        print(f"Fehler beim Laden des Modells: {e}")
        print(f"Stellen Sie sicher, dass das Modell '{MODEL_NAME}' verfügbar ist.")
        print("Falls nicht, installieren Sie es mit: pip install sentence-transformers")
        sys.exit(1)

# Qdrant-Client initialisieren
def get_client():
    try:
        return QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    except Exception as e:
        print(f"Fehler bei der Verbindung zu Qdrant: {e}")
        print(f"Stellen Sie sicher, dass Qdrant auf {QDRANT_HOST}:{QDRANT_PORT} läuft.")
        print("Verwenden Sie ./start-qdrant.sh, um Qdrant zu starten.")
        sys.exit(1)

# Sammlung erstellen
def create_collection(name=PROJECT_NAME):
    client = get_client()
    
    try:
        # Prüfen, ob Sammlung bereits existiert
        client.get_collection(collection_name=name)
        print(f"Sammlung '{name}' existiert bereits.")
        return
    except Exception:
        pass  # Sammlung existiert nicht, erstelle sie
    
    # Sammlung erstellen
    client.create_collection(
        collection_name=name,
        vectors_config=models.VectorParams(
            size=VECTOR_DIM,
            distance=models.Distance.COSINE
        )
    )
    print(f"Sammlung '{name}' erfolgreich erstellt.")

# Text einbetten und in Qdrant speichern
def embed_text(text, metadata=None, collection_name=PROJECT_NAME):
    model = get_model()
    client = get_client()
    
    # Text in Vektor umwandeln
    embedding = model.encode(text)
    
    # Standard-Metadaten, falls keine angegeben
    if metadata is None:
        metadata = {}
    
    # Einbettung in Qdrant speichern
    point_id = hash(text) % (2**63)  # Hash als ID, aber im positiven Bereich
    
    client.upsert(
        collection_name=collection_name,
        points=[
            models.PointStruct(
                id=point_id,
                vector=embedding.tolist(),
                payload={
                    "text": text,
                    **metadata
                }
            )
        ]
    )
    
    return {"id": point_id, "status": "success"}

# Ähnliche Texte suchen
def search_similar(text, limit=5, collection_name=PROJECT_NAME):
    model = get_model()
    client = get_client()
    
    # Text in Vektor umwandeln
    query_vector = model.encode(text)
    
    # Ähnliche Punkte in Qdrant suchen
    results = client.search(
        collection_name=collection_name,
        query_vector=query_vector.tolist(),
        limit=limit
    )
    
    return results

# Hauptfunktion mit Argumentparser
def main():
    parser = argparse.ArgumentParser(description=f"Vektor-Utilities für {PROJECT_NAME}")
    subparsers = parser.add_subparsers(dest="command", help="Befehle")
    
    # Collection-Befehl
    create_parser = subparsers.add_parser("create-collection", help="Sammlung erstellen")
    create_parser.add_argument("--name", default=PROJECT_NAME, help="Name der Sammlung")
    
    # Embed-Befehl
    embed_parser = subparsers.add_parser("embed", help="Text einbetten")
    embed_parser.add_argument("text", help="Einzubettender Text")
    embed_parser.add_argument("--collection", default=PROJECT_NAME, help="Name der Sammlung")
    embed_parser.add_argument("--metadata", help="Metadaten als JSON")
    
    # Search-Befehl
    search_parser = subparsers.add_parser("search", help="Ähnliche Texte suchen")
    search_parser.add_argument("text", help="Suchtext")
    search_parser.add_argument("--limit", type=int, default=5, help="Maximale Anzahl Ergebnisse")
    search_parser.add_argument("--collection", default=PROJECT_NAME, help="Name der Sammlung")
    
    # Argumente parsen
    args = parser.parse_args()
    
    # Befehl ausführen
    if args.command == "create-collection":
        create_collection(args.name)
    elif args.command == "embed":
        metadata = None
        if args.metadata:
            try:
                metadata = json.loads(args.metadata)
            except json.JSONDecodeError:
                print("Fehler: Metadaten sind kein gültiges JSON.")
                sys.exit(1)
        
        result = embed_text(args.text, metadata, args.collection)
        print(json.dumps(result, indent=2))
    elif args.command == "search":
        results = search_similar(args.text, args.limit, args.collection)
        for i, result in enumerate(results):
            print(f"{i+1}. Score: {result.score:.4f}")
            print(f"   Text: {result.payload.get('text', 'Kein Text verfügbar')}")
            print(f"   ID: {result.id}")
            print()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
EOF
    
    # Skript ausführbar machen
    chmod +x memory-bank/vector_index/scripts/vector_utils.py
    
    # Installationsskript für Python-Abhängigkeiten
    cat > memory-bank/vector_index/scripts/install_dependencies.sh << EOF
#!/bin/bash
# Installations-Skript für Vektor-Abhängigkeiten

# Prüfen, ob pip verfügbar ist
if ! command -v pip3 &> /dev/null; then
    echo "Fehler: pip3 ist nicht installiert."
    echo "Bitte installieren Sie pip für Python 3."
    exit 1
fi

# Erforderliche Pakete installieren
echo "Installiere erforderliche Python-Pakete..."
pip3 install sentence-transformers qdrant-client

echo "Installation abgeschlossen."
EOF
    
    # Skript ausführbar machen
    chmod +x memory-bank/vector_index/scripts/install_dependencies.sh
    
    # README für Vektordatenbank
    cat > memory-bank/vector_index/README.md << EOF
# Qdrant-Vektordatenbank für $PROJECT_NAME

## Übersicht

Diese Vektordatenbank speichert semantische Einbettungen für das Projekt, um intelligente 
Suche und Kontextabruf zu ermöglichen.

## Konfiguration

- **Host**: localhost
- **Port**: 6333
- **API-Endpunkt**: http://localhost:6333
- **Dashboard**: http://localhost:6333/dashboard
- **Embedding-Modell**: sentence-transformers/all-MiniLM-L6-v2
- **Embedding-Dimensionen**: $VECTOR_DIM

## Sammlungen

- **project_context**: Projektkontext und Dokumentation
- **code_embeddings**: Code-Snippets und -Fragmente
- **documentation**: Technische Dokumentation und Anleitungen

## Verwendung

### Starten und Stoppen der Datenbank

\`\`\`bash
# Starten
./start-qdrant.sh

# Stoppen
./stop-qdrant.sh
\`\`\`

### Abhängigkeiten installieren

\`\`\`bash
# Python-Abhängigkeiten installieren
./memory-bank/vector_index/scripts/install_dependencies.sh
\`\`\`

### Sammlung erstellen

\`\`\`bash
# Standardsammlung erstellen
python3 ./memory-bank/vector_index/scripts/vector_utils.py create-collection
\`\`\`

### Text einbetten

\`\`\`bash
# Text einbetten
python3 ./memory-bank/vector_index/scripts/vector_utils.py embed "Dieser Text wird eingebettet"

# Mit Metadaten
python3 ./memory-bank/vector_index/scripts/vector_utils.py embed "Dieser Text hat Metadaten" --metadata '{"source": "README", "type": "documentation"}'
\`\`\`

### Semantische Suche

\`\`\`bash
# Ähnliche Texte suchen
python3 ./memory-bank/vector_index/scripts/vector_utils.py search "Suche nach ähnlichem Text"

# Mit begrenzter Ergebnisanzahl
python3 ./memory-bank/vector_index/scripts/vector_utils.py search "Suche mit Limit" --limit 3
\`\`\`

## Integration mit Claude und MCP-Tools

Diese Vektordatenbank kann nahtlos mit Claude und MCP-Tools für semantische 
Suche und Kontextualisierung integriert werden:

1. **Claude Code**: Verwenden Sie Claude Code mit Kontexterkennung
2. **Memory-Bank MCP**: Verwenden Sie den Memory-Bank MCP für automatische Indexierung
3. **Desktop-Commander**: Verwenden Sie den Desktop-Commander für Dateizugriff
EOF
    
    log "SUCCESS" "Qdrant-Vektordatenbank eingerichtet."
    
    # Wenn interaktiv, Qdrant optional starten
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${YELLOW}Möchten Sie Qdrant jetzt starten? (j/n)${NC}"
        read -r START_QDRANT
        
        if [[ "$START_QDRANT" =~ ^[Jj] ]]; then
            log "INFO" "Starte Qdrant..."
            ./start-qdrant.sh
            
            echo -e "${YELLOW}Möchten Sie die Python-Abhängigkeiten für Vektoreinbettungen installieren? (j/n)${NC}"
            read -r INSTALL_DEPS
            
            if [[ "$INSTALL_DEPS" =~ ^[Jj] ]]; then
                log "INFO" "Installiere Python-Abhängigkeiten..."
                ./memory-bank/vector_index/scripts/install_dependencies.sh
                
                log "INFO" "Erstelle Standardsammlung..."
                python3 ./memory-bank/vector_index/scripts/vector_utils.py create-collection
            fi
        fi
    fi
    
    return 0
}

# MCP-Tools einrichten
setup_mcp_tools() {
    if [ "$MCP_TOOLS_ENABLED" = false ]; then
        log "INFO" "MCP-Tools-Setup übersprungen (MCP-Tools deaktiviert)."
        return 0
    fi
    
    log "INFO" "Richte MCP-Tools ein..."
    
    # Konfigurationsverzeichnis erstellen
    mkdir -p .config/claude
    
    # MCP-Tools-Konfigurationsdatei erstellen
    cat > .config/claude/mcpservers.json << EOF
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": ["-y", "commander-cli", "run"],
      "env": {
        "PROJECT_DIR": "$INSTALL_DIR/$PROJECT_NAME",
        "ALLOWED_OPERATIONS": "all"
      }
    },
    "memory-bank": {
      "command": "npx",
      "args": ["-y", "memory-store"],
      "env": {
        "MEMORY_BANK_PATH": "$INSTALL_DIR/$PROJECT_NAME/memory-bank",
        "PROJECT_NAME": "$PROJECT_NAME"
      }
    },
    "marketing-tools": {
      "command": "npx",
      "args": ["-y", "marketing-analytics"],
      "env": {
        "PROJECT_CONTEXT": "$INSTALL_DIR/$PROJECT_NAME/.context"
      }
    },
    "browser-tools": {
      "command": "npx",
      "args": ["-y", "puppeteer"],
      "env": {
        "BROWSER_MODE": "headless",
        "ALLOW_NAVIGATION": "true"
      }
    },
    "toolbox": {
      "command": "npx",
      "args": [
        "-y",
        "cli-toolbox",
        "run",
        "--no-interactive"
      ]
    }
  }
}
EOF
    
    # MCP-Tools-Dokumentation erstellen
    cat > memory-bank/project_context/mcp_connections.md << EOF
# MCP-Tool-Konfiguration für $PROJECT_NAME

## Aktivierte Tools

- **desktop-commander**: Dateisystem- und Shell-Operationen
- **memory-bank**: Memory-Bank-Verwaltung
- **marketing-tools**: Marketing-Analyse und -Tools
- **browser-tools**: Web-Recherche und -Automatisierung
- **toolbox**: Allgemeine KI-Tools und Hilfsprogramme

## Verbindungsdetails
- Alle Tools sind für das Projekt "$PROJECT_NAME" konfiguriert
- Pfad: $INSTALL_DIR/$PROJECT_NAME
- Konfigurationsdatei: $INSTALL_DIR/$PROJECT_NAME/.config/claude/mcpservers.json

## Berechtigungen
- Voller Lesezugriff auf das Projektverzeichnis
- Schreibzugriff für projektbezogene Dateien
- Ausführung von sicheren Befehlen innerhalb des Projekts
- Netzwerkzugriff für Web-Recherche und API-Aufrufe

## Verwendung
1. Starte Claude Code im Projektverzeichnis
2. Aktiviere MCP-Tools mit: \`/mcp\`
3. Verwende die Tools über natürliche Sprachbefehle

## Beispielworkflows
- "Durchsuche das Projektverzeichnis nach JavaScript-Dateien" → desktop-commander
- "Aktualisiere den Projektkontext mit neuem Feature XYZ" → memory-bank
- "Recherchiere Wettbewerber für unser Produkt" → browser-tools

## Technische Details
Die MCP-Tools werden über npx gestartet und kommunizieren über das Model Context Protocol mit Claude. 
Jedes Tool hat einen eigenen Zuständigkeitsbereich und spezifische Fähigkeiten, die es Claude ermöglichen, 
komplexe Aufgaben auszuführen, die über seine inhärenten Fähigkeiten hinausgehen.
EOF
    
    # Berechtigungskonfiguration erstellen
    mkdir -p memory-bank/project_context
    cat > memory-bank/project_context/permissions.json << EOF
{
  "tool_permissions": {
    "project_level": {
      "allowed_tools": [
        "Bash(**)",
        "Python(**)",
        "File(**)",
        "Web(**)",
        "API(**)"
      ],
      "restricted_tools": [],
      "execution_context": "project_sandbox"
    },
    "memory_bank_access": {
      "read": true,
      "write": true,
      "modify_structure": true
    },
    "mcp_integration": {
      "auto_connect": true,
      "share_context": true,
      "allow_chaining": true
    }
  }
}
EOF
    
    # Automatisierte Workflows erstellen
    mkdir -p memory-bank/automated_rules
    cat > memory-bank/automated_rules/tool_workflows.md << EOF
# MCP-Tool-Workflows

## Verfügbare Tools

### desktop-commander
- Dateisystem-Operationen
- Shell-Befehle ausführen
- Verzeichnisse durchsuchen und organisieren

### memory-bank
- Speichern und Abrufen von Projektkontext
- Aktualisieren von Projektfortschritt
- Verwalten von Projektwissen

### marketing-tools
- Marktrecherche durchführen
- Zielgruppenanalyse erstellen
- Marketing-Assets generieren

### browser-tools
- Webrecherche durchführen
- Daten von Websites extrahieren
- Browser-Automatisierung für Tests

### toolbox
- Bildgenerierung
- Textanalyse und -zusammenfassung
- Code-Optimierung und -Refactoring

## Workflow-Beispiele

1. **Projektaktualisierung**:
   \`memory-bank\` → Kontext abrufen → \`desktop-commander\` → Code aktualisieren → \`memory-bank\` → Fortschritt aktualisieren

2. **Marktrecherche**:
   \`browser-tools\` → Daten sammeln → \`marketing-tools\` → Analyse durchführen → \`memory-bank\` → Erkenntnisse speichern

3. **Code-Optimierung**:
   \`memory-bank\` → Architektur abrufen → \`toolbox\` → Code analysieren → \`desktop-commander\` → Änderungen anwenden
EOF
    
    # Startup-Skript für MCP-Tools erstellen
    cat > start-mcp-tools.sh << EOF
#!/bin/bash
# MCP-Tools Startup-Skript für $PROJECT_NAME

SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
cd "\$SCRIPT_DIR"

# Starte Claude Code mit MCP-Tools
claude << EOF
/mcp
Projekt $PROJECT_NAME wurde initialisiert. 
Folgende MCP-Tools sind verfügbar:
- desktop-commander: Dateisystem- und Shell-Operationen
- memory-bank: Memory-Bank-Verwaltung
- marketing-tools: Marketing-Analyse und -Tools
- browser-tools: Web-Recherche und -Automatisierung
- toolbox: Allgemeine KI-Tools und Hilfsprogramme
EOF

echo "MCP-Tools für $PROJECT_NAME aktiviert. Claude Code ist bereit für die Verwendung mit MCP-Tools."
EOF
    
    # Skript ausführbar machen
    chmod +x start-mcp-tools.sh
    
    # package.json für NPM erstellen
    cat > package.json << EOF
{
  "name": "${PROJECT_NAME}",
  "version": "0.1.0",
  "private": true,
  "description": "$PROJECT_NAME - Ein AGI-System-Projekt mit MCP-Tools-Integration",
  "scripts": {
    "start:mcp": "node -e \"console.log('MCP-Tools wurden konfiguriert und können mit Claude verwendet werden.')\"",
    "start:qdrant": "./start-qdrant.sh"
  },
  "dependencies": {
    "commander-cli": "^1.0.0",
    "memory-store": "^1.0.0",
    "marketing-analytics": "^1.0.0",
    "puppeteer": "^19.0.0",
    "cli-toolbox": "^1.0.0"
  }
}
EOF
    
    log "SUCCESS" "MCP-Tools eingerichtet."
    
    # Wenn interaktiv, NPM-Abhängigkeiten optional installieren
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${YELLOW}Möchten Sie die NPM-Abhängigkeiten für MCP-Tools installieren? (j/n)${NC}"
        read -r INSTALL_NPM
        
        if [[ "$INSTALL_NPM" =~ ^[Jj] ]]; then
            log "INFO" "Installiere NPM-Abhängigkeiten..."
            npm install
        fi
    fi
    
    return 0
}

# Berechtigungsverwaltung einrichten
setup_permissions() {
    log "INFO" "Richte Berechtigungsverwaltung ein..."
    
    # Berechtigungsskript erstellen
    cat > setup-permissions.sh << EOF
#!/bin/bash
# Berechtigungsverwaltung für $PROJECT_NAME

# Verzeichnisberechtigungen setzen
chmod -R 755 APP
chmod -R 755 MARKETING
chmod -R 755 FINANCE
chmod -R 755 DOCS
chmod -R 755 memory-bank
chmod -R 755 .config
chmod 644 .about.interactive
chmod 644 package.json

# Falls Qdrant aktiviert ist
if [ -f "start-qdrant.sh" ]; then
    chmod +x start-qdrant.sh
    chmod +x stop-qdrant.sh
fi

# Falls MCP-Tools aktiviert sind
if [ -f "start-mcp-tools.sh" ]; then
    chmod +x start-mcp-tools.sh
fi

echo "Berechtigungen erfolgreich aktualisiert."
EOF
    
    # Skript ausführbar machen
    chmod +x setup-permissions.sh
    
    # Skript ausführen
    ./setup-permissions.sh
    
    log "SUCCESS" "Berechtigungsverwaltung eingerichtet."
    return 0
}

# Zusammenfassung anzeigen
show_summary() {
    # Berechnungszeit
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    local MINUTES=$((DURATION / 60))
    local SECONDS=$((DURATION % 60))
    
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GREEN}AGI-System-Projekt erfolgreich initialisiert!${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "${CYAN}Projektdetails:${NC}"
    echo -e "  Projektname:              ${CYAN}$PROJECT_NAME${NC}"
    echo -e "  Verzeichnis:              ${CYAN}$INSTALL_DIR/$PROJECT_NAME${NC}"
    echo -e "  MCP-Tools aktiviert:      ${CYAN}$([ "$MCP_TOOLS_ENABLED" = true ] && echo "Ja" || echo "Nein")${NC}"
    echo -e "  Vektordatenbank aktiviert:${CYAN}$([ "$VECTOR_DB_ENABLED" = true ] && echo "Ja" || echo "Nein")${NC}"
    echo
    echo -e "${YELLOW}Komponenten:${NC}"
    echo -e "  - Memory-Bank: ${GRAY}$INSTALL_DIR/$PROJECT_NAME/memory-bank${NC}"
    echo -e "  - MCP-Tools-Konfiguration: ${GRAY}$INSTALL_DIR/$PROJECT_NAME/.config/claude${NC}"
    
    if [ "$VECTOR_DB_ENABLED" = true ] && [ "$USE_DOCKER" = true ]; then
        echo -e "  - Qdrant-Vektordatenbank: ${GRAY}http://localhost:6333${NC}"
    fi
    
    echo
    echo -e "${YELLOW}Nächste Schritte:${NC}"
    echo -e "  1. Wechseln Sie zum Projektverzeichnis:"
    echo -e "     ${GRAY}cd $INSTALL_DIR/$PROJECT_NAME${NC}"
    echo
    
    if [ "$VECTOR_DB_ENABLED" = true ] && [ "$USE_DOCKER" = true ]; then
        echo -e "  2. Starten Sie die Qdrant-Vektordatenbank (falls noch nicht geschehen):"
        echo -e "     ${GRAY}./start-qdrant.sh${NC}"
        echo
    fi
    
    if [ "$MCP_TOOLS_ENABLED" = true ]; then
        echo -e "  3. Starten Sie Claude Code mit MCP-Tools:"
        echo -e "     ${GRAY}./start-mcp-tools.sh${NC}"
        echo
    else
        echo -e "  3. Starten Sie Claude Code im Projektverzeichnis:"
        echo -e "     ${GRAY}claude${NC}"
        echo
    fi
    
    echo -e "  4. Füllen Sie die Memory-Bank mit Projektinformationen aus."
    echo
    
    echo -e "${GRAY}Installation abgeschlossen in $MINUTES Minuten und $SECONDS Sekunden.${NC}"
    echo -e "${GRAY}Logdatei: $LOG_FILE${NC}"
    
    return 0
}

# Initialisierungsprozess einrichten
setup_init_process() {
    log "INFO" "Richte Initialisierungsprozess ein..."
    
    # Initialisierungsskript erstellen
    cat > init-project.sh << EOF
#!/bin/bash
# Initialisierungsskript für $PROJECT_NAME

SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
cd "\$SCRIPT_DIR"
LOG_FILE="\$SCRIPT_DIR/logs/init-\$(date +%Y%m%d%H%M%S).log"
mkdir -p logs

# Logging-Funktion
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" | tee -a "\$LOG_FILE"
}

log "Starte Initialisierung von $PROJECT_NAME..."

# Berechtigungen aktualisieren
log "Aktualisiere Berechtigungen..."
./setup-permissions.sh

# Qdrant starten (falls aktiviert)
if [ -f "start-qdrant.sh" ]; then
    log "Prüfe Qdrant-Status..."
    if ! curl -s -f http://localhost:6333/health &> /dev/null; then
        log "Starte Qdrant..."
        ./start-qdrant.sh
    else
        log "Qdrant läuft bereits."
    fi
fi

log "Initialisierung abgeschlossen."
echo "Projekt $PROJECT_NAME wurde initialisiert und ist startklar."
EOF
    
    # Skript ausführbar machen
    chmod +x init-project.sh
    
    log "SUCCESS" "Initialisierungsprozess eingerichtet."
    return 0
}

# Hauptfunktion
main() {
    # Banner anzeigen (nur im interaktiven Modus)
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${BLUE}"
        echo "    _    ____ ___      _____           _                  "
        echo "   / \  / ___|_ _|    / / _ \ _ __ ___ (_) ___  ___| |_   "
        echo "  / _ \| |  _ | |    / / | | | '_ \` _ \| |/ _ \/ __| __|  "
        echo " / ___ \ |_| || |   / /| |_| | | | | | | |  __/ (__| |_   "
        echo "/_/   \_\____|___| /_/  \___/|_| |_| |_|_|\___|\___|\__|  "
        echo ""
        echo -e "AGI-System Master-Initialisierer v$VERSION${NC}"
        echo -e "${GRAY}$(date)${NC}"
        echo
    fi
    
    # Initialisierung des Logs
    echo "# AGI-System Master-Initialisierer Log" > "$LOG_FILE"
    echo "# $(date)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    # Parameter verarbeiten
    parse_args "$@"
    
    # Voraussetzungen prüfen
    check_prerequisites || exit 1
    
    # Übersicht über die Installation anzeigen (nur im interaktiven Modus)
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${BLUE}=============================================${NC}"
        echo -e "${BLUE}  AGI-System-Projekt-Initialisierung ${NC}"
        echo -e "${BLUE}=============================================${NC}"
        echo
        echo -e "${CYAN}Projektdetails:${NC}"
        echo -e "  Projektname:              ${CYAN}$PROJECT_NAME${NC}"
        echo -e "  Installationsverzeichnis: ${CYAN}$INSTALL_DIR/$PROJECT_NAME${NC}"
        echo -e "  MCP-Tools:                ${CYAN}$([ "$MCP_TOOLS_ENABLED" = true ] && echo "Aktiviert" || echo "Deaktiviert")${NC}"
        echo -e "  Vektordatenbank:          ${CYAN}$([ "$VECTOR_DB_ENABLED" = true ] && echo "Aktiviert" || echo "Deaktiviert")${NC}"
        echo -e "  Docker:                   ${CYAN}$([ "$USE_DOCKER" = true ] && echo "Aktiviert" || echo "Deaktiviert")${NC}"
        echo -e "  Einbettungsmodell:        ${CYAN}$EMBEDDING_MODEL${NC}"
        echo -e "  Einbettungsdimensionen:   ${CYAN}$VECTOR_DIM${NC}"
        echo
        
        echo -e "${YELLOW}Möchten Sie mit dieser Konfiguration fortfahren? (j/n)${NC}"
        read -r CONTINUE
        
        if [[ ! "$CONTINUE" =~ ^[Jj] ]]; then
            log "ERROR" "Installation abgebrochen."
            exit 1
        fi
    fi
    
    # Projektverzeichnisstruktur einrichten
    setup_project_structure || exit 1
    
    # Memory-Bank-Struktur einrichten
    setup_memory_bank || exit 1
    
    # Interaktive .about-Datei erstellen
    create_interactive_about || exit 1
    
    # Qdrant-Vektordatenbank einrichten (falls aktiviert)
    setup_qdrant
    
    # MCP-Tools einrichten (falls aktiviert)
    setup_mcp_tools
    
    # Berechtigungsverwaltung einrichten
    setup_permissions || exit 1
    
    # Initialisierungsprozess einrichten
    setup_init_process || exit 1
    
    # Zusammenfassung anzeigen
    show_summary
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?