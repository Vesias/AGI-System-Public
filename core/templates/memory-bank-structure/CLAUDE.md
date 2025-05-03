# CLAUDE.md

Dieses Dokument bietet Anweisungen für Claude Code bei der Arbeit mit dem VibeApp-Projekt.

## Projektstruktur

VibeApp folgt dem Vibe Coding Framework mit folgenden Hauptverzeichnissen:

- `/app`: Next.js App Router Struktur mit Pages und Layouts
- `/components`: React-Komponenten nach Atomic Design
- `/hooks`: Custom React Hooks
- `/lib`: Utility-Funktionen und Bibliotheken
- `/types`: TypeScript-Typdefinitionen
- `/public`: Statische Assets
- `/prisma`: Datenbank-Schema und Migrations
- `/memory-bank`: Projektdokumentation und Knowledge-Base

## Build-Befehle

```bash
# Entwicklungsserver starten
npm run dev

# Typüberprüfung
npm run typecheck

# Linting
npm run lint

# Unit-Tests
npm run test

# E2E-Tests
npm run test:e2e

# Einzelnen Test ausführen
npm run test -- -t "MoodEntryForm"

# Build erstellen
npm run build

# Produktionsserver starten
npm run start
```

## Code-Style

- **TypeScript**: Strict Mode, explizite Types für alle Props
- **Komponenten**: Server Components als Default, "use client" nur bei Bedarf
- **Styling**: Tailwind CSS mit shadcn/ui als Basis
- **State**: React Query für Server-State, Zustand für UI-State
- **Imports**: Absolute Imports mit `@/`-Prefix verwenden
- **Tests**: Co-located Tests in `__tests__`-Ordnern

## 3D-Visualisierung

Beim Bearbeiten von 3D-Komponenten:
- Performance-First-Ansatz
- Canvas-Größe und Renderer-Konfiguration beachten
- Immer alternativen 2D-Modus mitentwickeln
- `useFrame` sparsam verwenden

## Wichtige Dateien

- `/app/providers.tsx`: Zentrale Provider-Konfiguration
- `/lib/supabase.ts`: Supabase-Client und Hilfsfunktionen
- `/components/ui/index.ts`: UI-Komponenten-Exports
- `/hooks/useMoodEntry.ts`: Core Hook für Stimmungseingabe
- `/components/visualization/MoodLandscape.tsx`: 3D-Hauptvisualisierung