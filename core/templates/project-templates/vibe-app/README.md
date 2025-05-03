# VibeApp Projektvorlage

Diese Vorlage bietet die grundlegende Struktur für eine moderne Progressive Web App mit 3D-Visualisierung, Offline-Funktionalität und KI-Integration.

## Projektüberblick

VibeApp ist eine moderne PWA, die es Nutzern ermöglicht, ihre Stimmung und Aktivitäten zu verfolgen und zu visualisieren. Die App nutzt KI-basierte Analyse, um personalisierte Wohlbefindensvorschläge zu generieren und bietet interaktive 3D-Visualisierungen der gesammelten Daten.

## Technologie-Stack

- **Frontend**: Next.js 15, React 19, TypeScript
- **Styling**: Tailwind CSS, shadcn/ui
- **State Management**: React Query, Zustand
- **Backend**: Supabase (Auth, Database, Edge Functions)
- **3D-Visualisierung**: Three.js, react-three-fiber
- **Offline-Funktionalität**: Service Workers, IndexedDB
- **Datenvisualisierung**: Framer Motion

## Verzeichnisstruktur

```
VibeApp/
├── APP/                    # Anwendungscode
├── MARKETING/              # Marketingmaterialien
├── FINANCE/                # Finanzdokumente
├── DOCS/                   # Dokumentation
└── memory-bank/            # Projektdokumentation
    ├── projectbrief.md     # Projektübersicht
    ├── productContext.md   # Produktkontext
    ├── activeContext.md    # Aktueller Fokus
    ├── systemPatterns.md   # Systemarchitektur
    ├── techContext.md      # Technologie-Dokumentation
    ├── progress.md         # Fortschrittsdokumentation
    └── .clauderules        # Projektspezifische Regeln
```

## Getting Started

1. Projekt initialisieren:
   ```bash
   ~/.claude/init_project.sh MeinVibeApp --template=vibe-app
   ```

2. Abhängigkeiten installieren:
   ```bash
   cd MeinVibeApp/APP
   npm install
   ```

3. Entwicklungsserver starten:
   ```bash
   npm run dev
   ```

4. Datenbankkonfiguration:
   - Supabase-Projekt erstellen
   - Umgebungsvariablen in .env konfigurieren

## Hauptfunktionalitäten

- Tägliche Stimmungs- und Aktivitätserfassung
- 3D-Visualisierung der Stimmungsdaten
- KI-gestützte Analyse und Empfehlungen
- Offline-Funktionalität
- Teilen von Stimmungszusammenfassungen