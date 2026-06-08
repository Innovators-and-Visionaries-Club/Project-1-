import streamlit as str
import os
from langchain_ollama import OllamaEmbeddings, OllamaLLM
from langchain_community.vectorstores import Chroma
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
import difflib
from spellchecker import SpellChecker
# Direct module routing to completely bypass library version conflicts
import langchain_classic.chains.retrieval as retrieval_module
import langchain_classic.chains.combine_documents.stuff as stuff_module

# =====================================================================
# 1. VISUAL INTERFACE (Streamlit Setup)
# =====================================================================
str.set_page_config(page_title="Project Smriti", page_icon="📚")
str.title("📚 Project Smriti: Offline Study Assistant")

DATABASE_STORAGE_FOLDER = "./chroma_data" 

# =====================================================================
# 2. AI BACKEND LOGIC (LangChain Pipeline)
# =====================================================================
@str.cache_resource
def build_local_rag_system():
    # A. Math Vectorization: Hook up your local mxbai-embed-large model
    local_embeddings = OllamaEmbeddings(
        model="mxbai-embed-large",
        base_url="http://localhost:11434"
    )
    
    # B. Vector Storage: Link directly to your pre-existing chroma_data folder
    # We skip PDF parsing to drastically improve loading speed! (Under 5 seconds)
    vector_database = Chroma(
        persist_directory=DATABASE_STORAGE_FOLDER,
        embedding_function=local_embeddings
    )
    
    # C. Conversational Brain: Initialize llama3.2:1b with a sweetspot temperature
    local_llm = OllamaLLM(
        model="llama3.2:1b",
        base_url="http://localhost:11434",
        temperature=0.7 ,
        num_ctx=1024, # Smaller context window = extremely fast processing
        num_predict=400 # Increased token limit to prevent cutting off mid-sentence
    )
    
    # Fetch just the single most relevant document to minimize reading time
    data_retriever = vector_database.as_retriever(search_kwargs={"k": 1}) 

    # D. Guardrail Instruction: The exact rules telling the AI how to behave
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
    
    # E. The Assembly Line Chain: Connect the retriever and LLM directly
    # We bypass the dual-LLM history reformulator for 2x speed! Chat history is still passed to the final prompt.
    document_processing_chain = stuff_module.create_stuff_documents_chain(local_llm, qa_prompt)
    complete_rag_chain = retrieval_module.create_retrieval_chain(data_retriever, document_processing_chain)
    
    return complete_rag_chain

# =====================================================================
# 3. RUNNING THE APPLICATION INTERACTIVE LOOP
# =====================================================================
# Show a spinning loading wheel while the machine verifies the vector index
with str.spinner("Booting up local models and connecting to vector database..."):
    ai_chain = build_local_rag_system()

if ai_chain:
    str.success("System Status: OFFLINE PIPELINE READY TO CHAT! ✅")

    # Add a Clear Chat button to the sidebar to give the user a fresh start
    with str.sidebar:
        if str.button("🗑️ Clear Chat History", use_container_width=True):
            str.session_state.chat_history = []
            str.rerun()

    # Keep track of previous chat messages so they don't disappear when you click things
    if "chat_history" not in str.session_state:
        str.session_state.chat_history = []

    # Print prior conversational turns onto the web screen layout
    for message in str.session_state.chat_history:
        with str.chat_message(message["user_type"]):
            str.markdown(message["text_content"])

    # Wait for the user to type a question into the text bar at the bottom
    if raw_question := str.chat_input("Ask me anything about your elective notes..."):
        # Instantly correct spelling mistakes in the user's question before processing
        spell = SpellChecker()
        corrected_words = []
        for word in raw_question.split():
            # Don't try to correct pure acronyms or words with numbers
            if word.isalpha() and word == word.lower():
                correction = spell.correction(word)
                corrected_words.append(correction if correction else word)
            else:
                corrected_words.append(word)
        user_question = " ".join(corrected_words)

        # 1. Render user question instantly
        with str.chat_message("user"):
            str.markdown(raw_question) # Show their original typed question
            
        # Convert the Streamlit chat history format into LangChain message objects
        langchain_history = []
        
        # Check if the assistant asked a question in its last response
        asked_for_confirmation = False
        if str.session_state.chat_history:
            last_msg = str.session_state.chat_history[-1]
            if last_msg["user_type"] == "assistant" and last_msg["text_content"].strip().endswith("?"):
                asked_for_confirmation = True

        # Only fetch history if the user explicitly asks for context OR the AI just asked a question
        context_keywords = ["with respect to previous response", "wrt previous response", "as you said earlier"]
        
        # Fuzzy match to handle typos in keywords (e.g., "wrt previuos response")
        user_wants_history = False
        for keyword in context_keywords:
            if keyword in raw_question.lower() or keyword in user_question.lower():
                user_wants_history = True
                break
            
            # Slide a window across the string to check for fuzzy matches
            words = raw_question.lower().split()
            key_words = keyword.split()
            if len(words) >= len(key_words):
                for i in range(len(words) - len(key_words) + 1):
                    chunk = " ".join(words[i:i+len(key_words)])
                    if difflib.SequenceMatcher(None, keyword, chunk).ratio() > 0.85:
                        user_wants_history = True
                        break
                        
        if asked_for_confirmation or user_wants_history:
            for msg in str.session_state.chat_history:
                if msg["user_type"] == "user":
                    langchain_history.append(HumanMessage(content=msg["text_content"]))
                else:
                    langchain_history.append(AIMessage(content=msg["text_content"]))
                
        str.session_state.chat_history.append({"user_type": "user", "text_content": user_question})

        # 2. Feed question into LangChain and render the AI's response
        with str.chat_message("assistant"):
            try:
                # Use a generator to stream the answer dynamically token-by-token!
                def answer_generator():
                    for chunk in ai_chain.stream({
                        "input": user_question,
                        "chat_history": langchain_history
                    }):
                        if "answer" in chunk:
                            yield chunk["answer"]
                
                # Streamlit automatically types out the text as it's generated (0 latency feel)
                extracted_answer = str.write_stream(answer_generator())
                str.session_state.chat_history.append({"user_type": "assistant", "text_content": extracted_answer})
            except Exception as error_details:
                str.error(f"Pipeline Execution Error: {str(error_details)}")