# MCP-Tool-Konfiguration für test-project

## Aktivierte Tools
- **desktop-commander**: Dateisystem- und Shell-Operationen
- **memory-bank**: Memory-Bank-Verwaltung
- **marketing-tools**: Marketing-Analyse und -Tools
- **browser-tools**: Web-Recherche und -Automatisierung
- **toolbox**: Allgemeine KI-Tools und Hilfsprogramme

## Verbindungsdetails
- Alle Tools sind für das Projekt "test-project" konfiguriert
- Pfad: /home/jan/AGI-System-Public/test-project
- Konfigurationsdatei: /home/jan/AGI-System-Public/test-project/.config/claude/mcpservers.json

## Berechtigungen
- Voller Lesezugriff auf das Projektverzeichnis
- Schreibzugriff für projektbezogene Dateien
- Ausführung von sicheren Befehlen innerhalb des Projekts
- Netzwerkzugriff für Web-Recherche und API-Aufrufe

## Verwendung
1. Starte Claude Code im Projektverzeichnis
2. Aktiviere MCP-Tools mit: `/mcp`
3. Verwende die Tools über natürliche Sprachbefehle

## Beispielworkflows
- "Durchsuche das Projektverzeichnis nach JavaScript-Dateien" → desktop-commander
- "Aktualisiere den Projektkontext mit neuem Feature XYZ" → memory-bank
- "Recherchiere Wettbewerber für unser Produkt" → browser-tools

## Technische Details
Die MCP-Tools werden über npx gestartet und kommunizieren über das Model Context Protocol mit Claude. 
Jedes Tool hat einen eigenen Zuständigkeitsbereich und spezifische Fähigkeiten, die es Claude ermöglichen, 
komplexe Aufgaben auszuführen, die über seine inhärenten Fähigkeiten hinausgehen.
