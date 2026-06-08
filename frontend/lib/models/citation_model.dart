class CitationModel {
  final String documentId;
  final String documentName;
  final int pageNumber;
  final String textSnippet;

  CitationModel({
    required this.documentId,
    required this.documentName,
    required this.pageNumber,
    required this.textSnippet,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documentName': documentName,
      'pageNumber': pageNumber,
      'textSnippet': textSnippet,
    };
  }

  factory CitationModel.fromMap(Map<String, dynamic> map) {
    return CitationModel(
      documentId: map['documentId'],
      documentName: map['documentName'],
      pageNumber: map['pageNumber'],
      textSnippet: map['textSnippet'],
    );
  }
}
