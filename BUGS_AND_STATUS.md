# GVibe - Active Bugs, Status & Development Log

This document lists the active bugs under investigation, the setup status, and outstanding items for the GVibe team to resolve.

---

## ✅ Resolved Bugs (2026-07-06)

### 1. E2EE Direct Message Decryption Failures (`🔒 Could not decrypt`)
*   **Status:** ✅ RESOLVED (Updated 2026-07-07)
*   **Root Cause:**
    1. Keys were being wiped from secure storage on every user logout (`logout()`), meaning a user logging back in lost the matching private key required to decrypt their own history.
    2. Transient sync/network errors during key validation automatically fell back to wiping and recreating keys, causing frequent historical decryption failures.
    3. `getMyPublicKeyBase64()` returned a cached public key without verifying if the corresponding private key was present, causing public/private key desynchronization if `_getOrCreateKeyPair()` subsequently generated a new pair.
    4. **Race condition/Out-of-Sync cached keys:** The client previously cached the recipient's public key (`_recipientPublicKey`) only once when the chat screen opened. If the partner logged in on another device or rotated their keys, the client continued to encrypt outgoing messages using the stale cached key and failed to decrypt incoming messages encrypted with the new key, causing `SecretBoxAuthenticationError: SecretBox has wrong message authentication code (MAC)`.
*   **Fixes Applied:**
    *   **Persistent Keys:** Removed `clearSecureKeys()` from `logout()`. Since keys are namespaced by the user ID (`gvibe_chat_private_key_v1_$uid`), account switching works cleanly without wiping history.
    *   **No Auto-Wipe:** Removed the key-wiping `uploadFreshKeys()` fallback from the `syncEncryptionKeys()` error catch block to prevent data loss on network glitches.
    *   **Consistent Pairings:** Updated `getMyPublicKeyBase64()` to always call `_getOrCreateKeyPair()` to guarantee that the returned public key matches the loaded private key.
    *   **Per-Message Key Tracking:** Added `senderPublicKey` and `receiverPublicKey` fields to the backend `Message` schema and socket payload. Clients now explicitly pass both public keys when sending a DM.
    *   **Dynamic Decrypt Resolution:** The client now decrypts messages using the exact public key attached to the message (`senderPublicKey` for incoming, `receiverPublicKey` for outgoing), falling back to the current cached public key for legacy messages. This fully immune-proofs E2EE against key rotation and eliminates race conditions.
    *   **Decryption Failure Reporting:** Created a new debug endpoint `/api/messages/debug/log-decrypt-failure` and wired it to `EncryptionService.instance.decrypt()` to automatically report decryption errors to backend console logs (logging client, partner, database public keys, and client public/private keys).
    *   **Socket Logging:** Added server-side E2EE public key logging on `dm:send` socket events to track exact key status at message transmission.

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

### 10. Client-Side Self-Verification Bypass Vulnerability
*   **Status:** ✅ RESOLVED
*   **Root Cause:** The `isVerified` status of a user (extracted from their Google account name mapping via regex) was being determined on the client-side and sent directly via `PUT /api/users/profile`. A malicious user could easily intercept the HTTP request or modify client code to set `isVerified: true` and verify their own account.
*   **Fix:**
    *   Moved name regex matching validation entirely to the backend `googleAuth` handler. The server now checks if the student's Google account name matches `^(.*?)\s+(\d{10})$` and persists `isVerified = true` securely during registration/login.
    *   Removed standard profile updates to the `isVerified` field in `user.controller.js` to ensure the status remains read-only.

### 11. Missing Database Indexes (Performance Bottleneck)
*   **Status:** ✅ RESOLVED
*   **Root Cause:**
    *   The `Post` model had no indexes defined, causing feed queries (`Post.find().sort({ createdAt: -1 })`) and tag-based searches (`Post.find({ tags })`) to perform full collection scans.
    *   The `Vibe` model lacked an index on `createdAt: -1`.
    *   The `Community` model lacked an index on `{ isPrivate: 1, memberCount: -1 }` used by `discoverCommunities`.
*   **Fix:**
    *   Added compound index `{ tags: 1, createdAt: -1 }` and key index `{ createdAt: -1 }` to the `Post` schema.
    *   Added key index `{ createdAt: -1 }` to the `Vibe` schema.
    *   Added compound index `{ isPrivate: 1, memberCount: -1 }` to the `Community` schema.

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
5.  **Community Kick/Ban Enforcement:**
    *   Implement a banned/kicked user list per community to prevent kicked members from immediately re-joining public communities via `joinCommunity`.
6.  **Scalable Recommendation Engine:**
    *   Optimize the in-memory recommendation sorting in `discovery.controller.js`'s `discoverPeople` method. Replace the full `User.find()` fetch with MongoDB aggregation pipelines (`$lookup` and `$project`) to avoid pulling the entire user base into Node.js heap memory.
