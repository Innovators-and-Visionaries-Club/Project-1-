import '../models/chunk_model.dart';
import 'database_service.dart';
import 'embedding_service.dart';

class VectorDbService {
  static final VectorDbService instance = VectorDbService._init();

  VectorDbService._init();

  // Ingests list of chunks, computes their embeddings, and saves them to the DB
  Future<void> indexChunks(List<ChunkModel> chunks, {bool isMock = true}) async {
    final List<ChunkModel> indexedChunks = [];
    for (var chunk in chunks) {
      final embedding = await EmbeddingService.instance.getEmbedding(chunk.text, isMock: isMock);
      indexedChunks.add(ChunkModel(
        id: chunk.id,
        documentId: chunk.documentId,
        documentName: chunk.documentName,
        pageNumber: chunk.pageNumber,
        text: chunk.text,
        embedding: embedding,
      ));
    }
    await DatabaseService.instance.insertChunks(indexedChunks);
  }

  // Searches chunks matching the query. If documentId is provided, filters to that document.
  Future<List<ChunkModel>> search(String query, {String? documentId, int topK = 3, bool isMock = true}) async {
    if (query.trim().isEmpty) return [];

    final queryEmbedding = await EmbeddingService.instance.getEmbedding(query, isMock: isMock);
    final allChunks = await DatabaseService.instance.getChunks(documentId: documentId);
    
    final List<MapEntry<ChunkModel, double>> scoredChunks = [];

    for (var chunk in allChunks) {
      if (chunk.embedding == null || chunk.embedding!.length != queryEmbedding.length) continue;
      
      // Calculate dot product of normalized vectors
      double dotProduct = 0.0;
      for (int i = 0; i < queryEmbedding.length; i++) {
        dotProduct += queryEmbedding[i] * chunk.embedding![i];
      }
      
      // Boost score if the query shares keywords with the chunk (hybrid search heuristic)
      double keywordBoost = _calculateKeywordBoost(query, chunk.text);
      double finalScore = dotProduct + keywordBoost;

      scoredChunks.add(MapEntry(chunk, finalScore));
    }

    // Sort by final score descending
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    // Return the top K matching chunks
    return scoredChunks.take(topK).map((entry) => entry.key).toList();
  }

  // Simple keyword matching boost to improve relevance of local search
  double _calculateKeywordBoost(String query, String text) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3);
    final textLower = text.toLowerCase();
    
    int matches = 0;
    for (var word in queryWords) {
      if (textLower.contains(word)) {
        matches++;
      }
    }
    
    if (queryWords.isEmpty) return 0.0;
    return (matches / queryWords.length) * 0.15; // Max 0.15 score boost
  }
}
