#!/usr/bin/env python3
# Skript für semantische Suche in test-project

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    import sys
    import argparse
    import json
    
    def parse_args():
        parser = argparse.ArgumentParser(description="Semantische Suche für test-project")
        parser.add_argument("--host", default="localhost", help="Qdrant-Host")
        parser.add_argument("--port", default=6333, type=int, help="Qdrant-Port")
        parser.add_argument("--collection", required=True, help="Name der Sammlung")
        parser.add_argument("--vector", required=True, help="Pfad zur JSON-Datei mit Suchvektor")
        parser.add_argument("--limit", default=5, type=int, help="Anzahl der Ergebnisse")
        parser.add_argument("--output", help="Pfad zur Ausgabedatei (optional)")
        return parser.parse_args()
    
    def semantic_search(args):
        try:
            client = QdrantClient(args.host, port=args.port)
            
            # Vektor laden
            with open(args.vector, "r") as f:
                vector_data = json.load(f)
            
            query_vector = vector_data["vector"]
            
            # Suche durchführen
            results = client.search(
                collection_name=args.collection,
                query_vector=query_vector,
                limit=args.limit
            )
            
            # Ergebnisse formatieren
            formatted_results = []
            for result in results:
                formatted_results.append({
                    "id": result.id,
                    "score": result.score,
                    "payload": result.payload
                })
            
            # Ausgabe
            if args.output:
                with open(args.output, "w") as f:
                    json.dump(formatted_results, f, indent=2)
                print(f"Ergebnisse in {args.output} gespeichert.")
            else:
                print(json.dumps(formatted_results, indent=2))
            
            return True
        
        except Exception as e:
            print(f"Fehler bei der semantischen Suche: {e}")
            return False
    
    if __name__ == "__main__":
        args = parse_args()
        success = semantic_search(args)
        sys.exit(0 if success else 1)
        
except ImportError:
    print("Fehler: qdrant-client ist nicht installiert.")
    print("Bitte installieren Sie das Paket mit: pip install qdrant-client")
    print("Oder: python -m pip install qdrant-client")
    sys.exit(1)
