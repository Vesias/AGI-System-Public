# VibeApp Aktiver Entwicklungskontext

Datum: 03.05.2025

## Aktuelle Prioritäten

- **3D-Visualisierungskomponente** - Entwicklung der Kernfunktion für die interaktive Datenvisualisierung
- **Stimmungseingabe-Interface** - Benutzerfreundliche, schnelle Erfassungsoberfläche
- **Offline-Datenspeicherung** - Lokale Datenbankstruktur mit Synchronisierungsmechanismus
- **Design-System** - Einrichtung der Grundkomponenten mit Tailwind und shadcn/ui

## Status der MRIs (Minimale umsetzbare Inkremente)

- ⏳ MRI VIS-1: 3D-Visualisierungsgrundlage mit react-three-fiber
- ⏳ MRI UI-1: Stimmungseingabe-Komponente mit Emoticons und Slider
- 🔄 MRI DB-1: Lokale Datenbankschemadefinition in Supabase
- 🔄 MRI DS-1: Farbschema, Typografie und Grundkomponenten

## Technische Entscheidungen

1. **3D-Visualisierung**
   - react-three-fiber als Basis
   - Drei.js für die 3D-Rendering-Engine
   - Framer Motion 3D für Animationen
   - Abstraktion in eigene React-Hooks für Wiederverwendbarkeit

2. **Stimmungserfassung**
   - Emoticon-basierte Primärauswahl (7 Basisemotionen)
   - Slider für Intensität (1-10)
   - Aktivitäts-Tags mit Autovervollständigung
   - Optional: Notizfeld für Details

3. **Datenspeicherung**
   - IndexedDB als primärer lokaler Speicher
   - React Query für Datenzustandsmanagement
   - Supabase für Backend-Synchronisation
   - Ende-zu-Ende-Verschlüsselung mit OPAQUE

4. **Komponenten-Architektur**
   - Atomic Design Prinzipien
   - Server Components für statische UI-Elemente
   - Client Components für interaktive Elemente
   - Feature-basierte Dateisystemorganisation

## Offene Fragen

1. Soll die 3D-Visualisierung auf WebGL oder WebGPU aufbauen?
2. Wie detailliert soll die initiale Emotionserfassung sein?
3. Sollen wir zukunftssicher mit React 19 starten oder bei 18 bleiben?
4. Performance-Bedenken bei der 3D-Visualisierung auf älteren Mobilgeräten?
5. Beste Strategie für intelligente Offline-/Online-Synchronisation?

## Nächste Schritte

1. Prototyp der 3D-Visualisierungskomponente entwickeln
2. Stimmungseingabe-Interface mit Nutzertests validieren
3. Datenbankschema finalisieren und in Supabase implementieren
4. Design-System dokumentieren und Komponenten-Bibliothek starten
5. PWA-Konfiguration mit Service-Worker für Offline-Funktionalität einrichten

## Blockerissues

1. **Performance**: 3D-Rendering auf älteren Mobilgeräten noch nicht optimiert
2. **Design**: Finales Logo und Farbschema noch nicht entschieden
3. **API**: Supabase-Schema für Synchronisation noch in Entwicklung

## Zusätzliche Notizen

- Desktop- und Mobile-Ansicht von Anfang an parallel entwickeln
- Accessibility (A11y) für alle Komponenten berücksichtigen
- Bei 3D-Visualisierung alternative 2D-Ansicht für Performance-Probleme vorsehen