# VibeApp Technologiekontext

Datum: 03.05.2025

## Technologie-Stack

VibeApp basiert auf dem Vibe Coding Framework mit folgenden Kernkomponenten:

### Frontend
- **Next.js 15**: App Router, Server Components, React Server Actions
- **React 19**: Hooks, Server Components, Suspense
- **TypeScript**: Strenge Typisierung und Developer Experience
- **Tailwind CSS**: Utility-First Styling
- **shadcn/ui**: Unstyled, zugängliche Komponenten-Bibliothek
- **Framer Motion**: Animation und Interaktionseffekte
- **Three.js + react-three-fiber**: 3D-Visualisierung und -Interaktion

### Backend & Datenbanken
- **Supabase**: Backend as a Service (BaaS)
  - PostgreSQL-Datenbank
  - Authentifizierung und Autorisierung
  - Edge Functions (Deno-basiert)
  - Realtime-Funktionalität
- **Prisma**: Type-safe Database Client
- **tRPC + Zod**: End-to-End Typsicherheit für API-Aufrufe

### State Management & Daten
- **TanStack Query v5**: Server State Management
- **Zustand**: Client State Management
- **IndexedDB (Dexie.js)**: Lokale Datenbank für Offline-Zugriff 
- **Service Worker**: Offline-Funktionalität
- **Web Crypto API**: Ende-zu-Ende-Verschlüsselung

### Hosting & Infrastruktur
- **Vercel**: Frontend-Hosting, Edge Functions, Analytics
- **GitHub Actions**: CI/CD-Pipeline
- **Playwright**: E2E-Testing
- **Vitest**: Unit- und Integrationstests
- **TypeDoc**: Automatische Dokumentationsgenerierung

### Analytics & Monitoring
- **Vercel Analytics**: Performance-Monitoring
- **Sentry**: Fehlertracking
- **Axiom**: Log-Management
- **PostHog**: Product Analytics (GDPR-konform, EU-gehostet)

## Begründung der Technologieauswahl

### Next.js 15 & React 19
Wir haben uns für die neuesten Versionen entschieden, um aktuelle Funktionen wie Server Components, React Server Actions und verbesserte Caching-Mechanismen zu nutzen. Diese ermöglichen eine bessere Performance und User Experience, besonders bei der komplexen Datenvisualisierung.

### 3D-Visualisierung
React Three Fiber wurde wegen seiner hervorragenden React-Integration ausgewählt, was uns eine deklarative Programmierung von 3D-Szenen ermöglicht. Die Kombination mit Framer Motion 3D vereinfacht die Animation von 3D-Objekten erheblich.

### Offline-First-Ansatz
Durch die Kombination von IndexedDB, Service Workers und React Query können wir eine robuste Offline-Erfahrung bieten. Daten werden lokal gespeichert und bei Verbindung intelligent synchronisiert, was besonders für eine tägliche Tracking-App wichtig ist.

### Ende-zu-Ende-Verschlüsselung
Bei persönlichen Daten wie Stimmungen und mentaler Gesundheit ist Datenschutz essenziell. Die Web Crypto API ermöglicht eine clientseitige Verschlüsselung, sodass unverschlüsselte Daten nie den Browser verlassen.

### Vercel & Supabase
Diese Cloud-Services bieten eine skalierbare, wartungsarme Infrastruktur, die perfekt für unser Entwicklungsteam geeignet ist. Die enge Integration beider Dienste ermöglicht schnelle Iterationen und einfaches Deployment.

## Architektur-Prinzipien

1. **Offline-First**: Die App funktioniert ohne Internetverbindung vollständig
2. **Security by Design**: Datenschutz und Sicherheit als Grundprinzip
3. **Component-First**: Atomic Design mit wiederverwendbaren, selbstdokumentierenden Komponenten
4. **Performance-Optimiert**: Core Web Vitals als zentrale Metriken
5. **Mobile-First**: Optimiert für mobile Nutzung mit Desktop als sekundärem Formfaktor

## Bibliotheken und Abhängigkeiten

### Kern-Dependencies
- next (^15.0.0)
- react (^19.0.0)
- react-dom (^19.0.0)
- typescript (^5.3.0)
- tailwindcss (^4.0.0)
- @tanstack/react-query (^5.0.0)
- zustand (^4.4.0)
- @supabase/supabase-js (^2.39.0)
- framer-motion (^10.16.0)
- @react-three/fiber (^8.15.0)
- @react-three/drei (^9.90.0)
- three (^0.160.0)
- prisma (^5.7.0)
- zod (^3.22.0)
- dexie (^3.2.4)

### Dev-Dependencies
- eslint (^8.55.0)
- prettier (^3.1.0)
- vitest (^1.0.0)
- playwright (^1.40.0)
- @types/react (^19.0.0)
- @types/three (^0.160.0)
- postcss (^8.4.32)
- autoprefixer (^10.4.16)
- tailwind-merge (^2.1.0)
- class-variance-authority (^0.7.0)

## API-Integrationen

1. **Supabase Auth**: Für Authentifizierung und Benutzerkonten
2. **Vibe API**: Interne API für KI-gesteuerte Empfehlungen
3. **OpenAI API**: Für generative Textzusammenfassungen (geplant)
4. **Health-APIs**: Apple HealthKit, Google Fit (geplant)

## Technische Schulden & Risiken

1. **Browser-Unterstützung**: Webkryptographie und IndexedDB könnten in älteren Browsern Probleme verursachen
2. **3D-Performance**: Optimierung für Low-End-Geräte notwendig
3. **Synchronisierungskonflikte**: Bei längerer Offline-Nutzung könnten Konflikte auftreten
4. **PWA-Installation**: Unterschiedliche Erfahrung je nach Browser/Betriebssystem

## Entwicklungsumgebung

- Visual Studio Code mit empfohlenen Extensions
- Node.js v20 LTS
- pnpm als Paketmanager
- Docker für lokale Supabase-Entwicklung
- Git mit Conventional Commits