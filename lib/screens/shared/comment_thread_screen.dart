import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../constants/app_constants.dart';

class CommentThreadScreen extends StatefulWidget {
  final String projectId;
  final int phaseNo;
  final String phaseTitle;

  const CommentThreadScreen({
    super.key,
    required this.projectId,
    required this.phaseNo,
    required this.phaseTitle,
  });

  @override
  State<CommentThreadScreen> createState() => _CommentThreadScreenState();
}

class _CommentThreadScreenState extends State<CommentThreadScreen> {
  final CommentRepository _commentRepo = CommentRepository();
  final AuditTrailRepository _auditRepo = AuditTrailRepository();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    setState(() => _sending = true);
    await _commentRepo.addComment(
      projectId: widget.projectId,
      phaseNo: widget.phaseNo,
      senderId: user.id,
      senderName: user.name,
      senderRole: user.role,
      message: text,
    );
    await _auditRepo.addAuditEntry(
      projectId: widget.projectId,
      phaseNo: widget.phaseNo,
      action: 'comment_added',
      performedBy: user.id,
      role: user.role,
      message: '${user.name} added a comment',
    );
    _msgCtrl.clear();
    setState(() => _sending = false);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase ${widget.phaseNo}: ${widget.phaseTitle}',
                style: const TextStyle(fontSize: 14)),
            const Text('Comments', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _commentRepo.getComments(widget.projectId, widget.phaseNo),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No comments yet',
                    subtitle: 'Start the conversation below',
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, i) => CommentBubble(
                    comment: comments[i],
                    isMe: comments[i].senderId == me.id,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a comment...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _sending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
