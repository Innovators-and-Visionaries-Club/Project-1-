import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/document_model.dart';
import '../models/message_model.dart';
import '../models/citation_model.dart';
import '../models/chunk_model.dart';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';
import '../models/timeline_model.dart';
import 'database_service.dart';
import 'vector_service.dart';
import 'ingestion_service.dart';
import 'llm_service.dart';

class AppProvider extends ChangeNotifier {
  List<DocumentModel> _documents = [];
  List<MessageModel> _messages = [];
  List<FlashcardModel> _flashcards = [];
  List<QuizModel> _quizzes = [];
  List<TimelineModel> _timelineItems = [];
  bool _isDarkMode = false;
  bool _isMockMode = true;
  String? _selectedDocumentId; // To filter searches to specific files
  bool _isIngesting = false;
  String _ingestionProgress = '';
  String _ingestionProgressText = '';
  double _ingestionProgressValue = 0.0;
  String? _lastIngestedFileName;
  String _modelDownloadStatus = "Ready"; // 'Download Needed', 'Downloading', 'Ready'
  double _modelDownloadProgress = 1.0;
  bool _isInitialized = false;
  double _initProgress = 0.0;
  bool _isInitializing = false;
  bool _isOnboardingCompleted = false;
  List<String> _queryHistory = [];
  String? _filterDocumentId;

  bool get isInitialized => _isInitialized;
  double get initProgress => _initProgress;
  bool get isInitializing => _isInitializing;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  List<DocumentModel> get documents => _documents;
  List<MessageModel> get messages => _messages;
  List<FlashcardModel> get flashcards => _flashcards;
  List<QuizModel> get quizzes => _quizzes;
  List<TimelineModel> get timelineItems => _timelineItems;
  bool get isDarkMode => _isDarkMode;
  bool get isMockMode => _isMockMode;
  String? get selectedDocumentId => _selectedDocumentId;
  bool get isIngesting => _isIngesting;
  String get ingestionProgress => _ingestionProgress;
  String get ingestionProgressText => _ingestionProgressText;
  double get ingestionProgressValue => _ingestionProgressValue;
  String? get lastIngestedFileName => _lastIngestedFileName;
  void consumeIngestedFileName() { _lastIngestedFileName = null; }
  String get modelDownloadStatus => _modelDownloadStatus;
  double get modelDownloadProgress => _modelDownloadProgress;
  List<String> get queryHistory => _queryHistory;
  String? get filterDocumentId => _filterDocumentId;
  void setFilterDocument(String? id) { _filterDocumentId = id; notifyListeners(); }

  final _uuid = const Uuid();

  AppProvider() {
    _loadSettings();
    _loadDocuments();
    _loadMessages();
  }

  // --- Initialize & Settings ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMockMode = prefs.getBool('isMockMode') ?? true;
    _modelDownloadStatus = prefs.getString('modelDownloadStatus') ?? "Ready";
    _modelDownloadProgress = prefs.getDouble('modelDownloadProgress') ?? 1.0;
    _isInitialized = prefs.getBool('isInitialized') ?? false;
    _isOnboardingCompleted = prefs.getBool('isOnboardingCompleted') ?? false;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    // Load query history
    final historyJson = prefs.getString('query_history');
    if (historyJson != null) {
      _queryHistory = List<String>.from(jsonDecode(historyJson));
    }

    // Load study features
    await _loadFlashcards();
    await _loadQuizzes();
    await _loadTimeline();

    notifyListeners();
  }

  Future<void> toggleMockMode(bool value) async {
    _isMockMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMockMode', value);
    notifyListeners();
  }

  Future<void> setModelDownloadStatus(String status, double progress) async {
    _modelDownloadStatus = status;
    _modelDownloadProgress = progress;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modelDownloadStatus', status);
    await prefs.setDouble('modelDownloadProgress', progress);
    notifyListeners();
  }

  Future<void> initializeEngine() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _initProgress = 0.0;
    notifyListeners();

    try {
      final cacheDir = await getTemporaryDirectory();

      // Check Model presence
      final modelFile = File('${cacheDir.path}/llama3.2_1b_mobile.task');
      if (await modelFile.exists()) {
         _initProgress = 1.0;
      } else {
         debugPrint("Warning: llama3.2_1b_mobile.task missing in cache.");
      }
      
    } catch (e) {
      debugPrint("Engine Init Error: $e");
    }

    _isInitialized = true;
    _isInitializing = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInitialized', true);
    notifyListeners();
  }

  Future<void> completeOnboardingStep() async {
    _isOnboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);
    notifyListeners();
  }

  Future<void> resetInitialization() async {
    _isInitialized = false;
    _isOnboardingCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInitialized', false);
    await prefs.setBool('isOnboardingCompleted', false);
    notifyListeners();
  }

  // --- Document Operations ---

  Future<void> _loadDocuments() async {
    _documents = await DatabaseService.instance.getDocuments();
    notifyListeners();
  }

  void setSelectedDocumentId(String? id) {
    _selectedDocumentId = id;
    notifyListeners();
  }

  Future<void> ingestFile(String filePath, String fileName, int fileSize) async {
    _isIngesting = true;
    notifyListeners();

    final docId = _uuid.v4();
    final newDoc = DocumentModel(
      id: docId,
      name: fileName,
      path: filePath,
      size: fileSize,
      dateAdded: DateTime.now(),
      pageCount: 0,
      status: 'Ingesting',
      tokenCount: 0,
    );

    // Add to local list immediately to show in UI
    _documents.insert(0, newDoc);
    notifyListeners();

    try {
      // 1. Save initial record
      await DatabaseService.instance.insertDocument(newDoc);

      // 2. Stream real ingestion pipeline progress
      await for (final progress in IngressionService.instance.ingestFile(newDoc, filePath)) {
        _ingestionProgress = progress;
        _ingestionProgressText = progress;
        // Map stream messages to a 0–1 progress value
        if (progress.toLowerCase().contains('extracting')) {
          _ingestionProgressValue = 0.25;
        } else if (progress.toLowerCase().contains('creating')) {
          _ingestionProgressValue = 0.55;
        } else if (progress.toLowerCase().contains('saving')) {
          _ingestionProgressValue = 0.80;
        } else if (progress.toLowerCase().contains('done')) {
          _ingestionProgressValue = 1.0;
        }
        notifyListeners();
      }

      _lastIngestedFileName = fileName;
      await _loadDocuments(); // refresh from DB to get updated status and page counts

      // Brief pause at 100% then reset bar
      await Future.delayed(const Duration(seconds: 1));
      _ingestionProgressValue = 0.0;
      _ingestionProgressText = '';
      notifyListeners();
    } catch (e) {
      _ingestionProgressText = 'Failed — tap to retry';
      _ingestionProgressValue = -1.0; // sentinel for error state
      notifyListeners();
      _updateDocStateInList(docId, 'Failed');
      await DatabaseService.instance.updateDocumentStatus(docId, 'Failed');
    } finally {
      _isIngesting = false;
      notifyListeners();
    }
  }

  void _updateDocStateInList(String docId, String status, {int? pageCount, int? tokenCount}) {
    final idx = _documents.indexWhere((d) => d.id == docId);
    if (idx != -1) {
      _documents[idx] = _documents[idx].copyWith(
        status: status,
        pageCount: pageCount,
        tokenCount: tokenCount,
      );
      notifyListeners();
    }
  }

  Future<void> deleteDocument(String docId) async {
    await DatabaseService.instance.deleteDocument(docId);
    if (_selectedDocumentId == docId) {
      _selectedDocumentId = null;
    }
    await _loadDocuments();
  }

  // --- Message / Chat Operations ---

  Future<void> _loadMessages() async {
    _messages = await DatabaseService.instance.getMessages();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Save to query history
    _queryHistory.insert(0, text.trim());
    if (_queryHistory.length > 10) _queryHistory = _queryHistory.sublist(0, 10);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('query_history', jsonEncode(_queryHistory));
    });
    notifyListeners();

    // 1. Add User Message
    final userMsg = MessageModel(
      id: _uuid.v4(),
      sender: 'user',
      text: text,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMsg);
    notifyListeners();
    await DatabaseService.instance.insertMessage(userMsg);

    // 2. Perform Retrieval (RAG)
    final List<ChunkModel> retrievedChunks = await VectorService.instance.findRelevantChunks(
      text,
      documentId: _filterDocumentId ?? _selectedDocumentId,
      topK: 3,
    );

    // Convert retrieved chunks to UI Citations
    final List<CitationModel> citations = retrievedChunks.map((chunk) => CitationModel(
      documentId: chunk.documentId,
      documentName: chunk.documentName,
      pageNumber: chunk.pageNumber,
      textSnippet: chunk.text,
    )).toList();

    // 3. Create Placeholder AI Message in streaming state
    final aiMsgId = _uuid.v4();
    final aiMsgPlaceholder = MessageModel(
      id: aiMsgId,
      sender: 'ai',
      text: 'Thinking...',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    _messages.add(aiMsgPlaceholder);
    notifyListeners();

    // 4. Generate Answer Stream from Local LLM
    // Keep isMock: true as fallback if chunks list is empty
    final bool useMock = retrievedChunks.isEmpty ? true : false;
    final answerStream = LlmService.instance.generateAnswerStream(
      text,
      retrievedChunks,
      isMock: useMock,
    );

    StreamSubscription<String>? subscription;
    subscription = answerStream.listen(
      (accumulatedText) {
        final idx = _messages.indexWhere((m) => m.id == aiMsgId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            text: accumulatedText,
            isStreaming: true,
          );
          notifyListeners();
        }
      },
      onDone: () async {
        final idx = _messages.indexWhere((m) => m.id == aiMsgId);
        if (idx != -1) {
          final finalizedMsg = _messages[idx].copyWith(
            citations: citations,
            isStreaming: false,
          );
          _messages[idx] = finalizedMsg;
          notifyListeners();
          
          // Persist the final message to database
          await DatabaseService.instance.insertMessage(finalizedMsg);
        }
        subscription?.cancel();
      },
      onError: (err) {
        final idx = _messages.indexWhere((m) => m.id == aiMsgId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            text: "Error generating response: ${err.toString()}",
            isStreaming: false,
          );
          notifyListeners();
        }
        subscription?.cancel();
      }
    );
  }

  Future<void> _loadFlashcards() async {
    _flashcards = await DatabaseService.instance.getFlashcards();
    notifyListeners();
  }

  Future<void> _loadQuizzes() async {
    _quizzes = await DatabaseService.instance.getQuizzes();
    notifyListeners();
  }

  Future<void> _loadTimeline() async {
    _timelineItems = await DatabaseService.instance.getTimeline();
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> generateFlashcardsForDoc(String docId, String docName) async {
    // Generate 5 mock flashcards based on document name or generic concepts
    final prefix = docName.toLowerCase();
    List<Map<String, String>> qaList = [];
    
    if (prefix.contains('flutter') || prefix.contains('dart')) {
      qaList = [
        {'q': 'What is Flutter?', 'a': 'Flutter is Google\'s portable UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.'},
        {'q': 'What is a Widget in Flutter?', 'a': 'A widget is the basic building block of a Flutter app\'s user interface. Everything in Flutter is a widget.'},
        {'q': 'What language is used to write Flutter apps?', 'a': 'Flutter applications are written in Dart, a modern, class-based, object-oriented language developed by Google.'},
        {'q': 'Stateful vs Stateless Widgets?', 'a': 'StatelessWidgets are immutable, meaning their properties cannot change. StatefulWidgets can maintain state that might change during the lifetime of the widget.'},
        {'q': 'What is the purpose of runApp()?', 'a': 'The runApp() function takes the given Widget and makes it the root of the widget tree, inflating it to the screen.'},
      ];
    } else if (prefix.contains('history') || prefix.contains('world')) {
      qaList = [
        {'q': 'When did World War I begin?', 'a': 'World War I began on July 28, 1914.'},
        {'q': 'Who was the first President of the United States?', 'a': 'George Washington was the first President, serving from 1789 to 1797.'},
        {'q': 'Where was the ancient city of Pompeii located?', 'a': 'Pompeii was located near modern Naples in the Campania region of Italy, and was buried by Mount Vesuvius in 79 AD.'},
        {'q': 'What was the Magna Carta?', 'a': 'A charter of rights agreed to by King John of England in 1215, which established the principle that everyone, including the king, is subject to the law.'},
        {'q': 'When was the United Nations founded?', 'a': 'The United Nations was founded on October 24, 1945, in San Francisco, California.'},
      ];
    } else {
      qaList = [
        {'q': 'What is the main topic of $docName?', 'a': 'This document focuses on key study topics, core terminology, and key concepts outlined in the notebook sections.'},
        {'q': 'Define the primary term in $docName.', 'a': 'The primary term represents the central concept that binds the study materials and outlines detailed under this topic.'},
        {'q': 'Identify the core objective of this notebook.', 'a': 'To systematically organize structural concepts, definitions, and references for revision and exam prep.'},
        {'q': 'What is the relationship between the main ideas?', 'a': 'The main ideas connect sequential topics, building a comprehensive understanding of $docName.'},
        {'q': 'Explain the key summary of the first section.', 'a': 'It introduces basic definitions, background contexts, and historical development of the topic.'},
      ];
    }

    for (var qa in qaList) {
      final card = FlashcardModel(
        id: _uuid.v4(),
        question: qa['q']!,
        answer: qa['a']!,
        documentId: docId,
        difficulty: 'new',
        nextReviewDate: DateTime.now(),
      );
      await DatabaseService.instance.insertFlashcard(card);
    }

    final timelineItem = TimelineModel(
      id: _uuid.v4(),
      title: 'flashcards generated',
      description: 'Generated 5 study cards for $docName.',
      timestamp: DateTime.now(),
      type: 'flashcard_created',
      referenceId: docId,
    );
    await DatabaseService.instance.insertTimelineItem(timelineItem);

    await _loadFlashcards();
    await _loadTimeline();
  }

  Future<void> rateFlashcard(String cardId, String difficulty) async {
    DateTime nextReview;
    switch (difficulty) {
      case 'hard':
        nextReview = DateTime.now().add(const Duration(minutes: 10));
        break;
      case 'good':
        nextReview = DateTime.now().add(const Duration(days: 1));
        break;
      case 'easy':
        nextReview = DateTime.now().add(const Duration(days: 3));
        break;
      default:
        nextReview = DateTime.now().add(const Duration(days: 1));
    }
    await DatabaseService.instance.updateFlashcardDifficulty(cardId, difficulty, nextReview);
    await _loadFlashcards();
  }

  Future<void> generateQuizForDoc(String docId, String docName) async {
    final prefix = docName.toLowerCase();
    List<QuizQuestion> questions = [];

    if (prefix.contains('flutter') || prefix.contains('dart')) {
      questions = [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What is the main programming language used in Flutter?',
          options: ['Java', 'Dart', 'Swift', 'Kotlin'],
          correctAnswerIndex: 1,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Which widget is immutable and has no mutable state?',
          options: ['StatefulWidget', 'InheritedWidget', 'StatelessWidget', 'Container'],
          correctAnswerIndex: 2,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Which function starts a Flutter app and inflates the root widget?',
          options: ['runApp()', 'main()', 'initApp()', 'startWidget()'],
          correctAnswerIndex: 0,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What command is used to analyze code for compile errors?',
          options: ['flutter test', 'flutter doctor', 'flutter format', 'flutter analyze'],
          correctAnswerIndex: 3,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Does Flutter render UI components using native platform OEM widgets?',
          options: ['Yes, always', 'No, it draws them on a canvas', 'Only on iOS', 'Only on Web'],
          correctAnswerIndex: 1,
        ),
      ];
    } else if (prefix.contains('history') || prefix.contains('world')) {
      questions = [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Who was the first President of the United States?',
          options: ['Thomas Jefferson', 'John Adams', 'George Washington', 'Benjamin Franklin'],
          correctAnswerIndex: 2,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'In which year did World War II end?',
          options: ['1918', '1945', '1939', '1950'],
          correctAnswerIndex: 1,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'The ancient city of Pompeii was destroyed by which volcano?',
          options: ['Mount Vesuvius', 'Mount Etna', 'Krakatoa', 'Mount Fuji'],
          correctAnswerIndex: 0,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Who wrote the Declaration of Independence?',
          options: ['George Washington', 'Thomas Jefferson', 'Alexander Hamilton', 'Abraham Lincoln'],
          correctAnswerIndex: 1,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'The Magna Carta was signed in which year?',
          options: ['1066', '1215', '1492', '1776'],
          correctAnswerIndex: 1,
        ),
      ];
    } else {
      questions = [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What is the primary topic discussed in $docName?',
          options: ['Science and Math', 'Humanities and Arts', 'Systematic concept overview', 'Practical code implementations'],
          correctAnswerIndex: 2,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Why should study materials like $docName be structured?',
          options: ['To store in cloud storage', 'To enhance recall, scheduling, and active review', 'To read online with high latency', 'To avoid local backups'],
          correctAnswerIndex: 1,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What is a core benefit of local AI processing?',
          options: ['Requires internet', '100% offline privacy and zero server fees', 'Faster download speeds', 'Cloud backups'],
          correctAnswerIndex: 1,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Which element is essential for learning and retention?',
          options: ['Continuous scrolling', 'Active recall and spaced repetition', 'Listening to music', 'Reading without summaries'],
          correctAnswerIndex: 1,
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'How does Smriti assist in studying documents?',
          options: ['By translating to French', 'By compiling to binaries', 'By generating summaries, flashcards, and quizzes locally', 'By emailing them to teachers'],
          correctAnswerIndex: 2,
        ),
      ];
    }

    final quiz = QuizModel(
      id: _uuid.v4(),
      title: 'Review Quiz: $docName',
      documentId: docId,
      questions: questions,
    );

    await DatabaseService.instance.insertQuiz(quiz);
    await _loadQuizzes();
  }

  Future<void> submitQuizScore(String docId, String quizTitle, int score, int totalQuestions) async {
    final timelineItem = TimelineModel(
      id: _uuid.v4(),
      title: 'quiz completed',
      description: 'Completed "$quizTitle". Scored $score/$totalQuestions.',
      timestamp: DateTime.now(),
      type: 'quiz_completed',
      referenceId: docId,
    );
    
    await DatabaseService.instance.insertTimelineItem(timelineItem);
    await _loadTimeline();
  }

  Future<void> addTimelineItem(String title, String description, String type, String referenceId) async {
    final item = TimelineModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: type,
      referenceId: referenceId,
    );
    await DatabaseService.instance.insertTimelineItem(item);
    await _loadTimeline();
  }

  Future<void> clearChatHistory() async {
    // Save the conversation to a permanent PDF backup before wiping
    if (_messages.isNotEmpty) {
      try {
        final pdf = pw.Document();
        
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text("Smriti Chat Backup", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Paragraph(text: "Date: ${DateTime.now().toString().split('.')[0]}"),
                pw.SizedBox(height: 20),
                ..._messages.map((m) {
                  final isUser = m.sender == 'user';
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: isUser ? PdfColors.blue100 : PdfColors.grey200,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isUser ? "You" : "Smriti AI",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isUser ? PdfColors.blue800 : PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(m.text),
                      ],
                    ),
                  );
                }).toList(),
              ];
            },
          ),
        );

        // Save to application documents directory so it survives cache clearing
        final docsDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final backupDir = Directory('${docsDir.path}/saved_chats');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        final backupFile = File('${backupDir.path}/chat_$timestamp.pdf');
        
        await backupFile.writeAsBytes(await pdf.save());
        debugPrint('Conversation saved to permanent storage: ${backupFile.path}');
      } catch (e) {
        debugPrint('Failed to save conversation PDF: $e');
      }
    }

    final db = await DatabaseService.instance.database;
    await db.delete('messages');
    _messages.clear();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await DatabaseService.instance.clearAllData();
    _documents.clear();
    _messages.clear();
    _flashcards.clear();
    _quizzes.clear();
    _timelineItems.clear();
    _selectedDocumentId = null;
    await resetInitialization();
    notifyListeners();
  }
}
