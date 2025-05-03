# Sicherheitsrichtlinien für AGI-System

## Datenschutz und Sicherheitsmodell

Das AGI-System verwendet ein mehrstufiges Sicherheitsmodell zum Schutz sensibler Daten:

### 1. Öffentliche Ebene (unverschlüsselt)
- Grundlegende Konfigurationsdateien
- Skripte ohne sensible Parameter
- Templates und Dokumentation
- Projektstruktur und Organisationsrichtlinien

### 2. Geschützte Ebene (mit Berechtigungskontrolle)
- Berechtigungsverwaltung und Zugriffskontrollen
- Nicht-sensible MCP-Server-Konfigurationen
- Projektvorlagen und Best Practices

### 3. Verschlüsselte Ebene (git-crypt)
- API-Schlüssel und Zugangsdaten
- Persönliche Benutzerprofile mit sensiblen Daten
- Vollständige MCP-Server-Konfigurationen
- Vertrauliche Geschäftsinformationen

## Verwendung von git-crypt

Dieses Repository verwendet git-crypt für die Verschlüsselung sensibler Daten. 

### Installation
```bash
# Auf Debian/Ubuntu
sudo apt-get install git-crypt

# Auf macOS mit Homebrew
brew install git-crypt
```

### Zugriff auf verschlüsselte Inhalte

Wenn du Zugriff erhalten hast:
1. Importiere den GPG-Schlüssel, der dir zur Verfügung gestellt wurde
2. Entschlüssle das Repository mit:
   ```bash
   git-crypt unlock
   ```

## Richtlinien für Kontributoren

1. **Keine sensiblen Daten im öffentlichen Bereich**
   - Niemals API-Schlüssel in unverschlüsselten Dateien
   - Keine persönlichen Informationen in öffentlichen Commits
   - Keine Passwörter oder Tokens im Klartext

2. **Verwenden der Verschlüsselung**
   - Alle sensiblen Daten müssen in Dateien sein, die in .gitattributes als verschlüsselt markiert sind
   - Prüfe mit `git-crypt status`, ob Dateien mit sensiblen Daten wirklich verschlüsselt sind

3. **Zugriffsmanagement**
   - GPG-Schlüssel müssen sicher aufbewahrt werden
   - Bei Schlüsselverlust sofort das Team benachrichtigen
   - Regelmäßig die Berechtigungsliste überprüfen

## Melden von Schwachstellen

Wenn du eine Sicherheitslücke entdeckst, bitte kontaktiere:
- **E-Mail**: vesiassr@gmail.com
- **Betreff**: [SECURITY] AGI-System Vulnerability

Bitte nicht öffentlich über Sicherheitslücken berichten, bis diese behoben wurden.