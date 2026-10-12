const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // ── Direct Messages ──────────────────────────────────────────────
  receiver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },

  // ── Community / Group Messages ───────────────────────────────────
  community: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Community',
    default: null,
  },

  // ── Payload ──────────────────────────────────────────────────────
  // Unified content for both DMs and Community chats (transmitted over TLS/WSS)
  content: {
    type: String,
    required: [true, 'Message content is required'],
    trim: true,
    maxlength: 4000,
  },

  // Audit trail: IP of sender at creation time (hidden from standard queries)
  ipAddress: {
    type: String,
    default: null,
    select: false,
  },

  // ── Read receipts ─────────────────────────────────────────────────
  // DM: simple boolean; Community: list of userIds who have read it
  read:   { type: Boolean, default: false },          // DM only
  readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // community

  // ── Soft delete ───────────────────────────────────────────────────
  deletedAt: { type: Date, default: null },

}, { timestamps: true });

// ── Indexes ───────────────────────────────────────────────────────────
// Fetch DM conversation (most common query): O(log n) per user pair
messageSchema.index({ sender: 1, receiver: 1, createdAt: -1 });
messageSchema.index({ receiver: 1, sender: 1, createdAt: -1 });

// Fetch community messages with cursor-based pagination
messageSchema.index({ community: 1, createdAt: -1 });

// Unread DM count badge
messageSchema.index({ receiver: 1, read: 1 });

module.exports = mongoose.model('Message', messageSchema);
