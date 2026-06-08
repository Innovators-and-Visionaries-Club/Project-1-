import 'dart:async';
import '../models/chunk_model.dart';

class LlmService {
  static final LlmService instance = LlmService._init();

  LlmService._init();

  // Streams responses token-by-token (word-by-word) to create a beautiful typing effect
  Stream<String> generateAnswerStream(
    String query,
    List<ChunkModel> contextChunks, {
    bool isMock = true,
  }) async* {
    if (isMock) {
      final responseText = _synthesizeResponse(query, contextChunks);
      final words = responseText.split(' ');
      
      String accumulated = '';
      for (int i = 0; i < words.length; i++) {
        // Yield at a variable typing rate simulating 10-15 tokens per second
        final delayMs = 30 + (i % 3 == 0 ? 50 : 10);
        await Future.delayed(Duration(milliseconds: delayMs));
        
        accumulated += (i == 0 ? '' : ' ') + words[i];
        yield accumulated;
      }
    } else {
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

      // 2. Implement a SMART mock that uses the real chunks
      String answerText;
      if (contextChunks.isEmpty) {
        answerText = "I couldn't find that in your documents.";
      } else {
        final buffer = StringBuffer();
        buffer.write("📚 [From your documents]\\n\\n");
        for (var chunk in contextChunks) {
          final sentences = chunk.text.split(RegExp(r'(?<=[.!?])\\s+')).where((s) => s.isNotEmpty).toList();
          final summaryLine = sentences.isNotEmpty ? sentences.first : chunk.text;
          buffer.write("- $summaryLine (Source: ${chunk.documentName}, Page ${chunk.pageNumber})\\n");
        }
        answerText = buffer.toString().trim();
      }

      // Stream it word-by-word
      final words = answerText.split(' ');
      String accumulated = '';
      for (int i = 0; i < words.length; i++) {
        final delayMs = 30 + (i % 3 == 0 ? 50 : 10);
        await Future.delayed(Duration(milliseconds: delayMs));
        accumulated += (i == 0 ? '' : ' ') + words[i];
        yield accumulated;
      }
    }
  }

  Stream<String> _realLlmGenerate(String prompt) async* {
    // TODO: Replace with MediaPipe LLM Inference API
    // Model: Gemma 2B Q4, path: getApplicationDocumentsDirectory()/models/gemma2b_q4.bin
    // Use: LlmInference.createFromOptions() from package:flutter_mediapipe
    yield "LLM not yet loaded";
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
