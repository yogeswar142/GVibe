import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'encryption_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'user_data';
  static const String _userIdKey = 'user_id';

  // Save JWT token and connect Socket.io
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // Connect socket immediately so DMs arrive without delay
    SocketService.instance.connect(token);
  }

  // Get JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Save user data as JSON (also persists userId for socket DM routing)
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if the user is switching accounts to clear key cache
    final existingUid = prefs.getString(_userIdKey);
    final newUid = userData['_id']?.toString() ?? userData['id']?.toString();
    if (existingUid != null && existingUid != newUid) {
      EncryptionService.instance.clearCache();
      await EncryptionService.instance.clearSecureKeys();
    }
    
    await prefs.setString(_userKey, jsonEncode(userData));
    // Persist userId separately for quick access without full JSON decode
    if (newUid != null) await prefs.setString(_userIdKey, newUid);
  }

  // Get cached user data
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Clear all auth data (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey);
    // Disconnect socket and clear in-memory E2EE key pair + secure storage E2EE keys
    SocketService.instance.disconnect();
    EncryptionService.instance.clearCache();
    await EncryptionService.instance.clearSecureKeys();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  // Orchestrate Google Sign-in: tries real Google Auth first, falls back to simulation on dev errors
  static Future<Map<String, dynamic>?> triggerGoogleAuth({
    required BuildContext context,
    required String action, // 'login' or 'register'
  }) async {
    try {
      // Initialize GoogleSignIn using the new Web Client ID as the serverClientId.
      // This allows the Android app to obtain ID tokens/auth codes.
      await GoogleSignIn.instance.initialize(
        serverClientId: '102660971528-qp48pr3151d6sit1f1bch7s4hln68fr5.apps.googleusercontent.com',
      );

      // 2. Try real Google Sign-In via authenticate()
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final String email = googleUser.email;
      final String name = googleUser.displayName ?? '';
      final String googleId = googleUser.id;

      // 2. Call backend
      try {
        final response = await ApiService().dio.post('/auth/google', data: {
          'email': email,
          'name': name,
          'googleId': googleId,
          'action': action,
        });
        return response.data;
      } on DioException catch (dioError) {
        // Backend returned a response error (like 400 Bad Request / email not allowed / user exists)
        final msg = ApiService.getErrorMessage(dioError);
        return {
          'success': false,
          'message': msg,
          'code': dioError.response?.data?['code'],
        };
      }
    } catch (e) {
      debugPrint('Google Sign-In initialization/authentication failed: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Google Auth Unavailable'),
            content: const Text(
              'Something went wrong or the Google auth option is not working. '
              'Please try again after some time.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }
}
