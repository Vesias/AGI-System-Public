# Vibe Coding Framework

Das Vibe Coding Framework ist ein moderner Full-Stack-Entwicklungsansatz für Web- und Blockchain-Anwendungen. Dieses Dokument beschreibt die Komponenten, Konzepte und Best Practices des Frameworks.

## Übersicht

Vibe Coding ist ein kuratierter Stack moderner Technologien, der:

- Performance und Benutzererfahrung priorisiert
- Typsicherheit über die gesamte Anwendung hinweg gewährleistet
- Developer Experience durch integrierte Tools verbessert
- Best Practices aus der Webentwicklung konsolidiert
- Einen klaren Entwicklungspfad für komplexe Anwendungen bietet

## Core Stack (Kernkomponenten)

### UI/SSR: Next.js 15
- **App Router**: Moderne Routingarchitektur
- **Turbopack**: Schnelle Build-Zeiten
- **React 19**: Moderne React-Features wie Server Components
- **TypeScript**: Vollständige Typsicherheit

### DB + Auth: Supabase
- **PostgreSQL**: Robuste, relationale Datenbank
- **Row-Level Security**: Granulare Zugriffskontrollen
- **TypeScript Edge-Funktionen**: Serverlose Funktionen mit Deno
- **Auth-System**: Integrierte Authentifizierung

### Hosting: Vercel
- **Preview-Deployments**: Automatische Previews für PRs
- **Edge Runtime**: Globale Performance
- **Analytics**: Integriertes Monitoring
- **CI/CD**: Automatisierte Deployments

### Component Kit: shadcn/ui + Tailwind
- **Unstyled Components**: Anpassbare UI-Komponenten
- **Utility-First CSS**: Flexibles Styling
- **100% TypeScript**: Vollständig typisiert
- **Themes**: Einfache Theming-Unterstützung

### 3D/Visuals: Three.js + react-three-fiber
- **WebGL-Rendering**: Hochleistungsgrafik
- **Deklaratives 3D**: React-Paradigma für 3D
- **Framer Motion 3D**: Animationen für 3D-Objekte
- **Performance-Optimierungen**: Für mobile Geräte

## Erweiterungen für Blockchain-Integration

### Ethereum & Layer-2
- **wagmi + viem**: React Hooks für Ethereum
- **RainbowKit**: Wallet-Integration
- **WalletConnect v2**: Multi-Wallet-Support

### Solana
- **Phantom Wallet**: Multi-Chain-Integration (SOL, ETH, BTC)
- **Anchor Framework**: Smart Contract-Entwicklung
- **Metaplex**: NFT-Standards und -Tools

## DX-, Safety- & Observability-Layer

### End-to-End-Types: tRPC
- **Vollständige API-Typsicherheit**: Frontend und Backend
- **Automatische API-Dokumentation**: Typen als Dokumentation
- **Schemavalidierung**: Integriert mit Zod

### Runtime-Validation: Zod
- **Schemavalidierung**: Typsichere Validierung
- **Integration mit Forms**: Formularvalidierung
- **API-Absicherung**: Request/Response-Validierung

### Data-Sync: TanStack Query v5
- **Server-State Management**: Caching und Invalidierung
- **Optimistic Updates**: Bessere UX
- **Echtzeit-Integration**: Mit Supabase Realtime

### Testing: Playwright
- **End-to-End-Tests**: Browserübergreifend
- **Component Testing**: Isolierte Tests
- **Visual Regression**: UI-Konsistenz

### Error-Tracking: Sentry
- **Fehlererfassung**: Frontend und Backend
- **Performance-Monitoring**: Core Web Vitals
- **Trace-Analyse**: Debuggen komplexer Probleme

## Projektstruktur

Eine typische Vibe-Coding-Projektstruktur sieht wie folgt aus:

```
project-root/
├── APP/                       # Anwendungscode
│   ├── src/                   # Quellcode
│   │   ├── app/               # Next.js App Router
│   │   │   ├── layout.tsx     # Root Layout
│   │   │   ├── page.tsx       # Homepage
│   │   │   └── [...routes]/   # Weitere Routen
│   │   ├── components/        # React-Komponenten
│   │   │   ├── ui/            # Basis-UI-Komponenten
│   │   │   └── [feature]/     # Feature-spezifische Komponenten
│   │   ├── hooks/             # Custom React Hooks
│   │   ├── lib/               # Utilities und Bibliotheken
│   │   ├── server/            # Servercode
│   │   │   ├── api/           # API-Routen
│   │   │   ├── db/            # Datenbank-Zugriff
│   │   │   └── auth/          # Authentifizierung
│   │   ├── styles/            # Globale Styles
│   │   └── types/             # TypeScript-Typdefinitionen
│   ├── public/                # Statische Assets
│   ├── tests/                 # Tests
│   └── package.json           # Abhängigkeiten
├── MARKETING/                 # Marketing-Materialien
├── FINANCE/                   # Finanzielle Dokumente
├── DOCS/                      # Dokumentation
└── memory-bank/               # Projektdokumentation und Kontext
```

## Best Practices

### Server/Client-Komponententrennung

```tsx
// Server Component (app/dashboard/page.tsx)
export default async function DashboardPage() {
  const userData = await getUserData(); // Server-Side-Daten
  
  return (
    <DashboardLayout>
      <UserStats data={userData.stats} />
      <ClientVisualization initialData={userData.moodEntries} />
    </DashboardLayout>
  );
}

// Client Component (components/client-visualization.tsx)
"use client";

import { useThree, Canvas } from "@react-three/fiber";

export function ClientVisualization({ initialData }) {
  // Client-side interaktive Logik hier
  return (
    <div className="h-[50vh]">
      <Canvas>
        <MoodVisualization data={initialData} />
      </Canvas>
    </div>
  );
}
```

### API-Typsicherheit mit tRPC

```tsx
// server/api/router.ts
export const appRouter = createTRPCRouter({
  users: createTRPCRouter({
    getProfile: publicProcedure
      .input(z.object({ userId: z.string() }))
      .query(async ({ ctx, input }) => {
        return ctx.db.user.findUnique({
          where: { id: input.userId },
        });
      }),
  }),
});

// components/ProfileCard.tsx
export function ProfileCard({ userId }: { userId: string }) {
  const { data, isLoading } = api.users.getProfile.useQuery({ userId });
  
  if (isLoading) return <Skeleton />;
  
  return <div>{data.name}</div>; // Vollständig typisiert!
}
```

### 3D-Visualisierung

```tsx
// components/visualization/MoodLandscape.tsx
"use client";

export function MoodLandscape({ entries }) {
  return (
    <Canvas>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      
      {Object.entries(entries).map(([day, dayEntries], index) => (
        <DayColumn 
          key={day}
          position={[index * 2, 0, 0]}
          entries={dayEntries}
          day={day}
        />
      ))}
      
      <OrbitControls 
        enableZoom={true}
        enablePan={true}
      />
    </Canvas>
  );
}
```

### Offline-First mit React Query

```tsx
// hooks/useMoodEntry.ts
export function useMoodEntry() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (entry: MoodEntry) => {
      // Immer zuerst lokal speichern
      await saveLocally(entry);
      
      // Versuche Remote-Speicherung, wenn online
      if (navigator.onLine) {
        try {
          await saveRemote(entry);
          await markAsSynced(entry.id);
        } catch (error) {
          // Bei Fehler bleibt der Eintrag unsynced
          console.error('Remote sync failed, will retry later', error);
        }
      }
      
      return entry;
    },
    onSuccess: () => {
      // Cache invalidieren
      queryClient.invalidateQueries({ queryKey: ['moodEntries'] });
    },
  });
}
```

## Vibe Coding Projekt erstellen

Das AGI-System bietet ein spezielles Skript für Vibe-Coding-Projekte:

```bash
~/.claude/templates/project-types/vibe-coding-init.sh MeinVibeProjekt
```

Dies erstellt ein neues Projekt mit:
- Vorkonfiguriertem Next.js 15 mit App Router
- Tailwind CSS und shadcn/ui
- TypeScript-Konfiguration
- Supabase-Integration
- 3D-Visualisierungskomponenten (react-three-fiber)
- Vollständiger Memory-Bank

## Weitere Ressourcen

- [Next.js Dokumentation](https://nextjs.org/docs)
- [Supabase Dokumentation](https://supabase.com/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [shadcn/ui](https://ui.shadcn.com)
- [TanStack Query](https://tanstack.com/query)
- [tRPC](https://trpc.io)
- [React Three Fiber](https://docs.pmnd.rs/react-three-fiber)