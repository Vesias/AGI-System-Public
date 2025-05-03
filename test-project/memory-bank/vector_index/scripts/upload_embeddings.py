#!/usr/bin/env python3
# Skript zum Hochladen von Einbettungen für test-project

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import json
    import os
    import argparse
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Lädt Einbettungen für test-project in Qdrant hoch")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=6333, type=int, help="Qdrant-Port")
        parser.add_argument("--collection", required=True, help="Name der Sammlung")
        parser.add_argument("--embeddings", required=True, help="Pfad zur JSON-Datei mit Einbettungen")
        return parser.parse_args()
    
    def upload_embeddings(args):
        try:
            client = QdrantClient(args.host, port=args.port)
            
            # Prüfen, ob Datei existiert
            if not os.path.isfile(args.embeddings):
                print(f"Fehler: Datei {args.embeddings} existiert nicht.")
                return False
            
            # Prüfen, ob Sammlung existiert
            try:
                client.get_collection(collection_name=args.collection)
            except Exception:
                print(f"Fehler: Sammlung {args.collection} existiert nicht.")
                return False
            
            # Einbettungen laden
            with open(args.embeddings, "r") as f:
                embeddings_data = json.load(f)
            
            # Punkte erstellen
            points = []
            for i, item in enumerate(embeddings_data):
                points.append(
                    models.PointStruct(
                        id=i if "id" not in item else item["id"],
                        vector=item["vector"],
                        payload=item["payload"] if "payload" in item else {}
                    )
                )
            
            # Einbettungen hochladen
            client.upsert(
                collection_name=args.collection,
                points=points
            )
            
            print(f"{len(points)} Einbettungen erfolgreich in Sammlung '{args.collection}' hochgeladen.")
            return True
        
        except Exception as e:
            print(f"Fehler beim Hochladen der Einbettungen: {e}")
            return False
    
    if __name__ == "__main__":
        args = parse_args()
        success = upload_embeddings(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
