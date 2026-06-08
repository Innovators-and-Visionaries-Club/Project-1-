import 'dart:convert';
import '../models/chunk_model.dart';
import 'database_service.dart';

class VectorService {
  static final VectorService instance = VectorService._init();

  VectorService._init();

  final List<String> _stopwords = [
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', "you're", "you've", "you'll", "you'd", 'your', 'yours', 'yourself', 'yourselves',
    'he', 'him', 'his', 'himself', 'she', "she's", 'her', 'hers', 'herself', 'it', "it's", 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves',
    'what', 'which', 'who', 'whom', 'this', 'that', "that'll", 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having',
    'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against',
    'between', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again',
    'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such',
    'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will', 'just', 'don', "don't", 'should', "should've", 'now', 'd', 'll', 'm', 'o', 're', 've', 'y', 'ain', 'aren', "aren't", 'couldn', "couldn't", 'didn', "didn't", 'doesn', "doesn't", 'hadn', "hadn't", 'hasn', "hasn't", 'haven', "haven't", 'isn', "isn't", 'ma', 'mightn', "mightn't", 'mustn', "mustn't", 'needn', "needn't", 'shan', "shan't", 'shouldn', "shouldn't", 'wasn', "wasn't", 'weren', "weren't", 'won', "won't", 'wouldn', "wouldn't"
  ];

  Future<List<ChunkModel>> findRelevantChunks(String query, {String? documentId, int topK = 5}) async {
    final allChunks = await DatabaseService.instance.getChunks(documentId: documentId);
    
    if (allChunks.isEmpty) return [];

    final rawQuery = query.toLowerCase().trim();
    if (rawQuery.isEmpty) return allChunks.take(topK).toList();

    // Tokenize query into words (lowercase, remove punctuation, remove stopwords)
    final queryClean = rawQuery.replaceAll(RegExp(r'[^\w\s]'), '');
    final queryWords = queryClean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !_stopwords.contains(w)).toList();

    final List<MapEntry<ChunkModel, double>> scoredChunks = [];

    for (var chunk in allChunks) {
      double score = 0.0;
      final chunkTextLower = chunk.text.toLowerCase();
      final chunkWords = chunkTextLower.replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

      if (queryWords.isNotEmpty && chunkWords.isNotEmpty) {
        // Count how many query words appear in chunk.text
        for (var word in queryWords) {
          int count = chunkWords.where((w) => w == word).length;
          score += count;
        }

        // Weight exact phrase matches higher (multiply score by 3)
        if (chunkTextLower.contains(rawQuery)) {
          score *= 3;
        }
        
        // Normalize by chunk length
        score = score / chunkWords.length;
      } else if (chunkWords.isNotEmpty && chunkTextLower.contains(rawQuery)) {
          // Edge case: query only contains stop words but exact matches
          score = 3.0 / chunkWords.length;
      }

      scoredChunks.add(MapEntry(chunk, score));
    }

    // Sort chunks by score descending
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    // Return top topK chunks (minimum 1, even if score is 0)
    final topChunks = scoredChunks.take(topK).map((e) => e.key).toList();
    if (topChunks.isEmpty) {
      return [allChunks.first];
    }
    return topChunks;
  }

  Future<void> storeEmbedding(String chunkId, List<double> embedding) async {
    // TODO: Replace this stub with real embedding logic when ONNX/TFLite is integrated
    final db = await DatabaseService.instance.database;
    await db.update(
      'chunks',
      {'embedding': jsonEncode(embedding)},
      where: 'id = ?',
      whereArgs: [chunkId],
    );
  }
}
