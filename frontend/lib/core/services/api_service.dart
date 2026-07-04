import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  // Navigator key linked to GoRouter's navigatorKey
  static GlobalKey<NavigatorState> get navigatorKey => AppRouter.navigatorKey;

  // Retrieve the base URL from the .env file.
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api';

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
  Future<bool> checkConnection() async {
    try {
      final response = await dio.get(
        '/',
        options: Options(
          connectTimeout: const Duration(milliseconds: 2500),
          receiveTimeout: const Duration(milliseconds: 2500),
        ),
      );
      
      // If response body is HTML (like Ngrok's gateway error page), the backend is offline
      final data = response.data;
      if (data is String && (data.contains('<!DOCTYPE html>') || data.contains('<html>'))) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 502 Bad Gateway / 503 Service Unavailable / 504 Gateway Timeout mean backend is offline
      if (status == 502 || status == 503 || status == 504 || status == 500) {
        return false;
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.message?.contains('Connection refused') == true ||
          e.message?.contains('SocketException') == true) {
        return false;
      }
      // Check if error response body is HTML
      final data = e.response?.data;
      if (data is String && (data.contains('<!DOCTYPE html>') || data.contains('<html>'))) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
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
