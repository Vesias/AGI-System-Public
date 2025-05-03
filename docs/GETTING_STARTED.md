# AGI-System: Erste Schritte

Diese Anleitung führt dich durch die ersten Schritte mit dem AGI-System, einem Framework zur Organisation und Verwaltung von Claude-basierten Projekten.

## Voraussetzungen

Bevor du beginnst, stelle sicher, dass folgende Komponenten installiert sind:

- **Git** (Version 2.23+)
- **Node.js** (Version 18+)
- **npm** (Version 8+)
- **git-crypt** (für verschlüsselte Inhalte, optional)
- **GPG** (für git-crypt, optional)

## Installation

### Standard-Installation (öffentliche Inhalte)

1. **Repository klonen**
   ```bash
   git clone https://github.com/Vesias/AGI-System-Public.git
   cd AGI-System-Public
   ```

2. **Setup-Skript ausführen**
   ```bash
   chmod +x core/scripts/setup.sh
   ./core/scripts/setup.sh
   ```

   Das Setup-Skript führt folgende Aktionen aus:
   - Erstellt notwendige Verzeichnisse in ~/.claude/
   - Kopiert Konfigurationsdateien und Templates
   - Erstellt ein Benutzerprofil
   - Richtet Berechtigungen korrekt ein

3. **API-Schlüssel hinzufügen**
   
   Bearbeite die Datei `~/.claude/.env` und füge deine API-Schlüssel hinzu:
   ```
   MCP_API_KEY="dein-mcp-api-schlüssel"
   BRAVE_SEARCH_API_KEY="dein-brave-api-schlüssel"
   ```

### Erweiterte Installation (mit Zugriff auf verschlüsselte Inhalte)

Wenn du Zugriff auf verschlüsselte Inhalte hast (benötigt Berechtigungen):

1. **Repository klonen**
   ```bash
   git clone https://github.com/Vesias/AGI-System-Public.git
   cd AGI-System-Public
   ```

2. **Entschlüsseln des Repositories**
   ```bash
   git-crypt unlock
   ```
   
   > **Hinweis**: Dies erfordert, dass dein GPG-Schlüssel bereits zum Repository hinzugefügt wurde. Falls du keinen Zugriff hast, kontaktiere den Repository-Eigentümer.

3. **Vollständiges Setup ausführen**
   ```bash
   chmod +x core/scripts/setup-full.sh
   ./core/scripts/setup-full.sh
   ```

## Erste Schritte

Nach der Installation kannst du mit dem AGI-System arbeiten:

### Neues Projekt erstellen

```bash
~/.claude/init_project.sh MeinProjekt
```

Dies erstellt ein neues Projekt mit der standardisierten Struktur:
- APP/
- MARKETING/
- FINANCE/
- DOCS/
- memory-bank/

### Vibe-Coding-Projekt erstellen

Für ein modernes Web-Projekt mit dem Vibe-Coding-Stack:

```bash
~/.claude/templates/project-types/vibe-coding-init.sh MeinVibeProjekt
```

### Memory-Bank aktualisieren

Nach Änderungen an einem Projekt:

```bash
~/.claude/update_memory.sh /pfad/zum/projekt
```

## Memory-Bank verstehen

Die Memory-Bank ist das Herzstück des AGI-Systems und enthält folgende Dateien:

- **projectbrief.md**: Allgemeine Projektbeschreibung und Ziele
- **productContext.md**: Problem-Lösungs-Analyse und Nutzerreise
- **activeContext.md**: Aktueller Entwicklungsfokus und Prioritäten
- **systemPatterns.md**: Architektur- und Design-Patterns
- **techContext.md**: Technologie-Stack und technische Entscheidungen
- **progress.md**: Chronologische Dokumentation des Fortschritts
- **.clauderules**: Projektspezifische Regeln und Best Practices

Diese Dateien ermöglichen eine kontinuierliche Arbeit über mehrere Sitzungen hinweg und erleichtern den Wissenstransfer im Team.

## MCP-Tools verwenden

Das AGI-System integriert verschiedene MCP-Tools (Model Context Protocol) für erweiterte Funktionalität:

```bash
# Mit Desktop-Commander arbeiten
claude "verwende desktop-commander, um Dateien mit dem Muster *.md zu finden"

# Mit Memory-Bank-MCP arbeiten
claude "nutze memory-bank-mcp, um die Memory-Bank des Projekts zu analysieren"

# Sequentielles Denken anwenden
claude "verwende sequentialthinking, um eine Lösung für folgendes Problem zu entwickeln..."
```

## Hilfe und Support

Wenn du Hilfe benötigst oder auf Probleme stößt:

1. Überprüfe die Dokumentation im `docs/`-Verzeichnis
2. Kontaktiere den Repository-Eigentümer: vesiassr@gmail.com
3. Erstelle ein Issue im GitHub-Repository