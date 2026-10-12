/// Real-time Socket.io service for GVibe DMs and community chat.
library;

// Singleton Socket.io client.
//
// Responsibilities:
//  - Connect/disconnect with JWT authentication
//  - Expose typed stream controllers for DM and community events
//  - Handle typing indicators, read receipts, and presence
//  - Auto-reconnect on mobile network switches (handled by socket.io client)
//
// Usage:
//   SocketService.instance.connect(token);
//   SocketService.instance.dmStream.listen(...)
//   SocketService.instance.sendDM(...)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

// ── Event data models ────────────────────────────────────────────────────────

class DmMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  const DmMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory DmMessage.fromMap(Map<String, dynamic> m) {
    final sender = m['sender'] is Map ? m['sender'] as Map : {};
    return DmMessage(
      id:           m['_id']?.toString() ?? '',
      senderId:     sender['_id']?.toString() ?? m['senderId']?.toString() ?? (m['sender'] is String ? m['sender'].toString() : ''),
      senderName:   sender['name']?.toString() ?? '',
      senderAvatar: sender['avatar']?.toString(),
      receiverId:   m['receiverId']?.toString() ?? (m['receiver'] is Map ? m['receiver']['_id']?.toString() : m['receiver']?.toString()) ?? '',
      content:      m['content']?.toString() ?? '',
      createdAt:    DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CommunityMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String communityId;
  final String content;
  final DateTime createdAt;

  const CommunityMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.communityId,
    required this.content,
    required this.createdAt,
  });

  factory CommunityMessage.fromMap(Map<String, dynamic> m) {
    final sender = m['sender'] as Map<String, dynamic>? ?? {};
    return CommunityMessage(
      id:           m['_id']?.toString() ?? '',
      senderId:     sender['_id']?.toString() ?? '',
      senderName:   sender['name']?.toString() ?? '',
      senderAvatar: sender['avatar']?.toString(),
      communityId:  m['communityId']?.toString() ?? '',
      content:      m['content']?.toString() ?? '',
      createdAt:    DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TypingEvent {
  final String senderId;
  final String? senderName;
  final bool isTyping;
  const TypingEvent({required this.senderId, this.senderName, required this.isTyping});
}

// ── Service ──────────────────────────────────────────────────────────────────

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  // Stream controllers — broadcast so multiple listeners can attach
  final _dmController        = StreamController<DmMessage>.broadcast();
  final _communityController = StreamController<CommunityMessage>.broadcast();
  final _dmTypingController  = StreamController<TypingEvent>.broadcast();
  final _comTypingController = StreamController<TypingEvent>.broadcast();
  final _readAckController   = StreamController<String>.broadcast();
  final _onlineController    = StreamController<String>.broadcast();
  final _offlineController   = StreamController<String>.broadcast();

  // Deduplication set to ensure a message is never emitted twice to dmStream
  final _recentDmIds = <String>{};

  void _emitDm(DmMessage msg) {
    if (msg.id.isNotEmpty) {
      if (_recentDmIds.contains(msg.id)) return;
      _recentDmIds.add(msg.id);
      if (_recentDmIds.length > 200) {
        _recentDmIds.remove(_recentDmIds.first);
      }
    }
    _dmController.add(msg);
  }

  Stream<DmMessage>        get dmStream          => _dmController.stream;
  Stream<CommunityMessage> get communityStream   => _communityController.stream;
  Stream<TypingEvent>      get dmTypingStream    => _dmTypingController.stream;
  Stream<TypingEvent>      get comTypingStream   => _comTypingController.stream;
  Stream<String>           get readAckStream     => _readAckController.stream;
  Stream<String>           get onlineStream      => _onlineController.stream;
  Stream<String>           get offlineStream     => _offlineController.stream;

  String? _currentToken;

  // ── Connect ───────────────────────────────────────────────────────────────

  void connect(String jwtToken) {
    if (_socket != null && _socket!.connected && _currentToken == jwtToken) return;

    if (_socket != null) {
      disconnect();
    }

    _currentToken = jwtToken;

    final socketUrl = (dotenv.env['SOCKET_URL'] != null && !dotenv.env['SOCKET_URL']!.contains('onrender.com'))
        ? dotenv.env['SOCKET_URL']!
        : ApiService.baseUrl.replaceAll('/api', '');

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .disableAutoConnect()
      .setAuth({'token': jwtToken})
      .enableForceNew()
      .setReconnectionAttempts(10)
      .setReconnectionDelay(2000)
      .build(),
    );

    _registerHandlers();
    _socket!.connect();
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentToken = null;
  }

  // ── DM Actions ────────────────────────────────────────────────────────────

  /// Send a Direct Message. Tries real-time Socket.io with immediate REST fallback.
  Future<bool> sendDM({
    required String receiverId,
    required String content,
  }) async {
    if (_socket != null && _socket!.connected) {
      final completer = Completer<bool>();
      _socket!.emitWithAck('dm:send', {
        'receiverId': receiverId,
        'content':    content,
      }, ack: (data) {
        final success = (data as Map?)?['success'] == true;
        if (success && data is Map && data['data'] != null) {
          try {
            final payload = Map<String, dynamic>.from(data['data'] as Map);
            _emitDm(DmMessage.fromMap(payload));
          } catch (_) {}
        }
        if (!completer.isCompleted) completer.complete(success);
      });
      // Fast fallback to REST after 3 seconds if socket ack stalls
      Future.delayed(const Duration(seconds: 3), () async {
        if (!completer.isCompleted) {
          debugPrint('⚠️ [Socket] dm:send timeout. Falling back to REST API...');
          final restSuccess = await _sendDmViaRest(receiverId, content);
          completer.complete(restSuccess);
        }
      });
      return completer.future;
    }

    // Socket disconnected: deliver directly via REST API
    debugPrint('ℹ️ [Socket] Disconnected. Sending DM directly via REST API...');
    return _sendDmViaRest(receiverId, content);
  }

  Future<bool> _sendDmViaRest(String receiverId, String content) async {
    try {
      final response = await ApiService().dio.post(
        '/messages/dms/$receiverId',
        data: {'content': content},
      );
      final success = response.data['success'] == true;
      if (success && response.data['data'] != null) {
        try {
          final payload = Map<String, dynamic>.from(response.data['data'] as Map);
          _emitDm(DmMessage.fromMap(payload));
        } catch (_) {}
      }
      return success;
    } catch (e) {
      debugPrint('❌ [REST DM] Failed to send message via REST: $e');
      return false;
    }
  }

  void sendReadAck(String senderId) {
    _socket?.emit('dm:read', {'senderId': senderId});
  }

  void sendDmTyping(String receiverId, {required bool isTyping}) {
    _socket?.emit('dm:typing', {'receiverId': receiverId, 'isTyping': isTyping});
  }

  // ── Community Actions ─────────────────────────────────────────────────────

  Future<bool> sendCommunityMessage({
    required String communityId,
    required String content,
  }) {
    final completer = Completer<bool>();
    _socket?.emitWithAck('community:send', {
      'communityId': communityId,
      'content':     content,
    }, ack: (data) {
      final success = (data as Map?)?['success'] == true;
      if (!completer.isCompleted) completer.complete(success);
    });
    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future;
  }

  void joinCommunityRoom(String communityId) {
    _socket?.emit('community:join_room', {'communityId': communityId});
  }

  void sendCommunityTyping(String communityId, {required bool isTyping}) {
    _socket?.emit('community:typing', {'communityId': communityId, 'isTyping': isTyping});
  }

  // ── Event Handlers ────────────────────────────────────────────────────────

  void _registerHandlers() {
    _socket!
      ..onConnect((_)    => debugPrint('🟢 Socket connected'))
      ..onDisconnect((_) => debugPrint('🔴 Socket disconnected'))
      ..onConnectError((e) => debugPrint('❌ Socket connect error: $e'))

      ..on('dm:receive', (data) {
        try {
          _emitDm(DmMessage.fromMap(Map<String, dynamic>.from(data as Map)));
        } catch (e) {
          debugPrint('dm:receive parse error: $e');
        }
      })

      ..on('community:receive', (data) {
        try {
          _communityController.add(CommunityMessage.fromMap(Map<String, dynamic>.from(data as Map)));
        } catch (e) {
          debugPrint('community:receive parse error: $e');
        }
      })

      ..on('dm:typing', (data) {
        final m = Map<String, dynamic>.from(data as Map);
        _dmTypingController.add(TypingEvent(
          senderId:  m['senderId']?.toString() ?? '',
          isTyping:  m['isTyping'] == true,
        ));
      })

      ..on('community:typing', (data) {
        final m = Map<String, dynamic>.from(data as Map);
        _comTypingController.add(TypingEvent(
          senderId:   m['senderId']?.toString() ?? '',
          senderName: m['senderName']?.toString(),
          isTyping:   m['isTyping'] == true,
        ));
      })

      ..on('dm:read_ack', (data) {
        final readBy = (data as Map)['readBy']?.toString() ?? '';
        if (readBy.isNotEmpty) _readAckController.add(readBy);
      })

      ..on('user:online',  (data) {
        final uid = (data as Map)['userId']?.toString() ?? '';
        if (uid.isNotEmpty) _onlineController.add(uid);
      })

      ..on('user:offline', (data) {
        final uid = (data as Map)['userId']?.toString() ?? '';
        if (uid.isNotEmpty) _offlineController.add(uid);
      });
  }

  void dispose() {
    disconnect();
    _dmController.close();
    _communityController.close();
    _dmTypingController.close();
    _comTypingController.close();
    _readAckController.close();
    _onlineController.close();
    _offlineController.close();
  }
}
