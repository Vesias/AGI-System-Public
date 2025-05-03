# AGI-System: Klonbares Framework

Ein modernes Framework zur Organisation und Verwaltung von Claude-basierten Projekten mit Memory-Bank-System, MCP-Tools-Integration und Claude Code Terminal-Unterstützung.

## Überblick

Das AGI-System bietet eine strukturierte Umgebung für die Arbeit mit Claude und anderen KI-Systemen. Die Hauptfunktionen umfassen:

- **Memory-Bank-System**: Für Projektkontinuität zwischen Sitzungen
- **MCP-Tools-Integration**: Nahtlose Nutzung erweiterter KI-Funktionen
- **Claude Code Integration**: Terminal-basierte KI-Codierung mit Kontextverständnis
- **Vibe Coding Framework**: Moderner Tech-Stack für Webentwicklung
- **Projektvorlagen**: Standardisierte Struktur für einheitliche Projekte

## Installation

### Voraussetzungen

- Git 2.23+ 
- Git-Crypt (für verschlüsselte Inhalte)
- Node.js 18+
- GPG (für Entschlüsselung)

### Standard-Installation

```bash
# Repository klonen
git clone https://github.com/Vesias/AGI-System-Public.git
cd AGI-System-Public

# Setup-Skript ausführen
./core/scripts/setup.sh
```

### Erweiterte Installation (mit Berechtigungen)

Wenn Sie Zugriff auf verschlüsselte Inhalte haben:

```bash
# Repository klonen
git clone https://github.com/Vesias/AGI-System-Public.git
cd AGI-System-Public

# Entschlüsseln (erfordert Berechtigungen)
git-crypt unlock

# Vollständiges Setup ausführen
./core/scripts/setup-full.sh
```

## Verwendung

Nach der Installation können Sie:

```bash
# Ein neues Projekt erstellen
~/.claude/init_project.sh MeinProjekt

# Memory-Bank aktualisieren
~/.claude/update_memory.sh

# Claude Code für ein Projekt einrichten
cd MeinProjekt
/path/to/AGI-System-Public/core/scripts/setup-claude-code.sh

# Claude Code starten
claude
```

## Berechtigungssystem

Dieses Repository verwendet ein mehrstufiges Berechtigungssystem:

1. **Öffentlich**: Grundstruktur und nicht-sensible Konfiguration (für alle verfügbar)
2. **Geschützt**: Erfordert Berechtigungseintrag in access-control.json
3. **Verschlüsselt**: Sensible Daten mit git-crypt verschlüsselt (GPG-Schlüssel erforderlich)

Die Verwaltung der Berechtigungen erfolgt über das `permissions-parser.sh` Skript:

```bash
# Benutzer auflisten
./core/scripts/permissions-parser.sh list

# Neuen Benutzer hinzufügen
./core/scripts/permissions-parser.sh add <rolle> <name> <email>

# Benutzer entfernen
./core/scripts/permissions-parser.sh remove <email>
```

## Technische Details

- **Core**: Grundlegende Systemdateien und Konfiguration
- **Templates**: Vorlagen für verschiedene Projekttypen
- **Scripts**: Automatisierungsroutinen für häufige Aufgaben
- **.git-crypt**: Verschlüsselte sensible Dateien und Konfigurationen

## Anfragen für Zugriff

Für Zugriff auf verschlüsselte Inhalte oder erweiterte Berechtigungen kontaktieren Sie:
- **E-Mail**: vesiassr@gmail.com
- **GitHub**: @Vesias

## Lizenz

Privat. Alle Rechte vorbehalten.