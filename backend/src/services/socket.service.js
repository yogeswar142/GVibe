/**
 * socket.service.js
 * Initialises Socket.io on the http.Server and manages:
 *  - JWT-authenticated connections
 *  - Direct Message (E2EE) events
 *  - Community / Group chat events
 *  - Presence (online / typing / last-seen)
 *
 * Design goals:
 *  - Server is stateless: messages are persisted to MongoDB then emitted.
 *  - Each user joins a personal room (userId) so we can target them across
 *    multiple tabs / devices without a Redis adapter (fine for MVP scale).
 *  - Community rooms follow pattern: `community:<communityId>`
 *  - No heavy aggregations inside socket handlers — use lean() + projections.
 */

const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Message = require('../models/Message');
const Community = require('../models/Community');

let io; // exported so REST controllers can emit when needed

// ─── Server-level per-user rate limit buckets ─────────────────────────────────
// Keyed by userId string so multi-device users share the same bucket.
const _dmBuckets  = new Map(); // userId → { count, resetAt }
const _comBuckets = new Map(); // userId → { count, resetAt }

const _checkUserLimit = (bucketsMap, userId, max) => {
  const now = Date.now();
  let bucket = bucketsMap.get(userId);
  if (!bucket || now >= bucket.resetAt) {
    bucket = { count: 0, resetAt: now + 60_000 };
    bucketsMap.set(userId, bucket);
  }
  bucket.count += 1;
  return bucket.count <= max;
};

// ─── JWT Auth Middleware for Socket.io ────────────────────────────────────────
const socketAuthMiddleware = async (socket, next) => {
  try {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Authentication error: no token'));

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('_id name avatar publicKey');
    if (!user) return next(new Error('Authentication error: user not found'));

    socket.user = user;
    next();
  } catch (err) {
    next(new Error('Authentication error: invalid token'));
  }
};

// ─── Init ─────────────────────────────────────────────────────────────────────
const initSocket = (httpServer) => {
  // ── Allowed origins: same list as Express CORS ──────────────────────────
  const rawOrigins = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map(o => o.trim())
    .filter(Boolean);
  const allowedOrigins = new Set([
    'http://localhost:3000',
    'http://10.0.2.2:5000',
    'https://levitative-unpresumptuously-claire.ngrok-free.dev',
    ...rawOrigins,
  ]);

  io = new Server(httpServer, {
    cors: {
      origin: (origin, callback) => {
        // Mobile apps send no origin — always allow
        if (!origin || allowedOrigins.has(origin)) return callback(null, true);
        callback(new Error(`Socket CORS: origin '${origin}' not allowed`));
      },
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  io.use(socketAuthMiddleware);

  io.on('connection', async (socket) => {
    const userId = socket.user._id.toString();
    console.log(`🟢 Socket connected: ${socket.user.name} (${userId})`);

    // ── Rate limiting: server-level per-user buckets (BUG-09 fix) ───────────
    // Using shared server-level maps so multiple devices share one quota.
    const checkLimit = (bucketsMap, max) => _checkUserLimit(bucketsMap, userId, max);

    // ── Personal room: targetable from REST handlers too ──────────────────
    socket.join(userId);

    // ── Mark user online ──────────────────────────────────────────────────
    await User.findByIdAndUpdate(userId, { lastSeen: null }); // null = online
    // BUG-07 fix: emit presence only to this user's followers, not everyone
    try {
      const self = await User.findById(userId).select('followers').lean();
      (self?.followers ?? []).forEach(fid => {
        io.to(fid.toString()).emit('user:online', { userId });
      });
      // Also notify the user themselves (useful for multi-device)
      io.to(userId).emit('user:online', { userId });
    } catch (_) {
      // Non-critical — swallow presence emit errors
    }

    // ── Rejoin all community rooms this user belongs to ───────────────────
    const communities = await Community.find(
      { 'members.user': userId },
      { _id: 1 }
    ).lean();
    communities.forEach(c => socket.join(`community:${c._id}`));

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: dm:send
    // Payload: { receiverId, ciphertext, nonce, mac }
    // The server stores the opaque ciphertext and forwards it — never reads it.
    // ─────────────────────────────────────────────────────────────────────
    socket.on('dm:send', async (data, ack) => {
      try {
        if (!checkLimit(_dmBuckets, 30)) {
          return ack?.({ success: false, error: 'Rate limit: slow down (30 DMs/min max)' });
        }
        const { receiverId, ciphertext, nonce, mac } = data;

        if (!receiverId || !ciphertext || !nonce || !mac) {
          return ack?.({ success: false, error: 'Missing required fields' });
        }

        // Persist encrypted payload
        const message = await Message.create({
          sender: userId,
          receiver: receiverId,
          ciphertext,
          nonce,
          mac,
        });

        console.log(`💬 [Socket] DM sent by ${socket.user.name} (${userId}) to ${receiverId}`);

        const payload = {
          _id: message._id,
          sender: { _id: socket.user._id, name: socket.user.name, avatar: socket.user.avatar },
          receiverId,
          ciphertext,
          nonce,
          mac,
          createdAt: message.createdAt,
        };

        // Emit to receiver's personal room (works across their devices)
        io.to(receiverId).emit('dm:receive', payload);

        // Confirm to sender
        ack?.({ success: true, data: payload });
      } catch (err) {
        console.error('dm:send error:', err.message);
        ack?.({ success: false, error: 'Server error' });
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: dm:read
    // Marks all unread messages from a sender as read
    // ─────────────────────────────────────────────────────────────────────
    socket.on('dm:read', async ({ senderId }) => {
      if (!senderId) return;
      await Message.updateMany(
        { sender: senderId, receiver: userId, read: false },
        { $set: { read: true } }
      );
      // Notify sender their messages were read
      io.to(senderId).emit('dm:read_ack', { readBy: userId });
    });

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: dm:typing
    // Lightweight ephemeral event — no DB write
    // ─────────────────────────────────────────────────────────────────────
    socket.on('dm:typing', ({ receiverId, isTyping }) => {
      if (!receiverId) return;
      io.to(receiverId).emit('dm:typing', { senderId: userId, isTyping });
    });

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: community:send
    // Community messages are plaintext (moderatable, searchable).
    // ─────────────────────────────────────────────────────────────────────
    socket.on('community:send', async (data, ack) => {
      try {
        if (!checkLimit(_comBuckets, 60)) {
          return ack?.({ success: false, error: 'Rate limit: slow down (60 messages/min max)' });
        }
        const { communityId, content } = data;

        if (!communityId || !content?.trim()) {
          return ack?.({ success: false, error: 'Missing required fields' });
        }

        // Verify membership with a lean query (no full doc load)
        const isMember = await Community.exists({
          _id: communityId,
          'members.user': userId,
        });
        if (!isMember) {
          return ack?.({ success: false, error: 'Not a member of this community' });
        }

        const message = await Message.create({
          sender: userId,
          community: communityId,
          content: content.trim(),
        });

        console.log(`💬 [Socket] Community message sent by ${socket.user.name} (${userId}) to community ${communityId}`);

        // Increment counter without loading full doc
        await Community.findByIdAndUpdate(communityId, { $inc: { messageCount: 1 } });

        const payload = {
          _id: message._id,
          sender: { _id: socket.user._id, name: socket.user.name, avatar: socket.user.avatar },
          communityId,
          content: message.content,
          createdAt: message.createdAt,
        };

        // Broadcast to everyone in the community room (including sender)
        io.to(`community:${communityId}`).emit('community:receive', payload);
        ack?.({ success: true, data: payload });
      } catch (err) {
        console.error('community:send error:', err.message);
        ack?.({ success: false, error: 'Server error' });
      }
    });

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: community:typing
    // ─────────────────────────────────────────────────────────────────────
    socket.on('community:typing', ({ communityId, isTyping }) => {
      if (!communityId) return;
      socket.to(`community:${communityId}`).emit('community:typing', {
        senderId: userId,
        senderName: socket.user.name,
        isTyping,
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: community:join_room
    // Called when the user navigates into a community screen
    // ─────────────────────────────────────────────────────────────────────
    socket.on('community:join_room', ({ communityId }) => {
      if (!communityId) return;
      socket.join(`community:${communityId}`);
    });

    // ─────────────────────────────────────────────────────────────────────
    // EVENT: disconnect
    // ─────────────────────────────────────────────────────────────────────
    socket.on('disconnect', async () => {
      console.log(`🔴 Socket disconnected: ${socket.user.name} (${userId})`);
      const lastSeen = new Date();
      await User.findByIdAndUpdate(userId, { lastSeen });
      // BUG-07 fix: emit offline presence only to this user's followers
      try {
        const self = await User.findById(userId).select('followers').lean();
        (self?.followers ?? []).forEach(fid => {
          io.to(fid.toString()).emit('user:offline', { userId, lastSeen });
        });
        io.to(userId).emit('user:offline', { userId, lastSeen });
      } catch (_) {
        // Non-critical
      }
    });
  });

  console.log('⚡ Socket.io initialised');
  return io;
};

// Export io so REST controllers can emit (e.g., push notifications)
const getIO = () => {
  if (!io) throw new Error('Socket.io not initialised');
  return io;
};

module.exports = { initSocket, getIO };
