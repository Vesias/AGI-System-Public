# Memory-Bank System: Leitfaden

Das Memory-Bank-System ist das Herzstück des AGI-Systems und ermöglicht eine kontinuierliche Entwicklung über mehrere Sitzungen hinweg. Dieser Leitfaden erklärt die Struktur, Verwendung und Best Practices für die Arbeit mit der Memory-Bank.

## Grundkonzept

Die Memory-Bank ist eine Sammlung von strukturierten Markdown-Dateien, die das Wissen und den Kontext eines Projekts enthalten. Sie bietet:

- **Kontinuität**: Bewahrt Kontext zwischen Arbeitssitzungen
- **Standardisierung**: Einheitliche Dokumentationsstruktur für alle Projekte
- **Entscheidungsdokumentation**: Nachvollziehbarkeit von Architektur- und Designentscheidungen
- **Fortschrittsüberwachung**: Chronologische Aufzeichnung der Entwicklungsarbeiten
- **Wissenstransfer**: Erleichtert die Einarbeitung neuer Teammitglieder

## Memory-Bank-Struktur

Jedes Projekt enthält einen `memory-bank/`-Ordner mit folgenden Dateien:

### 1. `projectbrief.md`

Enthält die grundlegende Projektdefinition und den Umfang.

**Zweck**: Bietet einen schnellen Überblick über das Projekt, Ziele und Hauptfunktionen.

**Inhalt**:
- Projektübersicht und Vision
- Kernfunktionen
- Zielgruppe
- Technologische Anforderungen
- Geschäftsmodell
- Erfolgskriterien
- Zeitrahmen und Projektteam

### 2. `productContext.md`

Definiert das Problem, das gelöst wird, und den Produktkontext.

**Zweck**: Stellt sicher, dass die Entwicklung auf die Lösung des richtigen Problems ausgerichtet ist.

**Inhalt**:
- Problemdefinition
- Beschreibung der angebotenen Lösung
- Nutzerreise und Interaktionspunkte
- Differenzierung im Markt
- Zukünftige Erweiterungen
- Erfolgsmetriken

### 3. `activeContext.md`

Dokumentiert den aktuellen Entwicklungsfokus und die Prioritäten.

**Zweck**: Stellt sicher, dass die tägliche Entwicklungsarbeit auf die wichtigsten Aspekte ausgerichtet ist.

**Inhalt**:
- Aktuelle Prioritäten
- Status der MRIs (Minimale umsetzbare Inkremente)
- Offene Fragen
- Bekannte Probleme
- Nächste Schritte
- Blockerissues

### 4. `systemPatterns.md`

Definiert die Architektur und Design-Patterns des Systems.

**Zweck**: Dokumentiert technische Entscheidungen und Entwurfsmuster für konsistente Entwicklung.

**Inhalt**:
- Architekturübersicht (oft mit Diagrammen)
- Design-Patterns und Beispielcode
- Datenmodell und Datenbankschema
- Sicherheits- und Datenschutzpatterns
- Performance-Optimierungen
- Testmuster

### 5. `techContext.md`

Beschreibt den verwendeten Technologie-Stack und technische Entscheidungen.

**Zweck**: Dokumentiert die technologischen Grundlagen des Projekts.

**Inhalt**:
- Detaillierter Tech-Stack mit Versionen
- Begründung der Technologieauswahl
- Architektuprinzipien
- Bibliotheken und Abhängigkeiten
- API-Integrationen
- Technische Schulden und Risiken

### 6. `progress.md`

Chronologische Aufzeichnung des Projektfortschritts.

**Zweck**: Bietet einen historischen Überblick über die Entwicklung und erreichte Meilensteine.

**Inhalt**:
- Datierte Einträge
- Abgeschlossene Aufgaben
- Gelöste Probleme
- Getroffene Entscheidungen
- Nächste Schritte

### 7. `.clauderules`

Projektspezifische Regeln, Erkenntnisse und Best Practices.

**Zweck**: Definiert die Richtlinien für die Arbeit am Projekt.

**Inhalt**:
- Projektspezifische Regeln
- Erkenntnisse und Best Practices
- Code-Konventionen
- Praktische Hinweise

## Arbeiten mit der Memory-Bank

### Memory-Bank erstellen

Eine neue Memory-Bank wird automatisch erstellt, wenn du ein Projekt mit dem AGI-System initialisierst:

```bash
~/.claude/init_project.sh MeinProjekt
```

### Memory-Bank aktualisieren

Nach bedeutenden Änderungen solltest du die Memory-Bank aktualisieren:

```bash
~/.claude/update_memory.sh /pfad/zum/projekt
```

Dies aktualisiert automatisch Datumsangaben und fügt neue Einträge in `progress.md` hinzu.

### Memory-Bank konsultieren

Vor der Arbeit an einem Projekt solltest du immer die Memory-Bank konsultieren:

1. Lies `activeContext.md` für den aktuellen Fokus
2. Überprüfe `progress.md` für den aktuellen Stand
3. Konsultiere `systemPatterns.md` für Architekturentscheidungen

### Memory-Bank mit Claude nutzen

Claude kann die Memory-Bank direkt analysieren und nutzen:

```bash
# Memory-Bank analysieren
claude "analysiere die Memory-Bank des Projekts und erstelle eine Zusammenfassung"

# Spezifische Dateien nutzen
claude "erkläre die Architektur basierend auf systemPatterns.md"

# Memory-Bank aktualisieren
claude "aktualisiere progress.md mit einem Eintrag zu den heutigen Änderungen"
```

## Best Practices

1. **Regelmäßige Aktualisierung**: Halte die Memory-Bank nach jeder Arbeitssitzung aktuell
2. **Spezifische Einträge**: Mache konkrete, nicht allgemeine Aufzeichnungen
3. **Entscheidungen dokumentieren**: Erkläre das "Warum" hinter wichtigen Entscheidungen
4. **Fortschritt chronologisch dokumentieren**: Datiere Einträge in `progress.md`
5. **Konsistenter Stil**: Verwende einheitliche Formatierung und Struktur
6. **Codebeispiele einbinden**: Verwende Codeblöcke für Implementierungsdetails
7. **Architekturänderungen kommunizieren**: Halte `systemPatterns.md` aktuell

## Häufige Probleme und Lösungen

### Problem: Memory-Bank wird inkonsistent
**Lösung**: Verwende das update_memory.sh-Skript regelmäßig und folge den vorgegebenen Strukturen

### Problem: Schwierigkeit, Informationen zu finden
**Lösung**: Halte die Struktur konsistent und verwende Überschriften und Aufzählungen für bessere Lesbarkeit

### Problem: Kollaboration in der Memory-Bank
**Lösung**: Verwende Git für Versionskontrolle und kläre Konflikte durch Diskussion

### Problem: Unklare Progression im Projekt
**Lösung**: Halte progress.md chronologisch und achte auf klare Datierung und Meilensteine