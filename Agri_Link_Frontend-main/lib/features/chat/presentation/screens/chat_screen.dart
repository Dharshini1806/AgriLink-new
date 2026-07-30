import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ChatScreen({super.key, required this.orderId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgC     = TextEditingController();
  final _scroll   = ScrollController();
  bool _isTyping  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(chatProvider(widget.orderId).notifier);
      notifier.init();
    });
  }

  @override
  void dispose() {
    _msgC.dispose(); _scroll.dispose();
    ref.read(chatProvider(widget.orderId).notifier).dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _onTyping(String v) {
    final notifier = ref.read(chatProvider(widget.orderId).notifier);
    if (v.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      notifier.emitTypingStart();
    } else if (v.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      notifier.emitTypingStop();
    }
  }

  void _send() {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    _msgC.clear();
    setState(() => _isTyping = false);
    ref.read(chatProvider(widget.orderId).notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final chatState  = ref.watch(chatProvider(widget.orderId));
    final currentUser = ref.watch(authStateProvider).value?.user;

    // Auto-scroll on new message
    ref.listen(chatProvider(widget.orderId), (_, next) {
      if (next.messages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          Text('Order #${widget.orderId.length >= 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: chatState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : chatState.messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No messages yet', style: GoogleFonts.poppins(color: AppColors.textHint)),
                  const SizedBox(height: 4),
                  Text('Start the conversation!', style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12)),
                ]))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: chatState.messages.length + (chatState.otherUserTyping ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == chatState.messages.length && chatState.otherUserTyping) {
                      return const _TypingIndicator();
                    }
                    final msg = chatState.messages[i];
                    final isMe = msg['sender_id'] == currentUser?.id;
                    return _MessageBubble(msg: msg, isMe: isMe);
                  },
                ),
        ),

        // Typing indicator text
        if (chatState.otherUserTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Other person is typing…',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ),

        // Input row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgC,
                  onChanged: _onTyping,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
                    filled: true, fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final sentAt = DateTime.tryParse(msg['sent_at'] as String? ?? '');
    final timeStr = sentAt != null ? DateFormat('h:mm a').format(sentAt.toLocal()) : '';
    final isRead  = msg['is_read'] as bool? ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                (msg['sender_name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.sentBubble : AppColors.receivedBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(msg['content'] as String,
                  style: GoogleFonts.poppins(
                    color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14)),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(timeStr, style: GoogleFonts.poppins(
                    fontSize: 10, color: isMe ? Colors.white70 : AppColors.textHint)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 13, color: isRead ? Colors.lightBlueAccent : Colors.white70,
                    ),
                  ],
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 34, bottom: 6),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          _dot(0), _dot(200), _dot(400),
        ]),
      ),
    ]),
  );

  Widget _dot(int delay) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    builder: (_, v, __) => Container(
      width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.textHint.withOpacity(0.5 + v * 0.5),
        shape: BoxShape.circle,
      ),
    ),
  );
}
