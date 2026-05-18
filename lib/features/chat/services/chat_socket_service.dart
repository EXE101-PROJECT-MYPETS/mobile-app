import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

import '../models/message_model.dart';

class ChatSocketService {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String _incomingBuffer = '';
  bool _stompConnected = false;
  bool _manuallyDisconnected = false;
  int _reconnectAttempts = 0;
  int _subscriptionCounter = 0;
  String? _conversationSubscriptionId;
  String? _shopSubscriptionId;
  String? _activeConversationId;
  String? _activeShopId;
  void Function(MessageModel message)? _onMessage;

  Future<void> listenToConversation(
    String conversationId,
    void Function(MessageModel message) onMessage, {
    String? shopId,
  }) async {
    _activeConversationId = conversationId;
    _activeShopId = shopId;
    _onMessage = onMessage;
    _manuallyDisconnected = false;

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
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
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
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      final socket = await WebSocket.connect(ApiConfig.chatWebSocketUrl);
      _socket = socket;
      _subscription = socket.listen(
        _handleData,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: true,
      );

      _sendFrame('CONNECT', {
        'accept-version': '1.2',
        'heart-beat': '0,0',
        'host': Uri.parse(ApiConfig.baseUrl).host,
      });
    } catch (e) {
      debugPrint('Error connecting chat websocket: $e');
      _clearSocketState();
      _scheduleReconnect();
    }
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
    final lines = frame.split('\n').map((line) {
      return line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
    }).toList();
    if (lines.isEmpty) {
      return;
    }

    final command = lines.first.trim();
    if (command.isEmpty) {
      return;
    }

    final blankLineIndex = lines.indexWhere((line) => line.trim().isEmpty);
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
        _stompConnected = true;
        _reconnectAttempts = 0;
        _subscribeToActiveConversation();
        _subscribeToActiveShop();
        break;
      case 'MESSAGE':
        _handleMessage(headers, body);
        break;
      case 'ERROR':
        debugPrint('Chat websocket error frame: $body');
        break;
    }
  }

  void _handleMessage(Map<String, String> headers, String body) {
    final destination = headers['destination'] ?? '';
    final activeConversationId = _activeConversationId;
    final expectedConvDestination =
        '/topic/conversations/$activeConversationId/messages';
    final expectedShopDestination = _activeShopId != null
        ? '/topic/shops/$_activeShopId/messages'
        : '';

    if (destination.isNotEmpty &&
        destination != expectedConvDestination &&
        (expectedShopDestination.isEmpty ||
            destination != expectedShopDestination)) {
      return;
    }

    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = MessageModel.fromJson(decoded);
        if (activeConversationId == null ||
            activeConversationId.isEmpty ||
            message.conversationId == activeConversationId ||
            message.shopId == _activeShopId) {
          _onMessage?.call(message);
        }
      }
    } catch (e) {
      debugPrint('Failed to decode chat websocket message: $e');
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
    _sendFrame('SUBSCRIBE', {
      'id': _conversationSubscriptionId!,
      'destination': '/topic/conversations/$conversationId/messages',
    });
  }

  void _subscribeToActiveShop() {
    final shopId = _activeShopId;
    if (!_stompConnected || _socket == null || shopId == null) {
      return;
    }

    if (_shopSubscriptionId != null) {
      _sendFrame('UNSUBSCRIBE', {'id': _shopSubscriptionId!});
    }

    _shopSubscriptionId = 'sub-shop-${++_subscriptionCounter}';
    _sendFrame('SUBSCRIBE', {
      'id': _shopSubscriptionId!,
      'destination': '/topic/shops/$shopId/messages',
    });
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

  void _handleDone() {
    _clearSocketState();
    _scheduleReconnect();
  }

  void _handleError(Object error) {
    debugPrint('Chat websocket closed with error: $error');
    _clearSocketState();
    _scheduleReconnect();
  }

  void _clearSocketState() {
    _stompConnected = false;
    _conversationSubscriptionId = null;
    _shopSubscriptionId = null;
    _socket = null;
    _subscription = null;
  }

  void _scheduleReconnect() {
    if (_manuallyDisconnected ||
        _activeConversationId == null ||
        _onMessage == null ||
        _reconnectTimer != null) {
      return;
    }

    final delaySeconds = _reconnectAttempts < 5 ? 1 << _reconnectAttempts : 30;
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      if (!_manuallyDisconnected && _activeConversationId != null) {
        _connect();
      }
    });
  }
}
