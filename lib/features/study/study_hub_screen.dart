import 'package:flutter/material.dart';
import 'flashcards_screen.dart';
import 'quiz_generator_screen.dart';
import 'exam_revision_screen.dart';
import '../../core/theme.dart';

class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('STUDY HUB'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Study Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'enhance your memory',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generate revision cards and practice quizzes directly from your ingested notebooks. Everything is processed offline on your local AI engine.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'REVISION METHODS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Card 1: Flashcards Review
            _buildRevisionCard(
              context,
              icon: Icons.filter_none_rounded,
              title: 'Flashcard Decks',
              description: 'Flip and swipe active study cards. Rate your recall difficulty to optimize study schedules.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Card 2: Practice Quizzes
            _buildRevisionCard(
              context,
              icon: Icons.checklist_rtl_rounded,
              title: 'Quiz Generator',
              description: 'Create multi-option quizzes from notebook text extracts. Verify answers with review sheets.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizGeneratorScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Card 3: Exam Revision Mode
            _buildRevisionCard(
              context,
              icon: Icons.timer_outlined,
              title: 'Exam Revision Mode',
              description: 'Read document bullet outlines and study using the integrated offline Pomodoro focus timer.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExamRevisionScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
