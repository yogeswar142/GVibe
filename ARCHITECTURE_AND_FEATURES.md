# GVibe — Architecture, Tech Stack & Feature Specification

## 1. Executive Summary

**GVibe** is a specialized, real-time social and campus connection platform designed exclusively for students of GITAM University (`@student.gitam.edu`). The platform combines campus micro-blogging, community discussion groups, End-to-End Encrypted (E2EE) direct messaging, lost-and-found tracking, short-lived live location sharing, and link/profile engagement analytics into a cohesive, high-performance mobile and web experience.

---

## 2. Technology Stack

### 2.1. Frontend (Mobile & Web)
* **Framework:** Flutter 3.x / Dart SDK `^3.4.0`
* **Target Platforms:** Android, iOS, Web, Desktop (Linux, macOS, Windows)
* **State Management:** Riverpod (`flutter_riverpod: ^2.5.1`, `riverpod_annotation: ^2.3.5`, `riverpod_generator: ^2.4.0`)
* **Routing & Navigation:** `go_router: ^13.0.0` featuring declarative nested routes and custom physics-based page transitions (`_slideUpTransition`)
* **HTTP Networking:** `dio: ^5.4.3` configured with request/response interceptors, centralized error extraction, and Bearer token injection
* **Real-time WebSockets:** `socket_io_client: ^2.0.3+1` for persistent bi-directional communication
* **End-to-End Encryption (E2EE):** `cryptography: ^2.7.0` (X25519 Diffie-Hellman key exchange + ChaCha20-Poly1305 AEAD)
* **Secure Key Storage:** `flutter_secure_storage: ^9.2.2` (Keychain on iOS, Keystore/EncryptedSharedPreferences on Android)
* **Local Caching & Preferences:** `shared_preferences: ^2.2.3`
* **Authentication:** `google_sign_in: ^7.2.0`, `google_sign_in_web: ^1.1.3`, `google_sign_in_platform_interface: ^3.1.0`
* **Location & Geolocation:** `geolocator: ^14.0.2` with custom web platform conditional stubs
* **UI & Typography:** `google_fonts: ^6.2.1` (Inter / Outfit font hierarchies), `cached_network_image: ^3.3.1`, `cupertino_icons: ^1.0.8`
* **Design System & Theming:** Dual theme engine featuring Linear-inspired Dark Mode (`#08090A` / `#5E6AD2`) and Vercel-inspired Light Mode (`#FEFEFE` / `#0070F3`) managed via Riverpod `ThemeProvider` and `GVibeThemeExtension`

### 2.2. Backend (REST API & Real-time Sockets)
* **Runtime:** Node.js (LTS, CommonJS)
* **Web Framework:** Express.js (`v4.21.2`)
* **Real-time Engine:** Socket.io (`v4.8.3`) attached directly to the native Node `http.Server`
* **Database & ORM/ODM:** MongoDB with Mongoose (`v8.12.1`)
* **Authentication & Cryptography:** 
  * `jsonwebtoken: ^9.0.2` (Stateless JWT auth with Bearer tokens)
  * `bcryptjs: ^2.4.3` (Salted blowfish password hashing)
  * `google-auth-library: ^10.9.0` (Server-side Google OAuth token verification)
  * Node.js built-in `crypto` module (Cryptographic random bytes for short links, SHA-256 visitor fingerprinting)
* **Security & Hardening Middleware:**
  * `helmet: ^8.2.0` (Content-Security-Policy, anti-MIME sniffing, XSS headers)
  * `cors: ^2.8.5` (Origin restriction supporting local dev and tunnel endpoints)
  * `express-mongo-sanitize: ^2.2.0` (NoSQL injection guard sanitizing `$` and `.` operators)
  * `hpp: ^0.2.3` (HTTP Parameter Pollution prevention)
  * `express-rate-limit: ^8.5.2` (Tiered rate limiters: strict auth brute-force protection, general API limiter, DM send quotas)
* **Reverse Proxy Trust:** `trust proxy = 1` for Ngrok and Cloudflare load balancer compatibility

### 2.3. Development & Testing Infrastructure
* **Physical Test Device:** OnePlus CPH2613 (Android 16, SDK 36) via Wireless ADB (`192.168.1.5:37707`)
* **Tunnel Endpoint:** Ngrok static development domain (`https://levitative-unpresumptuously-claire.ngrok-free.dev`)
* **Backend Dev Server:** Nodemon (`v3.1.9`)

---

## 3. High-Level System Architecture

```
                       ┌──────────────────────────────────────────────┐
                       │            GVibe Client (Flutter)            │
                       │  - Android / iOS / Web                       │
                       │  - Riverpod State Architecture               │
                       │  - FlutterSecureStorage (X25519 Private Key)  │
                       └──────────────┬───────────────────────────────┘
                                      │
                 HTTPS (REST API)     │     WSS (Socket.io)
                 Bearer JWT Auth      │     Token Handshake Auth
                                      ▼
                       ┌──────────────────────────────────────────────┐
                       │           GVibe Backend (Express.js)         │
                       │  - Reverse Proxy / Ngrok Tunnels             │
                       │  - Helmet / Sanitizer / Rate Limiters        │
                       │  - JWT Verification Middleware               │
                       │  - Socket.io Realtime Service Engine         │
                       └──────────────┬───────────────────────────────┘
                                      │
                                      ▼
                       ┌──────────────────────────────────────────────┐
                       │            MongoDB Database (Atlas)          │
                       │  - Users & X25519 Public Keys                │
                       │  - Posts, Vibes & Comments                   │
                       │  - E2EE Message Store (Ciphertext Only)      │
                       │  - Communities & Group Chats                 │
                       │  - Live Locations (TTL Auto-Expiry)          │
                       │  - Short Links & Visitor Analytics           │
                       └──────────────────────────────────────────────┘
```

### 3.1. Cryptographic Security Model (E2EE DMs)
1. **Key Generation:** When a user logs in, the client checks `FlutterSecureStorage` for an existing X25519 keypair. If none exists, it generates a fresh keypair using the `cryptography` package.
2. **Key Storage:** The private key **never leaves the device**. It is stored in hardware-backed secure storage namespaced by user ID (`gvibe_chat_private_key_v1_$uid`).
3. **Key Registration:** The corresponding X25519 public key is uploaded to the backend via `PUT /api/messages/keys/public`.
4. **Message Encryption:** Outgoing direct messages perform Diffie-Hellman key exchange (ECDH) against the recipient's public key to derive a symmetric shared secret, then encrypt the message using ChaCha20-Poly1305.
5. **Zero-Knowledge Backend:** The server only stores and routes `{ ciphertext, nonce, mac, senderPublicKey, receiverPublicKey }`. The server cannot inspect or decrypt direct messages.
6. **Key Rotation Resilience:** Every DM payload explicitly carries `senderPublicKey` and `receiverPublicKey`, ensuring past and future messages remain decryptable even if keys are rotated.

---

## 4. Database Models & Schema Specifications

The MongoDB database contains 9 specialized schemas:

### 4.1. `User`
* **Campus Identity:** `name`, `username`, `email` (strictly `@student.gitam.edu`), `registrationNumber` (extracted from student name via regex), `isVerified` (read-only, set server-side), `profileComplete`, `tempProfileData`.
* **Academic Profile:** `dob`, `branch`, `academicLevel`, `dept`, `year`, `interests` (array), `bio`, `avatar`, `level`.
* **Social Connections:** `followers` and `following` (User ObjectId references).
* **E2EE Public Key:** `publicKey.x25519`, `publicKey.updatedAt`.
* **Presence & Privacy:** `lastSeen`, `privacy` (`public` or `private`).

### 4.2. `Post`
* **Content:** `author` (ref User), `content` (up to 2,000 characters), `type` (`text`, `image`, `video`).
* **Categorization:** `category` (`general`, `lost_found`, `ride_share`, `teammate`).
* **Social Metrics:** `likes` (array of User ObjectIds), `comments` (embedded subdocuments with user ref and text), `tags` (lowercase strings), `sharesCount`, `viewsCount`.
* **Indexes:** Compound index on `{ category: 1, createdAt: -1 }` and `{ tags: 1, createdAt: -1 }`.

### 4.3. `Vibe`
* Micro-status updates / quick thoughts (up to 1,000 characters).
* Embedded media URLs, like arrays, threaded comments.
* Indexed chronologically on `{ createdAt: -1 }`.

### 4.4. `Community`
* **Identity:** `name` (unique), `handle` (unique, lowercase), `description`, `avatar`, `banner`.
* **Access Control:** `isPrivate` (boolean), `inviteCode` (populated when private), `creator` (User ref).
* **Memberships:** `members` array containing `{ user, role, joinedAt }` where roles include `owner`, `admin`, and `member`.
* **Counters:** Incremental atomic counters `memberCount` and `messageCount`.
* **Indexes:** Text search index on `name` and `description`; compound discovery index on `{ isPrivate: 1, memberCount: -1 }`.

### 4.5. `Message`
* **Addressing:** `sender` (User ref), `receiver` (User ref for DMs), `community` (Community ref for group chat).
* **Plaintext Payload:** `content` (used for community messages).
* **E2EE Payload:** `ciphertext`, `nonce`, `mac`, `senderPublicKey`, `receiverPublicKey`.
* **Status:** `read` (boolean for DMs), `readBy` (array of User refs for community), `deletedAt` (soft-delete).
* **Indexes:** Compound query indexes on `{ sender: 1, receiver: 1, createdAt: -1 }` and `{ community: 1, createdAt: -1 }`.

### 4.6. `LostItem`
* **Item Details:** `title`, `description`, `status` (`lost` or `found`), `category` (10 campus categories: `electronics`, `id_cards`, `keys`, `wallet`, `clothing`, `books`, `bags`, `jewellery`, `sports`, `other`).
* **Location & Imagery:** Campus location description, Cloudinary image URLs.
* **Resolution:** `isResolved` (boolean), `resolvedAt`, `resolvedBy`.

### 4.7. `LiveLocation`
* **Session Details:** `liveCode` (unique 6-character alphanumeric code), `user`, `userName`, `userAvatar`.
* **Coordinates:** `latitude`, `longitude`, `accuracy`, `history` (recent breadcrumb points capped at 100).
* **Lifecycle:** `durationMinutes` (5 to 1440 mins), `expiresAt`, `isActive`, `viewsCount`.
* **Public Route:** Served via `/live/:code` with an interactive web UI.

### 4.8. `ShortLink`
* **Shortener Engine:** 6-character unique code (`shortCode`), `destinationUrl`, `creator`, optional `postId`.
* **Clickstream Analytics:** `totalClicks`, `uniqueVisitors` (SHA-256 hash of IP + User-Agent), `uniqueVisitorCount`.
* **Device & Client Breakdown:** Devices (`android`, `iphone`, `desktop`, `other`), browsers (`chrome`, `safari`, `firefox`, `edge`, `other`), referrers (`LinkedIn`, `WhatsApp`, `Google`, `X`, `Direct`, etc.), and top countries.
* **Redirection Route:** `/s/:code` with automatic HTTP 302 redirect and async background tracking.

### 4.9. `UserAnalytics`
* **Profile Metrics:** `profileViews` (total and unique visitor hashes), `searchAppearances`, `profileClicks`, `sharesCount`, `linkClicks`, `followersGained`.
* **Discovery Search Queries:** `searchTagsFound` map recording which keyword tags led to discovery.
* **Timeline Graph:** `viewsHistory` array storing daily view counts (`YYYY-MM-DD`).

---

## 5. Comprehensive Feature Breakdown

### 5.1. Authentication & Campus Security
* **Campus Domain Restriction:** Enforces `@student.gitam.edu` email registration.
* **Server-Side Identity Verification:** Automatically extracts student registration numbers from Google Profile names matching `^(.*?)\s+(\d{10})$` and grants `isVerified: true` securely on the server to prevent client-side bypass.
* **Onboarding & Step-by-Step Profile Creation:** Multi-step wizard collecting branch, year, interests, and bio with temporary progress persistence.

### 5.2. Campus Feed & Categorized Micro-Blogging
* **Category Filters:** Filter posts by All, General, Lost & Found, Ride Share, and Teammates.
* **Rich Markdown & Discord-Style Links:** Supports custom hyperlinks and formatting inside post cards.
* **Engagements:** Real-time like counters, threaded comments modal sheet, share modal with dynamic short links and QR codes.

### 5.3. Real-Time Chat & Communities
* **End-to-End Encrypted Direct Messages:** Zero-knowledge transmission, instant optimistic message rendering on sender UI, delivery receipts, typing indicators, and presence broadcast scoped strictly to followers.
* **Campus Communities:** Public and private groups with role management (Owner, Admin, Member), invite codes, and real-time group chat rooms.

### 5.4. Campus Utility Features
* **Lost & Found Hub:** Dedicated portal to report, discover, filter, and resolve lost or found items on campus grounds.
* **Auto-Expiring Live Location:** Real-time geosharing with customizable expiration. Generates a sharable link (`/live/:code`) that displays an interactive map or an expired notice when time elapses.
* **Link Shortener & Social Analytics:** Built-in URL shortener providing in-depth audience demographics (devices, browsers, sources, countries).
* **Creator & Profile Analytics:** Personal dashboard tracking profile impressions, search presence, and follower growth over time.

### 5.5. UI/UX Design System
* **Dual Design Palettes:**
  * **Dark Mode:** Deep slate/zinc aesthetic inspired by Linear (`#08090A` background, `#121316` surface, `#5E6AD2` indigo accent).
  * **Light Mode:** High-contrast crisp aesthetic inspired by Vercel (`#FEFEFE` background, `#FFFFFF` cards, `#0070F3` electric blue accent).
* **Responsive Layouts:** Overflow-safe widgets, adaptive Google Sign-In buttons across web and mobile, and smooth custom navigation transitions.
