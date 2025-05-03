#!/bin/bash
# Vibe-Coding-Projekt Initialisierung

set -e

# Farbdefinitionen für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner anzeigen
echo -e "${BLUE}"
echo "  ____ _       _    _   _ ____  _____   "
echo " / ___| |     / \  | | | |  _ \| ____|  "
echo "| |   | |    / _ \ | | | | | | |  _|    "
echo "| |___| |___/ ___ \| |_| | |_| | |___   "
echo " \____|_____/_/   \_\\___/|____/|_____|  "
echo "                                        "
echo -e "Vibe-Coding-Projekt Initialisierung${NC}"
echo

# Parameter und Standardwerte
PROJECT_NAME=${1:-""}
BASE_DIR=${2:-"$HOME/Schreibtisch/CLAUDE"}
TEMPLATE_DIR="$HOME/.claude/templates"

# Überprüfe Abhängigkeiten
check_dependencies() {
    echo -e "${YELLOW}Überprüfe Abhängigkeiten...${NC}"
    
    # Git prüfen
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Git ist nicht installiert. Bitte installiere Git mit: sudo apt install git${NC}"
        exit 1
    fi
    
    # Node.js prüfen
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Node.js ist nicht installiert. Bitte installiere Node.js mit: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs${NC}"
        exit 1
    fi
    
    # npm prüfen
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}npm ist nicht installiert. Bitte installiere npm mit: sudo apt install npm${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Alle Abhängigkeiten vorhanden.${NC}"
}

# Parameter validieren
validate_params() {
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${RED}Fehler: Kein Projektname angegeben.${NC}"
        echo -e "Verwendung: $0 <PROJEKTNAME> [BASIS-VERZEICHNIS]"
        exit 1
    fi
    
    # Prüfe ob BASE_DIR existiert, wenn nicht, erstelle es
    if [ ! -d "$BASE_DIR" ]; then
        echo -e "${YELLOW}Basisverzeichnis $BASE_DIR existiert nicht. Soll es erstellt werden? (j/n)${NC}"
        read -r ANSWER
        if [[ "$ANSWER" =~ ^[Jj] ]]; then
            mkdir -p "$BASE_DIR"
            echo -e "${GREEN}Basisverzeichnis $BASE_DIR erstellt.${NC}"
        else
            echo -e "${RED}Abbruch: Basisverzeichnis muss existieren.${NC}"
            exit 1
        fi
    fi
    
    # Prüfe ob Projekt bereits existiert
    PROJECT_PATH="$BASE_DIR/$PROJECT_NAME"
    if [ -d "$PROJECT_PATH" ]; then
        echo -e "${RED}Fehler: Projekt $PROJECT_NAME existiert bereits in $BASE_DIR.${NC}"
        exit 1
    fi
}

# Projektstruktur erstellen
create_project_structure() {
    echo -e "${YELLOW}Erstelle Projektstruktur...${NC}"
    
    mkdir -p "$PROJECT_PATH"
    mkdir -p "$PROJECT_PATH/APP"
    mkdir -p "$PROJECT_PATH/MARKETING"
    mkdir -p "$PROJECT_PATH/FINANCE"
    mkdir -p "$PROJECT_PATH/DOCS"
    mkdir -p "$PROJECT_PATH/memory-bank"
    
    echo -e "${GREEN}Verzeichnisstruktur erstellt.${NC}"
}

# Memory-Bank Templates kopieren
copy_templates() {
    echo -e "${YELLOW}Kopiere Memory-Bank Templates...${NC}"
    
    # Datum für Aktualisierung
    TODAY=$(date +"%d.%m.%Y")
    
    # Kopiere und aktualisiere Templates
    if [ -d "$TEMPLATE_DIR/memory-bank-structure" ]; then
        # Bevorzuge die spezielle Memory-Bank-Struktur, wenn vorhanden
        cp -r "$TEMPLATE_DIR/memory-bank-structure/"* "$PROJECT_PATH/memory-bank/"
        
        # Ersetze Platzhalter
        find "$PROJECT_PATH/memory-bank" -type f -exec sed -i "s/VibeApp/$PROJECT_NAME/g" {} \;
        find "$PROJECT_PATH/memory-bank" -type f -exec sed -i "s/03.05.2025/$TODAY/g" {} \;
    else
        # Fallback auf Standard-Templates
        for template in projectbrief.md productContext.md activeContext.md systemPatterns.md techContext.md progress.md .clauderules CLAUDE.md; do
            if [ -f "$TEMPLATE_DIR/$template" ]; then
                # Ersetze Datumsplatzhalter und Projektnamen
                sed "s/DATUM_HEUTE/$TODAY/g; s/PROJEKTNAME/$PROJECT_NAME/g" "$TEMPLATE_DIR/$template" > "$PROJECT_PATH/memory-bank/$template"
                echo -e "  ${GREEN}✓${NC} $template"
            else
                echo -e "  ${RED}✗${NC} $template (nicht gefunden)"
            fi
        done
    fi
    
    echo -e "${GREEN}Memory-Bank Templates kopiert und angepasst.${NC}"
}

# Next.js Projekt erstellen
create_nextjs_project() {
    echo -e "${YELLOW}Erstelle Next.js Projekt...${NC}"
    
    cd "$PROJECT_PATH/APP"
    
    # Temporäre package.json erstellen
    cat > package.json << EOL
{
  "name": "${PROJECT_NAME,,}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  }
}
EOL
    
    # Verzeichnisstruktur erstellen
    mkdir -p src/app
    mkdir -p src/components/{ui,layout,3d}
    mkdir -p src/lib
    mkdir -p src/hooks
    mkdir -p src/server/{api,db,auth}
    mkdir -p src/styles
    mkdir -p src/types
    mkdir -p public
    mkdir -p tests
    
    # App Router Dateien erstellen
    cat > src/app/layout.tsx << EOL
import '@/styles/globals.css';
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: '${PROJECT_NAME}',
  description: 'Created with Vibe Coding Framework',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="de">
      <body className={inter.className}>
        <main className="min-h-screen bg-background">
          {children}
        </main>
      </body>
    </html>
  );
}
EOL
    
    cat > src/app/page.tsx << EOL
import Link from 'next/link';

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 text-center">
      <h1 className="text-4xl font-bold mb-4">${PROJECT_NAME}</h1>
      <p className="text-lg mb-8">Willkommen zu deinem neuen Vibe-Coding-Projekt!</p>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-w-5xl">
        <Link 
          href="https://nextjs.org/docs" 
          className="p-6 border rounded-lg hover:bg-gray-100 transition-colors"
        >
          <h2 className="text-xl font-semibold mb-2">Next.js Docs &rarr;</h2>
          <p>Finde detaillierte Informationen über Next.js Features und API.</p>
        </Link>

        <Link 
          href="https://supabase.com/docs" 
          className="p-6 border rounded-lg hover:bg-gray-100 transition-colors"
        >
          <h2 className="text-xl font-semibold mb-2">Supabase &rarr;</h2>
          <p>Lerne mehr über Supabase, deine Backend-as-a-Service Lösung.</p>
        </Link>

        <Link 
          href="https://docs.pmnd.rs/react-three-fiber/getting-started/introduction" 
          className="p-6 border rounded-lg hover:bg-gray-100 transition-colors"
        >
          <h2 className="text-xl font-semibold mb-2">React Three Fiber &rarr;</h2>
          <p>Entdecke 3D-Visualisierungen mit React Three Fiber.</p>
        </Link>
      </div>
      
      <p className="mt-8 text-sm text-gray-500">
        Erstellt mit dem Vibe Coding Framework
      </p>
    </div>
  );
}
EOL
    
    # Stylesheet erstellen
    cat > src/styles/globals.css << EOL
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    
    --card: 0 0% 100%;
    --card-foreground: 240 10% 3.9%;
    
    --popover: 0 0% 100%;
    --popover-foreground: 240 10% 3.9%;
    
    --primary: 240 5.9% 10%;
    --primary-foreground: 0 0% 98%;
    
    --secondary: 240 4.8% 95.9%;
    --secondary-foreground: 240 5.9% 10%;
    
    --muted: 240 4.8% 95.9%;
    --muted-foreground: 240 3.8% 46.1%;
    
    --accent: 240 4.8% 95.9%;
    --accent-foreground: 240 5.9% 10%;
    
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;

    --border: 240 5.9% 90%;
    --input: 240 5.9% 90%;
    --ring: 240 10% 3.9%;
    
    --radius: 0.5rem;
  }
 
  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    
    --card: 240 10% 3.9%;
    --card-foreground: 0 0% 98%;
    
    --popover: 240 10% 3.9%;
    --popover-foreground: 0 0% 98%;
    
    --primary: 0 0% 98%;
    --primary-foreground: 240 5.9% 10%;
    
    --secondary: 240 3.7% 15.9%;
    --secondary-foreground: 0 0% 98%;
    
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    
    --accent: 240 3.7% 15.9%;
    --accent-foreground: 0 0% 98%;
    
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    
    --border: 240 3.7% 15.9%;
    --input: 240 3.7% 15.9%;
    --ring: 240 4.9% 83.9%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOL
    
    # 3D-Komponente erstellen
    cat > src/components/3d/VibeScene.tsx << EOL
"use client";

import { Canvas } from "@react-three/fiber";
import { OrbitControls, PerspectiveCamera, useGLTF } from "@react-three/drei";
import { Suspense } from "react";

export function VibeScene() {
  return (
    <div className="h-[400px] w-full">
      <Canvas>
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} />
        
        <Suspense fallback={null}>
          <VibeObject />
        </Suspense>
        
        <OrbitControls />
        <PerspectiveCamera makeDefault position={[0, 0, 5]} />
      </Canvas>
    </div>
  );
}

function VibeObject() {
  // Hier später ein 3D-Modell oder eine benutzerdefinierte Geometrie einfügen
  return (
    <mesh>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="purple" />
    </mesh>
  );
}
EOL
    
    # UI-Komponenten erstellen
    cat > src/components/ui/button.tsx << EOL
"use client";

import * as React from "react";
import { VariantProps, cva } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "underline-offset-4 hover:underline text-primary",
      },
      size: {
        default: "h-10 py-2 px-4",
        sm: "h-9 px-3 rounded-md",
        lg: "h-11 px-8 rounded-md",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
EOL
    
    # Utils erstellen
    cat > src/lib/utils.ts << EOL
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOL
    
    # Beispiel-Hook erstellen
    cat > src/hooks/useLocalStorage.ts << EOL
"use client";

import { useState, useEffect } from "react";

export function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T) => void] {
  // State zum Speichern unseres Wertes
  const [storedValue, setStoredValue] = useState<T>(initialValue);

  // Beim Mounten von Hook und Fenster, versuchen wir den Wert zu holen
  useEffect(() => {
    try {
      if (typeof window === "undefined") {
        return;
      }
      
      // Wert aus localStorage holen
      const item = window.localStorage.getItem(key);
      // Parse gespeicherten JSON oder falls keiner, gib initialValue zurück
      setStoredValue(item ? JSON.parse(item) : initialValue);
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  }, [key, initialValue]);

  // Rückgabe einer Wrapper-Funktion um localStorage zu aktualisieren
  const setValue = (value: T) => {
    try {
      // Erlaube value als Funktion, ähnlich wie useState
      const valueToStore =
        value instanceof Function ? value(storedValue) : value;
      // State speichern
      setStoredValue(valueToStore);
      // Speichern in localStorage
      if (typeof window !== "undefined") {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue];
}
EOL
    
    # tsconfig.json erstellen
    cat > tsconfig.json << EOL
{
  "compilerOptions": {
    "target": "es2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOL
    
    # .env Beispiel erstellen
    cat > .env.example << EOL
# Supabase Konfiguration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Umgebungsvariablen
NEXT_PUBLIC_SITE_URL=http://localhost:3000
EOL
    
    # README erstellen
    cat > README.md << EOL
# ${PROJECT_NAME}

Ein Projekt basierend auf dem Vibe Coding Framework.

## Features

- Next.js 15 mit App Router
- Supabase für Datenbank und Auth
- Tailwind CSS für Styling
- 3D-Visualisierung mit React Three Fiber
- TypeScript für Typsicherheit

## Erste Schritte

### Installation

\`\`\`bash
# Abhängigkeiten installieren
npm install

# Entwicklungsserver starten
npm run dev
\`\`\`

### Umgebungsvariablen einrichten

Kopiere \`.env.example\` zu \`.env.local\` und füge deine Supabase-Daten ein.

## Projektstruktur

- \`src/app\`: Next.js App Router
- \`src/components\`: React-Komponenten
  - \`ui\`: Basiskomponenten
  - \`layout\`: Layout-Komponenten
  - \`3d\`: 3D-Visualisierungen
- \`src/lib\`: Hilfsfunktionen
- \`src/hooks\`: Custom React Hooks
- \`src/server\`: Serverseitiger Code
- \`src/styles\`: Globale Styles
- \`src/types\`: TypeScript-Typdeklarationen

## Weitere Informationen

Weitere Dokumentation befindet sich im \`DOCS/\`-Verzeichnis des Projekts.
EOL
    
    # .gitignore erstellen
    cat > .gitignore << EOL
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnp
.pnp.js

# Next.js
.next/
out/
build/
dist/

# Umgebungsvariablen
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Vercel
.vercel

# Testing
coverage/

# Debug
.DS_Store
*.pem
.env.local

# IDE
.vscode/*
!.vscode/settings.json
!.vscode/extensions.json
.idea/
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
EOL
    
    # next.config.js erstellen
    cat > next.config.js << EOL
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['images.unsplash.com'],
  },
  experimental: {
    serverActions: true,
  },
}

module.exports = nextConfig
EOL
    
    # tailwind.config.js erstellen
    cat > tailwind.config.js << EOL
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
EOL
    
    # postcss.config.js erstellen
    cat > postcss.config.js << EOL
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOL
    
    echo -e "${GREEN}Next.js Projekt-Dateien erstellt.${NC}"
}

# Git initialisieren
init_git() {
    echo -e "${YELLOW}Initialisiere Git-Repository...${NC}"
    
    cd "$PROJECT_PATH"
    
    # .gitignore erstellen (falls noch nicht vorhanden)
    if [ ! -f .gitignore ]; then
        cat > .gitignore << EOL
# Betriebssystemdateien
.DS_Store
Thumbs.db

# IDE-Dateien
.idea/
.vscode/*
!.vscode/settings.json
!.vscode/extensions.json

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Next.js
.next/
out/

# Umgebungsvariablen
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Dependencies
package-lock.json
yarn.lock
EOL
    fi
    
    git init
    git add .
    git commit -m "Initialer Commit: Vibe-Coding-Projekt $PROJECT_NAME erstellt"
    
    echo -e "${GREEN}Git-Repository initialisiert.${NC}"
}

# Zusammenfassung anzeigen
show_summary() {
    echo
    echo -e "${GREEN}Vibe-Coding-Projekt $PROJECT_NAME wurde erfolgreich erstellt!${NC}"
    echo
    echo -e "${BLUE}Projektpfad:${NC} $PROJECT_PATH"
    echo -e "${BLUE}Struktur:${NC}"
    echo " ├── APP/                 # Next.js 15 Anwendung"
    echo " │   ├── src/             # Quellcode"
    echo " │   │   ├── app/         # App Router"
    echo " │   │   ├── components/  # React-Komponenten"
    echo " │   │   ├── hooks/       # Custom Hooks"
    echo " │   │   ├── lib/         # Utilities"
    echo " │   │   ├── server/      # Server-Code"
    echo " │   │   ├── styles/      # CSS"
    echo " │   │   └── types/       # TypeScript-Definitionen"
    echo " │   └── public/          # Statische Assets"
    echo " ├── MARKETING/"
    echo " ├── FINANCE/"
    echo " ├── DOCS/"
    echo " └── memory-bank/         # Projektdokumentation"
    echo
    echo -e "${YELLOW}Nächste Schritte:${NC}"
    echo "  1. Abhängigkeiten installieren:"
    echo "     cd $PROJECT_PATH/APP && npm install"
    echo
    echo "  2. Entwicklungsserver starten:"
    echo "     npm run dev"
    echo
    echo "  3. Memory-Bank erkunden, um mehr über das Projekt zu verstehen"
    echo
}

# Abhängigkeiten installieren
install_dependencies() {
    echo -e "${YELLOW}Möchtest du die Abhängigkeiten jetzt installieren? (j/n)${NC}"
    read -r INSTALL_DEPS
    
    if [[ "$INSTALL_DEPS" =~ ^[Jj] ]]; then
        echo -e "${YELLOW}Installiere Abhängigkeiten...${NC}"
        cd "$PROJECT_PATH/APP"
        
        # package.json erstellen
        cat > package.json << EOL
{
  "name": "${PROJECT_NAME,,}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@react-three/drei": "^9.90.0",
    "@react-three/fiber": "^8.15.12",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "tailwind-merge": "^2.1.0",
    "tailwindcss-animate": "^1.0.7",
    "three": "^0.160.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.4",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@types/three": "^0.160.0",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-config-next": "^15.0.0",
    "postcss": "^8.4.32",
    "tailwindcss": "^4.0.0",
    "typescript": "^5.3.3"
  }
}
EOL
        
        npm install
        
        echo -e "${GREEN}Abhängigkeiten erfolgreich installiert.${NC}"
    else
        echo -e "${YELLOW}Abhängigkeiten werden nicht installiert. Du kannst sie später mit 'npm install' installieren.${NC}"
    fi
}

# Hauptfunktion
main() {
    check_dependencies
    validate_params
    create_project_structure
    copy_templates
    create_nextjs_project
    init_git
    install_dependencies
    show_summary
}

# Führe das Skript aus
main