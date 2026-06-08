import os
import glob
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.document_loaders import UnstructuredPowerPointLoader
from langchain_community.document_loaders import UnstructuredWordDocumentLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_ollama import OllamaEmbeddings

# Configuration
DOCUMENTS_FOLDER = "./documents"
DATABASE_STORAGE_FOLDER = "./chroma_data"
EMBEDDING_MODEL = "mxbai-embed-large"

def ingest_documents():
    os.makedirs(DOCUMENTS_FOLDER, exist_ok=True)
    
    # 1. Gather all documents
    pdf_files = glob.glob(os.path.join(DOCUMENTS_FOLDER, "*.pdf"))
    pptx_files = glob.glob(os.path.join(DOCUMENTS_FOLDER, "*.pptx"))
    docx_files = glob.glob(os.path.join(DOCUMENTS_FOLDER, "*.docx"))
    
    all_files = pdf_files + pptx_files + docx_files
    
    if not all_files:
        print(f"No documents found in '{DOCUMENTS_FOLDER}'. Please add some PDFs, PPTXs, or DOCXs and run again.")
        return
        
    print(f"Found {len(all_files)} documents. Starting ingestion...")
    
    # 2. Extract text from documents
    raw_documents = []
    for file_path in all_files:
        print(f"Reading: {file_path}")
        try:
            if file_path.endswith('.pdf'):
                loader = PyPDFLoader(file_path)
                raw_documents.extend(loader.load())
            elif file_path.endswith('.pptx'):
                loader = UnstructuredPowerPointLoader(file_path)
                raw_documents.extend(loader.load())
            elif file_path.endswith('.docx'):
                loader = UnstructuredWordDocumentLoader(file_path)
                raw_documents.extend(loader.load())
        except Exception as e:
            print(f"Failed to read {file_path}: {e}")

    if not raw_documents:
        print("No text could be extracted.")
        return

    # 3. Split into semantic chunks
    print("Splitting text into chunks...")
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
    chunks = text_splitter.split_documents(raw_documents)
    print(f"Generated {len(chunks)} text chunks.")

    # 4. Embed and store in ChromaDB
    print(f"Embedding and saving to {DATABASE_STORAGE_FOLDER}...")
    local_embeddings = OllamaEmbeddings(
        model=EMBEDDING_MODEL,
        base_url="http://localhost:11434"
    )
    
    vector_db = Chroma.from_documents(
        documents=chunks,
        embedding=local_embeddings,
        persist_directory=DATABASE_STORAGE_FOLDER
    )
    
    print("✅ Ingestion complete! The API and App are ready to serve this data.")

if __name__ == "__main__":
    ingest_documents()
