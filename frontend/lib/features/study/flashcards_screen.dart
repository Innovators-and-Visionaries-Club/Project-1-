import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../models/flashcard_model.dart';
import '../../models/document_model.dart';
import '../../core/theme.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  DocumentModel? _selectedDoc;
  int _currentIndex = 0;
  bool _isGenerating = false;

  void _generateCards(AppProvider provider) async {
    if (_selectedDoc == null) return;
    setState(() {
      _isGenerating = true;
    });
    
    await provider.generateFlashcardsForDoc(_selectedDoc!.id, _selectedDoc!.name);
    
    setState(() {
      _isGenerating = false;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final docs = provider.documents.where((d) => d.status == 'Ready').toList();
    
    // Filter flashcards by selected document if selected
    final cards = _selectedDoc == null 
        ? <FlashcardModel>[] 
        : provider.flashcards.where((c) => c.documentId == _selectedDoc!.id).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('FLASHCARDS'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selection dropdown
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

            // Main Deck Board
            Expanded(
              child: _selectedDoc == null
                  ? _buildSelectPrompt()
                  : _isGenerating
                      ? _buildGeneratingState()
                      : cards.isEmpty
                          ? _buildEmptyCardsState(provider)
                          : _currentIndex >= cards.length
                              ? _buildCompletedState(provider)
                              : _buildCardReviewer(provider, cards[_currentIndex], cards.length),
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
              _currentIndex = 0;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_none_rounded, size: 48, color: AppTheme.textLight),
          SizedBox(height: 16),
          Text(
            'choose a notebook above',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Select an active ingested file to review flashcards or trigger AI card extraction.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
            'generating flashcard index...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'Smriti is analyzing text segments to create Q&A cards.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCardsState(AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, size: 48, color: Colors.black),
          const SizedBox(height: 16),
          const Text(
            'no flashcards generated yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Extract active flashcards directly from the document using local AI.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _generateCards(provider),
            child: const Text('Generate Flashcards'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 54, color: Colors.black),
          const SizedBox(height: 20),
          const Text(
            'study session finished!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'All study cards inside this notebook have been reviewed successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
            child: const Text('Study Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardReviewer(AppProvider provider, FlashcardModel card, int totalCards) {
    return Column(
      children: [
        // Counter
        Text(
          'CARD ${_currentIndex + 1} OF $totalCards',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 15),

        // Flip Card Widget
        Expanded(
          child: FlipCard(
            front: _buildCardSide(card.question, isFront: true),
            back: _buildCardSide(card.answer, isFront: false),
          ),
        ),
        const SizedBox(height: 24),

        // Action recall buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRecallButton('hard', Colors.redAccent, () {
              provider.rateFlashcard(card.id, 'hard');
              setState(() {
                _currentIndex++;
              });
            }),
            _buildRecallButton('good', Colors.black, () {
              provider.rateFlashcard(card.id, 'good');
              setState(() {
                _currentIndex++;
              });
            }),
            _buildRecallButton('easy', const Color(0xFF10B981), () {
              provider.rateFlashcard(card.id, 'easy');
              setState(() {
                _currentIndex++;
              });
            }),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCardSide(String text, {required bool isFront}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFront ? Colors.black : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isFront ? 'question' : 'answer',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isFront ? Colors.white : Colors.black,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap to Flip Card',
            style: TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 90,
      height: 38,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}

// 3D Flip Card Widget
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const FlipCard({super.key, required this.front, required this.back});

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBack = angle >= pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}
