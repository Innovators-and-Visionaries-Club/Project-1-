import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/document_model.dart';
import '../models/chunk_model.dart';
import '../models/message_model.dart';
import '../models/flashcard_model.dart';
import '../models/quiz_model.dart';
import '../models/timeline_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smriti.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        size INTEGER NOT NULL,
        dateAdded TEXT NOT NULL,
        pageCount INTEGER NOT NULL,
        status TEXT NOT NULL,
        tokenCount INTEGER NOT NULL
      )
    ''');

    // Chunks table (with serialized embedding)
    await db.execute('''
      CREATE TABLE chunks (
        id TEXT PRIMARY KEY,
        documentId TEXT NOT NULL,
        documentName TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        text TEXT NOT NULL,
        embedding TEXT,
        FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // Messages table (citations serialized as JSON)
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        citations TEXT NOT NULL
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        documentId TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        nextReviewDate TEXT NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // Quizzes table
    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        documentId TEXT NOT NULL,
        questions TEXT NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // Timeline table
    await db.execute('''
      CREATE TABLE timeline (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        referenceId TEXT NOT NULL
      )
    ''');
  }

  // --- Document Operations ---

  Future<List<DocumentModel>> getDocuments() async {
    final db = await instance.database;
    final result = await db.query('documents', orderBy: 'dateAdded DESC');
    return result.map((json) => DocumentModel.fromMap(json)).toList();
  }

  Future<void> insertDocument(DocumentModel doc) async {
    final db = await instance.database;
    await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDocumentStatus(String id, String status, {int? tokenCount, int? pageCount}) async {
    final db = await instance.database;
    Map<String, dynamic> values = {'status': status};
    if (tokenCount != null) values['tokenCount'] = tokenCount;
    if (pageCount != null) values['pageCount'] = pageCount;

    await db.update(
      'documents',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await instance.database;
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Delete related chunks as cascade fallback if DB foreign key is disabled
    await db.delete(
      'chunks',
      where: 'documentId = ?',
      whereArgs: [id],
    );
  }

  // --- Chunk Operations ---

  Future<void> insertChunks(List<ChunkModel> chunks) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var chunk in chunks) {
      batch.insert(
        'chunks',
        chunk.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChunkModel>> getChunks({String? documentId}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result;
    if (documentId != null) {
      result = await db.query(
        'chunks',
        where: 'documentId = ?',
        whereArgs: [documentId],
      );
    } else {
      result = await db.query('chunks');
    }
    return result.map((json) => ChunkModel.fromMap(json)).toList();
  }

  // --- Message Operations ---

  Future<List<MessageModel>> getMessages() async {
    final db = await instance.database;
    final result = await db.query('messages', orderBy: 'timestamp ASC');
    return result.map((json) {
      // Deserialize citations
      List<dynamic> citationsRaw = jsonDecode(json['citations'] as String);
      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(json);
      mutableMap['citations'] = citationsRaw;
      return MessageModel.fromMap(mutableMap);
    }).toList();
  }

  Future<void> insertMessage(MessageModel message) async {
    final db = await instance.database;
    final map = {
      'id': message.id,
      'sender': message.sender,
      'text': message.text,
      'timestamp': message.timestamp.toIso8601String(),
      'citations': jsonEncode(message.citations.map((c) => c.toMap()).toList()),
    };
    await db.insert(
      'messages',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('chunks');
    await db.delete('documents');
    await db.delete('messages');
    await db.delete('flashcards');
    await db.delete('quizzes');
    await db.delete('timeline');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }

  // --- Flashcard Operations ---

  Future<List<FlashcardModel>> getFlashcards({String? documentId}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result;
    if (documentId != null) {
      result = await db.query(
        'flashcards',
        where: 'documentId = ?',
        whereArgs: [documentId],
      );
    } else {
      result = await db.query('flashcards', orderBy: 'nextReviewDate ASC');
    }
    return result.map((json) => FlashcardModel.fromMap(json)).toList();
  }

  Future<void> insertFlashcard(FlashcardModel card) async {
    final db = await instance.database;
    await db.insert(
      'flashcards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFlashcardDifficulty(String id, String difficulty, DateTime nextReviewDate) async {
    final db = await instance.database;
    await db.update(
      'flashcards',
      {
        'difficulty': difficulty,
        'nextReviewDate': nextReviewDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFlashcard(String id) async {
    final db = await instance.database;
    await db.delete(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Quiz Operations ---

  Future<List<QuizModel>> getQuizzes({String? documentId}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result;
    if (documentId != null) {
      result = await db.query(
        'quizzes',
        where: 'documentId = ?',
        whereArgs: [documentId],
      );
    } else {
      result = await db.query('quizzes');
    }
    return result.map((json) => QuizModel.fromMap(json)).toList();
  }

  Future<void> insertQuiz(QuizModel quiz) async {
    final db = await instance.database;
    await db.insert(
      'quizzes',
      quiz.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteQuiz(String id) async {
    final db = await instance.database;
    await db.delete(
      'quizzes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Timeline Operations ---

  Future<List<TimelineModel>> getTimeline() async {
    final db = await instance.database;
    final result = await db.query('timeline', orderBy: 'timestamp DESC');
    return result.map((json) => TimelineModel.fromMap(json)).toList();
  }

  Future<void> insertTimelineItem(TimelineModel item) async {
    final db = await instance.database;
    await db.insert(
      'timeline',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
