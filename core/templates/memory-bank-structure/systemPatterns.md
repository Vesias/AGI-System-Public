# VibeApp Systemarchitektur und Design-Patterns

Datum: 03.05.2025

## Architektur-Übersicht

VibeApp folgt einer modernen, verteilten Architektur, die Client- und Server-Komponenten effektiv kombiniert:

```
+--------------------------------------------------+
|                    CLIENT                         |
|  +----------------+  +------------------------+   |
|  | Presentation   |  | Local State & Storage  |   |
|  | - UI Components|  | - Zustand              |   |
|  | - 3D Renderer  |  | - IndexedDB            |   |
|  +----------------+  +------------------------+   |
|  +----------------+  +------------------------+   |
|  | Data Fetching  |  | Offline Capabilities   |   |
|  | - React Query  |  | - Service Worker       |   |
|  | - tRPC Client  |  | - Sync Engine          |   |
|  +----------------+  +------------------------+   |
+--------------------------------------------------+
                         ^
                         |
                         v
+--------------------------------------------------+
|                    SERVER                         |
|  +----------------+  +------------------------+   |
|  | API Layer      |  | Authentication         |   |
|  | - tRPC Router  |  | - Supabase Auth        |   |
|  | - Edge Functions|  | - OAuth Providers      |   |
|  +----------------+  +------------------------+   |
|  +----------------+  +------------------------+   |
|  | Data Access    |  | AI Services            |   |
|  | - Prisma       |  | - Recommendation Engine|   |
|  | - Supabase     |  | - Pattern Recognition  |   |
|  +----------------+  +------------------------+   |
+--------------------------------------------------+
                         ^
                         |
                         v
+--------------------------------------------------+
|                  DATABASE                         |
|  +----------------+  +------------------------+   |
|  | PostgreSQL     |  | Analytics & Monitoring |   |
|  | - User Data    |  | - Usage Metrics        |   |
|  | - Encrypted    |  | - Performance Data     |   |
|  |   Records      |  | - Error Tracking       |   |
|  +----------------+  +------------------------+   |
+--------------------------------------------------+
```

## Design-Patterns

### 1. Atomic Design System

Die UI-Komponenten folgen dem Atomic Design Prinzip:

- **Atoms**: Grundlegende UI-Elemente (Buttons, Inputs, Icons)
- **Molecules**: Kombinationen aus Atoms (Form-Felder, Emoticon-Selector)
- **Organisms**: Komplexe UI-Sektionen (Mood Entry Form, Visualization Panel)
- **Templates**: Seitenlayouts ohne Inhalt
- **Pages**: Vollständige Seitenansichten mit Daten

```tsx
// Atom-Beispiel: Button
const Button = ({ children, variant = "primary", ...props }) => (
  <button 
    className={cn(
      "px-4 py-2 rounded-md font-medium",
      variant === "primary" && "bg-vibe-primary text-white",
      variant === "secondary" && "bg-vibe-secondary text-vibe-primary"
    )}
    {...props}
  >
    {children}
  </button>
);

// Molecule-Beispiel: EmoticonSelector
const EmoticonSelector = ({ selected, onChange }) => (
  <div className="flex gap-2">
    {emotions.map((emotion) => (
      <Emoticon
        key={emotion.id}
        emotion={emotion}
        isSelected={selected === emotion.id}
        onClick={() => onChange(emotion.id)}
      />
    ))}
  </div>
);
```

### 2. Server/Client Component Pattern

Klare Trennung zwischen Server- und Client-Komponenten:

```tsx
// Server Component (app/dashboard/page.tsx)
export default async function DashboardPage() {
  const userData = await getUserData();
  
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

### 3. Repository Pattern für Datenzugriff

```typescript
// repositories/mood-entry-repository.ts
export class MoodEntryRepository {
  // Lokaler Speicher
  static async saveLocally(entry: MoodEntry): Promise<void> {
    await db.moodEntries.put(entry);
  }
  
  // Remote-Speicher mit Verschlüsselung
  static async saveRemote(entry: MoodEntry): Promise<void> {
    const encryptedEntry = await encryptEntry(entry);
    await supabase.from('mood_entries').insert(encryptedEntry);
  }
  
  // Synchronisierung
  static async sync(): Promise<void> {
    const localEntries = await db.moodEntries
      .where('synced').equals(false)
      .toArray();
      
    // Batch-Upload
    await Promise.all(
      localEntries.map(entry => this.saveRemote(entry))
    );
    
    // Markiere als synchronisiert
    await db.moodEntries
      .where('id').anyOf(localEntries.map(e => e.id))
      .modify({ synced: true });
  }
}
```

### 4. Offline-First Synchronization Pattern

```typescript
// hooks/useMoodEntry.ts
export function useMoodEntry() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (entry: MoodEntry) => {
      // Immer zuerst lokal speichern
      await MoodEntryRepository.saveLocally(entry);
      
      // Versuche Remote-Speicherung, wenn online
      if (navigator.onLine) {
        try {
          await MoodEntryRepository.saveRemote(entry);
          await db.moodEntries
            .where('id').equals(entry.id)
            .modify({ synced: true });
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

### 5. 3D Visualization Pattern

```typescript
// components/visualization/mood-landscape.tsx
"use client";

export function MoodLandscape({ entries }) {
  // Gruppiere nach Tagen
  const dataByDay = useMemo(() => groupByDay(entries), [entries]);
  
  return (
    <Canvas>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      
      {Object.entries(dataByDay).map(([day, dayEntries], index) => (
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
        minDistance={5}
        maxDistance={20}
      />
    </Canvas>
  );
}

// DayColumn.tsx
function DayColumn({ entries, position, day }) {
  const avgMood = useMemo(() => calculateAvgMood(entries), [entries]);
  const color = moodToColor(avgMood);
  
  return (
    <group position={position}>
      <Text position={[0, -2, 0]}>{formatDay(day)}</Text>
      {entries.map((entry, i) => (
        <MoodSphere 
          key={entry.id}
          entry={entry}
          position={[0, i * 0.5, 0]}
          onClick={() => showEntryDetails(entry)}
        />
      ))}
    </group>
  );
}
```

### 6. Command Pattern für Aktionen

```typescript
// commands/mood-commands.ts
export const moodCommands = {
  addMoodEntry: async (entry: MoodEntry): Promise<void> => {
    // Validierung
    validateMoodEntry(entry);
    
    // Lokale Speicherung
    await MoodEntryRepository.saveLocally(entry);
    
    // Event-Logging
    logUserAction('add_mood_entry', { moodValue: entry.value });
    
    // Synchronisierung anstoßen
    if (navigator.onLine) {
      await MoodEntryRepository.sync();
    }
  },
  
  updateMoodEntry: async (id: string, updates: Partial<MoodEntry>): Promise<void> => {
    // Validierung
    if (updates.value) validateMoodValue(updates.value);
    
    // Aktualisierung
    const entry = await db.moodEntries.get(id);
    const updatedEntry = { ...entry, ...updates, updatedAt: new Date() };
    
    await MoodEntryRepository.saveLocally(updatedEntry);
    
    // Event-Logging
    logUserAction('update_mood_entry', { entryId: id });
    
    // Synchronisierung
    if (navigator.onLine) {
      await MoodEntryRepository.sync();
    }
  }
};
```

## Datenbankschema

```prisma
// schema.prisma
model User {
  id            String       @id @default(uuid())
  email         String       @unique
  name          String?
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt
  settings      Json?
  moodEntries   MoodEntry[]
  activities    Activity[]
  insights      Insight[]
}

model MoodEntry {
  id            String       @id @default(uuid())
  userId        String
  user          User         @relation(fields: [userId], references: [id])
  value         Int          // 1-10 Skala
  emotion       String       // primary emotion
  notes         String?
  activities    Activity[]
  location      String?
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt
  encryptedData String?      // E2E-verschlüsselte zusätzliche Daten
}

model Activity {
  id            String       @id @default(uuid())
  name          String
  icon          String?
  userId        String
  user          User         @relation(fields: [userId], references: [id])
  moodEntries   MoodEntry[]
  createdAt     DateTime     @default(now())
}

model Insight {
  id            String       @id @default(uuid())
  userId        String
  user          User         @relation(fields: [userId], references: [id])
  type          String       // "correlation", "pattern", "recommendation"
  content       String
  createdAt     DateTime     @default(now())
  isRead        Boolean      @default(false)
}
```

## Sicherheits- und Datenschutzpatterns

### 1. End-to-End-Verschlüsselung

```typescript
// utils/encryption.ts
export async function generateUserKey(password: string, email: string): Promise<CryptoKey> {
  const salt = await deriveKeySalt(email);
  
  // Schlüssel aus Passwort ableiten (PBKDF2)
  return crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt,
      iterations: 100000,
      hash: 'SHA-256'
    },
    await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password),
      { name: 'PBKDF2' },
      false,
      ['deriveKey']
    ),
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  );
}

export async function encryptEntry(entry: MoodEntry, key: CryptoKey): Promise<EncryptedMoodEntry> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  
  // Sensitive Daten verschlüsseln
  const sensitiveData = JSON.stringify({
    notes: entry.notes,
    location: entry.location,
    customFields: entry.customFields
  });
  
  const encryptedData = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    new TextEncoder().encode(sensitiveData)
  );
  
  // Kombiniere IV und verschlüsselte Daten
  const encryptionBundle = {
    iv: Array.from(iv),
    data: Array.from(new Uint8Array(encryptedData))
  };
  
  // Erstelle Entry mit verschlüsselten Daten
  return {
    ...entry,
    notes: undefined,
    location: undefined,
    customFields: undefined,
    encryptedData: JSON.stringify(encryptionBundle)
  };
}
```

### 2. Berechtigungssystem

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const session = getSupabaseSession(request);
  
  // Prüfe Authentifizierung für geschützte Routen
  if (
    !session && 
    (request.nextUrl.pathname.startsWith('/dashboard') ||
     request.nextUrl.pathname.startsWith('/api/protected'))
  ) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  // Prüfe Premium-Zugang
  if (
    request.nextUrl.pathname.startsWith('/premium') &&
    !isPremiumUser(session)
  ) {
    return NextResponse.redirect(new URL('/upgrade', request.url));
  }
  
  return NextResponse.next();
}
```

## Performance-Optimierungen

### 1. Virtualisierung für lange Listen

```tsx
// components/mood-history-list.tsx
import { useVirtualizer } from '@tanstack/react-virtual';

export function MoodHistoryList({ entries }) {
  const parentRef = useRef<HTMLDivElement>(null);
  
  const virtualizer = useVirtualizer({
    count: entries.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80, // Höhe jedes Eintrags
  });
  
  return (
    <div 
      ref={parentRef}
      className="h-[600px] overflow-auto"
    >
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            <MoodEntryCard entry={entries[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 2. Progressive Rendering der 3D-Visualisierung

```tsx
// hooks/use-progressive-detail.ts
export function useProgressiveDetail() {
  const [detailLevel, setDetailLevel] = useState('low');
  const frameLoop = useThree((state) => state.frameloop);
  
  // Steigere Detail-Level nach initialem Rendering
  useEffect(() => {
    // Niedrige Details sofort
    setDetailLevel('low');
    
    // Mittlere Details nach 100ms
    const t1 = setTimeout(() => setDetailLevel('medium'), 100);
    
    // Hohe Details nach 500ms wenn nicht interagiert wird
    const t2 = setTimeout(() => setDetailLevel('high'), 500);
    
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
    };
  }, []);
  
  // Reduziere Details während Interaktion
  useFrame(() => {
    if (frameLoop === 'always') {
      // Nutzer interagiert, reduziere Details
      setDetailLevel('low');
    }
  });
  
  return detailLevel;
}
```

## Testmuster

```typescript
// tests/mood-entry.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MoodEntryForm } from '@/components/mood-entry-form';
import { mockMoodRepository } from '@/mocks/repositories';

jest.mock('@/repositories/mood-entry-repository', () => mockMoodRepository);

describe('MoodEntryForm', () => {
  it('should save entry when form is submitted', async () => {
    // Arrange
    render(<MoodEntryForm />);
    
    // Act
    await userEvent.click(screen.getByTestId('emotion-happy'));
    await userEvent.click(screen.getByRole('button', { name: /save/i }));
    
    // Assert
    await waitFor(() => {
      expect(mockMoodRepository.saveLocally).toHaveBeenCalledWith(
        expect.objectContaining({
          emotion: 'happy',
          value: expect.any(Number)
        })
      );
    });
  });
});
```

Diese Patterns und Strukturen bilden die Grundlage der VibeApp-Architektur und werden während der Entwicklung kontinuierlich verfeinert und erweitert.