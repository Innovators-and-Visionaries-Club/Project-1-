import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/document_model.dart';
import '../models/chunk_model.dart';
import 'database_service.dart';

class UnsupportedFileTypeException implements Exception {
  final String message;
  UnsupportedFileTypeException(this.message);
  @override
  String toString() => message;
}

class IngressionService {
  static final IngressionService instance = IngressionService._init();
  final Uuid _uuid = const Uuid();

  IngressionService._init();

  Stream<String> ingestFile(DocumentModel doc, String filePath) async* {
    yield "Extracting text...";
    try {
      await DatabaseService.instance.updateDocumentStatus(doc.id, 'processing');
      
      final extension = filePath.split('.').last.toLowerCase();
      List<ChunkModel> chunks = [];

      if (extension == 'txt') {
        final text = await File(filePath).readAsString();
        chunks.addAll(_chunkText(text, doc, 1));
      } else if (extension == 'pdf') {
        chunks.addAll(await _extractAndChunkPdf(filePath, doc));
      } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
        final text = await _extractImageText(filePath);
        chunks.addAll(_chunkText(text, doc, 1));
      } else if (extension == 'docx') {
        final text = await _extractDocxText(filePath);
        chunks.addAll(_chunkText(text, doc, 1));
      } else {
        throw UnsupportedFileTypeException('Unsupported file type: $extension');
      }
      
      yield "Creating ${chunks.length} chunks...";
      
      yield "Saving to database...";
      await DatabaseService.instance.insertChunks(chunks);
      await DatabaseService.instance.updateDocumentStatus(
        doc.id, 
        'Ready', 
        pageCount: chunks.isNotEmpty ? chunks.last.pageNumber : 1, 
        tokenCount: chunks.fold<int>(0, (sum, c) => sum + c.text.split(' ').length)
      );
      
      yield "Done! Ready to query.";
    } catch (e) {
      await DatabaseService.instance.updateDocumentStatus(doc.id, 'failed');
      yield "Error during ingestion: ${e.toString()}";
    }
  }

  Future<List<ChunkModel>> _extractAndChunkPdf(String filePath, DocumentModel doc) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    List<ChunkModel> allChunks = [];
    
    for (int i = 0; i < document.pages.count; i++) {
      String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (pageText.trim().isEmpty) {
        pageText = "[PAGE ${i+1} EMPTY OR IMAGE - OCR NEEDED]";
      }
      allChunks.addAll(_chunkText(pageText, doc, i + 1));
    }
    document.dispose();
    return allChunks;
  }

  Future<String> _extractImageText(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  Future<String> _extractDocxText(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final targetName = 'word/document.xml'.codeUnits;
    int foundIndex = -1;
    for (int i = 0; i <= bytes.length - targetName.length; i++) {
      bool match = true;
      for (int j = 0; j < targetName.length; j++) {
        if (bytes[i + j] != targetName[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex == -1) return "";

    int headerStart = -1;
    for (int i = foundIndex; i >= 0; i--) {
      if (i + 3 < bytes.length && bytes[i] == 0x50 && bytes[i+1] == 0x4b && bytes[i+2] == 0x03 && bytes[i+3] == 0x04) {
        headerStart = i;
        break;
      }
    }

    if (headerStart == -1) return "";

    int compMethod = bytes[headerStart + 8] | (bytes[headerStart + 9] << 8);
    int compSize = bytes[headerStart + 18] | (bytes[headerStart + 19] << 8) | (bytes[headerStart + 20] << 16) | (bytes[headerStart + 21] << 24);
    int nameLen = bytes[headerStart + 26] | (bytes[headerStart + 27] << 8);
    int extraLen = bytes[headerStart + 28] | (bytes[headerStart + 29] << 8);

    int dataStart = headerStart + 30 + nameLen + extraLen;
    final compressedData = bytes.sublist(dataStart, dataStart + compSize);

    List<int> uncompressedData;
    if (compMethod == 8) {
      uncompressedData = ZLibDecoder(raw: true).convert(compressedData);
    } else if (compMethod == 0) {
      uncompressedData = compressedData;
    } else {
      return "Unsupported compression method in docx: $compMethod";
    }

    final xmlStr = utf8.decode(uncompressedData, allowMalformed: true);
    return xmlStr.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<ChunkModel> _chunkText(String text, DocumentModel doc, int pageNumber) {
    const int chunkSize = 1000;
    const int chunkOverlap = 200;
    
    // 1. Semantic split: Start with paragraphs
    final paragraphs = text.split(RegExp(r'\n\n+'));
    List<String> allSentences = [];
    
    // 2. Further split huge paragraphs by sentence boundaries
    for (var p in paragraphs) {
      if (p.length > chunkSize) {
        final sentences = p.replaceAll(RegExp(r'(?<=\.)\s+'), '\n').split('\n');
        for (var s in sentences) {
          if (s.length > chunkSize) {
             // Hard slice if a single semantic block is absurdly long
             for (int i = 0; i < s.length; i += chunkSize) {
               allSentences.add(s.substring(i, (i + chunkSize) > s.length ? s.length : (i + chunkSize)));
             }
          } else {
             allSentences.add(s);
          }
        }
      } else {
        allSentences.add(p);
      }
    }

    List<ChunkModel> chunks = [];
    String currentChunk = "";

    // 3. Assemble chunks up to target size with calculated overlap
    for (var sentence in allSentences) {
      if (sentence.trim().isEmpty) continue;
      
      if (currentChunk.length + sentence.length > chunkSize && currentChunk.isNotEmpty) {
        chunks.add(ChunkModel(
          id: _uuid.v4(),
          documentId: doc.id,
          documentName: doc.name,
          pageNumber: pageNumber,
          text: currentChunk.trim(),
          embedding: null,
        ));
        
        // Overlap logic: preserve exactly ~200 characters from the end of the previous chunk
        int overlapStart = currentChunk.length - chunkOverlap;
        if (overlapStart < 0) overlapStart = 0;
        
        // Find a natural word boundary for the overlap start
        int spaceIdx = currentChunk.indexOf(' ', overlapStart);
        if (spaceIdx == -1 || spaceIdx > currentChunk.length - 50) {
           spaceIdx = overlapStart; 
        }
        
        currentChunk = currentChunk.substring(spaceIdx).trim() + " " + sentence.trim();
      } else {
        currentChunk += (currentChunk.isEmpty ? "" : " ") + sentence.trim();
      }
    }

    if (currentChunk.trim().isNotEmpty) {
      chunks.add(ChunkModel(
        id: _uuid.v4(),
        documentId: doc.id,
        documentName: doc.name,
        pageNumber: pageNumber,
        text: currentChunk.trim(),
        embedding: null,
      ));
    }

    return chunks;
  }
}
