class ChunkModel {
  final String id;
  final String documentId;
  final String documentName;
  final int pageNumber;
  final String text;
  final List<double>? embedding; // Will store vector embeddings (usually 384 or 768 floats)

  ChunkModel({
    required this.id,
    required this.documentId,
    required this.documentName,
    required this.pageNumber,
    required this.text,
    this.embedding,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'documentName': documentName,
      'pageNumber': pageNumber,
      'text': text,
      // Embedding list can be serialized as a string of comma-separated floats or JSON list in sqflite
      'embedding': embedding != null ? embedding!.join(',') : null,
    };
  }

  factory ChunkModel.fromMap(Map<String, dynamic> map) {
    String? embeddingStr = map['embedding'];
    List<double>? embeddingList;
    if (embeddingStr != null && embeddingStr.isNotEmpty) {
      embeddingList = embeddingStr.split(',').map((s) => double.parse(s)).toList();
    }

    return ChunkModel(
      id: map['id'],
      documentId: map['documentId'],
      documentName: map['documentName'],
      pageNumber: map['pageNumber'],
      text: map['text'],
      embedding: embeddingList,
    );
  }
}
