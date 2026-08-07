import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/api_urls.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat/chat_message.dart';
import '../../services/api_service.dart';
import '../../services/app_web_socket.dart';
import '../../services/chat/booking_chat_service.dart';
import '../../services/storage_service.dart';

/// Customer <-> worker chat for one booking.
///
/// Reusable from both sides: the customer opens it from the tracking screen
/// and the worker from their active-job screen — they just pass the other
/// party's name/avatar. History loads once over REST; everything after that
/// (including this device's own sent messages, which the server echoes back)
/// arrives live on the booking WebSocket, the same connection the tracking
/// screens use for status/location. Chat frames are told apart from
/// booking-status frames by an `"event": "chat_message"` key.
class BookingChatScreen extends StatefulWidget {
  const BookingChatScreen({
    required this.bookingId,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.avatarAsset,
    this.chatService,
    super.key,
  });

  /// The Booking id — same value used for `ws/bookings/<id>/` and the
  /// `.../bookings/<id>/messages/` history endpoint.
  final String bookingId;

  /// The other party's display name, shown in the header.
  final String title;

  /// Optional secondary header line (e.g. the service/category name).
  final String? subtitle;

  /// Other party's avatar. A network URL is preferred; the asset is a
  /// fallback; if neither is usable an initial-letter placeholder shows.
  final String? avatarUrl;
  final String? avatarAsset;

  /// Injectable for tests; defaults to the real REST-backed service.
  final BookingChatService? chatService;

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  late final BookingChatService _service;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  AppWebSocket? _socket;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  int? _currentUserId;
  bool _loading = true;
  String? _loadError;
  bool _connected = false;

  /// Monotonic counter backing the local id of each optimistic message, so a
  /// sent message can be matched to its server echo for reconciliation.
  int _localSeq = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.chatService ?? BookingChatService();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _disconnectSocket();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _currentUserId = await StorageService.getCurrentUserId();
    await _loadHistory();
    if (!mounted) return;
    await _startSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _service.fetchHistory(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loading = false;
        _loadError = null;
      });
      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e is ChatException
            ? e.message
            : 'Unable to load messages. Please try again.';
      });
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _loadHistory();
    if (!mounted) return;
    if (_socket == null) await _startSocket();
  }

  Future<void> _startSocket() async {
    final token = await StorageService.getAccessToken();
    if (token == null || !mounted) return;

    final socket = AppWebSocket(
      ApiUrls.bookingSocket(widget.bookingId, token),
    );
    _socket = socket;
    _socketSubscription = socket.connect().listen(
      _handleSocketMessage,
      onDone: () => _handleSocketClosed(socket),
    );
    if (mounted) setState(() => _connected = true);
  }

  /// Reconnect-with-recovery, mirroring the tracking screen: give up on a
  /// "not authorized for this booking" (4003), refresh the session first on an
  /// expired token (4001), otherwise just reconnect.
  Future<void> _handleSocketClosed(AppWebSocket closedSocket) async {
    if (_socket != closedSocket) return; // already superseded — ignore
    _socket = null;
    _socketSubscription = null;
    if (mounted) setState(() => _connected = false);
    if (!mounted) return;

    if (closedSocket.closeCode == 4003) return;

    if (closedSocket.closeCode == 4001) {
      final refreshed = await ApiService().checkAndRefreshSession();
      if (!refreshed || !mounted) return;
    }

    await _startSocket();
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    // Booking status/location updates ride this same socket — ignore anything
    // that isn't a chat message here.
    if (!ChatMessage.isChatEvent(message)) return;
    _appendOrReconcile(ChatMessage.fromWebSocket(message));
  }

  /// Adds an incoming message, reconciling it with a pending optimistic copy
  /// if this is the echo of something we just sent, and de-duplicating by
  /// server id so a message never appears twice.
  void _appendOrReconcile(ChatMessage incoming) {
    final isOwnEcho =
        _currentUserId == null || incoming.senderId == _currentUserId;
    if (isOwnEcho) {
      final pendingIndex = _messages.indexWhere(
        (m) => m.pending && m.content == incoming.content,
      );
      if (pendingIndex != -1) {
        setState(() => _messages[pendingIndex] = incoming);
        return;
      }
    }

    if (incoming.id != null &&
        _messages.any((m) => m.id != null && m.id == incoming.id)) {
      return; // Already have it (e.g. arrived in history, or duplicate push).
    }

    setState(() => _messages.add(incoming));
    _scrollToBottomSoon();
  }

  void _handleSend() {
    final content = _input.text.trim();
    if (content.isEmpty) return;

    final socket = _socket;
    if (socket == null) {
      // Not connected — don't drop the text silently.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconnecting… please try again.')),
      );
      unawaited(_startSocket());
      return;
    }

    final optimistic = ChatMessage.pendingOutgoing(
      localId: 'local_${_localSeq++}',
      senderId: _currentUserId ?? -1,
      content: content,
    );

    setState(() {
      _messages.add(optimistic);
      _input.clear();
    });
    _scrollToBottomSoon();

    // Exact frame shape the backend expects; it persists the message and
    // broadcasts it back to the whole booking group (including us), which is
    // what reconciles the pending copy above.
    socket.send({'type': 'chat.message', 'content': content});
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _disconnectSocket() {
    _socketSubscription?.cancel();
    _socket?.disconnect();
    _socket = null;
    _socketSubscription = null;
  }

  bool _isMine(ChatMessage message) =>
      message.pending || message.senderId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9FF),
        appBar: _buildAppBar(),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (!_connected && !_loading) const _ReconnectingBanner(),
              Expanded(child: _buildBody()),
              _ChatComposer(
                controller: _input,
                onSend: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      foregroundColor: AppColors.black,
      titleSpacing: 0,
      title: Row(
        children: [
          _ChatAvatar(
            name: widget.title,
            imageUrl: widget.avatarUrl,
            imageAsset: widget.avatarAsset,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _connected
                      ? (widget.subtitle ?? 'Connected')
                      : 'Reconnecting…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _connected ? AppColors.grey : AppColors.orange,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null && _messages.isEmpty) {
      return _ChatErrorView(message: _loadError!, onRetry: _retryLoad);
    }
    if (_messages.isEmpty) {
      return const _EmptyConversation();
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageBubble(
          message: message,
          isMine: _isMine(message),
        );
      },
    );
  }
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.orange.withValues(alpha: .12),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.orange,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Reconnecting…',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine
                  ? null
                  : Border.all(color: const Color(0xFFE8E3F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.black,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatClock(message.createdAt),
                      style: TextStyle(
                        color: isMine
                            ? Colors.white.withValues(alpha: .78)
                            : AppColors.grey,
                        fontSize: 9.5,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.pending
                            ? Icons.schedule_rounded
                            : Icons.done_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: .78),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E3F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: AppColors.black),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF3F0FB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.name,
    this.imageUrl,
    this.imageAsset,
  });

  final String name;
  final String? imageUrl;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final asset = imageAsset?.trim();
    Widget placeholder() {
      final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
      return Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );
    }

    Widget child = placeholder();
    if (url != null && url.isNotEmpty) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    } else if (asset != null && asset.isNotEmpty) {
      child = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }

    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.lightPurple,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 46,
            color: AppColors.primary.withValues(alpha: .5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Say hello to get the conversation started.',
            style: TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChatErrorView extends StatelessWidget {
  const _ChatErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
