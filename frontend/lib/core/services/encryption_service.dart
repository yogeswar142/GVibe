/// End-to-end encryption service using X25519 ECDH + AES-GCM-256.
library;

// Handles all X25519 key-pair generation, secure storage of the private key,
// and AES-GCM-256 encrypt/decrypt for E2EE DMs.
//
// Design rules:
//  - Private key NEVER leaves the device (stored in hardware keystore via
//    flutter_secure_storage).
//  - Server receives only: ciphertext, nonce, mac — all opaque bytes.
//  - Public key is uploaded once per device boot/login for others to use.

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  Future<String> _getPrivateKeyStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? 'default';
    return 'gvibe_chat_private_key_v1_$uid';
  }

  Future<String> _getPublicKeyStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? 'default';
    return 'gvibe_chat_public_key_v1_$uid';
  }

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _x25519 = X25519();
  final _aes    = AesGcm.with256bits();

  String? _cachedUserId;
  SimpleKeyPair? _cachedKeyPair;

  // ── Key Management ─────────────────────────────────────────────────────────

  /// Returns the local key pair, loading from secure storage or generating fresh.
  Future<SimpleKeyPair> _getOrCreateKeyPair() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? 'default';

    if (_cachedKeyPair != null && _cachedUserId == uid) {
      return _cachedKeyPair!;
    }

    // Cache mismatch or empty: clear and reload under active user namespace
    _cachedKeyPair = null;
    _cachedUserId = uid;

    final privateKeyKey = await _getPrivateKeyStorageKey();
    final publicKeyKey = await _getPublicKeyStorageKey();

    final storedPrivate = await _storage.read(key: privateKeyKey);
    if (storedPrivate != null) {
      try {
        final bytes = base64Decode(storedPrivate);
        _cachedKeyPair = await _x25519.newKeyPairFromSeed(bytes);
        // BUG-08 fix: always re-derive and re-write the public key from the
        // private seed so public/private keys in storage can never desync.
        final pubKey = await _cachedKeyPair!.extractPublicKey();
        await _storage.write(
          key: publicKeyKey,
          value: base64Encode(pubKey.bytes),
        );
        return _cachedKeyPair!;
      } catch (_) {
        // Corrupted key — fall through to regenerate
      }
    }

    // Generate brand new key pair
    final keyPair = await _x25519.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    await _storage.write(
      key: privateKeyKey,
      value: base64Encode(privateBytes),
    );

    // Cache the public key in plain prefs for quick retrieval
    final pubKey = await keyPair.extractPublicKey();
    await _storage.write(
      key: publicKeyKey,
      value: base64Encode(pubKey.bytes),
    );

    _cachedKeyPair = keyPair;
    return keyPair;
  }

  /// Returns the user's own X25519 public key as a Base64 string.
  /// This is safe to share — uploaded to the server for others to encrypt DMs.
  Future<String> getMyPublicKeyBase64() async {
    final kp = await _getOrCreateKeyPair();
    final pub = await kp.extractPublicKey();
    return base64Encode(pub.bytes);
  }

  // ── Encryption ─────────────────────────────────────────────────────────────

  /// Encrypts [plaintext] for a recipient identified by their Base64 public key.
  /// Returns a map containing ciphertext, nonce, and mac — all Base64 encoded.
  Future<Map<String, String>> encrypt({
    required String plaintext,
    required String recipientPublicKeyBase64,
  }) async {
    final myKeyPair = await _getOrCreateKeyPair();

    final recipientPubBytes = base64Decode(recipientPublicKeyBase64);
    final recipientPublicKey = SimplePublicKey(recipientPubBytes, type: KeyPairType.x25519);

    // ECDH shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    // AES-GCM-256 encryption
    final secretBox = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: sharedSecret,
    );

    final myPub = await getMyPublicKeyBase64();
    print('🔑 [E2EE Encrypt] Encrypted message using recipient key: $recipientPublicKeyBase64 | My key: $myPub');

    return {
      'ciphertext': base64Encode(secretBox.cipherText),
      'nonce':      base64Encode(secretBox.nonce),
      'mac':        base64Encode(secretBox.mac.bytes),
    };
  }

  // ── Decryption ─────────────────────────────────────────────────────────────

  /// Decrypts an incoming DM using the other party's public key.
  ///
  /// ECDH is symmetric: sharedSecret(myPrivate, theirPublic)
  ///   == sharedSecret(theirPrivate, myPublic)
  /// So [remotePartyPublicKeyBase64] is the recipient's key when decrypting
  /// messages YOU sent from history, and the sender's key for received messages.
  /// Both cases use the OTHER person's public key — that is intentional.
  ///
  /// Returns the plaintext string, or null on any error.
  Future<String?> decrypt({
    required String ciphertextBase64,
    required String nonceBase64,
    required String macBase64,
    required String remotePartyPublicKeyBase64, // BUG-03 fix: was 'senderPublicKeyBase64'
    String? messageId,
    String? remotePartyId,
  }) async {
    try {
      final myKeyPair = await _getOrCreateKeyPair();

      final remoteBytes = base64Decode(remotePartyPublicKeyBase64);
      final remotePublicKey = SimplePublicKey(remoteBytes, type: KeyPairType.x25519);

      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: myKeyPair,
        remotePublicKey: remotePublicKey,
      );

      final secretBox = SecretBox(
        base64Decode(ciphertextBase64),
        nonce: base64Decode(nonceBase64),
        mac:   Mac(base64Decode(macBase64)),
      );

      final decryptedBytes = await _aes.decrypt(secretBox, secretKey: sharedSecret);
      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('🔑 [E2EE Decrypt Error] Decryption failed! Details: $e');
      print('🔑 [E2EE Decrypt Error] Remote Public Key: $remotePartyPublicKeyBase64');
      String? myPub;
      try {
        myPub = await getMyPublicKeyBase64();
        print('🔑 [E2EE Decrypt Error] My Public Key: $myPub');
      } catch (_) {}

      // Report failure to the backend for debugging
      if (messageId != null && remotePartyId != null) {
        try {
          await ApiService().dio.post('/messages/debug/log-decrypt-failure', data: {
            'messageId': messageId,
            'remotePartyId': remotePartyId,
            'remotePartyPublicKey': remotePartyPublicKeyBase64,
            'myPublicKeyUsed': myPub,
            'errorDetails': e.toString(),
          });
        } catch (reportErr) {
          print('🔑 [E2EE Decrypt Error] Failed to upload decryption failure report: $reportErr');
        }
      }
      return null;
    }
  }

  /// Wipes the cached key pair from memory (call on logout).
  void clearCache() {
    _cachedKeyPair = null;
    _cachedUserId = null;
  }

  /// Wipes public and private keys from secure storage (call on logout).
  Future<void> clearSecureKeys() async {
    final privateKeyKey = await _getPrivateKeyStorageKey();
    final publicKeyKey = await _getPublicKeyStorageKey();
    await _storage.delete(key: privateKeyKey);
    await _storage.delete(key: publicKeyKey);
  }
}
