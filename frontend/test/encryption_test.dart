import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('X25519 seed restore test', () async {
    final x25519 = X25519();

    // 1. Generate keypair
    final keyPair = await x25519.newKeyPair();
    final pubKey = await keyPair.extractPublicKey();
    final privBytes = await keyPair.extractPrivateKeyBytes();

    final originalPubBase64 = base64Encode(pubKey.bytes);
    final privBase64 = base64Encode(privBytes);

    print('Original Pub: $originalPubBase64');
    print('Private Key Bytes Base64: $privBase64');

    // 2. Restore from seed
    final restoredKeyPair = await x25519.newKeyPairFromSeed(privBytes);
    final restoredPub = await restoredKeyPair.extractPublicKey();
    final restoredPubBase64 = base64Encode(restoredPub.bytes);

    print('Restored Pub: $restoredPubBase64');

    expect(restoredPubBase64, originalPubBase64);
  });
}
