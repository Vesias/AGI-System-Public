# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Running all tests: ./run-tests.sh
- Running a single test: ./run-tests.sh -t unit|integration|system
- Running tests in verbose mode: ./run-tests.sh -v
- Installation: ./setup.sh or ./setup-optimized.sh
- Running permissions: ./permissions-parser.sh list|add|update|remove <file> [args...]

## Code Style
- Shell scripts use bash (/usr/bin/env bash) with set -e for error handling
- Functions are documented with descriptive comments
- Variables use UPPER_CASE for global variables, lower_case for local ones
- Error handling with dedicated log functions (log_error, log_info)
- JSON parsing preferably with jq, but fallback mechanisms implemented
- Color-coded output using ANSI color codes
- Comprehensive help texts for all scripts with -h option

## Project Structure
- core/scripts: Main shell scripts
- core/templates: Template files
- tests/unit, tests/integration, tests/system: Test files by type

# Technische Systemanalyse: Kompatibilität und Stabilität

Die Analyse Ihrer technischen Komponenten zeigt erhebliche Stabilitätsrisiken und Kompatibilitätsprobleme. Während einige NPM-Pakete wie Commander und Puppeteer stabil sind, weisen MCP-Tools und Qdrant Konfigurationsschwächen auf. Besonders kritisch sind die Permission-System-Implementierung mit unsicheren JSON-Strukturen und mehrere Docker-Kompatibilitätsprobleme. Das System benötigt dringend verbesserte Dokumentation, erweiterte Tests und standardisierte Konfigurationen, um Stabilität zu gewährleisten.

## 1. NPM-Pakete Statusanalyse

### Existenz und Verfügbarkeit

Von den fünf untersuchten Paketen sind nur zwei uneingeschränkt einsatzbereit:

- **commander** ✅ (nicht commander-cli)
  - Aktuelle Version: 13.1.0 (vor 3 Monaten aktualisiert)
  - Extrem populär mit über 92.000 abhängigen Projekten
  - Aktiv gewartet mit regelmäßigen Updates
  - **Empfehlung**: Ohne Einschränkungen für Produktionseinsatz geeignet

- **memory-store** ⚠️
  - Existiert, aber Version 0.0.1 (vor 13 Jahren zuletzt aktualisiert)
  - Sehr geringe Nutzung (nur 4 abhängige Projekte)
  - Status: Verlassen (keine Updates seit 13 Jahren)
  - **Empfehlung**: Nicht für Produktion empfohlen. Alternativen wie `memorystore` oder `cache-manager-memory-store` verwenden

- **marketing-analytics** ❌
  - Existiert nicht unter diesem Namen
  - Alternative `@amplitude/marketing-analytics-browser` existiert (Version 1.0.20)
  - Status: Im Wartungsmodus, wird durch Browser SDK 2.0 ersetzt
  - **Empfehlung**: Stattdessen `@amplitude/analytics-browser` verwenden

- **puppeteer** ✅
  - Aktuelle Version: 24.7.2 (vor 7 Tagen aktualisiert)
  - Sehr populär mit über 8.200 abhängigen Projekten
  - Aktiv gewartet mit häufigen Updates
  - **Empfehlung**: Für Produktion empfohlen. Für neuere Projekte `playwright` erwägen

- **cli-toolbox** ❌
  - Existiert nicht unter diesem Namen
  - Ähnliche Pakete (`toolbox-cli`, `@offirmo/cli-toolbox`) sind verlassen
  - **Empfehlung**: Spezifischere Pakete wie `commander`, `chalk` und `inquirer` verwenden

### Empfohlene Verbesserungen

1. NPM-Pakete mit festen Versionen definieren (`"dependency": "1.2.3"` statt `"^1.2.3"`)
2. Verlassene Pakete ersetzen: `memory-store` durch `memorystore` oder `cache-manager-memory-store`
3. Inexistente Pakete durch etablierte Alternativen ersetzen
4. Regelmäßige Sicherheitsaudits mit `npm audit` durchführen
5. Package-lock.json in die Versionskontrolle einbeziehen

## 2. MCP-Tools und Kompatibilitätsanalyse

### Claude Code mit MCP-Integration

Claude Code interagiert mit MCP als Server, der Funktionen für Dateioperationen, Shell-Befehle und Code-Analyse bereitstellt. Wesentliche Kompatibilitätsprobleme:

1. **Tool-Namenseinschränkungen**: Names-Pattern-Beschränkungen führen zu API-Fehlern
2. **Transportprotokoll-Limits**: Claude Code unterstützt primär stdio-Transport, nicht SSE-Server
3. **Java-Versionsunterschiede**: Inkompatibilitäten zwischen neueren MCP-Servern (Java 21) und Claude Desktop (Java 11)

### JSON-Konfigurationsstruktur (mcpservers.json)

Die grundlegende Struktur ist:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "API_KEY": "your-api-key"
      }
    }
  }
}
```

Häufige Konfigurationsfehler:

1. **Pfadformatierungsfehler**: Inkonsistente Pfadtrenner (besonders bei Windows)
2. **Fehlende Umgebungsvariablen**: API-Schlüssel oder Anmeldedaten fehlen
3. **Plattformübergreifende Kompatibilitätsprobleme**: WSL-Integrationen benötigen Spezialbehandlung

### Git-Crypt Integration

Git-crypt ermöglicht transparente Verschlüsselung von Dateien in Git-Repositories, hat jedoch Sicherheitslücken:

1. **Keine Repository-Manipulationsschutz**: Git-crypt schützt nicht vor Repository-Manipulationen
2. **Keine Schlüsselwiderrufung**: Kein Mechanismus, um Zugriff nach Gewährung zu widerrufen
3. **Metadaten-Exposition**: Dateinamen und Commit-Nachrichten werden nicht verschlüsselt
4. **SHA-1 HMAC-Schwächen**: Nutzt SHA-1 für Integrität, bekannte Schwachstellen

Sicherheitsverbesserungen:
- Signierte Git-Commits und Tags zusätzlich zu git-crypt verwenden
- Ordnungsgemäßes Schlüsselmanagement implementieren
- Für hochsensible Daten Alternativen wie HashiCorp Vault erwägen

### Docker-Container-Konflikte

Häufige Konflikte zwischen Qdrant und anderen Komponenten:

1. **Port-Binding-Konflikte**: Default-Ports (6333, 6334) kollidieren mit anderen Diensten
2. **Volume-Mounting-Konflikte**: Mehrere Container versuchen, dieselben Host-Volumes zu mounten
3. **Ressourcenzuweisungskonflikte**: Qdrants speicherintensive Operationen können andere Container behindern

Empfehlungen zur Konfliktminimierung:
- Docker Compose oder Kubernetes für Container-Orchestrierung verwenden
- Ressourcenlimits für Qdrant-Container implementieren
- Nicht-Standard-Netzwerkkonfigurationen verwenden, um IP-Bereichsüberlappungen zu vermeiden

## 3. Berechtigungssystem-Implementierung

### Best Practices für access-control.json

Empfohlene Strukturen für verschiedene Zugriffssteuerungsmodelle:

**Role-Based Access Control (RBAC)**:
```json
{
  "version": "1.0",
  "roles": {
    "admin": {
      "description": "Administrator with full access",
      "permissions": {
        "users": ["create", "read", "update", "delete"],
        "content": ["create", "read", "update", "delete"],
        "settings": ["read", "update"]
      }
    },
    "editor": {
      "description": "Content editor",
      "permissions": {
        "users": ["read"],
        "content": ["create", "read", "update"],
        "settings": ["read"]
      }
    }
  }
}
```

**Attribute-Based Access Control (ABAC)**:
```json
{
  "version": "1.0",
  "policies": [
    {
      "name": "finance_document_access",
      "effect": "allow",
      "actions": ["read", "write"],
      "resources": ["/documents/*"],
      "conditions": {
        "user.department": "finance",
        "resource.classification": ["public", "internal"]
      }
    }
  ]
}
```

Die wichtigsten Validierungsmethoden:
1. **JSON Schema**: Struktur durch Schema validieren
2. **Programmatische Validierung**: Validierungslogik im Anwendungscode implementieren
3. **Testbasierte Validierung**: Unit-Tests zur Überprüfung der Regelintegrität

### Kompatibilität der JSON-Verarbeitung im permissions-manager.sh

Häufige Probleme bei der JSON-Verarbeitung in Shell-Skripten:

1. **Parsing-Komplexität**: Native Shell-Tools wie `grep` und `sed` sind nicht für strukturiertes JSON konzipiert
2. **Escape-Probleme**: Sonderzeichen in JSON können Parsing-Fehler verursachen
3. **Typsicherheit**: Shell-Skripten fehlt native JSON-Typbehandlung

Empfohlene Tools:
- **jq**: Der Goldstandard für JSON-Verarbeitung in Shell-Skripten
  - Beispiel: `jq '.roles[] | select(.permissions[] | contains("admin"))' access-control.json`
- **Python mit JSON-Modul**: Für komplexere Verarbeitung
- **Node.js**: Ausgezeichnete JSON-Handhabung mit nativer Unterstützung

Sicherheitsempfehlungen:
- Niemals `eval` mit JSON-Daten verwenden
- Dateirechte angemessen einschränken (z.B. `chmod 600 access-control.json`)
- JSON-Schema zur Validierung vor Verarbeitung nutzen

## 4. Qdrant-Vektordatenbank-Setup

### Docker-Konfiguration für Qdrant

Grundlegende Docker-Konfiguration:
```bash
docker run -p 6333:6333 \
  -v $(pwd)/path/to/data:/qdrant/storage \
  qdrant/qdrant
```

Erweiterte Produktionskonfiguration:
```bash
docker run -p 6333:6333 -p 6334:6334 \
  -v $(pwd)/path/to/data:/qdrant/storage \
  -v $(pwd)/path/to/custom_config.yaml:/qdrant/config/production.yaml \
  -e QDRANT__SERVICE__API_KEY=<YOUR_API_KEY> \
  -e QDRANT__SERVICE__ENABLE_TLS=1 \
  qdrant/qdrant:v1.13.0
```

Verfügbare Versionen:
- **Latest Stable**: `qdrant/qdrant:latest`
- **Spezifische Versionen**: `qdrant/qdrant:v1.13.0`
- **GPU-Unterstützung**: `qdrant/qdrant:v1.13.0-gpu-nvidia`
- **Unprivileged Versionen**: `qdrant/qdrant:v1.13.0-unprivileged`

### Kompatibilitätsprobleme

**Mit Ubuntu/Linux-Systemen**:
1. **Architektur-Unterstützung**: Nur 64-bit-Systeme (x86_64/amd64 und AArch64/arm64)
2. **Dateisystem-Anforderungen**: POSIX-kompatible Dateisysteme erforderlich
3. **Nicht kompatibel mit**: Netzwerk-Dateisystemen (NFS) oder Objektspeichern (S3)

**Mit Docker-Versionen**:
1. **Minimum Docker-Version**: Docker Engine 19.03+ empfohlen
2. **Docker Compose**: v2.23.1 oder höher für volle Funktionalität
3. **Volume-Mounting**: In älteren Docker-Versionen können Probleme mit Volume-Berechtigungen auftreten

**Speicherplatzkonflikte**:
1. **Unzureichender Speicherplatz**: Qdrant benötigt ausreichend Speicher für Vektordaten, Indizes und WAL
2. **Gemeinsame Speicherkonflikte**: Mehrere Qdrant-Instanzen versuchen, auf denselben Speicherort zuzugreifen
3. **Gleichzeitiger Zugriff**: Lokaler Modus unterstützt keinen gleichzeitigen Zugriff

Speicheranforderungen berechnen:
- 1 Million Vektoren mit 768 Dimensionen ≈ 3GB für Vektoren allein
- HNSW-Index fügt typischerweise 50-100% Overhead hinzu

## 5. Gesamtsystem-Stabilität

### Potenzielle Komponentenkonflikte

**NPM-Pakete**:
- Chrome-Download-Konflikte bei mehreren gleichzeitigen Puppeteer-Installationen
- Port-Konflikte, wenn mehrere Puppeteer-Instanzen dieselben Debugging-Ports verwenden
- Bibliotheksabhängigkeitskonflikte, besonders mit Abhängigkeiten wie `ws` und `https-proxy-agent`

**Berechtigungssysteme**:
- Prioritätsauflösungskonflikte: Wenn mehrere Berechtigungsregeln mit widersprüchlichen Einstellungen auf dieselbe Ressource angewendet werden
- Vererbungskettenkonflikte: Widersprüchliche Zugriffsrichtlinien durch Vererbung von verschiedenen Ebenen

**Docker-Container**:
- Port-Binding-Konflikte mit Qdrant-Standardports (6333, 6334)
- Ressourcenzuweisungskonflikte durch Qdrants speicherintensive Operationen

### Race Conditions

**In Berechtigungssystemen**:
- **Check-Then-Act-Muster**: Berechtigungen werden geprüft, könnten sich aber während der folgenden Aktion ändern
- **Time-of-Check to Time-of-Use (TOCTOU)**: Berechtigungen werden zu einem Zeitpunkt überprüft, aber später verwendet

**In Qdrant**:
- **Vektoreinfügungskonflikte**: Mehrere gleichzeitige Vektoreinfügungen führen zu Indexkorruption
- **Search-While-Indexing-Probleme**: Race Conditions beim Durchsuchen einer Sammlung während der Indizierung

**In NPM-Paketen**:
- Installationsrace-Conditions: Mehrere gleichzeitige npm-Installationen verursachen Dateisystemkonflikte
- Browser-Launch-Race-Conditions bei Puppeteer, wenn mehrere Prozesse versuchen, dasselbe Benutzerdatenverzeichnis zu verwenden

### Sicherheitslücken

**In JSON-basierter Zugriffssteuerung**:
- **JSON-Injection-Angriffe**: Böswillige Eingaben manipulieren Zugriffssteuerungsregeln
- **Unsachgemäße Validierung**: Fehlerhafte Validierung von JSON-Struktur vor der Verarbeitung
- **JWT-basierte Schwachstellen**: Bei Verwendung von JSON Web Tokens für die Zugriffssteuerung

**In Docker-Konfigurationen**:
- **Standardkonfigurationsschwächen**: Qdrant startet standardmäßig ohne Authentifizierung oder Verschlüsselung
- **Exponierte Ports**: Versehentliches Offenlegen von Management-Ports für öffentliche Netzwerke
- **Container-Privilegien-Eskalation**: Ausführen von Containern mit übermäßigen Privilegien

## 6. Dokumentations- und Testabdeckung

### Fehlende Testfälle

**Für NPM-Pakete**:
1. **Unzureichende Edge-Case-Tests**: Viele Pakete testen nur den "Happy Path"
2. **Mangel an Integrationstests**: Tests, die überprüfen, wie Komponenten zusammenarbeiten, fehlen oft
3. **Abhängigkeitsinteraktionstests**: NPM-Pakete testen selten, wie sie mit ihren Abhängigkeiten interagieren

**Für Berechtigungssysteme**:
1. **Rollenbasierter Testansatz**: Jede Rolle testen, um zu überprüfen, ob sie genau die erwarteten Berechtigungen hat
2. **Negativer Testfokus**: Immer testen, dass Berechtigungen standardmäßig verweigert werden
3. **Automatisierte Integrationstests**: Verwendung von Integrationstests mit realistischen Benutzerkontexten

**Für Docker-Systeme wie Qdrant**:
1. **Testcontainers-Framework**: Tests mit realen, isolierten Diensten in Docker-Containern ausführen
2. **Docker Compose für Testumgebungen**: Docker Compose-Dateien zur Erstellung reproduzierbarer Testumgebungen verwenden
3. **Indexierungstests**: Vektorindizes mit verschiedenen Parametern (HNSW, Quantisierung) testen

### Unzureichend dokumentierte Funktionen

**Für NPM-Pakete**:
- README.md mit klarer Paketbeschreibung, Installationsanleitung, Beispielen und API-Dokumentation
- JSDoc für alle öffentlichen APIs
- Versionierungsdokumentation mit CHANGELOG.md

**Für Berechtigungssysteme**:
- Dokumentation des konzeptionellen Modells (RBAC, ABAC usw.)
- Dokumentation der Implementierung (Datenbankschema, Cachingmechanismen)
- Dokumentation vordefinierter Rollen und ihrer Berechtigungen

**Für Docker-Konfigurationen**:
- Dokumentation jedes signifikanten Schritts im Dockerfile
- Dokumentation aller Umgebungsvariablen mit Standardwerten und akzeptablen Bereichen
- Dokumentation der Ressourcenanforderungen (CPU, Speicher, Festplatte)

### Versionierungsanforderungen

**Für NPM-Abhängigkeiten**:
- Exakte Versionen für Produktionsabhängigkeiten verwenden (`"dependency": "1.2.3"`)
- Caret-Bereiche für kompatible Abhängigkeiten verwenden (`"dependency": "^1.2.3"`)
- Package-lock.json in die Versionskontrolle einbeziehen

**Für Docker-Image-Versionen**:
- Semantische Versionierung für Tags verwenden
- Niemals das Tag `latest` in der Produktion verwenden
- Basisbilder auf bestimmte Versionen festlegen

**Für Git-basierte Abhängigkeiten**:
- Tags für stabile Versionen verwenden (`git+https://github.com/user/repo.git#v1.0.0`)
- Commit-Hashes für unveränderliche Referenzen verwenden (`git+https://github.com/user/repo.git#commithash`)
- Branch-Referenzen in der Produktion vermeiden

## Abschließende Empfehlungen

### NPM-Pakete
1. `commander` statt `commander-cli` verwenden
2. `memory-store` durch `memorystore` oder `cache-manager-memory-store` ersetzen
3. `@amplitude/analytics-browser` statt `@amplitude/marketing-analytics-browser` implementieren
4. `puppeteer` beibehalten oder für neuere Projekte `playwright` erwägen
5. Statt `cli-toolbox` spezifische Pakete wie `commander`, `chalk` und `inquirer` verwenden

### MCP-Integration
1. Direkte Konfigurationsdateibearbeitung statt CLI-Assistenten verwenden
2. Java-Versionskompatibilität zwischen Claude Desktop und MCP-Servern sicherstellen
3. Transport-Security mit TLS für alle Kommunikationsebenen implementieren
4. Separate sensible Konfigurationen mit git-crypt verschlüsseln

### Berechtigungssystem
1. Klare Rollendefinitionen mit präzisen Berechtigungen implementieren
2. `jq` für JSON-Verarbeitung in Shell-Skripten verwenden
3. JSON-Schema-Validierung für access-control.json implementieren
4. Atomare Operationen für Berechtigungsprüfungen und nachfolgende Aktionen implementieren

### Qdrant-Konfiguration
1. Spezifische Version statt `latest` in Produktionsumgebungen verwenden
2. API-Schlüssel und TLS-Verschlüsselung aktivieren
3. Container als Nicht-Root-Benutzer ausführen
4. Resource Limits für CPU und Memory definieren

### Systemstabilität
1. Komponenten durch klare Schnittstellendefinitionen isolieren
2. Transaktionsbasierte Ansätze für mehrstufige Operationen implementieren
3. Proper Synchronisierungsmechanismen für gemeinsam genutzte Ressourcen einführen
4. Sicherheitsüberwachung mit automatisierten Scans implementieren

### Tests und Dokumentation
1. Edge-Case-Tests für alle kritischen Komponenten entwickeln
2. Integrationstests für komponentenübergreifende Szenarien implementieren
3. Umfassende README-Dateien für alle Komponenten erstellen
4. CI/CD-Pipeline für automatisierte Tests einrichten

Die Umsetzung dieser Empfehlungen wird die Systemstabilität erheblich verbessern und potenzielle Konflikte, Race Conditions und Sicherheitsrisiken minimieren.