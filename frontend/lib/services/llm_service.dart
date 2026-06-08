import 'dart:async';
import 'dart:io';
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

  Stream<String> _realLlmGenerate(String prompt) async* {
    try {
      final cacheDir = await getTemporaryDirectory();
      final modelPath = '${cacheDir.path}/llama3.2_1b_mobile.task';
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        yield "⚠️ LLM model not found in cache. Please copy 'llama3.2_1b_mobile.task' to the app's cache directory.";
        return;
      }

      // The actual implementation will use the Google MediaPipe GenAI plugin
      // final llmInference = await LlmInference.createFromOptions(LlmInferenceOptions(modelPath: modelPath));
      // final responseStream = llmInference.generateResponseStream(prompt);
      // await for (final token in responseStream) { yield token; }
      
      // Placeholder for compilation
      yield "⚡ Offline Inference Engine initialized using: $modelPath\\n\\n[Local AI output will stream here]";

    } catch (e) {
      yield "❌ Error running offline LLM: $e";
    }
  }

}
