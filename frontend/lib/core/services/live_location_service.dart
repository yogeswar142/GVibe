import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'location_service.dart';

class LiveLocationSession {
  final String sessionId;
  final String liveCode;
  final String shareUrl;
  final DateTime expiresAt;
  final int durationMinutes;

  const LiveLocationSession({
    required this.sessionId,
    required this.liveCode,
    required this.shareUrl,
    required this.expiresAt,
    required this.durationMinutes,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// Service managing real-time location streaming and periodic background updates
class LiveLocationService {
  static final LiveLocationService _instance = LiveLocationService._internal();
  factory LiveLocationService() => _instance;
  LiveLocationService._internal();

  LiveLocationSession? _currentSession;
  Timer? _updateTimer;

  LiveLocationSession? get activeSession {
    if (_currentSession != null && _currentSession!.isExpired) {
      stopLiveLocation();
      return null;
    }
    return _currentSession;
  }

  bool get isSharing => activeSession != null;

  /// Starts a live location session and initiates periodic tracking
  Future<LiveLocationSession?> startLiveLocation({
    required BuildContext context,
    int durationMinutes = 60,
  }) async {
    // 1. Fetch initial coordinates
    final coords = await LocationService.getCurrentCoordinates(context: context);
    if (coords == null) {
      return null;
    }

    try {
      final response = await ApiService().dio.post('/live-location/start', data: {
        'latitude': coords['lat'],
        'longitude': coords['lng'],
        'durationMinutes': durationMinutes,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final session = LiveLocationSession(
          sessionId: data['sessionId'].toString(),
          liveCode: data['liveCode'].toString(),
          shareUrl: data['shareUrl'].toString(),
          expiresAt: DateTime.parse(data['expiresAt'].toString()),
          durationMinutes: (data['durationMinutes'] as num).toInt(),
        );

        _currentSession = session;
        _startUpdateLoop();
        return session;
      }
    } catch (e) {
      debugPrint('[LiveLocationService] Failed to start live location: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start live location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return null;
  }

  /// Periodic update loop running every 25 seconds while active
  void _startUpdateLoop() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 25), (timer) async {
      final session = _currentSession;
      if (session == null || session.isExpired) {
        stopLiveLocation();
        return;
      }

      final coords = await LocationService.getCurrentCoordinates();
      if (coords == null) return;

      try {
        await ApiService().dio.put('/live-location/update', data: {
          'liveCode': session.liveCode,
          'latitude': coords['lat'],
          'longitude': coords['lng'],
        });
        debugPrint('[LiveLocationService] Updated location for ${session.liveCode}');
      } catch (e) {
        debugPrint('[LiveLocationService] Location update tick failed: $e');
      }
    });
  }

  /// Stops the active live location sharing session
  Future<void> stopLiveLocation() async {
    _updateTimer?.cancel();
    _updateTimer = null;

    final session = _currentSession;
    _currentSession = null;

    if (session != null) {
      try {
        await ApiService().dio.post('/live-location/stop', data: {
          'liveCode': session.liveCode,
        });
      } catch (e) {
        debugPrint('[LiveLocationService] Stop request failed: $e');
      }
    }
  }
}
