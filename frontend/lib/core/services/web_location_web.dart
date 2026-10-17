// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Direct browser HTML5 Geolocation API implementation for Flutter Web.
/// Bypasses Flutter plugin MethodChannels to prevent MissingPluginException.
Future<Map<String, double>?> getBrowserCoordinates() async {
  try {
    final geo = html.window.navigator.geolocation;
    // ignore: unnecessary_null_comparison
    if (geo == null) {
      debugPrint('[WebLocation] Geolocation not supported by browser.');
      return null;
    }

    // 1. Try high accuracy with a 3-second timeout (works on GPS-enabled mobile browsers)
    try {
      final pos = await geo.getCurrentPosition(
        enableHighAccuracy: true,
        timeout: const Duration(seconds: 3),
      );
      final coords = pos.coords;
      if (coords != null &&
          coords.latitude != null &&
          coords.longitude != null) {
        return {
          'lat': coords.latitude!.toDouble(),
          'lng': coords.longitude!.toDouble(),
        };
      }
    } catch (e) {
      debugPrint('[WebLocation] High accuracy unavailable/timed out, falling back to standard accuracy: $e');
    }

    // 2. Standard accuracy fallback with cached coordinates (essential for desktop/Chrome)
    final fallbackPos = await geo.getCurrentPosition(
      enableHighAccuracy: false,
      timeout: const Duration(seconds: 8),
      maximumAge: const Duration(minutes: 1),
    );

    final coords = fallbackPos.coords;
    if (coords != null && coords.latitude != null && coords.longitude != null) {
      return {
        'lat': coords.latitude!.toDouble(),
        'lng': coords.longitude!.toDouble(),
      };
    }
  } catch (e) {
    debugPrint('[WebLocation] Browser Geolocation error: $e');
  }
  return null;
}
