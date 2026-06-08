import 'dart:convert';

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  int? userAnswerIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.userAnswerIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': jsonEncode(options),
      'correctAnswerIndex': correctAnswerIndex,
      'userAnswerIndex': userAnswerIndex,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    var rawOptions = map['options'];
    List<String> optionsList = [];
    if (rawOptions is String) {
      optionsList = List<String>.from(jsonDecode(rawOptions));
    } else if (rawOptions is List) {
      optionsList = List<String>.from(rawOptions);
    }
    
    return QuizQuestion(
      id: map['id'],
      question: map['question'],
      options: optionsList,
      correctAnswerIndex: map['correctAnswerIndex'],
      userAnswerIndex: map['userAnswerIndex'],
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String documentId;
  final List<QuizQuestion> questions;

  QuizModel({
    required this.id,
    required this.title,
    required this.documentId,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'documentId': documentId,
      'questions': jsonEncode(questions.map((q) => q.toMap()).toList()),
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    var rawQuestions = map['questions'];
    List<QuizQuestion> questionsList = [];
    if (rawQuestions is String) {
      var decoded = jsonDecode(rawQuestions) as List;
      questionsList = decoded.map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q))).toList();
    } else if (rawQuestions is List) {
      questionsList = rawQuestions.map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q))).toList();
    }

    return QuizModel(
      id: map['id'],
      title: map['title'],
      documentId: map['documentId'],
      questions: questionsList,
    );
  }
}
