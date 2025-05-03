#!/usr/bin/env bash
# ============================================================================
# AGI-System Host-Server für Master-Initialisierer
# 
# Dieses Skript richtet einen einfachen HTTP-Server ein, um den Master-Initialisierer
# für die Installation über curl bereitzustellen.
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
PORT=8000
HOST="localhost"
SERVE_DIR="/tmp/agi-system-host"
MASTER_INIT="$SCRIPT_DIR/master-init.sh"
USE_NGINX=false
DOMAIN=""

# Funktion zur Anzeige der Verwendung
usage() {
    cat << EOF
Verwendung: $0 [Optionen]

Optionen:
  -h, --help                 Diese Hilfe anzeigen
  -p, --port PORT            HTTP-Serverport (Standard: $PORT)
  --host HOST                Host-Adresse (Standard: $HOST)
  --nginx                    Nginx für die Bereitstellung verwenden
  --domain DOMAIN            Domainname für Nginx-Konfiguration
  --serve-dir DIR            Verzeichnis für den HTTP-Server (Standard: $SERVE_DIR)

Beispiel:
  $0 --port 8080
  $0 --nginx --domain agi-tools.example.com
EOF
}

# Argumente verarbeiten
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -p|--port)
                shift
                PORT="$1"
                ;;
            --host)
                shift
                HOST="$1"
                ;;
            --serve-dir)
                shift
                SERVE_DIR="$1"
                ;;
            --nginx)
                USE_NGINX=true
                ;;
            --domain)
                shift
                DOMAIN="$1"
                ;;
            *)
                echo -e "${RED}Fehler: Unbekannte Option $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done

    # Wenn Nginx verwendet wird, muss eine Domain angegeben werden
    if [ "$USE_NGINX" = true ] && [ -z "$DOMAIN" ]; then
        echo -e "${RED}Fehler: Bei Verwendung von Nginx muss eine Domain mit --domain angegeben werden.${NC}" >&2
        usage
        exit 1
    fi
}

# Überprüfen, ob der Master-Initialisierer existiert
check_master_init() {
    if [ ! -f "$MASTER_INIT" ]; then
        echo -e "${RED}Fehler: Master-Initialisierer nicht gefunden: $MASTER_INIT${NC}" >&2
        exit 1
    fi
}

# Server-Verzeichnis vorbereiten
prepare_server_dir() {
    echo -e "${BLUE}Bereite Server-Verzeichnis vor...${NC}"
    
    mkdir -p "$SERVE_DIR"
    cp "$MASTER_INIT" "$SERVE_DIR/master-init.sh"
    chmod 644 "$SERVE_DIR/master-init.sh"
    
    # Index-Datei mit Installationsanleitung erstellen
    cat > "$SERVE_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AGI-System-Installer</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        pre {
            background-color: #f6f8fa;
            border-radius: 6px;
            padding: 16px;
            overflow: auto;
        }
        code {
            font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
        }
        h1, h2 {
            border-bottom: 1px solid #eaecef;
            padding-bottom: 0.3em;
        }
        .note {
            background-color: #fffbdd;
            border-left: 4px solid #efc554;
            padding: 1em;
        }
    </style>
</head>
<body>
    <h1>AGI-System-Installer</h1>
    
    <p>Willkommen beim AGI-System-Installer. Mit diesem Tool können Sie schnell ein neues AGI-System-Projekt initialisieren.</p>
    
    <h2>Installation über curl</h2>
    
    <p>Führen Sie den folgenden Befehl aus, um ein neues Projekt zu erstellen:</p>
    
    <pre><code>curl -sSfL http://${HOST}:${PORT}/master-init.sh | bash -s -- --project PROJEKTNAME</code></pre>
    
    <p>Ersetzen Sie <strong>PROJEKTNAME</strong> mit dem Namen Ihres Projekts.</p>
    
    <h2>Optionen</h2>
    
    <p>Der Master-Initialisierer unterstützt verschiedene Optionen:</p>
    
    <pre><code>--project PROJEKT     Projektname (erforderlich)
--dir VERZEICHNIS     Installationsverzeichnis
--no-mcp-tools        MCP-Tools-Integration deaktivieren
--no-vector-db        Vektordatenbank-Integration deaktivieren
--no-docker           Keine Docker-Container verwenden</code></pre>
    
    <div class="note">
        <p><strong>Hinweis:</strong> Es wird empfohlen, das Skript vor der Ausführung zu prüfen:</p>
        <pre><code>curl -sSfL http://${HOST}:${PORT}/master-init.sh > master-init.sh
cat master-init.sh  # Überprüfen Sie den Inhalt
bash master-init.sh --project PROJEKTNAME</code></pre>
    </div>
    
    <h2>Dokumentation</h2>
    
    <p>Detaillierte Dokumentation finden Sie im <a href="https://github.com/user/AGI-System-Public" target="_blank">GitHub-Repository</a>.</p>
    
    <footer>
        <p>AGI-System Master-Initialisierer © $(date +%Y)</p>
    </footer>
</body>
</html>
EOF
    
    # Beschreibungsdatei für die Installation erstellen
    cat > "$SERVE_DIR/README.txt" << EOF
AGI-System Master-Initialisierer
================================

Installation über curl:

curl -sSfL http://${HOST}:${PORT}/master-init.sh | bash -s -- --project PROJEKTNAME

Ersetzen Sie PROJEKTNAME mit dem Namen Ihres Projekts.

Weitere Optionen:

--dir VERZEICHNIS     Installationsverzeichnis
--no-mcp-tools        MCP-Tools-Integration deaktivieren
--no-vector-db        Vektordatenbank-Integration deaktivieren
--no-docker           Keine Docker-Container verwenden

Weitere Informationen finden Sie auf der Webseite unter http://${HOST}:${PORT}/
EOF
    
    echo -e "${GREEN}Server-Verzeichnis vorbereitet: $SERVE_DIR${NC}"
}

# Python-HTTP-Server starten
start_python_server() {
    echo -e "${BLUE}Starte Python-HTTP-Server auf Port $PORT...${NC}"
    
    # Prüfen, ob Python verfügbar ist
    if command -v python3 &> /dev/null; then
        cd "$SERVE_DIR"
        
        echo -e "${GREEN}Server gestartet auf http://$HOST:$PORT/${NC}"
        echo -e "${YELLOW}Drücken Sie Strg+C, um den Server zu beenden.${NC}"
        echo -e "${BLUE}Installation mit:${NC}"
        echo -e "${CYAN}curl -sSfL http://$HOST:$PORT/master-init.sh | bash -s -- --project PROJEKTNAME${NC}"
        
        python3 -m http.server "$PORT" --bind "$HOST"
    else
        echo -e "${RED}Fehler: Python 3 ist nicht installiert.${NC}" >&2
        exit 1
    fi
}

# Nginx-Server konfigurieren
setup_nginx() {
    echo -e "${BLUE}Konfiguriere Nginx für Domain $DOMAIN...${NC}"
    
    # Prüfen, ob Nginx installiert ist
    if ! command -v nginx &> /dev/null; then
        echo -e "${RED}Fehler: Nginx ist nicht installiert.${NC}" >&2
        exit 1
    fi
    
    # Prüfen, ob als Root ausgeführt wird
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Fehler: Für die Nginx-Konfiguration sind Root-Rechte erforderlich.${NC}" >&2
        echo -e "${YELLOW}Führen Sie das Skript mit sudo aus.${NC}" >&2
        exit 1
    fi
    
    # Nginx-Konfiguration erstellen
    local nginx_conf="/etc/nginx/sites-available/agi-system-host"
    
    cat > "$nginx_conf" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $SERVE_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    
    # Konfiguration aktivieren und Nginx neu starten
    ln -sf "$nginx_conf" /etc/nginx/sites-enabled/
    nginx -t
    systemctl restart nginx
    
    echo -e "${GREEN}Nginx konfiguriert für http://$DOMAIN/${NC}"
    echo -e "${BLUE}Installation mit:${NC}"
    echo -e "${CYAN}curl -sSfL http://$DOMAIN/master-init.sh | bash -s -- --project PROJEKTNAME${NC}"
}

# Hauptfunktion
main() {
    # Banner anzeigen
    echo -e "${BLUE}"
    echo "    _    ____ ___      _____           _                  "
    echo "   / \  / ___|_ _|    / / _ \ _ __ ___ (_) ___  ___| |_   "
    echo "  / _ \| |  _ | |    / / | | | '_ \` _ \| |/ _ \/ __| __|  "
    echo " / ___ \ |_| || |   / /| |_| | | | | | | |  __/ (__| |_   "
    echo "/_/   \_\____|___| /_/  \___/|_| |_| |_|_|\___|\___|\__|  "
    echo ""
    echo -e "AGI-System Master-Initialisierer Host-Server${NC}"
    echo -e "${GRAY}$(date)${NC}"
    echo
    
    # Parameter verarbeiten
    parse_args "$@"
    
    # Prüfen, ob der Master-Initialisierer existiert
    check_master_init
    
    # Server-Verzeichnis vorbereiten
    prepare_server_dir
    
    # Server starten
    if [ "$USE_NGINX" = true ]; then
        setup_nginx
    else
        start_python_server
    fi
    
    return 0
}

# Hauptfunktion aufrufen
main "$@"
exit $?