import 'dart:math';

class EmbeddingService {
  static final EmbeddingService instance = EmbeddingService._init();

  EmbeddingService._init();

  Future<List<double>> getEmbedding(String text, {bool isMock = true}) async {
    // Artificial latency to simulate computation (e.g. 50ms)
    await Future.delayed(const Duration(milliseconds: 50));

    if (isMock) {
      // Deterministic generation based on string content
      final random = Random(_getStringSeed(text));
      final List<double> vector = List.generate(384, (_) {
        return (random.nextDouble() * 2.0) - 1.0;
      });

      // Normalize the vector so cosine similarity is just a dot product
      double sumSquares = vector.fold(0, (sum, val) => sum + (val * val));
      double magnitude = sqrt(sumSquares);
      if (magnitude > 0) {
        for (int i = 0; i < vector.length; i++) {
          vector[i] /= magnitude;
        }
      }
      return vector;
    } else {
      // Fallback for real local execution
      return getEmbedding(text, isMock: true);
    }
  }

  // Generates a stable integer seed from a string
  int _getStringSeed(String text) {
    int hash = 5381;
    for (int i = 0; i < text.length; i++) {
      hash = ((hash << 5) + hash) + text.codeUnitAt(i);
    }
    return hash.abs();
  }
}
