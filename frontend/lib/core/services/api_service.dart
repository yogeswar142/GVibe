import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  // Navigator key linked to GoRouter's navigatorKey
  static GlobalKey<NavigatorState> get navigatorKey => AppRouter.navigatorKey;

  static String? _resolvedBaseUrl;

  // Retrieve the base URL from the .env file with platform-specific adjustments.
  static String get baseUrl {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    
    String url = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';
    if (!kIsWeb && Platform.isAndroid) {
      url = url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Auth interceptor — attaches JWT token + handles backend-down
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        final res = error.response;
        bool isOffline = false;

        // 1. Connection error / timeouts / SocketExceptions
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.message?.contains('Connection refused') == true ||
            error.message?.contains('SocketException') == true) {
          isOffline = true;
        }

        // 2. HTTP Status codes: 502 / 503 / 504
        if (res != null) {
          if (res.statusCode == 502 || res.statusCode == 503 || res.statusCode == 504) {
            isOffline = true;
          }
          
          // 3. Check HTML content inside response (like ngrok offline HTML pages)
          if (res.data != null) {
            final bodyStr = res.data.toString();
            if (bodyStr.contains('<!DOCTYPE html>') ||
                bodyStr.contains('<html>') ||
                bodyStr.contains('ERR_NGROK_3200') ||
                bodyStr.contains('offline') ||
                bodyStr.contains('tunnel') && bodyStr.contains('not found')) {
              isOffline = true;
            }
          }
        }

        if (isOffline) {
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            // Check current matched route to prevent redundant routing
            try {
              final route = GoRouterState.of(context).matchedLocation;
              if (route != AppRouter.backendDown) {
                GoRouter.of(context).go(AppRouter.backendDown);
              }
            } catch (_) {
              // Fallback if GoRouterState isn't in scope
              GoRouter.of(context).go(AppRouter.backendDown);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Fast connectivity check to determine if the backend is reachable.
  /// Dynamically tests candidate URLs (configured, emulator local, and static Ngrok tunnel)
  /// and locks onto the first responding URL.
  Future<bool> checkConnection() async {
    final configuredUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';
    final candidates = <String>[];

    // 1. Configured URL
    candidates.add(configuredUrl);

    // 2. Android emulator translation if configured is localhost
    if (!kIsWeb && Platform.isAndroid) {
      if (configuredUrl.contains('localhost') || configuredUrl.contains('127.0.0.1')) {
        final emuUrl = configuredUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
        if (!candidates.contains(emuUrl)) {
          candidates.add(emuUrl);
        }
      }
    }

    // 3. Static Ngrok tunnel URL
    const ngrokUrl = 'https://levitative-unpresumptuously-claire.ngrok-free.dev/api';
    if (!candidates.contains(ngrokUrl)) {
      candidates.add(ngrokUrl);
    }

    // If we already successfully resolved one, test it first
    if (_resolvedBaseUrl != null) {
      candidates.remove(_resolvedBaseUrl!);
      candidates.insert(0, _resolvedBaseUrl!);
    }

    debugPrint('🔍 Testing backend candidate URLs: $candidates');

    for (final candidate in candidates) {
      try {
        final testDio = Dio(BaseOptions(
          baseUrl: candidate,
          connectTimeout: const Duration(milliseconds: 2000),
          receiveTimeout: const Duration(milliseconds: 2000),
        ));
        final response = await testDio.get('/');
        final data = response.data;
        
        // Ngrok returns standard HTML page if the tunnel is down/uninitialized/error
        final isHtml = data is String && (data.contains('<!DOCTYPE html>') || data.contains('<html>'));
        if (!isHtml) {
          _resolvedBaseUrl = candidate;
          dio.options.baseUrl = candidate;
          debugPrint('🔌 GVibe successfully locked onto backend URL: $candidate');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Candidate URL $candidate unreachable: $e');
      }
    }

    return false;
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      try {
        final data = error.response?.data;
        if (data is Map) {
          return data['message']?.toString() ?? 'An error occurred';
        } else if (data is String && data.isNotEmpty) {
          if (data.contains('<!DOCTYPE html>') || data.contains('<html>')) {
            return 'Server error (HTML response)';
          }
          return data;
        }
      } catch (_) {}
      return error.message ?? 'Network error';
    }
    return error?.toString() ?? 'An unexpected error occurred';
  }
}
