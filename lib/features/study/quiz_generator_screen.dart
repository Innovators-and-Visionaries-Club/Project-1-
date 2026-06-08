import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/document_model.dart';
import '../../core/theme.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  DocumentModel? _selectedDoc;
  QuizModel? _activeQuiz;
  int _currentQuestionIndex = 0;
  bool _isGenerating = false;
  bool _isSubmitted = false;
  
  // Store selected option index for each question
  final List<int> _selectedAnswers = [];

  void _generateQuiz(AppProvider provider) async {
    if (_selectedDoc == null) return;
    setState(() {
      _isGenerating = true;
      _isSubmitted = false;
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
    });

    await provider.generateQuizForDoc(_selectedDoc!.id, _selectedDoc!.name);

    // Get the latest generated quiz for this document
    final docQuizzes = provider.quizzes.where((q) => q.documentId == _selectedDoc!.id).toList();
    
    setState(() {
      _isGenerating = false;
      if (docQuizzes.isNotEmpty) {
        _activeQuiz = docQuizzes.last;
        _selectedAnswers.addAll(List<int>.filled(_activeQuiz!.questions.length, -1));
      }
    });
  }

  void _submitQuiz(AppProvider provider) {
    if (_activeQuiz == null) return;
    
    int score = 0;
    for (int i = 0; i < _activeQuiz!.questions.length; i++) {
      if (_selectedAnswers[i] == _activeQuiz!.questions[i].correctAnswerIndex) {
        score++;
      }
    }

    provider.submitQuizScore(
      _selectedDoc!.id,
      _activeQuiz!.title,
      score,
      _activeQuiz!.questions.length,
    );

    setState(() {
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final docs = provider.documents.where((d) => d.status == 'Ready').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QUIZ GENERATOR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown selector
            if (!_isSubmitted && !_isGenerating && _activeQuiz == null) ...[
              const Text(
                'SELECT STUDY BOOK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildDocDropdown(docs),
              const SizedBox(height: 20),
            ],

            // Content
            Expanded(
              child: _isGenerating
                  ? _buildGeneratingState()
                  : _activeQuiz == null
                      ? _buildSelectPrompt()
                      : _isSubmitted
                          ? _buildScoreSummary(provider)
                          : _buildQuizQuestionBoard(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocDropdown(List<DocumentModel> docs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DocumentModel>(
          value: _selectedDoc,
          hint: const Text('Choose a notebook...'),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.black),
          isExpanded: true,
          items: docs.map((doc) {
            return DropdownMenuItem(
              value: doc,
              child: Text(
                doc.name,
                style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (doc) {
            setState(() {
              _selectedDoc = doc;
              _activeQuiz = null;
              _isSubmitted = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checklist_rtl_rounded, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text(
            'generate practice quiz',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select an indexed document to test your knowledge with a five-question custom quiz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedDoc == null ? null : () => _generateQuiz(Provider.of<AppProvider>(context, listen: false)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedDoc == null ? const Color(0xFFE5E7EB) : Colors.black,
            ),
            child: const Text('Generate Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'creating multi-option board...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'Smriti is analyzing text segments to create quiz questions.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestionBoard(AppProvider provider) {
    final quiz = _activeQuiz!;
    final question = quiz.questions[_currentQuestionIndex];
    final totalQuestions = quiz.questions.length;
    final selectedIdx = _selectedAnswers[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUESTION ${_currentQuestionIndex + 1} OF $totalQuestions',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _selectedDoc!.name.toLowerCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / totalQuestions,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 25),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Options list
                ...List.generate(question.options.length, (index) {
                  final optionText = question.options[index];
                  final isSelected = selectedIdx == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.black : Colors.white,
                        foregroundColor: isSelected ? Colors.white : Colors.black,
                        side: BorderSide(
                          color: isSelected ? Colors.black : AppTheme.border,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.black,
                                width: 1.5,
                              ),
                              color: isSelected ? Colors.white : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation Footer buttons
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentQuestionIndex > 0)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                  });
                },
                child: const Text('Back', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            else
              const SizedBox(),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: selectedIdx == -1
                  ? null
                  : () {
                      if (_currentQuestionIndex < totalQuestions - 1) {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      } else {
                        _submitQuiz(provider);
                      }
                    },
              child: Text(
                _currentQuestionIndex == totalQuestions - 1 ? 'Finish Quiz' : 'Next Question',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreSummary(AppProvider provider) {
    final quiz = _activeQuiz!;
    int score = 0;
    for (int i = 0; i < quiz.questions.length; i++) {
      if (_selectedAnswers[i] == quiz.questions[i].correctAnswerIndex) {
        score++;
      }
    }
    final pct = (score / quiz.questions.length * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score circle
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score/${quiz.questions.length}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '$pct% score',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),

        const Text(
          'CORRECTION SHEET',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // Questions review list
        Expanded(
          child: ListView.builder(
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final q = quiz.questions[index];
              final userAns = _selectedAnswers[index];
              final isCorrect = userAns == q.correctAnswerIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect ? const Color(0xFF10B981) : Colors.black,
                      width: isCorrect ? 1.8 : 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Question ${index + 1}: ${q.question}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your Answer: ${userAns != -1 ? q.options[userAns] : "Skipped"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Correct Answer: ${q.options[q.correctAnswerIndex]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _activeQuiz = null;
                    _isSubmitted = false;
                  });
                },
                child: const Text('Practice Other Book', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                    _currentQuestionIndex = 0;
                    _selectedAnswers.fillRange(0, _selectedAnswers.length, -1);
                  });
                },
                child: const Text('Retake Quiz'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
