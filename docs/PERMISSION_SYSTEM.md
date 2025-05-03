# AGI-System: Berechtigungssystem

Das AGI-System verwendet ein mehrstufiges Berechtigungssystem, um Zugriff auf verschiedene Teile des Frameworks zu kontrollieren. Dieses Dokument erklärt, wie das Berechtigungssystem funktioniert und wie es verwaltet wird.

## Zugriffsebenen

Das System definiert drei Hauptzugriffsebenen:

1. **Admin**
   - Voller Zugriff auf alle Bereiche des Repositories
   - Kann Benutzer hinzufügen und entfernen
   - Kann GPG-Schlüssel für verschlüsselte Inhalte verwalten
   - Kann das Repository aktualisieren und erweitern

2. **Contributor**
   - Kann nicht-sensible Inhalte bearbeiten (core, templates)
   - Kann verschlüsselte Inhalte lesen (mit entsprechendem GPG-Schlüssel)
   - Kann keine neuen Benutzer hinzufügen

3. **Viewer**
   - Kann nur nicht-sensible Inhalte sehen und verwenden
   - Kein Zugriff auf verschlüsselte Inhalte
   - Lesezugriff auf öffentliche Konfiguration und Templates

## Berechtigungsdatei

Die Berechtigungen werden in der Datei `permissions/access-control.json` verwaltet. Das Format ist wie folgt:

```json
{
  "repository": "AGI-System-Public",
  "owner": "Vesias",
  "permissions": {
    "admin": [
      {
        "username": "Vesias",
        "email": "vesiassr@gmail.com",
        "gpg_key_id": "user_gpg_key_placeholder",
        "granted_on": "2025-05-03",
        "access_level": "full"
      }
    ],
    "contributors": [
      {
        "username": "contributor1",
        "email": "contributor1@example.com",
        "gpg_key_id": "contributor_gpg_key",
        "granted_on": "2025-05-03",
        "access_level": "contributor"
      }
    ],
    "viewers": [
      {
        "username": "viewer1",
        "email": "viewer1@example.com",
        "gpg_key_id": "",
        "granted_on": "2025-05-03",
        "access_level": "viewer"
      }
    ]
  },
  "access_levels": {
    "full": { /* details of full access */ },
    "contributor": { /* details of contributor access */ },
    "viewer": { /* details of viewer access */ }
  }
}
```

## Berechtigungsverwaltung

Für die Berechtigungsverwaltung stehen zwei Skripte zur Verfügung:

1. `permissions-parser.sh` (empfohlen): Robuste Lösung mit verbesserten Funktionen
2. `permissions-manage.sh` (legacy): Ältere Version, erfordert jq

### Verwendung von permissions-parser.sh

Die empfohlene Methode zur Verwaltung von Berechtigungen:

#### Benutzer auflisten

```bash
./core/scripts/permissions-parser.sh list
```

#### Benutzer hinzufügen

```bash
./core/scripts/permissions-parser.sh add "role" "username" "email@example.com" 
```

Wobei `role` einer der folgenden Werte sein kann: `admin`, `contributor`, `viewer`.

#### Benutzer entfernen

```bash
./core/scripts/permissions-parser.sh remove "email@example.com"
```

#### Benutzer aktualisieren

```bash
./core/scripts/permissions-parser.sh update "email@example.com" "new_role"
```

### Ältere Methode (permissions-manage.sh)

Falls aus Kompatibilitätsgründen benötigt:

#### Benutzer hinzufügen

```bash
./core/scripts/permissions-manage.sh add "username" "email@example.com" "role"
```

#### Benutzer entfernen

```bash
./core/scripts/permissions-manage.sh remove "email@example.com"
```

#### GPG-Schlüssel hinzufügen

```bash
./core/scripts/permissions-manage.sh gpg "email@example.com" "gpg_key_id"
```

#### Benutzer auflisten

```bash
./core/scripts/permissions-manage.sh list
```

## Git-Crypt Zugriff gewähren

Wenn ein Benutzer Zugriff auf verschlüsselte Inhalte erhalten soll, müssen zwei Schritte durchgeführt werden:

1. Benutzer zur Berechtigungsdatei hinzufügen (wie oben beschrieben)
2. GPG-Schlüssel für git-crypt hinzufügen:

```bash
# Importiere den GPG-Schlüssel des Benutzers
gpg --import user_public_key.gpg

# Füge den Benutzer zu git-crypt hinzu
git-crypt add-gpg-user user@email.com
```

## Berechtigungsprüfung

Das System verwendet das `permissions-check.sh` Skript, um Berechtigungen während der Installation und für bestimmte Operationen zu überprüfen:

```bash
./core/scripts/permissions-check.sh "username" "email@example.com"
```

Das Skript gibt einen Erfolgs- oder Fehlercode zurück, je nachdem, ob der Benutzer Zugriff hat, und zeigt die entsprechende Zugriffsebene an.

## Sicherheitsüberlegungen

- Die Berechtigungsdatei enthält keine sensiblen Informationen und ist daher nicht verschlüsselt
- GPG-Schlüssel und API-Schlüssel sind immer verschlüsselt
- Benutzerprofile mit sensiblen Informationen sind verschlüsselt
- Nur Administratoren sollten Berechtigungen verwalten

## Best Practices

1. **Regelmäßige Überprüfung**: Überprüfe regelmäßig die Berechtigungsliste und entferne inaktive Benutzer
2. **Minimalzugriff**: Gewähre nur die Rechte, die tatsächlich benötigt werden
3. **Sicherer Schlüsselaustausch**: Übertrage GPG-Schlüssel sicher (verschlüsselte E-Mail, sichere Dateifreigabe)
4. **Dokumentation**: Führe ein Protokoll über Berechtigungsänderungen
5. **Notfallplan**: Habe einen Plan für den Fall eines Schlüsselverlusts oder -kompromittierung