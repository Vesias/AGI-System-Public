#!/usr/bin/env python3
# Skript zum Erstellen von Qdrant-Sammlungen für test-project

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import argparse
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Erstellt Qdrant-Sammlungen für test-project")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=6333, type=int, help="Qdrant-Port")
        parser.add_argument("--force", action="store_true", help="Sammlungen überschreiben, falls sie existieren")
        return parser.parse_args()
    
    def create_collections(args):
        try:
            client = QdrantClient(args.host, port=args.port)
            
            # Sammlungen definieren
            collections = [
                "project_context",
                "code_embeddings",
                "documentation"
            ]
            
            # Sammlungen erstellen
            for collection in collections:
                try:
                    # Prüfen, ob Sammlung bereits existiert
                    try:
                        info = client.get_collection(collection_name=collection)
                        if args.force:
                            print(f"Sammlung '{collection}' existiert bereits, wird neu erstellt...")
                            client.delete_collection(collection_name=collection)
                        else:
                            print(f"Sammlung '{collection}' existiert bereits, wird übersprungen.")
                            continue
                    except Exception:
                        pass # Sammlung existiert nicht
                    
                    # Sammlung erstellen
                    client.create_collection(
                        collection_name=collection,
                        vectors_config=models.VectorParams(
                            size=1536,  # Dimension des Einbettungsmodells
                            distance=models.Distance.COSINE
                        )
                    )
                    print(f"Sammlung '{collection}' erfolgreich erstellt.")
                except Exception as e:
                    print(f"Fehler beim Erstellen der Sammlung '{collection}': {e}")
            
            print("Sammlungserstellung abgeschlossen.")
            return True
            
        except Exception as e:
            print(f"Fehler bei der Verbindung zur Qdrant-Datenbank: {e}")
            return False
    
    if __name__ == "__main__":
        args = parse_args()
        success = create_collections(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
