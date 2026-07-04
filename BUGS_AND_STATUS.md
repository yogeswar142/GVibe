# GVibe - Active Bugs, Status & Development Log

This document lists the active bugs under investigation, the setup status, and outstanding items for the GVibe team to resolve.

---

## ⚠️ Active Bugs & Problems Under Investigation

### 1. E2EE Direct Message Decryption Failures (`🔒 Could not decrypt`)
*   **Status:** 🔴 ACTIVE / IN PROGRESS
*   **The Problem:** Direct Messages occasionally show up as `🔒 Could not decrypt` or `🔒 Cannot decrypt (missing key)`.
*   **Investigation Notes & Clues:**
    *   In X25519 ECDH encryption, the shared secret between two users is derived from **User A's Private Key** and **User B's Public Key** (symmetric secret).
    *   We updated the decryption logic in [chat_detail_screen.dart](file:///home/yogeswar/Desktop/Projects/GVibe/frontend/lib/features/messages/chat_detail_screen.dart) to always use the recipient's public key (`_recipientPublicKey`) to decrypt messages.
    *   **Potential Clue 1 (Local State Caching):** Since the database was cleared, users registered fresh. However, local mobile devices retain their old private/public keys in secure storage (`gvibe_chat_private_key_v1`). If User A's device uses the old local key pair but the server has a newly generated key or vice versa, the shared secret calculation will mismatch. 
    *   **Potential Clue 2 (Key Upload Timing):** Public keys must be proactively uploaded. We added proactive uploading in [home_screen.dart](file:///home/yogeswar/Desktop/Projects/GVibe/frontend/lib/features/home/home_screen.dart), but if the device does not perform a **Hot Restart** or fresh rebuild after updates, the new upload and decryption hooks are not triggered.
    *   *Next Steps:* Verify if clearing the app storage on the device (or doing a fresh install) clears the secure storage key mismatches.

### 2. Multi-Account Socket Connection Alignment (Messages appearing as sent by other users)
*   **Status:** 🔴 ACTIVE / IN PROGRESS
*   **The Problem:** When switching accounts on a device (e.g. logging out of Amara and logging into Tanuj), the web socket connection occasionally reconnects using the previous user's credentials, causing messages to appear as sent by the wrong user.
*   **Investigation Notes & Clues:**
    *   The `socket_io_client` library caches connection managers based on the server URL. If a manager is cached, it reuses the connection and ignores the new auth headers/tokens during reconnect.
    *   We integrated `.enableForceNew()` inside the OptionBuilder of [socket_service.dart](file:///home/yogeswar/Desktop/Projects/GVibe/frontend/lib/core/services/socket_service.dart) to force a new manager instance.
    *   *Next Steps:* Verify if multiple instances/processes (e.g., hot restart leaving background processes running on the mobile device) are keeping separate background sockets active.

---

## 🛠️ Resolved Backend Crashes
*   **Socket reference error fix:** Fixed a backend crash in [socket.service.js](file:///home/yogeswar/Desktop/Projects/GVibe/backend/src/services/socket.service.js) where logging template strings threw a `ReferenceError: name is not defined`. Changed references to `socket.user.name` to print connections cleanly.

---

## 🚀 Future Roadmap & Enhancements

1.  **Device-to-Device Push Notifications:**
    *   Integrate Firebase Cloud Messaging (FCM) on the backend using the REST export client `getIO()` in `socket.service.js` to dispatch push alerts when users are offline.
2.  **Group Chat E2EE Encryption:**
    *   Implement group-key distribution protocols (e.g. Sender Keys / Signal Protocol) if community chats require E2EE.
3.  **Local Message Cache (SQFlite / Hive):**
    *   Cache decrypted message histories locally on the device to enable offline reading and speed up UI loading.
