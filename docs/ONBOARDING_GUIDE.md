# Onboarding-Anleitung für AGI-System-Benutzer

Diese Anleitung bietet einen schrittweisen Einstieg in das AGI-System für neue Benutzer und Teammitglieder. Sie führt Sie durch die Installation, Konfiguration und tägliche Nutzung des Systems.

## Inhaltsverzeichnis

1. [Voraussetzungen](#voraussetzungen)
2. [Installation](#installation)
3. [Erstes Projekt erstellen](#erstes-projekt-erstellen)
4. [Hauptfunktionen und Komponenten](#hauptfunktionen-und-komponenten)
5. [Tägliche Arbeitsabläufe](#tägliche-arbeitsabläufe)
6. [Fehlerbehebung und Support](#fehlerbehebung-und-support)
7. [Fortgeschrittene Funktionen](#fortgeschrittene-funktionen)

## Voraussetzungen

Bevor Sie beginnen, stellen Sie sicher, dass folgende Voraussetzungen erfüllt sind:

- **Betriebssystem**: Linux, macOS oder WSL unter Windows
- **Terminal**: Bash oder Zsh
- **Git**: Version 2.23 oder höher
- **Node.js**: Version 18 oder höher
- **NPM**: Aktuelle Version
- **Berechtigungen**: Für einige Funktionen benötigen Sie zusätzliche Berechtigungen vom Teamleiter

**Empfohlene Tools:**
- Visual Studio Code oder eine andere IDE mit Markdown-Unterstützung
- Ein moderner Terminal-Emulator (iTerm2, Alacritty, etc.)

## Installation

### Schritt 1: Repository klonen

```bash
# Repository klonen
git clone https://github.com/Vesias/AGI-System-Public.git
cd AGI-System-Public
```

### Schritt 2: Basis-Setup ausführen

```bash
# Setup-Skript ausführen
./core/scripts/setup.sh
```

Das Setup-Skript richtet die grundlegenden Komponenten ein und installiert das AGI-System in Ihrem Home-Verzeichnis.

### Schritt 3: Zugriffsberechtigungen einrichten (optional)

Wenn Sie Zugriff auf geschützte Bereiche benötigen:

1. Kontaktieren Sie Ihren Teamleiter, um in die `access-control.json` aufgenommen zu werden
2. Führen Sie das folgende Kommando aus, um Ihre Berechtigungen zu prüfen:

```bash
./core/scripts/permissions-check.sh
```

### Schritt 4: Vollständiges Setup (für berechtigte Benutzer)

Wenn Sie die entsprechenden Berechtigungen haben:

```bash
# Entschlüsseln (erfordert GPG-Schlüssel)
git-crypt unlock

# Vollständiges Setup ausführen
./core/scripts/setup-full.sh
```

### Schritt 5: Claude Code Integration (empfohlen)

Claude Code bietet eine nahtlose Terminal-basierte KI-Integration:

```bash
# Claude Code installieren (falls noch nicht geschehen)
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code

# Claude Code für AGI-System konfigurieren
/path/to/AGI-System-Public/core/scripts/setup-claude-code.sh
```

## Erstes Projekt erstellen

### Schritt 1: Projekt initialisieren

```bash
# Standard-Projekt erstellen
~/.claude/init_project.sh MeinErstesProjekt

# ODER: Vibe Coding Projekt erstellen (für Webentwicklung)
~/.claude/templates/project-types/vibe-coding-init.sh MeinVibeApp
```

### Schritt 2: Projektverzeichnis erkunden

Nach der Erstellung hat Ihr Projekt folgende Struktur:

```
MeinErstesProjekt/
├── APP/                    # Anwendungscode
├── MARKETING/              # Marketing-bezogene Ressourcen
├── FINANCE/                # Finanz-bezogene Dokumente
├── DOCS/                   # Projektdokumentation
└── memory-bank/            # Memory-Bank für Projektkontinuität
    ├── projectbrief.md     # Projektdefinition
    ├── productContext.md   # Produktkontext
    ├── activeContext.md    # Aktiver Arbeitskontext
    ├── systemPatterns.md   # Systemarchitektur
    ├── techContext.md      # Technologie-Stack
    └── progress.md         # Fortschrittsverfolgung
```

### Schritt 3: Memory-Bank erkunden und anpassen

Die Memory-Bank ist das Herzstück des AGI-Systems. Bearbeiten Sie die folgenden Dateien, um Ihr Projekt zu definieren:

1. `projectbrief.md`: Geben Sie eine kurze Beschreibung und Ziele des Projekts an
2. `productContext.md`: Definieren Sie den Produkt-/Lösungskontext
3. `techContext.md`: Wählen Sie die zu verwendenden Technologien

## Hauptfunktionen und Komponenten

### Memory-Bank-System

Die Memory-Bank dient als "Gedächtnis" für Claude und andere KI-Modelle. Sie ermöglicht die Kontinuität zwischen Sitzungen und Teammitgliedern durch strukturierte Dokumentation von:

- Projektkontext
- Technologieentscheidungen
- Aktiver Arbeitskontext
- Fortschrittsinformationen

**Aktualisierung der Memory-Bank:**
```bash
cd MeinProjekt
~/.claude/update_memory.sh
```

Weitere Informationen: [Memory-Bank Anleitung](MEMORY_BANK_GUIDE.md)

### MCP-Tools Integration

Model Context Protocol (MCP) Tools erweitern die Fähigkeiten von Claude:

- **desktop-commander**: Dateisystem und Shell-Operationen
- **brave-web-search**: Web-Recherche für aktuelle Informationen
- **memory-bank-mcp**: Verwaltung der projektspezifischen Memory-Banks
- **code-mcp**: Code-Generierung und -Optimierung

Weitere Informationen: [MCP-Tools Anleitung](MCP_TOOLS_GUIDE.md)

### Claude Code Terminal-Integration

Claude Code ist ein Terminal-basiertes Tool für die direkte Interaktion mit Claude:

```bash
# Claude Code im Projektverzeichnis starten
cd MeinProjekt
claude
```

**Häufige Claude Code Befehle:**
- `claude "erkläre diesen Code"` - Code-Erklärung
- `claude commit` - Intelligenter Git-Commit
- `/init` - Projektinitialisierung
- `/compact` - Kontext komprimieren

Weitere Informationen: [Claude Code Integration](CLAUDE_CODE_INTEGRATION.md)

### Vibe Coding Framework

Das Vibe Coding Framework ist ein modernes Full-Stack-Framework mit:

- Next.js 15 mit App Router
- Supabase für Datenbank, Auth und Edge Functions
- Vercel für Hosting und Edge Runtime
- Tailwind CSS und shadcn/ui für Design
- TypeScript für End-to-End-Typsicherheit

Weitere Informationen: [Vibe Coding Anleitung](VIBE_CODING_GUIDE.md)

## Tägliche Arbeitsabläufe

### 1. Arbeit an einem Projekt starten

```bash
# In das Projektverzeichnis wechseln
cd ~/Projekte/MeinProjekt

# Claude Code starten (empfohlen)
claude

# ODER: Direktes Bearbeiten der Memory-Bank
nano memory-bank/activeContext.md  # Aktiven Arbeitskontext aktualisieren
```

### 2. Fortschritt dokumentieren

Am Ende jeder Arbeitssitzung:

```bash
# Memory-Bank aktualisieren
~/.claude/update_memory.sh

# ODER mit Claude Code:
claude "fasse meinen heutigen Fortschritt zusammen und aktualisiere progress.md"
```

### 3. Mit dem Team synchronisieren

Bei Änderungen am gemeinsamen AGI-System-Repository:

```bash
# AGI-System aktualisieren
cd /path/to/AGI-System-Public
git pull
./core/scripts/setup.sh
```

## Fehlerbehebung und Support

### Häufige Probleme

#### Problem: Memory-Bank wird nicht aktualisiert
```bash
# Überprüfen der Berechtigungen
ls -la ~/.claude/update_memory.sh
# Ausführbarkeit sicherstellen
chmod +x ~/.claude/update_memory.sh
```

#### Problem: Claude Code findet die Memory-Bank nicht
```bash
# Claude Code neu konfigurieren
/path/to/AGI-System-Public/core/scripts/setup-claude-code.sh
```

#### Problem: Git-Crypt-Entschlüsselung funktioniert nicht
```bash
# GPG-Schlüssel überprüfen
gpg --list-keys
# Mit Teamleiter in Verbindung setzen, um GPG-Schlüssel hinzuzufügen
```

### Installations-Test

Um zu überprüfen, ob Ihre Installation korrekt funktioniert:

```bash
/path/to/AGI-System-Public/core/scripts/test-installation.sh
```

### Support erhalten

Bei Problemen mit dem AGI-System:

1. Konsultieren Sie die [Dokumentation](README.md)
2. Fragen Sie in der Team-Chat-Gruppe
3. Melden Sie ein Issue auf GitHub
4. Kontaktieren Sie den Repository-Eigentümer: vesiassr@gmail.com

## Fortgeschrittene Funktionen

### Multi-Projekt-Memory-System

Für komplexe Projekte mit mehreren Unterprojekten:

```bash
# Hauptprojekt erstellen
~/.claude/init_project.sh HauptProjekt

# Unterprojekte erstellen und verknüpfen
cd HauptProjekt
~/.claude/init_project.sh Unterprojekt1
ln -s ../Unterprojekt1/memory-bank memory-bank/subprojects/Unterprojekt1
```

### Anpassen der MCP-Tools-Konfiguration

```bash
# MCP-Konfiguration bearbeiten
nano ~/.claude/mcp-config.json
```

### Verschlüsselte Notizen in der Memory-Bank

Für sensible Informationen in der Memory-Bank:

```bash
# Verschlüsselte Notiz erstellen
echo "Sensible Information" | gpg -e -r "Ihr Name" > memory-bank/.notes.gpg

# Entschlüsseln zum Lesen
gpg -d memory-bank/.notes.gpg
```

---

Wir hoffen, dass diese Anleitung Ihnen beim Einstieg in das AGI-System hilft. Bei Fragen oder Verbesserungsvorschlägen zögern Sie nicht, das Team zu kontaktieren.

**Viel Erfolg mit Ihren AGI-System-Projekten!**