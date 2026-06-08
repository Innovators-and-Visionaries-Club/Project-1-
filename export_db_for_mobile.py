import json
import os
from langchain_community.vectorstores import Chroma
from langchain_ollama import OllamaEmbeddings

DATABASE_STORAGE_FOLDER = "./chroma_data"
EXPORT_FILE = "./mobile_knowledge_base.json"

print("Exporting ChromaDB to JSON for mobile ingestion...")

if not os.path.exists(DATABASE_STORAGE_FOLDER):
    print("❌ Error: ChromaDB folder not found. Have you ingested any documents yet using ingest_data.py?")
    exit(1)

# Initialize Chroma (without needing to re-embed, just to access data)
local_embeddings = OllamaEmbeddings(model="mxbai-embed-large", base_url="http://localhost:11434")
vector_db = Chroma(persist_directory=DATABASE_STORAGE_FOLDER, embedding_function=local_embeddings)

# Fetch all documents from the collection
collection = vector_db._collection
data = collection.get(include=["documents", "metadatas"])

documents = data.get("documents", [])
metadatas = data.get("metadatas", [])

export_data = []
for idx in range(len(documents)):
    export_data.append({
        "id": idx,
        "text": documents[idx],
        "metadata": metadatas[idx] if metadatas else {}
    })

print(f"Extracted {len(export_data)} knowledge chunks.")

with open(EXPORT_FILE, "w", encoding="utf-8") as f:
    json.dump(export_data, f, indent=4)

print(f"Success! Database exported to {EXPORT_FILE}")
print("Hand this JSON file over to your Flutter developer to load into ObjectBox.")
