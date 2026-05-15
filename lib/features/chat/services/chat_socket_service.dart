import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

import '../models/message_model.dart';

class ChatSocketService {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  String _incomingBuffer = '';
  bool _stompConnected = false;
  int _subscriptionCounter = 0;
  String? _conversationSubscriptionId;
  String? _shopSubscriptionId;
  String? _activeConversationId;
  String? _activeShopId;
  void Function(MessageModel message)? _onMessage;

  /// Whether we should try to reconnect when the socket is closed.
  bool _shouldReconnect = false;

  /// Delay between reconnect attempts.
  static const Duration _reconnectDelay = Duration(seconds: 3);

  /// Maximum consecutive reconnect attempts before giving up temporarily.
  static const int _maxReconnectAttempts = 10;
  int _reconnectAttempts = 0;

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  /// Heartbeat interval to keep ngrok WebSocket alive.
  static const Duration _heartbeatInterval = Duration(seconds: 15);

  Future<void> listenToConversation(
    String conversationId,
    void Function(MessageModel message) onMessage, {
    String? shopId,
  }) async {
    _activeConversationId = conversationId;
    _activeShopId = shopId;
    _onMessage = onMessage;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    debugPrint('[ChatSocket] listenToConversation: convId=$conversationId, shopId=$shopId');

    if (_socket == null) {
      await _connect();
      return;
    }

    if (_stompConnected) {
      _subscribeToActiveConversation();
      _subscribeToActiveShop();
    }
  }

  Future<void> disconnect() async {
    debugPrint('[ChatSocket] disconnect() called');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectAttempts = 0;
    _stompConnected = false;
    _conversationSubscriptionId = null;
    _shopSubscriptionId = null;
    _activeConversationId = null;
    _activeShopId = null;
    _incomingBuffer = '';
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
  }

  Future<void> _connect() async {
    // Clean up any existing connection first
    await _subscription?.cancel();
    _subscription = null;
    _socket = null;
    _stompConnected = false;
    _incomingBuffer = '';

    final wsUrl = ApiConfig.chatWebSocketUrl;
    debugPrint('[ChatSocket] Connecting to $wsUrl ...');

    try {
      final socket = await WebSocket.connect(
        wsUrl,
        headers: const {'ngrok-skip-browser-warning': 'true'},
      );
      _socket = socket;
      _reconnectAttempts = 0; // Reset on successful connection
      debugPrint('[ChatSocket] WebSocket connected successfully');

      _subscription = socket.listen(
        _handleData,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: true,
      );

      _sendFrame(
        'CONNECT',
        const {
          'accept-version': '1.2',
          'heart-beat': '15000,15000',
        },
      );
    } catch (e) {
      debugPrint('[ChatSocket] Error connecting websocket: $e');
      _socket = null;
      _subscription = null;
      _stompConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) {
      debugPrint('[ChatSocket] Reconnect disabled, not reconnecting');
      return;
    }

    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      debugPrint('[ChatSocket] Max reconnect attempts reached ($_maxReconnectAttempts), stopping');
      return;
    }

    debugPrint('[ChatSocket] Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${_reconnectDelay.inSeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_shouldReconnect) {
        _connect();
      }
    });
  }

  void _handleData(dynamic data) {
    _incomingBuffer += data is List<int> ? utf8.decode(data) : data.toString();

    while (true) {
      final terminatorIndex = _incomingBuffer.indexOf('\u0000');
      if (terminatorIndex == -1) {
        break;
      }

      final frame = _incomingBuffer.substring(0, terminatorIndex);
      _incomingBuffer = _incomingBuffer.substring(terminatorIndex + 1);

      if (frame.trim().isEmpty) {
        continue;
      }

      _processFrame(frame);
    }
  }

  void _processFrame(String frame) {
    final normalizedFrame = frame.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalizedFrame.split('\n');
    if (lines.isEmpty) {
      return;
    }

    final command = lines.first.trim();
    if (command.isEmpty) {
      return;
    }

    final blankLineIndex = lines.indexWhere((line) => line.isEmpty);
    final headerEndIndex = blankLineIndex == -1 ? lines.length : blankLineIndex;
    final headers = <String, String>{};

    for (var index = 1; index < headerEndIndex; index++) {
      final headerLine = lines[index];
      final separatorIndex = headerLine.indexOf(':');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = headerLine.substring(0, separatorIndex).trim();
      final value = headerLine.substring(separatorIndex + 1).trim();
      headers[key] = value;
    }

    final body = blankLineIndex == -1
        ? ''
        : lines.sublist(blankLineIndex + 1).join('\n');

    switch (command) {
      case 'CONNECTED':
        debugPrint('[ChatSocket] STOMP CONNECTED');
        _stompConnected = true;
        _startHeartbeat();
        _subscribeToActiveConversation();
        _subscribeToActiveShop();
        break;
      case 'MESSAGE':
        _handleMessage(headers, body);
        break;
      case 'ERROR':
        debugPrint('[ChatSocket] STOMP ERROR frame: $body');
        break;
      default:
        debugPrint('[ChatSocket] Unknown STOMP command: $command');
    }
  }

  void _handleMessage(Map<String, String> headers, String body) {
    final destination = headers['destination'] ?? '';
    debugPrint('[ChatSocket] MESSAGE received on destination: $destination');

    final activeConversationId = _activeConversationId;
    final activeShopId = _activeShopId;

    // Check if this message is for our conversation or shop topic
    final expectedConvDestination = activeConversationId != null
        ? '/topic/conversations/$activeConversationId/messages'
        : '';
    final expectedShopDestination = activeShopId != null
        ? '/topic/shops/$activeShopId/messages'
        : '';

    final matchesConv = expectedConvDestination.isNotEmpty && destination == expectedConvDestination;
    final matchesShop = expectedShopDestination.isNotEmpty && destination == expectedShopDestination;

    if (!matchesConv && !matchesShop) {
      debugPrint('[ChatSocket] Ignoring message for destination: $destination');
      debugPrint('[ChatSocket]   expected conv: $expectedConvDestination');
      debugPrint('[ChatSocket]   expected shop: $expectedShopDestination');
      return;
    }

    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = MessageModel.fromJson(decoded);
        debugPrint('[ChatSocket] Delivering message id=${message.id} to handler');
        _onMessage?.call(message);
      }
    } catch (e) {
      debugPrint('[ChatSocket] Failed to decode message: $e');
    }
  }

  void _subscribeToActiveConversation() {
    final conversationId = _activeConversationId;
    if (!_stompConnected || _socket == null || conversationId == null) {
      return;
    }

    if (_conversationSubscriptionId != null) {
      _sendFrame('UNSUBSCRIBE', {'id': _conversationSubscriptionId!});
    }

    _conversationSubscriptionId = 'sub-${++_subscriptionCounter}';
    final destination = '/topic/conversations/$conversationId/messages';
    debugPrint('[ChatSocket] SUBSCRIBE to $destination (id=${_conversationSubscriptionId})');
    _sendFrame(
      'SUBSCRIBE',
      {
        'id': _conversationSubscriptionId!,
        'destination': destination,
        'ack': 'auto',
      },
    );
  }

  void _subscribeToActiveShop() {
    final shopId = _activeShopId;
    if (!_stompConnected || _socket == null || shopId == null) {
      debugPrint('[ChatSocket] Cannot subscribe to shop topic: stompConnected=$_stompConnected, socket=${_socket != null}, shopId=$shopId');
      return;
    }

    if (_shopSubscriptionId != null) {
      _sendFrame('UNSUBSCRIBE', {'id': _shopSubscriptionId!});
    }

    _shopSubscriptionId = 'sub-shop-${++_subscriptionCounter}';
    final destination = '/topic/shops/$shopId/messages';
    debugPrint('[ChatSocket] SUBSCRIBE to $destination (id=${_shopSubscriptionId})');
    _sendFrame(
      'SUBSCRIBE',
      {
        'id': _shopSubscriptionId!,
        'destination': destination,
        'ack': 'auto',
      },
    );
  }

  void _sendFrame(
    String command,
    Map<String, String> headers, [
    String body = '',
  ]) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    final buffer = StringBuffer(command);
    headers.forEach((key, value) {
      buffer.write('\n$key:$value');
    });
    buffer.write('\n\n');
    buffer.write(body);
    buffer.write('\u0000');
    socket.add(buffer.toString());
  }

  /// Sends a STOMP heartbeat (newline) periodically to keep ngrok alive.
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      final socket = _socket;
      if (socket != null && _stompConnected) {
        socket.add('\n');
      }
    });
    debugPrint('[ChatSocket] Heartbeat started (every ${_heartbeatInterval.inSeconds}s)');
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _handleDone() {
    debugPrint('[ChatSocket] WebSocket closed (onDone)');
    _stopHeartbeat();
    _stompConnected = false;
    _conversationSubscriptionId = null;
    _shopSubscriptionId = null;
    _socket = null;
    _subscription = null;
    _scheduleReconnect();
  }

  void _handleError(Object error) {
    debugPrint('[ChatSocket] WebSocket error: $error');
    _stopHeartbeat();
    _stompConnected = false;
    _conversationSubscriptionId = null;
    _shopSubscriptionId = null;
    _socket = null;
    _subscription = null;
    _scheduleReconnect();
  }
}
