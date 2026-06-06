import 'citation_model.dart';

class MessageModel {
  final String id;
  final String sender; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;
  final List<CitationModel> citations;
  final bool isStreaming;

  MessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.citations = const [],
    this.isStreaming = false,
  });

  MessageModel copyWith({
    String? id,
    String? sender,
    String? text,
    DateTime? timestamp,
    List<CitationModel>? citations,
    bool? isStreaming,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      citations: citations ?? this.citations,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'citations': citations.map((c) => c.toMap()).toList(),
      // isStreaming is a UI-only state, not persisted to database.
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    var rawCitations = map['citations'] as List? ?? [];
    List<CitationModel> citationsList = rawCitations
        .map((c) => CitationModel.fromMap(Map<String, dynamic>.from(c)))
        .toList();

    return MessageModel(
      id: map['id'],
      sender: map['sender'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
      citations: citationsList,
      isStreaming: false,
    );
  }
}
