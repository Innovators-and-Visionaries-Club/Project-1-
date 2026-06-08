import os
import difflib
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Any
from spellchecker import SpellChecker

from langchain_ollama import OllamaEmbeddings, OllamaLLM
from langchain_community.vectorstores import Chroma
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
import langchain_classic.chains.retrieval as retrieval_module
import langchain_classic.chains.combine_documents.stuff as stuff_module

app = FastAPI(title="Project Smriti Mobile API")
DATABASE_STORAGE_FOLDER = "./chroma_data" 

# --- AI Backend Logic ---
print("Initializing AI Backend Pipeline...")
local_embeddings = OllamaEmbeddings(model="mxbai-embed-large", base_url="http://localhost:11434")
vector_database = Chroma(persist_directory=DATABASE_STORAGE_FOLDER, embedding_function=local_embeddings)
local_llm = OllamaLLM(model="llama3.2:1b", base_url="http://localhost:11434", temperature=0.7, num_ctx=1024, num_predict=400)
data_retriever = vector_database.as_retriever(search_kwargs={"k": 1}) 

system_instruction = (
    "You are an academic assistant. Answer the student's question clearly using the provided context blocks.\n"
    "Keep your answers brief and concise to ensure maximum speed.\n"
    "If the user makes spelling mistakes in domain-specific terminology, silently infer their meaning.\n"
    "If the context or chat history does not contain the answer, politely state that the information is missing.\n"
    "Do not make up facts.\n\n"
    "Context:\n{context}"
)

qa_prompt = ChatPromptTemplate.from_messages([
    ("system", system_instruction),
    MessagesPlaceholder("chat_history"),
    ("human", "{input}"),
])

document_processing_chain = stuff_module.create_stuff_documents_chain(local_llm, qa_prompt)
ai_chain = retrieval_module.create_retrieval_chain(data_retriever, document_processing_chain)
spell = SpellChecker()
print("Pipeline Ready.")

# --- API Models ---
class ChatMessage(BaseModel):
    user_type: str
    text_content: str

class AskRequest(BaseModel):
    user_question: str
    chat_history: List[ChatMessage] = []

class AskResponse(BaseModel):
    answer: str

# --- API Endpoints ---
@app.get("/")
def health_check():
    return {"status": "Smriti API is running!"}

@app.post("/ask", response_model=AskResponse)
def ask_question(request: AskRequest):
    raw_question = request.user_question
    
    # 1. Correct spelling
    corrected_words = []
    for word in raw_question.split():
        if word.isalpha() and word == word.lower():
            correction = spell.correction(word)
            corrected_words.append(correction if correction else word)
        else:
            corrected_words.append(word)
    user_question = " ".join(corrected_words)

    # 2. Logic to determine if history is needed
    langchain_history = []
    asked_for_confirmation = False
    
    if request.chat_history:
        last_msg = request.chat_history[-1]
        if last_msg.user_type == "assistant" and last_msg.text_content.strip().endswith("?"):
            asked_for_confirmation = True

    context_keywords = ["with respect to previous response", "wrt previous response", "as you said earlier"]
    user_wants_history = False
    for keyword in context_keywords:
        if keyword in raw_question.lower() or keyword in user_question.lower():
            user_wants_history = True
            break
        
        words = raw_question.lower().split()
        key_words = keyword.split()
        if len(words) >= len(key_words):
            for i in range(len(words) - len(key_words) + 1):
                chunk = " ".join(words[i:i+len(key_words)])
                if difflib.SequenceMatcher(None, keyword, chunk).ratio() > 0.85:
                    user_wants_history = True
                    break

    if asked_for_confirmation or user_wants_history:
        for msg in request.chat_history:
            if msg.user_type == "user":
                langchain_history.append(HumanMessage(content=msg.text_content))
            else:
                langchain_history.append(AIMessage(content=msg.text_content))

    # 3. Invoke LangChain RAG pipeline
    response = ai_chain.invoke({
        "input": user_question,
        "chat_history": langchain_history
    })
    
    return AskResponse(answer=response["answer"])

# Run with: uvicorn api:app --host 0.0.0.0 --port 8000
