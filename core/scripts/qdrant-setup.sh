#!/usr/bin/env bash
# ============================================================================
# Qdrant-Vektordatenbank-Setup für AGI-Projekte
# 
# Dieses Skript richtet die Qdrant-Vektordatenbank für AGI-Projekte ein und
# konfiguriert Sammlungen für semantische Suche und Kontextualisierung.
# ============================================================================

set -e

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Standardwerte
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PROJECT_DIR=""
QDRANT_PORT=6333
INTERACTIVE_MODE=true
DOCKER_COMPOSE=true
DOCKER_AVAILABLE=false
PYTHON_AVAILABLE=false
EMBEDDING_MODEL="claude-3-haiku"
EMBEDDING_DIM=1536
LOG_FILE="/tmp/qdrant-setup-$(date +%Y%m%d%H%M%S).log"

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}"
    echo "   ____    _                     _   "
    echo "  / __ \  | |                   | |  "
    echo " | |  | | | |  _ __   __ _  _ __ | |_ "
    echo " | |  | | | | | '_ \ / _\` || '__|| __|"
    echo " | |__| | | | | | | | (_| || |   | |_ "
    echo "  \___\_\ |_| |_| |_|\__,_||_|    \__|"
    echo "                                       "
    echo "  _____       _                 "
    echo " / ____|     | |                "
    echo "| (___    ___| |_ _   _ _ __    "
    echo " \___ \  / _ \ __| | | | '_ \   "
    echo " ____) ||  __/ |_| |_| | |_) |  "
    echo "|_____/  \___|\__|\__,_| .__/   "
    echo "                        | |      "
    echo "                        |_|      "
    echo -e "${NC}"
    echo -e "${GRAY}$(date)${NC}"
    echo
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

# Hilfetext anzeigen
show_help() {
    echo "Verwendung: $0 [optionen] <PROJEKTVERZEICHNIS>"
    echo
    echo "Optionen:"
    echo "  -h, --help                  Diese Hilfe anzeigen"
    echo "  -p, --port PORT             Qdrant-Port (Standard: 6333)"
    echo "  -n, --non-interactive       Nichtinteraktiver Modus (für Automatisierung)"
    echo "  -e, --embedding-model MODEL Embedding-Modell (Standard: claude-3-haiku)"
    echo "  -d, --embedding-dim DIM     Embedding-Dimension (Standard: 1536)"
    echo "  --no-docker-compose         Kein docker-compose verwenden (nur Einzelcontainer)"
    echo
    echo "Beispiele:"
    echo "  $0 /path/to/project                          # Standardkonfiguration"
    echo "  $0 --port 6334 --embedding-model text-embedding-ada-002 /path/to/project"
    echo "  $0 --non-interactive /path/to/project        # Für Skript-Integration"
    echo
}

# Funktion zur Prüfung der Abhängigkeiten
check_dependencies() {
    log "INFO" "Prüfe Abhängigkeiten..."
    
    # Prüfe Docker
    if command -v docker &> /dev/null; then
        DOCKER_AVAILABLE=true
    else
        log "ERROR" "Docker ist nicht installiert, aber für Qdrant erforderlich."
        
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${YELLOW}Docker ist für Qdrant erforderlich. Möchten Sie die Installation fortsetzen und Docker manuell installieren? (j/n)${NC}"
            read -r CONTINUE
            
            if [[ ! "$CONTINUE" =~ ^[Jj] ]]; then
                log "ERROR" "Installation abgebrochen."
                exit 1
            fi
        else
            log "ERROR" "Installation abgebrochen. Bitte installieren Sie Docker und versuchen Sie es erneut."
            exit 1
        fi
    fi
    
    # Prüfe docker-compose
    if [ "$DOCKER_COMPOSE" = true ]; then
        if ! command -v docker-compose &> /dev/null; then
            # Prüfe auf Docker Compose Plugin
            if ! docker compose version &> /dev/null; then
                log "WARNING" "docker-compose ist nicht installiert. Verwende Docker-Einzelcontainer."
                DOCKER_COMPOSE=false
            fi
        fi
    fi
    
    # Prüfe Python für Client-Skripts
    if command -v python3 &> /dev/null; then
        PYTHON_AVAILABLE=true
        
        # Prüfe qdrant-client
        if ! python3 -c "import qdrant_client" &> /dev/null 2>&1; then
            log "WARNING" "Python qdrant-client ist nicht installiert. Client-Skripts werden trotzdem generiert."
        fi
    else
        log "WARNING" "Python ist nicht installiert. Client-Skripts werden trotzdem generiert."
    fi
    
    log "SUCCESS" "Abhängigkeitsprüfung abgeschlossen."
    return 0
}

# Funktion zur Verarbeitung der Kommandozeilenargumente
process_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--port)
                shift
                QDRANT_PORT="$1"
                ;;
            -n|--non-interactive)
                INTERACTIVE_MODE=false
                ;;
            -e|--embedding-model)
                shift
                EMBEDDING_MODEL="$1"
                ;;
            -d|--embedding-dim)
                shift
                EMBEDDING_DIM="$1"
                ;;
            --no-docker-compose)
                DOCKER_COMPOSE=false
                ;;
            *)
                if [ -z "$PROJECT_DIR" ]; then
                    PROJECT_DIR="$1"
                else
                    log "ERROR" "Unbekannter Parameter: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
        shift
    done
    
    # Prüfe, ob Projektverzeichnis angegeben wurde
    if [ -z "$PROJECT_DIR" ]; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            read -p "Projektverzeichnis: " PROJECT_DIR
            
            if [ -z "$PROJECT_DIR" ]; then
                log "ERROR" "Kein Projektverzeichnis angegeben."
                exit 1
            fi
        else
            log "ERROR" "Kein Projektverzeichnis angegeben."
            show_help
            exit 1
        fi
    fi
    
    # Prüfe, ob Projektverzeichnis existiert
    if [ ! -d "$PROJECT_DIR" ]; then
        log "ERROR" "Projektverzeichnis existiert nicht: $PROJECT_DIR"
        exit 1
    fi
    
    # Prüfe Embedding-Dimensionen für bekannte Modelle
    case "$EMBEDDING_MODEL" in
        "claude-3-haiku"|"claude-3-sonnet"|"claude-3-opus")
            EMBEDDING_DIM=1536
            ;;
        "text-embedding-ada-002")
            EMBEDDING_DIM=1536
            ;;
        "text-embedding-3-small")
            EMBEDDING_DIM=1536
            ;;
        "text-embedding-3-large")
            EMBEDDING_DIM=3072
            ;;
    esac
    
    # Im interaktiven Modus nach Bestätigung fragen
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "${BLUE}Qdrant-Konfiguration:${NC}"
        echo -e "  Projektverzeichnis: ${CYAN}$PROJECT_DIR${NC}"
        echo -e "  Qdrant-Port:        ${CYAN}$QDRANT_PORT${NC}"
        echo -e "  Embedding-Modell:   ${CYAN}$EMBEDDING_MODEL${NC}"
        echo -e "  Embedding-Dimension:${CYAN}$EMBEDDING_DIM${NC}"
        echo -e "  Docker-Compose:     ${CYAN}$([ "$DOCKER_COMPOSE" = true ] && echo "Ja" || echo "Nein")${NC}"
        echo
        
        echo -e "${YELLOW}Möchten Sie mit dieser Konfiguration fortfahren? (j/n)${NC}"
        read -r CONTINUE
        
        if [[ ! "$CONTINUE" =~ ^[Jj] ]]; then
            log "ERROR" "Installation abgebrochen."
            exit 1
        fi
    fi
    
    return 0
}

# Erstelle Verzeichnisstruktur
create_directory_structure() {
    log "INFO" "Erstelle Verzeichnisstruktur..."
    
    # Verzeichnisse für Qdrant
    mkdir -p "$PROJECT_DIR/memory-bank/vector_index/embeddings"
    mkdir -p "$PROJECT_DIR/memory-bank/vector_index/collections"
    mkdir -p "$PROJECT_DIR/memory-bank/vector_index/queries"
    mkdir -p "$PROJECT_DIR/memory-bank/vector_index/scripts"
    
    # Erstelle Speicherverzeichnis für Qdrant
    mkdir -p "$PROJECT_DIR/qdrant_storage"
    
    log "SUCCESS" "Verzeichnisstruktur erstellt."
    return 0
}

# Erstelle Docker-Compose-Datei
create_docker_compose() {
    log "INFO" "Erstelle Docker-Compose-Konfiguration..."
    
    local docker_compose_file="$PROJECT_DIR/docker-compose.yml"
    
    # Falls bereits docker-compose.yml existiert, fragen, ob überschrieben werden soll
    if [ -f "$docker_compose_file" ]; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${YELLOW}docker-compose.yml existiert bereits. Möchten Sie sie überschreiben? (j/n)${NC}"
            read -r OVERWRITE
            
            if [[ ! "$OVERWRITE" =~ ^[Jj] ]]; then
                log "INFO" "Überspringe Docker-Compose-Erstellung."
                return 0
            fi
        else
            log "WARNING" "docker-compose.yml existiert bereits. Wird nicht überschrieben."
            return 0
        fi
    fi
    
    # Docker-Compose-Datei erstellen
    cat > "$docker_compose_file" << EOL
version: '3'
services:
  qdrant:
    image: qdrant/qdrant
    container_name: qdrant-$(basename "$PROJECT_DIR")
    ports:
      - "$QDRANT_PORT:6333"
      - "$((QDRANT_PORT+1)):6334"
    volumes:
      - ./qdrant_storage:/qdrant/storage
    restart: unless-stopped
    environment:
      - QDRANT_ALLOW_CORS=true
    networks:
      - agi_network

networks:
  agi_network:
    driver: bridge
EOL
    
    log "SUCCESS" "Docker-Compose-Konfiguration erstellt: $docker_compose_file"
    return 0
}

# Erstelle einzelnen Docker-Container
create_docker_container() {
    log "INFO" "Erstelle Docker-Container-Konfiguration..."
    
    local docker_script="$PROJECT_DIR/memory-bank/vector_index/scripts/start-qdrant.sh"
    
    # Startup-Skript erstellen
    cat > "$docker_script" << EOL
#!/bin/bash
# Qdrant-Vektordatenbank-Startup-Skript

# Container stoppen, falls er bereits läuft
docker stop qdrant-$(basename "$PROJECT_DIR") 2>/dev/null || true
docker rm qdrant-$(basename "$PROJECT_DIR") 2>/dev/null || true

# Container starten
docker run -d \\
  --name qdrant-$(basename "$PROJECT_DIR") \\
  -p $QDRANT_PORT:6333 \\
  -p $((QDRANT_PORT+1)):6334 \\
  -v "$(realpath "$PROJECT_DIR/qdrant_storage"):/qdrant/storage" \\
  -e QDRANT_ALLOW_CORS=true \\
  qdrant/qdrant

echo "Qdrant für $(basename "$PROJECT_DIR") gestartet auf http://localhost:$QDRANT_PORT"
echo "Weitere Informationen: $(realpath "$PROJECT_DIR/memory-bank/vector_index")"
EOL
    
    chmod +x "$docker_script"
    
    log "SUCCESS" "Docker-Container-Konfiguration erstellt: $docker_script"
    return 0
}

# Erstelle Benutzerfreundliches Startup-Skript
create_startup_script() {
    log "INFO" "Erstelle Startup-Skript..."
    
    local startup_script="$PROJECT_DIR/start-qdrant.sh"
    
    if [ "$DOCKER_COMPOSE" = true ]; then
        # Docker-Compose-Startup-Skript
        cat > "$startup_script" << EOL
#!/bin/bash
# Qdrant-Vektordatenbank-Startup-Skript

cd "\$(dirname "\$0")"

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

echo "Qdrant für $(basename "$PROJECT_DIR") gestartet auf http://localhost:$QDRANT_PORT"
echo "API-Endpunkt: http://localhost:$QDRANT_PORT"
echo "Dashboard: http://localhost:$QDRANT_PORT/dashboard"
echo "Weitere Informationen: $(realpath "$PROJECT_DIR/memory-bank/vector_index")"
EOL
    else
        # Direktes Docker-Container-Startup-Skript
        cat > "$startup_script" << EOL
#!/bin/bash
# Qdrant-Vektordatenbank-Startup-Skript

cd "\$(dirname "\$0")"
./memory-bank/vector_index/scripts/start-qdrant.sh
EOL
    fi
    
    chmod +x "$startup_script"
    
    # Stopp-Skript erstellen
    local stop_script="$PROJECT_DIR/stop-qdrant.sh"
    
    if [ "$DOCKER_COMPOSE" = true ]; then
        # Docker-Compose-Stopp-Skript
        cat > "$stop_script" << EOL
#!/bin/bash
# Qdrant-Vektordatenbank-Stopp-Skript

cd "\$(dirname "\$0")"

# Prüfen, ob Docker-Compose verfügbar ist
if command -v docker-compose &> /dev/null; then
    echo "Stoppe Qdrant mit docker-compose..."
    docker-compose down
elif docker compose version &> /dev/null; then
    echo "Stoppe Qdrant mit Docker Compose Plugin..."
    docker compose down
else
    echo "Docker Compose ist nicht verfügbar. Stoppe Docker-Container..."
    docker stop qdrant-$(basename "$PROJECT_DIR") 2>/dev/null || true
fi

echo "Qdrant für $(basename "$PROJECT_DIR") gestoppt."
EOL
    else
        # Direktes Docker-Container-Stopp-Skript
        cat > "$stop_script" << EOL
#!/bin/bash
# Qdrant-Vektordatenbank-Stopp-Skript

docker stop qdrant-$(basename "$PROJECT_DIR") 2>/dev/null || true
echo "Qdrant für $(basename "$PROJECT_DIR") gestoppt."
EOL
    fi
    
    chmod +x "$stop_script"
    
    log "SUCCESS" "Startup- und Stopp-Skripte erstellt."
    return 0
}

# Erstelle Python-Skripte für Qdrant-Client
create_python_scripts() {
    log "INFO" "Erstelle Python-Skripte für Qdrant-Client..."
    
    local scripts_dir="$PROJECT_DIR/memory-bank/vector_index/scripts"
    local project_name=$(basename "$PROJECT_DIR")
    
    # Skript zum Erstellen von Sammlungen
    cat > "$scripts_dir/create_collections.py" << EOL
#!/usr/bin/env python3
# Skript zum Erstellen von Qdrant-Sammlungen für $project_name

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import argparse
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Erstellt Qdrant-Sammlungen für $project_name")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=$QDRANT_PORT, type=int, help="Qdrant-Port")
        parser.add_argument("--force", action="store_true", help="Sammlungen überschreiben, falls sie existieren")
        return parser.parse_args()
    
    def create_collections(args):
        try:
            client = QdrantClient(args.host, port=args.port)
            
            # Sammlungen definieren
            collections = [
                "project_context",
                "code_embeddings",
                "documentation"
            ]
            
            # Sammlungen erstellen
            for collection in collections:
                try:
                    # Prüfen, ob Sammlung bereits existiert
                    try:
                        info = client.get_collection(collection_name=collection)
                        if args.force:
                            print(f"Sammlung '{collection}' existiert bereits, wird neu erstellt...")
                            client.delete_collection(collection_name=collection)
                        else:
                            print(f"Sammlung '{collection}' existiert bereits, wird übersprungen.")
                            continue
                    except Exception:
                        pass # Sammlung existiert nicht
                    
                    # Sammlung erstellen
                    client.create_collection(
                        collection_name=collection,
                        vectors_config=models.VectorParams(
                            size=$EMBEDDING_DIM,  # Dimension des Einbettungsmodells
                            distance=models.Distance.COSINE
                        )
                    )
                    print(f"Sammlung '{collection}' erfolgreich erstellt.")
                except Exception as e:
                    print(f"Fehler beim Erstellen der Sammlung '{collection}': {e}")
            
            print("Sammlungserstellung abgeschlossen.")
            return True
            
        except Exception as e:
            print(f"Fehler bei der Verbindung zur Qdrant-Datenbank: {e}")
            return False
    
    if __name__ == "__main__":
        args = parse_args()
        success = create_collections(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
EOL
    
    # Skript zum Hochladen von Einbettungen
    cat > "$scripts_dir/upload_embeddings.py" << EOL
#!/usr/bin/env python3
# Skript zum Hochladen von Einbettungen für $project_name

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import json
    import os
    import argparse
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Lädt Einbettungen für $project_name in Qdrant hoch")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=$QDRANT_PORT, type=int, help="Qdrant-Port")
        parser.add_argument("--collection", required=True, help="Name der Sammlung")
        parser.add_argument("--embeddings", required=True, help="Pfad zur JSON-Datei mit Einbettungen")
        return parser.parse_args()
    
    def upload_embeddings(args):
        try:
            client = QdrantClient(args.host, port=args.port)
            
            # Prüfen, ob Datei existiert
            if not os.path.isfile(args.embeddings):
                print(f"Fehler: Datei {args.embeddings} existiert nicht.")
                return False
            
            # Prüfen, ob Sammlung existiert
            try:
                client.get_collection(collection_name=args.collection)
            except Exception:
                print(f"Fehler: Sammlung {args.collection} existiert nicht.")
                return False
            
            # Einbettungen laden
            with open(args.embeddings, "r") as f:
                embeddings_data = json.load(f)
            
            # Punkte erstellen
            points = []
            for i, item in enumerate(embeddings_data):
                points.append(
                    models.PointStruct(
                        id=i if "id" not in item else item["id"],
                        vector=item["vector"],
                        payload=item["payload"] if "payload" in item else {}
                    )
                )
            
            # Einbettungen hochladen
            client.upsert(
                collection_name=args.collection,
                points=points
            )
            
            print(f"{len(points)} Einbettungen erfolgreich in Sammlung '{args.collection}' hochgeladen.")
            return True
        
        except Exception as e:
            print(f"Fehler beim Hochladen der Einbettungen: {e}")
            return False
    
    if __name__ == "__main__":
        args = parse_args()
        success = upload_embeddings(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
EOL
    
    # Skript für semantische Suche
    cat > "$scripts_dir/semantic_search.py" << EOL
#!/usr/bin/env python3
# Skript für semantische Suche in $project_name

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import argparse
    import json
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Semantische Suche für $project_name")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=$QDRANT_PORT, type=int, help="Qdrant-Port")
        parser.add_argument("--collection", required=True, help="Name der Sammlung")
        parser.add_argument("--vector", required=True, help="Pfad zur JSON-Datei mit Suchvektor")
        parser.add_argument("--limit", default=5, type=int, help="Anzahl der Ergebnisse")
        parser.add_argument("--output", help="Pfad zur Ausgabedatei (optional)")
        return parser.parse_args()
    
    def semantic_search(args):
        try:
            client = QdrantClient(args.host, port=args.port)
            
            # Vektor laden
            with open(args.vector, "r") as f:
                vector_data = json.load(f)
            
            query_vector = vector_data["vector"]
            
            # Suche durchführen
            results = client.search(
                collection_name=args.collection,
                query_vector=query_vector,
                limit=args.limit
            )
            
            # Ergebnisse formatieren
            formatted_results = []
            for result in results:
                formatted_results.append({
                    "id": result.id,
                    "score": result.score,
                    "payload": result.payload
                })
            
            # Ausgabe
            if args.output:
                with open(args.output, "w") as f:
                    json.dump(formatted_results, f, indent=2)
                print(f"Ergebnisse in {args.output} gespeichert.")
            else:
                print(json.dumps(formatted_results, indent=2))
            
            return True
        
        except Exception as e:
            print(f"Fehler bei der semantischen Suche: {e}")
            return False
    
    if __name__ == "__main__":
        args = parse_args()
        success = semantic_search(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
EOL
    
    # Skript für Projektindexierung
    cat > "$scripts_dir/index_project.py" << EOL
#!/usr/bin/env python3
# Skript zur Indexierung des $project_name-Projekts

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import os
    import argparse
    import json
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Indexiert das $project_name-Projekt")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=$QDRANT_PORT, type=int, help="Qdrant-Port")
        parser.add_argument("--project-dir", default="$PROJECT_DIR", help="Projektverzeichnis")
        parser.add_argument("--embeddings-only", action="store_true", help="Nur Einbettungen erstellen, nicht hochladen")
        parser.add_argument("--openai-api-key", help="OpenAI API-Schlüssel für Einbettungen")
        return parser.parse_args()
    
    def indexing_placeholder(args):
        print("Hinweis: Dies ist ein Platzhalter für die tatsächliche Indexierung.")
        print("Um das Projekt zu indexieren, müssen Sie:")
        print("1. Ein Einbettungsmodell auswählen oder bereitstellen")
        print("2. Den Code implementieren, um Projektdateien zu durchsuchen")
        print("3. Einbettungen für die Dateien erstellen")
        print("4. Die Einbettungen in Qdrant hochladen")
        print()
        print("Um die Einbettungen mit OpenAI zu erstellen, führen Sie aus:")
        print("pip install openai")
        print("./index_project.py --openai-api-key=YOUR_API_KEY")
        print()
        print("Alternativ können Sie Claude oder ein anderes Modell für Einbettungen verwenden.")
        return True
    
    if __name__ == "__main__":
        args = parse_args()
        success = indexing_placeholder(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
EOL
    
    # Alle Skripte ausführbar machen
    chmod +x "$scripts_dir/create_collections.py"
    chmod +x "$scripts_dir/upload_embeddings.py"
    chmod +x "$scripts_dir/semantic_search.py"
    chmod +x "$scripts_dir/index_project.py"
    
    log "SUCCESS" "Python-Skripte für Qdrant-Client erstellt."
    return 0
}

# Erstelle Beispiel-Einbettungen
create_example_embeddings() {
    log "INFO" "Erstelle Beispiel-Einbettungen..."
    
    local embeddings_dir="$PROJECT_DIR/memory-bank/vector_index/embeddings"
    local project_name=$(basename "$PROJECT_DIR")
    
    # Beispiel für Memory-Bank-Einbettungen
    cat > "$embeddings_dir/memory_bank_examples.json" << EOL
[
  {
    "id": 1,
    "vector": $(python3 -c "import json; print(json.dumps([0.1] * $EMBEDDING_DIM))"),
    "payload": {
      "text": "Das $project_name-Projekt verwendet eine Memory-Bank zur Speicherung von Kontextinformationen.",
      "file": "memory-bank/projectbrief.md",
      "type": "memory_bank"
    }
  },
  {
    "id": 2,
    "vector": $(python3 -c "import json; print(json.dumps([0.2] * $EMBEDDING_DIM))"),
    "payload": {
      "text": "Die Systemarchitektur basiert auf einem modularen Ansatz mit klarer Trennung von Geschäftslogik und Präsentation.",
      "file": "memory-bank/systemPatterns.md",
      "type": "memory_bank"
    }
  },
  {
    "id": 3,
    "vector": $(python3 -c "import json; print(json.dumps([0.3] * $EMBEDDING_DIM))"),
    "payload": {
      "text": "Das Projekt verwendet $EMBEDDING_MODEL als Embedding-Modell mit $EMBEDDING_DIM Dimensionen.",
      "file": "memory-bank/techContext.md",
      "type": "memory_bank"
    }
  }
]
EOL
    
    # Beispiel für Suchvektoren
    local queries_dir="$PROJECT_DIR/memory-bank/vector_index/queries"
    
    cat > "$queries_dir/memory_bank_query.json" << EOL
{
  "vector": $(python3 -c "import json; print(json.dumps([0.2] * $EMBEDDING_DIM))")
}
EOL
    
    log "SUCCESS" "Beispiel-Einbettungen erstellt."
    return 0
}

# Erstelle README für Vektordatenbank
create_vector_db_readme() {
    log "INFO" "Erstelle README für Vektordatenbank..."
    
    local readme_file="$PROJECT_DIR/memory-bank/vector_index/README.md"
    local project_name=$(basename "$PROJECT_DIR")
    
    cat > "$readme_file" << EOL
# Qdrant-Vektordatenbank für $project_name

## Übersicht

Diese Vektordatenbank speichert semantische Einbettungen für das Projekt, um intelligente Suche und Kontextabruf zu ermöglichen.

## Konfiguration

- **Host**: localhost
- **Port**: $QDRANT_PORT
- **API-Endpunkt**: http://localhost:$QDRANT_PORT
- **Dashboard**: http://localhost:$QDRANT_PORT/dashboard
- **Embedding-Modell**: $EMBEDDING_MODEL
- **Embedding-Dimensionen**: $EMBEDDING_DIM

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

### Sammlungen erstellen

\`\`\`bash
# Mit Python-Skript
python3 ./memory-bank/vector_index/scripts/create_collections.py

# Zum Überschreiben existierender Sammlungen
python3 ./memory-bank/vector_index/scripts/create_collections.py --force
\`\`\`

### Einbettungen hochladen

\`\`\`bash
# Beispiel-Einbettungen hochladen
python3 ./memory-bank/vector_index/scripts/upload_embeddings.py --collection project_context --embeddings ./memory-bank/vector_index/embeddings/memory_bank_examples.json
\`\`\`

### Semantische Suche

\`\`\`bash
# Beispiel-Suche
python3 ./memory-bank/vector_index/scripts/semantic_search.py --collection project_context --vector ./memory-bank/vector_index/queries/memory_bank_query.json
\`\`\`

## Python-Client-Beispiel

\`\`\`python
from qdrant_client import QdrantClient
from qdrant_client.http import models

# Client initialisieren
client = QdrantClient("localhost", port=$QDRANT_PORT)

# Sammlung erstellen
client.create_collection(
    collection_name="project_context",
    vectors_config=models.VectorParams(size=$EMBEDDING_DIM, distance=models.Distance.COSINE),
)

# Punkt hinzufügen
client.upsert(
    collection_name="project_context",
    points=[
        models.PointStruct(
            id=1,
            vector=[0.1, 0.2, ...],  # $EMBEDDING_DIM-dimensionaler Vektor
            payload={"text": "Projektkontext für $project_name"}
        )
    ]
)

# Suche
results = client.search(
    collection_name="project_context",
    query_vector=[0.1, 0.2, ...],  # $EMBEDDING_DIM-dimensionaler Vektor
    limit=5
)
\`\`\`

## Integration mit Claude und MCP-Tools

Diese Vektordatenbank kann nahtlos mit Claude und MCP-Tools für semantische Suche und Kontextualisierung integriert werden:

1. **Claude Code**: Verwenden Sie Claude Code mit Kontexterkennung
2. **Memory-Bank MCP**: Verwenden Sie den Memory-Bank MCP für automatische Indexierung
3. **Desktop-Commander**: Verwenden Sie den Desktop-Commander für Dateizugriff

## Abhängigkeiten installieren

\`\`\`bash
# Qdrant-Client installieren
pip install qdrant-client

# OpenAI-Client für Einbettungen (optional)
pip install openai
\`\`\`

## Weitere Ressourcen

- [Qdrant-Dokumentation](https://qdrant.tech/documentation/)
- [Python-Client-API](https://qdrant.github.io/qdrant-client/)
- [REST-API-Referenz](https://qdrant.github.io/qdrant/redoc/index.html)
EOL
    
    log "SUCCESS" "README für Vektordatenbank erstellt: $readme_file"
    return 0
}

# Starte Qdrant-Container
start_qdrant() {
    if [ "$INTERACTIVE_MODE" = false ]; then
        log "INFO" "Nichtinteraktiver Modus. Qdrant wird nicht gestartet."
        return 0
    fi
    
    echo -e "${YELLOW}Möchten Sie Qdrant jetzt starten? (j/n)${NC}"
    read -r START_NOW
    
    if [[ ! "$START_NOW" =~ ^[Jj] ]]; then
        log "INFO" "Qdrant wird nicht gestartet."
        return 0
    fi
    
    log "INFO" "Starte Qdrant..."
    
    cd "$PROJECT_DIR"
    
    if [ "$DOCKER_COMPOSE" = true ]; then
        # Mit Docker-Compose starten
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        elif docker compose version &> /dev/null; then
            docker compose up -d
        else
            # Fallback auf direkten Docker-Container
            bash "$PROJECT_DIR/memory-bank/vector_index/scripts/start-qdrant.sh"
        fi
    else
        # Mit Docker-Container starten
        bash "$PROJECT_DIR/memory-bank/vector_index/scripts/start-qdrant.sh"
    fi
    
    # Prüfen, ob Container läuft
    sleep 2
    if docker ps | grep -q "qdrant-$(basename "$PROJECT_DIR")"; then
        log "SUCCESS" "Qdrant wurde erfolgreich gestartet!"
        log "SUCCESS" "Dashboard verfügbar unter: http://localhost:$QDRANT_PORT/dashboard"
    else
        log "ERROR" "Qdrant konnte nicht gestartet werden. Bitte überprüfen Sie die Docker-Logs."
        return 1
    fi
    
    return 0
}

# Erstelle Sammlungen
create_collections() {
    if [ "$INTERACTIVE_MODE" = false ]; then
        log "INFO" "Nichtinteraktiver Modus. Sammlungen werden nicht erstellt."
        return 0
    fi
    
    if [ "$PYTHON_AVAILABLE" = false ]; then
        log "WARNING" "Python ist nicht installiert. Sammlungen können nicht automatisch erstellt werden."
        return 0
    fi
    
    echo -e "${YELLOW}Möchten Sie die Sammlungen jetzt erstellen? (j/n)${NC}"
    read -r CREATE_COLLECTIONS
    
    if [[ ! "$CREATE_COLLECTIONS" =~ ^[Jj] ]]; then
        log "INFO" "Sammlungen werden nicht erstellt."
        return 0
    fi
    
    log "INFO" "Erstelle Sammlungen..."
    
    # Prüfen, ob qdrant-client installiert ist
    if ! python3 -c "import qdrant_client" &> /dev/null 2>&1; then
        log "WARNING" "qdrant-client ist nicht installiert."
        
        echo -e "${YELLOW}qdrant-client ist nicht installiert. Möchten Sie es jetzt installieren? (j/n)${NC}"
        read -r INSTALL_CLIENT
        
        if [[ "$INSTALL_CLIENT" =~ ^[Jj] ]]; then
            log "INFO" "Installiere qdrant-client..."
            pip install qdrant-client
        else
            log "WARNING" "qdrant-client wird nicht installiert. Sammlungen können nicht erstellt werden."
            return 0
        fi
    fi
    
    # Sammlungen erstellen
    cd "$PROJECT_DIR"
    python3 ./memory-bank/vector_index/scripts/create_collections.py --force
    
    log "SUCCESS" "Sammlungen wurden erstellt."
    return 0
}

# Zusammenfassung anzeigen
show_summary() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GREEN}Qdrant-Vektordatenbank erfolgreich eingerichtet!${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo
    echo -e "${CYAN}Konfigurationsdetails:${NC}"
    echo -e "  Projektverzeichnis:     ${CYAN}$PROJECT_DIR${NC}"
    echo -e "  Qdrant-Port:            ${CYAN}$QDRANT_PORT${NC}"
    echo -e "  Embedding-Modell:       ${CYAN}$EMBEDDING_MODEL${NC}"
    echo -e "  Embedding-Dimensionen:  ${CYAN}$EMBEDDING_DIM${NC}"
    echo
    echo -e "${YELLOW}Nächste Schritte:${NC}"
    echo -e "  1. Starte Qdrant mit:"
    echo -e "     ${CYAN}cd $PROJECT_DIR && ./start-qdrant.sh${NC}"
    echo
    echo -e "  2. Erstelle Sammlungen mit:"
    echo -e "     ${CYAN}python3 ./memory-bank/vector_index/scripts/create_collections.py${NC}"
    echo
    echo -e "  3. Lade Einbettungen hoch mit:"
    echo -e "     ${CYAN}python3 ./memory-bank/vector_index/scripts/upload_embeddings.py --collection <collection> --embeddings <file>${NC}"
    echo
    echo -e "${GRAY}Die vollständige Dokumentation befindet sich in:${NC}"
    echo -e "${GRAY}$PROJECT_DIR/memory-bank/vector_index/README.md${NC}"
    echo
    
    return 0
}

# Hauptfunktion
main() {
    # Anzeige des Banners
    show_banner
    
    # Initialisierung des Logs
    echo "# Qdrant-Vektordatenbank-Setup Log" > "$LOG_FILE"
    echo "# $(date)" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
    
    # Parameter verarbeiten
    process_args "$@"
    
    # Abhängigkeiten prüfen
    check_dependencies || exit 1
    
    # Verzeichnisstruktur erstellen
    create_directory_structure || exit 1
    
    # Docker-Konfiguration erstellen
    if [ "$DOCKER_COMPOSE" = true ]; then
        create_docker_compose
    else
        create_docker_container
    fi
    
    # Startup-Skripte erstellen
    create_startup_script
    
    # Python-Skripte erstellen
    create_python_scripts
    
    # Beispiel-Einbettungen erstellen
    create_example_embeddings
    
    # README erstellen
    create_vector_db_readme
    
    # Qdrant starten (optional)
    start_qdrant
    
    # Sammlungen erstellen (optional)
    create_collections
    
    # Zusammenfassung anzeigen
    show_summary
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?