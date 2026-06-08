class DocumentModel {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime dateAdded;
  final int pageCount;
  final String status; // 'Ingesting', 'Indexing', 'Ready', 'Failed'
  final int tokenCount;

  DocumentModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.dateAdded,
    required this.pageCount,
    required this.status,
    required this.tokenCount,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    DateTime? dateAdded,
    int? pageCount,
    String? status,
    int? tokenCount,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      pageCount: pageCount ?? this.pageCount,
      status: status ?? this.status,
      tokenCount: tokenCount ?? this.tokenCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'dateAdded': dateAdded.toIso8601String(),
      'pageCount': pageCount,
      'status': status,
      'tokenCount': tokenCount,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      size: map['size'],
      dateAdded: DateTime.parse(map['dateAdded']),
      pageCount: map['pageCount'],
      status: map['status'],
      tokenCount: map['tokenCount'],
    );
  }
}
