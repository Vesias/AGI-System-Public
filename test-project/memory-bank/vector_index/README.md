# Qdrant-Vektordatenbank für test-project

## Übersicht

Diese Vektordatenbank speichert semantische Einbettungen für das Projekt, um intelligente Suche und Kontextabruf zu ermöglichen.

## Konfiguration

- **Host**: localhost
- **Port**: 6333
- **API-Endpunkt**: http://localhost:6333
- **Dashboard**: http://localhost:6333/dashboard
- **Embedding-Modell**: claude-3-haiku
- **Embedding-Dimensionen**: 1536

## Sammlungen

- **project_context**: Projektkontext und Dokumentation
- **code_embeddings**: Code-Snippets und -Fragmente
- **documentation**: Technische Dokumentation und Anleitungen

## Verwendung

### Starten und Stoppen der Datenbank

```bash
# Starten
./start-qdrant.sh

# Stoppen
./stop-qdrant.sh
```

### Sammlungen erstellen

```bash
# Mit Python-Skript
python3 ./memory-bank/vector_index/scripts/create_collections.py

# Zum Überschreiben existierender Sammlungen
python3 ./memory-bank/vector_index/scripts/create_collections.py --force
```

### Einbettungen hochladen

```bash
# Beispiel-Einbettungen hochladen
python3 ./memory-bank/vector_index/scripts/upload_embeddings.py --collection project_context --embeddings ./memory-bank/vector_index/embeddings/memory_bank_examples.json
```

### Semantische Suche

```bash
# Beispiel-Suche
python3 ./memory-bank/vector_index/scripts/semantic_search.py --collection project_context --vector ./memory-bank/vector_index/queries/memory_bank_query.json
```

## Python-Client-Beispiel

```python
from qdrant_client import QdrantClient
from qdrant_client.http import models

# Client initialisieren
client = QdrantClient("localhost", port=6333)

# Sammlung erstellen
client.create_collection(
    collection_name="project_context",
    vectors_config=models.VectorParams(size=1536, distance=models.Distance.COSINE),
)

# Punkt hinzufügen
client.upsert(
    collection_name="project_context",
    points=[
        models.PointStruct(
            id=1,
            vector=[0.1, 0.2, ...],  # 1536-dimensionaler Vektor
            payload={"text": "Projektkontext für test-project"}
        )
    ]
)

# Suche
results = client.search(
    collection_name="project_context",
    query_vector=[0.1, 0.2, ...],  # 1536-dimensionaler Vektor
    limit=5
)
```

## Integration mit Claude und MCP-Tools

Diese Vektordatenbank kann nahtlos mit Claude und MCP-Tools für semantische Suche und Kontextualisierung integriert werden:

1. **Claude Code**: Verwenden Sie Claude Code mit Kontexterkennung
2. **Memory-Bank MCP**: Verwenden Sie den Memory-Bank MCP für automatische Indexierung
3. **Desktop-Commander**: Verwenden Sie den Desktop-Commander für Dateizugriff

## Abhängigkeiten installieren

```bash
# Qdrant-Client installieren
pip install qdrant-client

# OpenAI-Client für Einbettungen (optional)
pip install openai
```

## Weitere Ressourcen

- [Qdrant-Dokumentation](https://qdrant.tech/documentation/)
- [Python-Client-API](https://qdrant.github.io/qdrant-client/)
- [REST-API-Referenz](https://qdrant.github.io/qdrant/redoc/index.html)
