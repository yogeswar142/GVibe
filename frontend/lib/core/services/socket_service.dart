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

// ── Event data models ────────────────────────────────────────────────────────

class DmMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String ciphertext;
  final String nonce;
  final String mac;
  final DateTime createdAt;

  const DmMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    required this.createdAt,
  });

  factory DmMessage.fromMap(Map<String, dynamic> m) {
    final sender = m['sender'] as Map<String, dynamic>? ?? {};
    return DmMessage(
      id:           m['_id']?.toString() ?? '',
      senderId:     sender['_id']?.toString() ?? m['senderId']?.toString() ?? '',
      senderName:   sender['name']?.toString() ?? '',
      senderAvatar: sender['avatar']?.toString(),
      receiverId:   m['receiverId']?.toString() ?? '',
      ciphertext:   m['ciphertext']?.toString() ?? '',
      nonce:        m['nonce']?.toString() ?? '',
      mac:          m['mac']?.toString() ?? '',
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

    final socketUrl = dotenv.env['SOCKET_URL']
        ?? dotenv.env['API_BASE_URL']?.replaceAll('/api', '')
        ?? 'http://10.0.2.2:5000';

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
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

  /// Send an E2EE DM. The payload is already encrypted by [EncryptionService].
  Future<bool> sendDM({
    required String receiverId,
    required String ciphertext,
    required String nonce,
    required String mac,
  }) {
    final completer = Completer<bool>();
    _socket?.emitWithAck('dm:send', {
      'receiverId': receiverId,
      'ciphertext': ciphertext,
      'nonce':      nonce,
      'mac':        mac,
    }, ack: (data) {
      final success = (data as Map?)?['success'] == true;
      if (!completer.isCompleted) completer.complete(success);
    });
    // Timeout fallback — 15s to handle slow mobile networks (BUG-06 fix)
    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future;
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
          _dmController.add(DmMessage.fromMap(Map<String, dynamic>.from(data as Map)));
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
