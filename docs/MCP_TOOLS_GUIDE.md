# MCP-Tools Guide

MCP (Model Context Protocol) Tools sind ein wichtiger Bestandteil des AGI-Systems und erweitern die Funktionalität von Claude und anderen KI-Modellen. Dieser Leitfaden erklärt, wie MCP-Tools im AGI-System konfiguriert und verwendet werden.

## Was sind MCP-Tools?

MCP-Tools sind spezialisierte Server, die es Claude ermöglichen, komplexe Aufgaben auszuführen, die über die Grundfähigkeiten des Modells hinausgehen. Diese Tools folgen dem Model Context Protocol und bieten eine standardisierte Schnittstelle für die Kommunikation zwischen dem KI-Modell und externen Funktionen.

## Im AGI-System integrierte MCP-Tools

Das AGI-System integriert standardmäßig folgende MCP-Tools:

### 1. desktop-commander
**Funktion**: Datei- und Ordneroperationen auf dem Desktop
**Typische Anwendungen**: Dateien suchen, verschieben, kopieren; mit dem Dateisystem interagieren

### 2. sequentialthinking
**Funktion**: Strukturierte Lösungsentwicklung für komplexe Probleme
**Typische Anwendungen**: Schrittweise Analyse, Hypothesengenerierung, logische Deduktion

### 3. brave-web-search
**Funktion**: Internetsuche über die Brave-Suchmaschine
**Typische Anwendungen**: Recherche zu aktuellen Themen, Informationsbeschaffung

### 4. memory-bank-mcp
**Funktion**: Spezielle Integration mit dem Memory-Bank-System
**Typische Anwendungen**: Analyse und Synthese von Memory-Bank-Inhalten, Projektwissensmanagement

### 5. code-mcp
**Funktion**: Erweiterte Codeverwaltung und -generierung
**Typische Anwendungen**: Codeanalyse, Refactoring, Optimierung, Testgenerierung

### 6. context7-mcp
**Funktion**: Semantische Kontextverwaltung
**Typische Anwendungen**: Zusammenhänge zwischen Informationen herstellen, Kontextübergang

### 7. magic-mcp
**Funktion**: Kreative Aufgaben und Ideengenerierung
**Typische Anwendungen**: Namensgebung, Konzeptentwicklung, kreative Lösungsfindung

## MCP-Tools konfigurieren

### Konfigurationsdatei

MCP-Tools werden in der Datei `~/.claude/mcpservers.json` konfiguriert. Das Format ist wie folgt:

```json
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": [
        "-y",
        "@smithery/cli@latest",
        "run",
        "@wonderwhy-er/desktop-commander",
        "--key",
        "YOUR_API_KEY"
      ]
    },
    // weitere Tools hier
  }
}
```

### API-Schlüssel konfigurieren

API-Schlüssel werden in der `.env`-Datei gespeichert:

```
# ~/.claude/.env
MCP_API_KEY="dein-api-schlüssel"
BRAVE_SEARCH_API_KEY="dein-brave-schlüssel"
```

Die Skripte des AGI-Systems integrieren diese Schlüssel automatisch in die MCP-Konfiguration.

### Neues MCP-Tool hinzufügen

Um ein neues MCP-Tool hinzuzufügen:

1. Bearbeite die `mcpservers.json`-Datei:
   ```bash
   nano ~/.claude/mcpservers.json
   ```

2. Füge einen neuen Eintrag hinzu:
   ```json
   "neues-tool": {
     "command": "npx",
     "args": [
       "-y",
       "@smithery/cli@latest",
       "run",
       "@autor/tool-name",
       "--key",
       "DEIN_API_SCHLÜSSEL"
     ]
   }
   ```

3. Starte Claude neu, damit die Änderungen wirksam werden.

## MCP-Tools verwenden

### Direkte Verwendung in Claude

```bash
# Desktop-Commander verwenden
claude "verwende desktop-commander, um alle Dateien mit der Endung .md zu finden"

# Sequentielles Denken verwenden
claude "verwende sequentialthinking, um folgendes Problem zu lösen: ..."

# Memory-Bank-MCP verwenden
claude "nutze memory-bank-mcp, um die Memory-Bank des Projekts X zu analysieren und Zusammenhänge zu finden"
```

### Gezieltes Aufrufen eines bestimmten Tools

```bash
# Brave-Suche für aktuelle Informationen
claude "nutze brave-web-search, um die neuesten Entwicklungen zu React 19 zu recherchieren"

# Code-MCP für Codeoptimierung
claude "verwende code-mcp, um diesen React-Komponenten-Code zu optimieren: ..."
```

### Kombination mehrerer Tools

```bash
claude "verwende desktop-commander, um die projektbrief.md zu finden, dann nutze memory-bank-mcp, um den Inhalt zu analysieren, und schließlich verwende sequentialthinking, um die nächsten Entwicklungsschritte zu planen"
```

## Tipps für die effektive Nutzung

1. **Klare Anweisungen geben**: Spezifiziere genau, welches Tool für welche Aufgabe verwendet werden soll

2. **Kontext bereitstellen**: Gib ausreichend Kontext für die Aufgabe, damit das Tool effektiv arbeiten kann

3. **Die richtigen Tools für die richtigen Aufgaben**:
   - Dateisystemoperationen → desktop-commander
   - Komplexe Probleme → sequentialthinking
   - Web-Recherche → brave-web-search
   - Projektanalyse → memory-bank-mcp
   - Code-bezogene Aufgaben → code-mcp
   - Zusammenhänge verstehen → context7-mcp
   - Kreative Aufgaben → magic-mcp

4. **Verkettung von Operationen**: Teile komplexe Aufgaben in Schritte auf, die von verschiedenen Tools bearbeitet werden können

5. **Fehlersuche**: Bei Problemen mit einem MCP-Tool:
   - Überprüfe API-Schlüssel in .env
   - Stelle sicher, dass das Tool korrekt in mcpservers.json konfiguriert ist
   - Prüfe die Netzwerkverbindung
   - Versuche, das Tool einzeln zu starten: `npx @smithery/cli@latest run @tool-name`

## Häufige Fehlermeldungen und Lösungen

### "Method not found" (-32601)
**Problem**: Das angeforderte Tool ist nicht verfügbar oder falsch konfiguriert
**Lösung**: Überprüfe den Tool-Namen und die Konfiguration in mcpservers.json

### "Invalid params" (-32602)
**Problem**: Die an das Tool übergebenen Parameter sind ungültig
**Lösung**: Überprüfe die Parameter und deren Format

### "Internal error" (-32603)
**Problem**: Ein interner Fehler im MCP-Tool
**Lösung**: Überprüfe die Logs, starte das Tool neu

### "Invalid API key"
**Problem**: Der API-Schlüssel ist ungültig oder fehlt
**Lösung**: Überprüfe den API-Schlüssel in .env und mcpservers.json