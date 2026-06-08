import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../models/document_model.dart';
import '../../core/theme.dart';

class ExamRevisionScreen extends StatefulWidget {
  const ExamRevisionScreen({super.key});

  @override
  State<ExamRevisionScreen> createState() => _ExamRevisionScreenState();
}

class _ExamRevisionScreenState extends State<ExamRevisionScreen> {
  DocumentModel? _selectedDoc;
  
  // Pomodoro variables
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isFocusMode = true; // true = 25m focus, false = 5m break
  int _totalDuration = 25 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timerCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _isFocusMode ? 25 * 60 : 5 * 60;
      _totalDuration = _secondsRemaining;
    });
  }

  void _switchMode(bool isFocus) {
    _timer?.cancel();
    setState(() {
      _isFocusMode = isFocus;
      _isRunning = false;
      _secondsRemaining = isFocus ? 25 * 60 : 5 * 60;
      _totalDuration = _secondsRemaining;
    });
  }

  void _timerCompleted() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    
    // Log to timeline
    if (_selectedDoc != null) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final label = _isFocusMode ? 'focus session completed' : 'study break completed';
      final desc = _isFocusMode
          ? 'Completed a 25-minute focus session for "${_selectedDoc!.name}".'
          : 'Completed a 5-minute study break.';
      provider.addTimelineItem(label, desc, 'chat_session', _selectedDoc!.id);
    }

    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isFocusMode ? 'Focus Finished!' : 'Break Over!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _isFocusMode
              ? 'Great job staying focused. Take a 5-minute break now.'
              : 'Break is over. Ready to get back to work?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _switchMode(!_isFocusMode);
            },
            child: const Text('Start Next Session', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final docs = provider.documents.where((d) => d.status == 'Ready').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EXAM REVISION MODE'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            // Select document dropdown
            const Text(
              'SELECT REVISION BOOK',
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

            // Revision summary guide + Pomodoro
            Expanded(
              child: _selectedDoc == null
                  ? _buildSelectPrompt()
                  : Column(
                      children: [
                        // Pomodoro Timer Panel (collapsible or fixed header)
                        _buildPomodoroPanel(),
                        const SizedBox(height: 20),
                        
                        // Revision Summary List
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'REVISION STUDY GUIDE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _buildRevisionGuide(),
                        ),
                      ],
                    ),
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
              _resetTimer();
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
          Icon(Icons.timer_outlined, size: 48, color: AppTheme.textLight),
          SizedBox(height: 16),
          Text(
            'choose a study notebook',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Select an indexed document to generate structural revision guides and run the Pomodoro clock.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroPanel() {
    final progress = _secondsRemaining / _totalDuration;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: Column(
        children: [
          // Header toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimerModeButton('Focus (25m)', _isFocusMode, () => _switchMode(true)),
              const SizedBox(width: 12),
              _buildTimerModeButton('Break (5m)', !_isFocusMode, () => _switchMode(false)),
            ],
          ),
          const SizedBox(height: 20),

          // Clock circle & controls
          Row(
            children: [
              // Circular progress timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 5,
                    ),
                  ),
                  Text(
                    _formatDuration(_secondsRemaining),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isFocusMode ? 'focus session' : 'recharging break',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keep your screen active and minimize distractions.',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isRunning ? _pauseTimer : _startTimer,
                            child: Text(_isRunning ? 'Pause' : 'Start', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.border, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          ),
                          onPressed: _resetTimer,
                          child: const Text('Reset', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerModeButton(String label, bool isActive, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive ? Colors.black : AppTheme.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRevisionGuide() {
    final title = _selectedDoc!.name.toLowerCase();
    
    // Generate guide structures
    final List<Widget> items = [];

    if (title.contains('flutter') || title.contains('dart')) {
      items.addAll([
        _buildSectionHeader('1. introduction to flutter framework'),
        _buildParagraph('Flutter is Google\'s open-source UI SDK designed to build cross-platform applications natively from a single codebase. It uses the Dart programming language and compiles directly to native platform architecture.'),
        _buildBulletPoint('declarative UI paradigm', 'The UI is a reflection of the current application state. When state changes, widgets rebuild.'),
        _buildBulletPoint('skia/impeller renderer', 'Unlike traditional frameworks that wrap OEM widgets, Flutter draws every pixel itself directly on a canvas, ensuring uniform visuals across platforms.'),
        
        _buildSectionHeader('2. component structure and widgets'),
        _buildParagraph('Everything in Flutter is a Widget. Layouts, margins, styles, and alignments are defined declaratively in the widget tree.'),
        _buildBulletPoint('stateless widgets', 'Immutable and static. Cannot hold mutable state; their visual properties depend strictly on constructor arguments.'),
        _buildBulletPoint('stateful widgets', 'Maintain a state object that persists across widget rebuilds. Rebuilds are triggered by calling setState().'),
        
        _buildSectionHeader('3. compilation types'),
        _buildBulletPoint('ahead-of-time (AOT)', 'Used for production releases. Compiles Dart directly to native CPU machine code for high performance.'),
        _buildBulletPoint('just-in-time (JIT)', 'Used during debug development. Enables the Hot Reload cycle by pushing code changes directly into the VM without full builds.'),
      ]);
    } else if (title.contains('history') || title.contains('world')) {
      items.addAll([
        _buildSectionHeader('1. founding origins of the republic'),
        _buildParagraph('The United States declared independence from Great Britain in 1776, establishing a representative constitutional democracy guided by federal principles.'),
        _buildBulletPoint('magna carta (1215)', 'Ancient precursor establishing that sovereign power is not absolute and is subject to laws.'),
        _buildBulletPoint('declaration of independence', 'Drafted primarily by Thomas Jefferson, asserting natural human rights to liberty and self-determination.'),
        
        _buildSectionHeader('2. major historical global conflicts'),
        _buildBulletPoint('world war i (1914 - 1918)', 'Triggered by the assassination of Archduke Franz Ferdinand, leading to global trench warfare and the collapse of major imperial empires.'),
        _buildBulletPoint('world war ii (1939 - 1945)', 'Fought between Allied and Axis powers. Ended with the fall of Berlin and atomic bombings of Hiroshima and Nagasaki, leading to the creation of the United Nations.'),
      ]);
    } else {
      items.addAll([
        _buildSectionHeader('1. overview of ${title.toUpperCase()}'),
        _buildParagraph('This revision guide outlines the critical study concepts, vocabulary terms, and contextual summaries compiled from the notebook file "$title". Review these sections systematically to prepare for testing.'),
        _buildSectionHeader('2. core terminology'),
        _buildBulletPoint('primary concept', 'The fundamental principle explaining how topics connect sequential logic within the study material.'),
        _buildBulletPoint('structured review', 'Active recall through summaries, micro-questions, and periodic testing cycles increases cognitive retention rates.'),
        _buildSectionHeader('3. critical review questions'),
        _buildBulletPoint('inquiry 1', 'How does the introductory section define the core problem statement?'),
        _buildBulletPoint('inquiry 2', 'What are the main supporting arguments outlined in the middle paragraphs?'),
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: items,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toLowerCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppTheme.textSecondary),
                children: [
                  TextSpan(
                    text: '${term.toLowerCase()}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(text: definition),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
