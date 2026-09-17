import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'web_location_stub.dart'
    if (dart.library.html) 'web_location_web.dart';

class CampusSpot {
  final String name;
  final double lat;
  final double lng;
  final String description;

  const CampusSpot({
    required this.name,
    required this.lat,
    required this.lng,
    required this.description,
  });

  String get mapsUrl => 'https://maps.google.com/?q=$lat,$lng';
}

/// Service to resolve current GPS location or popular GITAM campus spots.
class LocationService {
  LocationService._();

  /// Popular Gitam campus landmarks
  static const List<CampusSpot> campusSpots = [
    CampusSpot(
      name: 'GITAM ICT Bhavan',
      lat: 17.7818,
      lng: 83.3776,
      description: 'Computer Science & Engineering Block',
    ),
    CampusSpot(
      name: 'Knowledge Resource Centre (KRC)',
      lat: 17.7809,
      lng: 83.3765,
      description: 'Central Campus Library',
    ),
    CampusSpot(
      name: 'Open Air Theatre (OAT)',
      lat: 17.7825,
      lng: 83.3789,
      description: 'Cultural events & gatherings',
    ),
    CampusSpot(
      name: 'Gandhi Square',
      lat: 17.7812,
      lng: 83.3758,
      description: 'Central campus plaza',
    ),
    CampusSpot(
      name: 'GITAM Food Court',
      lat: 17.7831,
      lng: 83.3772,
      description: 'Cafeteria & food stalls',
    ),
    CampusSpot(
      name: 'Indoor Stadium',
      lat: 17.7801,
      lng: 83.3749,
      description: 'Sports complex & arena',
    ),
  ];

  /// Resolves raw device coordinates {lat, lng} across Web and Mobile
  static Future<Map<String, double>?> getCurrentCoordinates({
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      try {
        final coords = await getBrowserCoordinates();
        if (coords != null) return coords;
      } catch (e) {
        debugPrint('[LocationService] Web coordinates error: $e');
      }
      return null;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services on your device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Enable in device settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (e) {
      debugPrint('[LocationService] Failed to get GPS coordinates: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not obtain GPS location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Resolves current device coordinates and returns a Google Maps URL
  static Future<String?> getCurrentLocationUrl({
    required BuildContext context,
  }) async {
    final coords = await getCurrentCoordinates(context: context);
    if (coords != null) {
      final lat = coords['lat']!.toStringAsFixed(6);
      final lng = coords['lng']!.toStringAsFixed(6);
      return 'https://maps.google.com/?q=$lat,$lng';
    }
    return null;
  }
}
