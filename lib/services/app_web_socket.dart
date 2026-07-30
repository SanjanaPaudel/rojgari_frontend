import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Thin wrapper around [WebSocketChannel] for this app's JSON-message
/// sockets. Connection mechanics only — callers interpret the decoded
/// messages according to whichever endpoint they connected to (see
/// ApiUrls.workerOffersSocket / ApiUrls.bookingSocket for the two
/// documented message shapes).
class AppWebSocket {
  AppWebSocket(this._url);

  final String _url;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;

  /// Connects and returns a stream of decoded JSON messages. A single
  /// malformed message is dropped (not fatal) — the stream keeps going
  /// and waits for the next one.
  Stream<Map<String, dynamic>> connect() {
    final channel = WebSocketChannel.connect(Uri.parse(_url));
    _channel = channel;
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controller = controller;

    channel.stream.listen(
          (raw) {
        try {
          final decoded = jsonDecode(raw as String);
          if (decoded is Map<String, dynamic>) {
            controller.add(decoded);
          }
        } catch (_) {
          // Malformed message — ignore, wait for the next tick.
        }
      },
      onDone: () => controller.close(),
      onError: (_) => controller.close(),
      cancelOnError: true,
    );

    return controller.stream;
  }

  /// The close code once the connection has ended (e.g. 4001 = bad/expired
  /// token, 4003 = not authorized for this booking) — see the backend's
  /// WebSocket guide §2. Only meaningful after the stream closes.
  int? get closeCode => _channel?.closeCode;

  void disconnect() {
    _channel?.sink.close();
    _controller?.close();
  }
}