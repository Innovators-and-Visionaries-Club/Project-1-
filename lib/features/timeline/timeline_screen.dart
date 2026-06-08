import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../models/timeline_model.dart';
import '../../core/theme.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final items = provider.timelineItems;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MEMORY TIMELINE'),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildTimelineRow(context, items[index], index == items.length - 1);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 54, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text(
              'no activity recorded yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Upload textbooks, generate flashcards, or take quizzes. Your local study logs will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(BuildContext context, TimelineModel item, bool isLast) {
    IconData iconData;
    switch (item.type) {
      case 'document_ingested':
        iconData = Icons.description_outlined;
        break;
      case 'quiz_completed':
        iconData = Icons.checklist_rtl_rounded;
        break;
      case 'flashcard_created':
        iconData = Icons.filter_none_outlined;
        break;
      case 'chat_session':
        iconData = Icons.chat_bubble_outline_rounded;
        break;
      default:
        iconData = Icons.star_border_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator (connector line & dot)
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 15,
                    bottom: 0,
                    width: 1.5,
                    child: Container(
                      color: AppTheme.border,
                    ),
                  ),
                Positioned(
                  top: 10,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.8),
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.title.toLowerCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _formatTime(item.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
