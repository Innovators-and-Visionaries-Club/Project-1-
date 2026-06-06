class FlashcardModel {
  final String id;
  final String question;
  final String answer;
  final String documentId;
  final String difficulty; // 'new', 'hard', 'good', 'easy'
  final DateTime nextReviewDate;

  FlashcardModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.documentId,
    this.difficulty = 'new',
    required this.nextReviewDate,
  });

  FlashcardModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? documentId,
    String? difficulty,
    DateTime? nextReviewDate,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      documentId: documentId ?? this.documentId,
      difficulty: difficulty ?? this.difficulty,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'documentId': documentId,
      'difficulty': difficulty,
      'nextReviewDate': nextReviewDate.toIso8601String(),
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      documentId: map['documentId'],
      difficulty: map['difficulty'] ?? 'new',
      nextReviewDate: DateTime.parse(map['nextReviewDate']),
    );
  }
}
