import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class GlobeService {
  final _dio = ApiService().dio;

  static final GlobeService _instance = GlobeService._internal();
  factory GlobeService() => _instance;
  GlobeService._internal();

  static final _safeOptions = Options(
    validateStatus: (status) => status != null && status < 500,
  );

  /// Fetch active visible friends and campus event markers
  Future<List<Map<String, dynamic>>> getGlobeLocations() async {
    try {
      final res = await _dio.get('/globe/locations', options: _safeOptions);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['markers'] as List<dynamic>?;
        if (list != null) {
          return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[GlobeService] getGlobeLocations error: $e');
      return [];
    }
  }

  /// Update current user's shared location (rounded server-side)
  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    double accuracy = 0.0,
  }) async {
    try {
      final res = await _dio.put(
        '/globe/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
        },
        options: _safeOptions,
      );
      return res.statusCode == 200 && res.data['success'] == true;
    } catch (e) {
      debugPrint('[GlobeService] updateLocation error: $e');
      return false;
    }
  }

  /// Remove user's location and turn off sharing
  Future<bool> removeLocation() async {
    try {
      final res = await _dio.delete('/globe/location', options: _safeOptions);
      return res.statusCode == 200 && res.data['success'] == true;
    } catch (e) {
      debugPrint('[GlobeService] removeLocation error: $e');
      return false;
    }
  }

  /// Fetch user's globe sharing preferences
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final res = await _dio.get('/globe/settings', options: _safeOptions);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data'] as Map);
      }
      return null;
    } catch (e) {
      debugPrint('[GlobeService] getSettings error: $e');
      return null;
    }
  }

  /// Update user's globe sharing preferences
  Future<bool> updateSettings({
    bool? globeSharingEnabled,
    String? globeVisibleTo,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (globeSharingEnabled != null) {
        data['globeSharingEnabled'] = globeSharingEnabled;
      }
      if (globeVisibleTo != null) {
        data['globeVisibleTo'] = globeVisibleTo;
      }

      final res = await _dio.put('/globe/settings', data: data, options: _safeOptions);
      return res.statusCode == 200 && res.data['success'] == true;
    } catch (e) {
      debugPrint('[GlobeService] updateSettings error: $e');
      return false;
    }
  }
}
