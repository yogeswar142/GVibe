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

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const _privateKeyStorageKey = 'gvibe_chat_private_key_v1';
  static const _publicKeyStorageKey  = 'gvibe_chat_public_key_v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _x25519 = X25519();
  final _aes    = AesGcm.with256bits();

  SimpleKeyPair? _cachedKeyPair;

  // ── Key Management ─────────────────────────────────────────────────────────

  /// Returns the local key pair, loading from secure storage or generating fresh.
  Future<SimpleKeyPair> _getOrCreateKeyPair() async {
    if (_cachedKeyPair != null) return _cachedKeyPair!;

    final storedPrivate = await _storage.read(key: _privateKeyStorageKey);
    if (storedPrivate != null) {
      try {
        final bytes = base64Decode(storedPrivate);
        _cachedKeyPair = await _x25519.newKeyPairFromSeed(bytes);
        return _cachedKeyPair!;
      } catch (_) {
        // Corrupted key — regenerate
      }
    }

    // Generate brand new key pair
    final keyPair = await _x25519.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    await _storage.write(
      key: _privateKeyStorageKey,
      value: base64Encode(privateBytes),
    );

    // Cache the public key in plain prefs for quick retrieval
    final pubKey = await keyPair.extractPublicKey();
    await _storage.write(
      key: _publicKeyStorageKey,
      value: base64Encode(pubKey.bytes),
    );

    _cachedKeyPair = keyPair;
    return keyPair;
  }

  /// Returns the user's own X25519 public key as a Base64 string.
  /// This is safe to share — uploaded to the server for others to encrypt DMs.
  Future<String> getMyPublicKeyBase64() async {
    final stored = await _storage.read(key: _publicKeyStorageKey);
    if (stored != null) return stored;

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

  /// Decrypts an incoming DM using the sender's public key.
  /// Returns the plaintext string, or null on any error.
  Future<String?> decrypt({
    required String ciphertextBase64,
    required String nonceBase64,
    required String macBase64,
    required String senderPublicKeyBase64,
  }) async {
    try {
      final myKeyPair = await _getOrCreateKeyPair();

      final senderPubBytes = base64Decode(senderPublicKeyBase64);
      final senderPublicKey = SimplePublicKey(senderPubBytes, type: KeyPairType.x25519);

      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: myKeyPair,
        remotePublicKey: senderPublicKey,
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
      print('🔑 [E2EE Decrypt Error] Remote Public Key: $senderPublicKeyBase64');
      try {
        final myPub = await getMyPublicKeyBase64();
        print('🔑 [E2EE Decrypt Error] My Public Key: $myPub');
      } catch (_) {}
      return null;
    }
  }

  /// Wipes the cached key pair from memory (call on logout).
  void clearCache() => _cachedKeyPair = null;

  /// Wipes public and private keys from secure storage (call on logout).
  Future<void> clearSecureKeys() async {
    await _storage.delete(key: _privateKeyStorageKey);
    await _storage.delete(key: _publicKeyStorageKey);
  }
}
