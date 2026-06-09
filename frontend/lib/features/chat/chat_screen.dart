import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/llm_service.dart';
import '../../models/message_model.dart';
import '../../models/citation_model.dart';
import '../../models/document_model.dart';
import '../../core/theme.dart';
import '../study/quiz_generator_screen.dart';
import '../study/flashcards_screen.dart';
import '../../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Flush the Llama 3.2 engine from RAM when the user exits the chat screen
    LlmService.instance.disposeEngine();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitMessage(AppProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (provider.documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a document to your library first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.clear();
    provider.sendMessage(text);
    _scrollToBottom();
  }

  void _useSuggestion(AppProvider provider, String text) {
    provider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    if (provider.messages.isNotEmpty && provider.messages.last.isStreaming) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SMRITI ASSISTANT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.black),
            onPressed: () {
              provider.clearChatHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.documents.isNotEmpty)
            _buildDocumentFilterRow(provider),

          if (provider.selectedDocumentId != null) ...[
            _buildScopeBadge(provider),
            _buildQuickActionChips(provider),
          ],

          Expanded(
            child: provider.messages.isEmpty
                ? _buildEmptyState(provider)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.messages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = provider.messages[idx];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          if (provider.messages.isEmpty && provider.documents.isNotEmpty)
            _buildSuggestionsList(provider),

          if (provider.queryHistory.isNotEmpty)
            _buildQueryHistoryRow(provider),

          _buildInputBar(provider),
        ],
      ),
    );
  }

  Widget _buildDocumentFilterRow(AppProvider provider) {
    final docs = provider.documents.where((d) => d.status == 'Ready').toList();
    if (docs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length + 1, // +1 for "All Documents"
        itemBuilder: (ctx, idx) {
          if (idx == 0) {
            final isSelected = provider.filterDocumentId == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  'all documents',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                onSelected: (_) => provider.setFilterDocument(null),
              ),
            );
          }

          final doc = docs[idx - 1];
          final isSelected = provider.filterDocumentId == doc.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                doc.name.length > 20 ? '${doc.name.substring(0, 20)}...' : doc.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              avatar: isSelected
                  ? null
                  : const Icon(Icons.description_outlined, size: 12, color: Colors.black),
              onSelected: (_) => provider.setFilterDocument(isSelected ? null : doc.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionChips(AppProvider provider) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildActionChip(
            label: 'Summarize',
            icon: Icons.summarize_outlined,
            onPressed: () {
              provider.sendMessage("Please provide a concise summary of the key points in this document.");
              _scrollToBottom();
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            label: 'Simplify',
            icon: Icons.lightbulb_outline_rounded,
            onPressed: () {
              provider.sendMessage("Can you simplify the complex concepts in this document and explain them like I'm five?");
              _scrollToBottom();
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            label: 'Quiz',
            icon: Icons.checklist_rtl_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuizGeneratorScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            label: 'Flashcards',
            icon: Icons.filter_none_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({required String label, required IconData icon, required VoidCallback onPressed}) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      avatar: Icon(icon, size: 12, color: Colors.black),
      label: Text(
        label.toLowerCase(),
        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildScopeBadge(AppProvider provider) {
    final activeDocId = provider.selectedDocumentId;
    final doc = provider.documents.firstWhere((d) => d.id == activeDocId, 
      orElse: () => DocumentModel(id: '', name: 'Selected File', path: '', size: 0, dateAdded: DateTime.now(), pageCount: 0, status: '', tokenCount: 0));
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_list_rounded, size: 14, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chat isolated to: "${doc.name}"',
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

  Widget _buildEmptyState(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F4F6),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'conversations are private',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.documents.isEmpty
                  ? 'Ingest lecture documents or notes in the Library screen to enable offline AI assistant queries.'
                  : 'Ask anything about your notes. All answers are synthesized using local database retrieval.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildSuggestionsList(AppProvider provider) {
    final docNames = provider.documents.map((d) => d.name).take(2).toList();
    final List<String> suggestions = [
      if (docNames.isNotEmpty) "summarize the note ${docNames.first}",
      if (docNames.isNotEmpty) "key takeaways in ${docNames.first}",
      "explain offline rag",
      "smriti features list"
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (ctx, idx) {
          final suggestion = suggestions[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              label: Text(
                suggestion,
                style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _useSuggestion(provider, suggestion),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final isUser = msg.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.black : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.border, width: 1.2),
              ),
              child: msg.isStreaming && msg.text == 'Thinking...'
                  ? _buildThinkingIndicator()
                  : Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUser ? Colors.white : Colors.black,
                        height: 1.45,
                      ),
                    ),
            ),
            if (!isUser && msg.citations.isNotEmpty && !msg.isStreaming) ...[
              const SizedBox(height: 8),
              _buildCitationsList(msg.citations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return const SizedBox(
      width: 36,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(radius: 3, backgroundColor: Colors.black),
          CircleAvatar(radius: 3, backgroundColor: Colors.black),
          CircleAvatar(radius: 3, backgroundColor: Colors.black),
        ],
      ),
    );
  }

  Widget _buildCitationsList(List<CitationModel> citations) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: citations.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final citation = entry.value;

          return InkWell(
            onTap: () => _showCitationDetail(context, citation),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                '📄 ${citation.documentName}, page ${citation.pageNumber}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCitationDetail(BuildContext context, CitationModel citation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.black, width: 1.5),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_added_rounded, color: Colors.black),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    citation.documentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Page ${citation.pageNumber}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              ],
            ),
            const Divider(color: AppTheme.border, height: 25),
            const Text(
              'RETRIEVED SOURCE EXTRACT:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                citation.textSnippet,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.black,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryHistoryRow(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 6, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'recent',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.queryHistory.length,
              itemBuilder: (ctx, idx) {
                final query = provider.queryHistory[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      _controller.text = query;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: query.length),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        query.length > 30 ? '${query.substring(0, 30)}...' : query,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AppProvider provider) {
    final canSend = !(provider.messages.isNotEmpty && provider.messages.last.isStreaming);

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitMessage(provider),
              decoration: InputDecoration(
                hintText: provider.documents.isEmpty
                    ? 'Upload notes to chat...'
                    : 'Ask anything about your notes...',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: canSend ? Colors.black : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              onPressed: canSend ? () => _submitMessage(provider) : null,
            ),
          ),
        ],
      ),
    );
  }
}
