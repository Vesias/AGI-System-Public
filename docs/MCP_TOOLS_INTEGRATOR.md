# MCP-Tools-Integrator Guide

Dieses Dokument beschreibt den MCP-Tools-Integrator, einen umfassenden Ansatz zur Projektinitialisierung mit vollständiger MCP-Tools-Integration, Docker-Container-Management und Vektordatenbank-Einrichtung.

## Übersicht

Der MCP-Tools-Integrator ermöglicht die Erstellung eines vollständig konfigurierten AGI-System-Projekts mit nur einem Befehl. Er kombiniert die Funktionalität mehrerer Skripte in einem einzigen Master-Skript, das folgende Komponenten einrichtet:

- **Vollständige Verzeichnisstruktur** mit Memory-Bank und Konfigurationsverzeichnissen
- **Memory-Bank-System** für strukturierte Projektdokumentation
- **MCP-Tools-Integration** mit Desktop Commander, Memory Bank, Browser Tools und mehr
- **Qdrant-Vektordatenbank** für semantische Suche und Einbettungen
- **SentenceTransformers-Integration** für Texteinbettungen
- **Automatische Berechtigungsverwaltung** für Dateien und Verzeichnisse
- **Interaktive .about-Datei** für Projektkonfiguration

## Installation

### Lokale Installation

```bash
# Klonen des Repositories
git clone https://github.com/Vesias/AGI-System-Public.git
cd AGI-System-Public

# Direktes Ausführen des Master-Initialisierers
./core/scripts/master-init.sh --project PROJEKTNAME
```

### Remote-Installation via Curl

```bash
# Einrichtung eines neuen Projekts mit einem einzigen Befehl
curl -sSfL https://raw.githubusercontent.com/Vesias/AGI-System-Public/main/core/scripts/master-init.sh | bash -s -- --project PROJEKTNAME
```

## Konfigurationsoptionen

Der Master-Initialisierer bietet verschiedene Konfigurationsoptionen:

```
Optionen:
  -h, --help                Diese Hilfe anzeigen
  -p, --project PROJEKT     Projektname (erforderlich)
  -d, --dir VERZEICHNIS     Installationsverzeichnis (Standard: $HOME/AGI-Projekte)
  -n, --non-interactive     Nichtinteraktiver Modus (für Automatisierung)
  --no-mcp-tools            MCP-Tools-Integration deaktivieren
  --no-vector-db           Vektordatenbank-Integration deaktivieren
  --no-docker              Keine Docker-Container verwenden
  --embedding-model MODELL  Einbettungsmodell (Standard: claude-3-haiku)
  --embedding-dim DIM      Einbettungsdimensionen (Standard: 1536)
```

## Architektur

Der MCP-Tools-Integrator besteht aus drei Hauptkomponenten:

1. **master-init.sh**: Das Hauptskript zur Projekterstellung und -konfiguration
2. **host.sh**: Ein Hosting-Skript für die Bereitstellung des Master-Initialisierers via HTTP
3. **test-install.sh**: Ein Testskript zur Validierung der Installationsprozesses

### master-init.sh

Das Herzstück des Integrators ist das `master-init.sh`-Skript, das die Projekterstellung orchestriert. Es führt folgende Schritte aus:

1. Überprüfung der Systemvoraussetzungen
2. Einrichtung der Projektverzeichnisstruktur
3. Erstellung der Memory-Bank-Struktur
4. Generierung der interaktiven .about-Datei
5. Einrichtung der Qdrant-Vektordatenbank (optional)
6. Konfiguration der MCP-Tools (optional)
7. Einrichtung der Berechtigungsverwaltung
8. Erstellung eines Initialisierungsprozesses für Projekte

### host.sh

Das `host.sh`-Skript richtet einen HTTP-Server ein, um den Master-Initialisierer für die Installation über curl bereitzustellen. Es unterstützt:

- Einfachen Python-basierten HTTP-Server für Entwicklung und Tests
- Nginx-Integration für Produktionsumgebungen
- Anpassbare Host- und Port-Konfigurationen

### test-install.sh

Das `test-install.sh`-Skript validiert den Installationsprozess, indem es:

1. Eine Testumgebung vorbereitet
2. Den Master-Initialisierer ausführt
3. Die erzeugte Projektstruktur überprüft
4. Das Ergebnis berichtet

## Komponenten im Detail

### Memory-Bank-System

Die Memory-Bank dient als strukturierte Dokumentation für das Projekt und enthält folgende Dateien:

- **projectbrief.md**: Grundlegende Projektdefinition und Ziele
- **productContext.md**: Zweck und Problemlösung des Projekts
- **activeContext.md**: Aktueller Arbeitsfokus und nächste Schritte
- **systemPatterns.md**: Systemarchitektur und Design-Patterns
- **techContext.md**: Verwendete Technologien und technische Details
- **progress.md**: Aktueller Status und Fortschritt
- **.clauderules**: Spezifische Regeln und Erkenntnisse für Claude

### MCP-Tools-Integration

Der Integrator richtet folgende MCP-Tools ein und konfiguriert sie für das Projekt:

- **desktop-commander**: Dateisystem- und Shell-Operationen
- **memory-bank**: Memory-Bank-Verwaltung
- **marketing-tools**: Marketing-Analyse und -Tools
- **browser-tools**: Web-Recherche und -Automatisierung
- **toolbox**: Allgemeine KI-Tools und Hilfsprogramme

### Qdrant-Vektordatenbank

Für semantische Suche und Kontextualisierung wird eine Qdrant-Vektordatenbank eingerichtet mit:

- Docker-Container-Konfiguration
- Python-Utilities für Einbettungen
- Standardsammlungen für Projektkontexte
- Integration mit SentenceTransformers

## Nutzung nach der Installation

Nach der Installation des Projekts können Sie:

### 1. Qdrant-Vektordatenbank starten

```bash
cd PROJEKTNAME
./start-qdrant.sh
```

### 2. Claude Code mit MCP-Tools starten

```bash
cd PROJEKTNAME
./start-mcp-tools.sh
```

### 3. Projekt bei Bedarf neu initialisieren

```bash
cd PROJEKTNAME
./init-project.sh
```

## Projektstrukturbeschreibung

Nach der Installation hat Ihr Projekt folgende Struktur:

```
PROJEKTNAME/
├── .about.interactive         # Projektkonfiguration im JSON-Format
├── .claude/
│   └── CLAUDE.md              # Claude-spezifische Projektrichtlinien
├── .config/
│   ├── claude/                # Claude-Konfiguration
│   │   └── mcpservers.json    # MCP-Tools-Konfiguration
│   └── qdrant/                # Qdrant-Konfiguration
│       └── config.yaml        # Qdrant-Einstellungen
├── APP/                       # Anwendungscode
├── MARKETING/                 # Marketingmaterialien
├── FINANCE/                   # Finanzielle Dokumente
├── DOCS/                      # Projektdokumentation
├── memory-bank/               # Memory-Bank-System
│   ├── projectbrief.md        # Projektbeschreibung
│   ├── productContext.md      # Produktkontext
│   ├── activeContext.md       # Aktueller Fokus
│   ├── systemPatterns.md      # Architekturmuster
│   ├── techContext.md         # Technischer Kontext
│   ├── progress.md            # Projektfortschritt
│   ├── .clauderules           # Claude-Regeln
│   ├── project_context/       # Projektspezifischer Kontext
│   └── vector_index/          # Vektorindex-Dateien
│       ├── collections/       # Qdrant-Sammlungen
│       ├── embeddings/        # Einbettungsdaten
│       ├── queries/           # Suchanfragen
│       └── scripts/           # Python-Utilities
├── data/                      # Projektdaten
│   ├── qdrant/                # Qdrant-Speicher
│   └── transformers/          # SentenceTransformers-Modelle
├── docker-compose.yml         # Docker-Compose-Konfiguration
├── package.json               # NPM-Konfiguration
├── init-project.sh            # Initialisierungsskript
├── setup-permissions.sh       # Berechtigungsskript
├── start-mcp-tools.sh         # MCP-Tools-Startskript
├── start-qdrant.sh            # Qdrant-Startskript
└── stop-qdrant.sh             # Qdrant-Stoppskript
```

## Erweiterung und Anpassung

Der MCP-Tools-Integrator ist modular aufgebaut und kann leicht erweitert oder angepasst werden:

1. **Hinzufügen neuer MCP-Tools**: Erweitern Sie die MCP-Tools-Konfiguration in `mcpservers.json`.
2. **Anpassen der Memory-Bank-Struktur**: Ändern Sie die standardmäßigen Memory-Bank-Dateien.
3. **Integration weiterer Datenbanken**: Fügen Sie alternative Vektordatenbanken wie Pinecone oder Milvus hinzu.
4. **Anpassung der Einbettungsmodelle**: Verwenden Sie andere Modelle für die Texteinbettungen.

## Fehlerbehebung

### Häufige Probleme

1. **Docker-Berechtigungsprobleme**:
   ```
   Lösung: Führen Sie 'sudo usermod -aG docker $USER' aus und starten Sie die Session neu.
   ```

2. **Qdrant startet nicht**:
   ```
   Lösung: Prüfen Sie Docker-Status mit 'docker ps' und Logs mit 'docker logs qdrant-PROJEKTNAME'
   ```

3. **MCP-Tools-Konfigurationsprobleme**:
   ```
   Lösung: Überprüfen Sie die mcpservers.json und aktualisieren Sie die Umgebungsvariablen.
   ```

4. **Python-Abhängigkeiten fehlen**:
   ```
   Lösung: Führen Sie './memory-bank/vector_index/scripts/install_dependencies.sh' aus.
   ```

5. **Berechtigungsverwaltungsprobleme**:
   ```
   Lösung: Führen Sie './setup-permissions.sh' aus, um alle Dateiberechtigungen zu aktualisieren.
   ```

6. **"vector_index: Kommando nicht gefunden" Fehler**:
   ```
   Dieser Fehler tritt in älteren Versionen des Skripts auf und wurde in der aktuellen Version behoben.
   Lösung: Aktualisieren Sie auf die neueste Version des master-init.sh-Skripts.
   ```

7. **"Zugriff auf 'package.json' nicht möglich" Fehler**:
   ```
   Dieser Fehler kann auftreten, wenn MCP-Tools deaktiviert sind, wurde aber in der aktuellen Version behoben.
   Lösung: Aktualisieren Sie auf die neueste Version des master-init.sh-Skripts oder verwenden Sie --no-mcp-tools.
   ```

### Validierung der Installation

Um zu überprüfen, ob Ihre Installation korrekt funktioniert:

```bash
# Führen Sie das Produktionstestskript aus
./core/scripts/production-test.sh

# Oder für einen simulierten curl-Test
./core/scripts/production-test.sh --curl
```

Der Produktionstest validiert alle kritischen Komponenten und stellt sicher, dass die Installation fehlerfrei funktioniert.

### Produktions-Installation

Für die Verwendung in der Produktion sollten Sie folgenden Befehl verwenden:

```bash
curl -sSfL https://github.com/Vesias/AGI-System-Public/raw/main/core/scripts/master-init.sh | bash -s -- --project MeinProjekt
```

Dieser Befehl lädt die neueste Version des Skripts herunter und führt es mit standardmäßigen Produktionseinstellungen aus.

## Quellcode

Der vollständige Quellcode des MCP-Tools-Integrators ist in drei Hauptdateien verfügbar:

- [master-init.sh](../core/scripts/master-init.sh): Das Hauptinitialisierungsskript
- [host.sh](../core/scripts/host.sh): Das Hosting-Skript
- [test-install.sh](../core/scripts/test-install.sh): Das Testskript

## Fazit

Der MCP-Tools-Integrator bietet eine umfassende Lösung für die Projektinitialisierung mit MCP-Tools-Integration, semantischer Suche und strukturierter Dokumentation. Durch die Kombination verschiedener Tools und Technologien ermöglicht er einen schnellen Start mit AGI-System-Projekten und sorgt für eine konsistente Projektstruktur.