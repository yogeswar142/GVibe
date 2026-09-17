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

    final pos = await geo.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 10),
    );

    final coords = pos.coords;
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
