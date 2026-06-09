import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/app_provider.dart';
import '../../models/document_model.dart';
import '../../widgets/wavy_background.dart';
import '../../core/theme.dart';
import 'document_preview_screen.dart';

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late AppProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<AppProvider>(context, listen: false);
    _provider.removeListener(_onIngestionComplete); // avoid double-register
    _provider.addListener(_onIngestionComplete);
  }

  void _onIngestionComplete() {
    final name = _provider.lastIngestedFileName;
    if (name != null) {
      _provider.consumeIngestedFileName();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Γ£ô $name ingested ΓÇö ready to query'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onIngestionComplete);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickAndIngestFile(BuildContext context, AppProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        provider.ingestFile(file.path!, file.name, file.size);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    double kb = bytes / 1024;
    if (kb < 1024) {
      return "${kb.toStringAsFixed(1)} KB";
    }
    double mb = kb / 1024;
    return "${mb.toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final filteredDocs = provider.documents.where((doc) {
      return doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Wavy Black Header (Screen 3 & 6 Profile Section)
            _buildWavyProfileHeader(context, provider),

            // Ingestion Circular Progress block (Screen 5 style)
            if (provider.isIngesting) _buildCircularProgressBlock(provider),

            // Stats Cards Row
            _buildStatsRow(provider),

            // Overlapping white body card contents
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'my library',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.black,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickAndIngestFile(context, provider),
                        icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.black),
                        label: const Text(
                          'add note',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Selected Scope active indicator
                  _buildScopeBanner(provider),

                  // Document List
                  filteredDocs.isEmpty
                      ? _buildEmptyState(context, provider)
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 10, bottom: 90),
                          itemCount: filteredDocs.length,
                          itemBuilder: (ctx, idx) {
                            final doc = filteredDocs[idx];
                            return _buildDocumentCard(provider, doc);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndIngestFile(context, provider),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildWavyProfileHeader(BuildContext context, AppProvider provider) {
    return ClipPath(
      clipper: WavyHeaderClipper(),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 45),
        child: Column(
          children: [
            // Top Menu & Avatar row (Screen 6)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.sort_rounded, color: Colors.white),
                  onPressed: () {},
                ),
                // Circular initials avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'SL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Profile info (Screen 6)
            const Text(
              'smriti offline brain',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'offline ┬╖ private',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'model loaded: gemma 2b q4',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Overlapping pill badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${provider.documents.length} notebooks ingested',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search bar (Screen 3)
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ask your memory anything...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                  suffixIcon: Icon(Icons.search_rounded, color: Colors.black, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Centered circular progress block matching Screen 5 (56% layout)
  Widget _buildCircularProgressBlock(AppProvider provider) {
    // Find ingesting document name
    final ingestingDoc = provider.documents.firstWhere(
      (d) => d.status == 'Ingesting' || d.status == 'Indexing',
      orElse: () => DocumentModel(id: '', name: 'indexing file', path: '', size: 0, dateAdded: DateTime.now(), pageCount: 0, status: '', tokenCount: 0),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          // Screen 5 Circular Progress Ring (56% look)
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: null, // Indeterminate pulsing local processing
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
              const Text(
                'AI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'indexing & embedding',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  ingestingDoc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(AppProvider provider, DocumentModel doc) {
    final isSelected = provider.selectedDocumentId == doc.id;
    final isPdf = doc.name.toLowerCase().endsWith('.pdf');
    final isIngesting = doc.status == 'Ingesting' || doc.status == 'processing';
    final isFailed = doc.status == 'Failed' || doc.status == 'failed';
    final progressValue = provider.ingestionProgressValue;
    final isErrorState = progressValue == -1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: doc.status == 'Ready'
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(document: doc),
                  ),
                );
              }
            : null,
        onLongPress: doc.status == 'Ready'
            ? () {
                if (isSelected) {
                  provider.setSelectedDocumentId(null);
                } else {
                  provider.setSelectedDocumentId(doc.id);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF9FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.black : AppTheme.border,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                      color: isSelected ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),

                  // File Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isFailed ? Colors.redAccent : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatFileSize(doc.size),
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            const Text('ΓÇó', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            const SizedBox(width: 6),
                            Text(
                              doc.status == 'Ready'
                                  ? '${doc.pageCount} pages'
                                  : doc.status.toLowerCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: isFailed ? Colors.redAccent : AppTheme.textSecondary,
                                fontWeight: doc.status != 'Ready' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      provider.deleteDocument(doc.id);
                    },
                  ),
                ],
              ),

              // Inline progress bar ΓÇö only shown while ingesting this doc
              if (isIngesting && provider.isIngesting) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isErrorState
                        ? 1.0
                        : (progressValue == 0.0 ? null : progressValue),
                    minHeight: 3,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isErrorState ? Colors.redAccent : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isErrorState
                      ? 'Failed ΓÇö tap to retry'
                      : provider.ingestionProgressText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isErrorState ? Colors.redAccent : AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeBanner(AppProvider provider) {
    final activeDocId = provider.selectedDocumentId;
    if (activeDocId == null) return const SizedBox.shrink();

    final selectedDoc = provider.documents.firstWhere((d) => d.id == activeDocId, 
      orElse: () => DocumentModel(id: '', name: 'Selected Note', path: '', size: 0, dateAdded: DateTime.now(), pageCount: 0, status: '', tokenCount: 0));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.center_focus_strong_rounded, size: 14, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Focus scope isolated to: "${selectedDoc.name}"',
              style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => provider.setSelectedDocumentId(null),
            child: const Icon(Icons.close_rounded, size: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'your library is empty',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add TXT notes or PDF textbooks. They will be parsed, split, and stored offline in your device vector index.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildStatsRow(AppProvider provider) {
    final totalWords = provider.documents.fold(0, (sum, doc) => sum + doc.tokenCount);
    final totalCards = provider.flashcards.length;
    final totalQuizzes = provider.timelineItems.where((item) => item.type == 'quiz_completed').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'words indexed',
              _formatNumber(totalWords),
              Icons.analytics_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              'study cards',
              totalCards.toString(),
              Icons.filter_none_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              'quizzes taken',
              totalQuizzes.toString(),
              Icons.checklist_rtl_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toLowerCase(),
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
