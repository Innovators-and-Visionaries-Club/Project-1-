class TimelineModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String type; // 'document_ingested', 'quiz_completed', 'flashcard_created', 'chat_session'
  final String referenceId; // Associated ID (docId, quizId, messageId, etc.)

  TimelineModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.referenceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'referenceId': referenceId,
    };
  }

  factory TimelineModel.fromMap(Map<String, dynamic> map) {
    return TimelineModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      referenceId: map['referenceId'],
    );
  }
}
