import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/utils/storage_helper.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

// ── Chat State ────────────────────────────────────────────
class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final bool otherUserTyping;
  final bool isConnected;
  final bool otherUserOnline;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.otherUserTyping = false,
    this.isConnected = false,
    this.otherUserOnline = true,
    this.error,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    bool? otherUserTyping,
    bool? isConnected,
    bool? otherUserOnline,
    String? error,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    otherUserTyping: otherUserTyping ?? this.otherUserTyping,
    isConnected: isConnected ?? this.isConnected,
    otherUserOnline: otherUserOnline ?? this.otherUserOnline,
    error: error ?? this.error,
  );
}

// ── Notifier ──────────────────────────────────────────────
class ChatNotifier extends StateNotifier<ChatState> {
  final String _orderId;
  final _dio;
  IO.Socket? _socket;

  ChatNotifier(this._orderId, this._dio) : super(const ChatState());

  Future<void> init() async {
    state = state.copyWith(isLoading: true);

    // 1. Load history via REST
    try {
      final res = await _dio.get(ApiEndpoints.chatHistory(_orderId));
      final msgs = List<Map<String, dynamic>>.from(
        (res.data['data'] as List?) ?? [],
      );
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    // 2. Connect socket
    await _connectSocket();
  }

  Future<void> _connectSocket() async {
    final token = await StorageHelper.read(key: 'access_token');
    if (token == null) return;

    _socket = IO.io(
      ApiEndpoints.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('join_order_room', _orderId);
      _socket!.emit('mark_read', {'orderId': _orderId});
      state = state.copyWith(isConnected: true);
    });

    _socket!.on('new_message', (data) {
      final msg = Map<String, dynamic>.from(data as Map);
      state = state.copyWith(messages: [...state.messages, msg]);
    });

    _socket!.on('user_typing', (data) {
      final isTyping = (data as Map)['isTyping'] as bool? ?? true;
      state = state.copyWith(otherUserTyping: isTyping);
    });

    _socket!.on('messages_read', (_) {
      // Mark all as read locally
      final updated = state.messages.map((m) => {...m, 'is_read': true}).toList();
      state = state.copyWith(messages: updated);
    });

    // ── Previously missing event listeners ────────────────

    // Confirms successful room join
    _socket!.on('joined', (data) {
      state = state.copyWith(isConnected: true);
    });

    // Notifies when the other user disconnects
    _socket!.on('user_offline', (data) {
      state = state.copyWith(otherUserOnline: false, otherUserTyping: false);
    });

    // Handles server-side socket errors
    _socket!.on('error', (data) {
      final errorMsg = data is Map ? data['message']?.toString() : data.toString();
      state = state.copyWith(error: errorMsg ?? 'Socket error occurred');
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnected: false, otherUserTyping: false);
    });

    _socket!.connect();
  }

  void sendMessage(String content) {
    _socket?.emit('send_message', {'orderId': _orderId, 'content': content});
  }

  void emitTypingStart() => _socket?.emit('typing_start', {'orderId': _orderId});
  void emitTypingStop()  => _socket?.emit('typing_stop',  {'orderId': _orderId});

  @override
  void dispose() {
    _socket?.emit('leave_order_room', _orderId);
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, orderId) => ChatNotifier(orderId, ref.watch(dioProvider)),
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res  = await dio.get(ApiEndpoints.unreadCount);
    return (res.data['unread'] as int?) ?? 0;
  } catch (_) {
    return 0;
  }
});

