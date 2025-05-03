# AGI-System Testframework

Dieses Verzeichnis enthält Tests und Testressourcen für das AGI-System.

## Teststruktur

Die Tests sind in drei Kategorien unterteilt:

1. **Unit-Tests**: Testen einzelne Komponenten isoliert
2. **Integrationstests**: Testen das Zusammenspiel mehrerer Komponenten
3. **Systemtests**: Testen das Gesamtsystem oder größere Teilsysteme

## Aktuelle Tests

### Unit-Tests
- **setup-script-test.sh**: Überprüft die Grundfunktionalität der Setup-Skripte
- **structure-test.sh**: Überprüft die Grundstruktur des AGI-Systems
- **documentation-test.sh**: Überprüft die Vollständigkeit der Dokumentation
- **permissions-parser-test.sh**: Überprüft die Grundfunktionalität des permissions-parser.sh Skripts

### Integrationstests
- **claude-code-integration-test.sh**: Überprüft die Integration von Claude Code mit dem AGI-System
- **permissions-parser-integration-test.sh**: Überprüft die Integration und Funktionalität des permissions-parser.sh Skripts

### Systemtests
- **installation-test.sh**: Überprüft den vollständigen Installationsprozess
- **init-project-permissions-test.sh**: Überprüft die Integration von permissions-parser.sh in init-project-full.sh

## Testausführung

Um alle Tests auszuführen:

```bash
# Alle Tests ausführen
/home/jan/AGI-System-Public/core/scripts/run-tests.sh

# Ausführliche Ausgabe
/home/jan/AGI-System-Public/core/scripts/run-tests.sh --verbose

# Nur Unit-Tests ausführen
/home/jan/AGI-System-Public/core/scripts/run-tests.sh --test-type unit

# Schneller Testlauf (nur Tests mit hoher Priorität)
/home/jan/AGI-System-Public/core/scripts/run-tests.sh --quick
```

## Eigene Tests erstellen

Um einen neuen Test zu erstellen:

1. Wählen Sie die geeignete Test-Kategorie (unit, integration, system)
2. Erstellen Sie eine neue .sh-Datei im entsprechenden Verzeichnis
3. Verwenden Sie die Vorlage aus dem jeweiligen Verzeichnis als Ausgangspunkt
4. Machen Sie die Datei ausführbar (`chmod +x mein-test.sh`)

Beispiel für einen Unit-Test:

```bash
#!/usr/bin/env bash
# Test für Feature XYZ

# Test-Informationen
TEST_NAME="Feature XYZ Test"
TEST_DESCRIPTION="Überprüft die Funktionalität von Feature XYZ"
TEST_PRIORITY="medium"  # high, medium, low

# Test-Funktion
run_test() {
    # Zu testender Code oder Funktionalität
    
    # Hier den eigentlichen Test implementieren
    # Beispiel: Eine Funktion aufrufen und das Ergebnis prüfen
    
    # 0 zurückgeben bei Erfolg, andere Werte bei Fehler
    return 0
}

# Test ausführen und Ergebnis zurückgeben
run_test
exit $?
```

## Testbericht

Nach der Ausführung der Tests wird ein HTML-Bericht im temporären Verzeichnis erzeugt. Der Pfad zum Bericht wird am Ende der Testausführung angezeigt.

Um die Berichterstellung zu deaktivieren:

```bash
/home/jan/AGI-System-Public/core/scripts/run-tests.sh --no-report
```

## Continuous Integration

Die Tests können in eine CI/CD-Pipeline integriert werden. Beispiel für eine GitHub Actions Konfiguration:

```yaml
name: AGI-System Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Abhängigkeiten installieren
      run: |
        sudo apt-get update
        sudo apt-get install -y git bash
    
    - name: Tests ausführen
      run: |
        chmod +x ./core/scripts/run-tests.sh
        ./core/scripts/run-tests.sh --no-report
```

## Weitere Optionen

Für eine vollständige Liste der Optionen:

```bash
/home/jan/AGI-System-Public/core/scripts/run-tests.sh --help
```