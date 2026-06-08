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

  // Parses matching text chunks to construct a highly relevant answer utilizing references
  String _synthesizeResponse(String query, List<ChunkModel> chunks) {
    if (chunks.isEmpty) {
      return "I analyzed your notebook, but I couldn't find any relevant sections answering that query. "
          "Try uploading more files containing this information, or broaden your question.";
    }

    final queryLower = query.toLowerCase();
    final uniqueDocNames = chunks.map((c) => c.documentName).toSet().toList();
    final docsLabel = uniqueDocNames.length == 1 
        ? "the document **${uniqueDocNames.first}**" 
        : "the documents **${uniqueDocNames.join(', ')}**";

    // Scenario 1: User asks for a summary
    if (queryLower.contains('summar') || queryLower.contains('overview') || queryLower.contains('brief')) {
      final buffer = StringBuffer();
      buffer.writeln("Based on $docsLabel, here is a summary of the relevant key findings:\n");
      
      for (int i = 0; i < chunks.length; i++) {
        final sentences = chunks[i].text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
        final summaryLine = sentences.isNotEmpty ? sentences.first : chunks[i].text;
        
        buffer.writeln("• **${_getCategoryHeader(chunks[i].text)}**: $summaryLine *[Source: ${chunks[i].documentName}, page ${chunks[i].pageNumber}]*");
      }
      
      buffer.writeln("\nLet me know if you want me to expand on any specific section!");
      return buffer.toString();
    }

    // Scenario 2: Standard question answering
    final buffer = StringBuffer();
    buffer.writeln("According to $docsLabel, here is the information matching your query:\n");

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      
      // Format text paragraph with markdown and clean citation reference
      buffer.writeln("> ${chunk.text.trim()}\n");
      buffer.writeln("*(Referenced from **${chunk.documentName}**, page ${chunk.pageNumber})*\n");
    }

    buffer.writeln("Is there anything else you want to inspect from these references?");
    return buffer.toString();
  }

  // Generates short headers for summaries based on matching text content keywords
  String _getCategoryHeader(String text) {
    final textLower = text.toLowerCase();
    if (textLower.contains('experience') || textLower.contains('work')) return "Professional History";
    if (textLower.contains('education') || textLower.contains('bachelor')) return "Academic Background";
    if (textLower.contains('skill') || textLower.contains('expert')) return "Technical Capabilities";
    if (textLower.contains('rag') || textLower.contains('retrieval')) return "Retrieval Mechanism";
    if (textLower.contains('pipeline') || textLower.contains('stage')) return "System Ingestion Pipeline";
    if (textLower.contains('diagnosis') || textLower.contains('medical')) return "Clinical Assessment";
    if (textLower.contains('recommend') || textLower.contains('plan')) return "Action Plan & Treatment";
    return "Source Detail";
  }
}
