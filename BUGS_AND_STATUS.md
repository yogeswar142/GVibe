# GVibe - Active Bugs, Status & Development Log

This document lists the active bugs under investigation, the setup status, and outstanding items for the GVibe team to resolve.

---

## ✅ Resolved Bugs (2026-07-06)

### 1. E2EE Direct Message Decryption Failures (`🔒 Could not decrypt`)
*   **Status:** ✅ RESOLVED
*   **Root Cause:** Device retained old private keys in `FlutterSecureStorage` after a DB wipe or re-registration. The server stored a new public key, but the device's private key was old, causing ECDH shared secret mismatch.
*   **Fixes Applied:**
    *   `AuthService.uploadFreshKeys()` added — clears and regenerates the local E2EE keypair and uploads the new public key on every login/registration.
    *   Called in `login_screen.dart` (email login + Google login) and `signup_screen.dart` (Google registration).
    *   `EncryptionService._getOrCreateKeyPair()` now re-derives and re-writes the public key to secure storage when restoring from a private seed (BUG-08, prevents public/private desync).
    *   `home_screen.dart` now does a lightweight fallback key confirmation on cold-start.

### 2. Multi-Account Socket Connection Alignment (Messages appearing as sent by other users)
*   **Status:** ✅ RESOLVED
*   **Root Cause:** `AuthService.saveToken()` was connecting the socket immediately, before `saveUser()` could clear the stale key cache and establish the new user's identity.
*   **Fixes Applied:**
    *   `saveToken()` no longer calls `SocketService.connect()`. Socket is now connected at the end of `saveUser()`, after identity is fully settled.
    *   `AuthService.logout()` now calls `SocketService.disconnect()` first, before clearing preferences, so no in-flight events fire under the old identity.

### 3. Misleading `senderPublicKeyBase64` Parameter Name
*   **Status:** ✅ RESOLVED
*   **Fix:** Renamed to `remotePartyPublicKeyBase64` with a detailed comment explaining the symmetric ECDH property. All callers in `chat_detail_screen.dart` updated.

### 4. Soft-Deleted Messages Appearing in Inbox
*   **Status:** ✅ RESOLVED
*   **Fix:** Added `deletedAt: null` and `community: null` filters to the `getConversations` aggregation `$match` stage in `message.controller.js`.

### 5. Inbox Showed All Users Instead of Real Conversations
*   **Status:** ✅ RESOLVED
*   **Fix:** `messages_screen.dart` now calls `GET /messages/conversations` instead of `GET /users`. Shows real last message preview (`🔒 Encrypted message` for DMs), actual last-seen based online status, real timestamps, and partner avatars. Pull-to-refresh and empty state added.

### 6. False "Failed to Send" Snackbar on Slow Networks
*   **Status:** ✅ RESOLVED
*   **Fixes Applied:**
    *   Messages are now **optimistically added** to the list immediately on send — the user sees the message right away.
    *   On explicit server failure (not timeout), the optimistic message is removed and the snackbar shown.
    *   Socket ack timeout extended from 5 seconds to 15 seconds.

### 7. Online/Offline Presence Broadcast to All Users
*   **Status:** ✅ RESOLVED
*   **Fix:** `socket.service.js` now emits `user:online` and `user:offline` events only to the user's followers' rooms instead of `io.emit()` (all sockets). Also emits to the user's own room for multi-device support.

### 8. Key Pair Storage Desync (Public/Private Keys)
*   **Status:** ✅ RESOLVED (included in fix for BUG-01 above)
*   **Fix:** `_getOrCreateKeyPair()` now re-derives and re-writes the public key to `_publicKeyStorageKey` every time a key pair is restored from its private seed.

### 9. Per-Socket Rate Limiter Allows Multi-Device Abuse
*   **Status:** ✅ RESOLVED
*   **Fix:** Rate limit buckets moved from per-socket state (`dmCount`, `comCount`) to server-level `Map<userId, bucket>` (`_dmBuckets`, `_comBuckets`). Multi-device users now correctly share a single 30 DM/min and 60 community msg/min quota.

---

## 🛠️ Previously Resolved Backend Crashes
*   **Socket reference error fix:** Fixed a backend crash in `socket.service.js` where logging template strings threw a `ReferenceError: name is not defined`. Changed references to `socket.user.name` to print connections cleanly.

---

## 🚀 Future Roadmap & Enhancements

1.  **Device-to-Device Push Notifications:**
    *   Integrate Firebase Cloud Messaging (FCM) on the backend using the REST export client `getIO()` in `socket.service.js` to dispatch push alerts when users are offline.
2.  **Group Chat E2EE Encryption:**
    *   Implement group-key distribution protocols (e.g. Sender Keys / Signal Protocol) if community chats require E2EE.
3.  **Local Message Cache (SQFlite / Hive):**
    *   Cache decrypted message histories locally on the device to enable offline reading and speed up UI loading.
4.  **Real Unread Count in Inbox:**
    *   Add an unread message count to the `getConversations` aggregation response and wire it to the badge in `messages_screen.dart`.
