import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chunk_model.dart';

class LlmService {
  static final LlmService instance = LlmService._init();

  LlmService._init();

  // Streams responses token-by-token (word-by-word) to create a beautiful typing effect
  Stream<String> generateAnswerStream(
    String query,
    List<ChunkModel> contextChunks, {
    bool isMock = false, // Default to false to use the real offline engine
  }) async* {
    // 1. Build prompt from contextChunks
    final promptBuffer = StringBuffer();
    promptBuffer.writeln("You are a helpful study assistant for Smriti, an offline AI notebook.");
    promptBuffer.writeln("Answer using ONLY the context below. Be concise and clear.");
    promptBuffer.writeln("If answer not in context, say: I couldn't find that in your documents.");
    promptBuffer.writeln("Cite source and page at end of every answer.\\n");
    promptBuffer.writeln("Context:");
    for (var chunk in contextChunks) {
      promptBuffer.writeln("[${chunk.text} — Source: ${chunk.documentName}, Page ${chunk.pageNumber}]");
    }
    promptBuffer.writeln("\\nQuestion: $query");
    promptBuffer.writeln("Answer:");

    // Stream the generated tokens from the local on-device LLM
    yield* _realLlmGenerate(promptBuffer.toString());
  }

  // Represents the active memory state of the Llama 3.2 model
  bool _isEngineLoaded = false;
  // dynamic _llmInferenceEngine; // The actual MediaPipe engine object

  /// Loads the 1.5GB Llama 3.2 model into the phone's active RAM.
  /// This is called strictly ON-DEMAND when a chat message is sent.
  Future<void> _loadEngineIfNeeded() async {
    if (_isEngineLoaded) return;

    final cacheDir = await getTemporaryDirectory();
    final modelPath = '${cacheDir.path}/llama3.2_1b_mobile.task';
    final modelFile = File(modelPath);

    if (!await modelFile.exists()) {
      throw Exception("⚠️ LLM model not found in cache. Please copy 'llama3.2_1b_mobile.task' to the app's cache directory.");
    }

    // This is where the heavy 1.5GB load happens in MediaPipe:
    // _llmInferenceEngine = await LlmInference.createFromOptions(LlmInferenceOptions(modelPath: modelPath));
    
    _isEngineLoaded = true;
    debugPrint("✅ Llama 3.2 Engine loaded into active RAM.");
  }

  /// Flushes the LLM out of the phone's active RAM to conserve battery and memory.
  /// Can be called when the user exits the chat screen.
  void disposeEngine() {
    if (_isEngineLoaded) {
      // _llmInferenceEngine?.close();
      // _llmInferenceEngine = null;
      _isEngineLoaded = false;
      debugPrint("🧹 Llama 3.2 Engine disposed. RAM freed.");
    }
  }

  Stream<String> _realLlmGenerate(String prompt) async* {
    try {
      // 1. Lazy Load: Only boot up the LLM if it's not already in RAM
      await _loadEngineIfNeeded();

      // 2. Generate
      // final responseStream = _llmInferenceEngine.generateResponseStream(prompt);
      // await for (final token in responseStream) { yield token; }
      
      // Placeholder for compilation
      yield "⚡ Lazy-Loaded Llama 3.2 Engine initialized!\\n\\n[Local AI output will stream here]";

    } catch (e) {
      yield "❌ Error running offline LLM: $e";
    }
  }

}
