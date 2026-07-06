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

  // Save JWT token — does NOT connect the socket yet.
  // Call connectSocket() AFTER saveUser() so stale key caches are cleared first.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
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

  // Save user data as JSON (also persists userId for socket DM routing).
  // BUG-02 fix: connect the socket AFTER saving user so stale key caches are
  // cleared before any socket events fire under the new account.
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the user is switching accounts to clear key cache
    final existingUid = prefs.getString(_userIdKey);
    final newUid = userData['_id']?.toString() ?? userData['id']?.toString();
    if (existingUid != null && existingUid != newUid) {
      EncryptionService.instance.clearCache();
      // NOTE: We no longer delete keys on account switch because keys are user-namespaced.
      // This preserves historical DM readability when logging back into a previous account.
    }

    await prefs.setString(_userKey, jsonEncode(userData));
    // Persist userId separately for quick access without full JSON decode
    if (newUid != null) await prefs.setString(_userIdKey, newUid);

    // BUG-02 fix: connect socket only now, after user identity is settled.
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      SocketService.instance.connect(token);
    }
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
    // BUG-02 fix: disconnect socket FIRST before clearing credentials
    // so no in-flight events fire with a stale identity.
    SocketService.instance.disconnect();
    EncryptionService.instance.clearCache();
    await EncryptionService.instance.clearSecureKeys();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey);
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// BUG-01 fix: Clears the local E2EE keypair and re-uploads a fresh public
  /// key to the server. Call this after every login/registration to guarantee
  /// the device key and the server's stored key are always in sync.
  static Future<void> uploadFreshKeys(ApiService api) async {
    try {
      EncryptionService.instance.clearCache();
      await EncryptionService.instance.clearSecureKeys();
      final myPub = await EncryptionService.instance.getMyPublicKeyBase64();
      await api.dio.put('/messages/keys/public', data: {'x25519': myPub});
      debugPrint('🔑 [E2EE] Fresh key pair generated and uploaded: $myPub');
    } catch (e) {
      debugPrint('🔑 [E2EE Error] Failed to upload fresh key: $e');
    }
  }

  /// Syncs E2EE keys dynamically without wiping existing ones, preserving history.
  /// If missing or mismatched on the server, uploads/syncs them.
  static Future<void> syncEncryptionKeys(ApiService api) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString(_userIdKey);
      if (myId == null || myId.isEmpty) {
        await uploadFreshKeys(api);
        return;
      }

      final myLocalPub = await EncryptionService.instance.getMyPublicKeyBase64();
      
      final response = await api.dio.get('/messages/keys/$myId');
      if (response.data['success'] == true) {
        final serverPub = response.data['data']?['x25519']?.toString();
        if (serverPub == myLocalPub) {
          debugPrint('🔑 [E2EE] Keys are in sync with server. No rotation needed.');
          return;
        }
      }
      
      await api.dio.put('/messages/keys/public', data: {'x25519': myLocalPub});
      debugPrint('🔑 [E2EE] Uploaded local public key to server for sync: $myLocalPub');
    } catch (e) {
      debugPrint('🔑 [E2EE Sync Error] Failed to sync keys: $e. Falling back to uploading fresh keys.');
      await uploadFreshKeys(api);
    }
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
