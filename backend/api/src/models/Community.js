const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema({
  user:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  role:      { type: String, enum: ['owner', 'admin', 'member'], default: 'member' },
  joinedAt:  { type: Date, default: Date.now },
}, { _id: false });

const communitySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Community name is required'],
    unique: true,
    trim: true,
    maxlength: 60,
  },
  handle: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
    lowercase: true,
    maxlength: 30,
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500,
    default: '',
  },
  avatar:  { type: String, default: '' },   // URL / Cloudinary public_id
  banner:  { type: String, default: '' },

  isPrivate:   { type: Boolean, default: false },   // false = anyone can join
  inviteCode:  { type: String, default: null },     // populated when isPrivate=true

  // Structured membership with roles
  members: [memberSchema],

  // Creator reference (denormalised for quick owner check)
  creator: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // Counters (incremented/decremented, never calculated via aggregation)
  memberCount:  { type: Number, default: 1 },
  messageCount: { type: Number, default: 0 },

}, { timestamps: true });

// ── Indexes ───────────────────────────────────────────────────────────
communitySchema.index({ 'members.user': 1 });      // "my communities" query
communitySchema.index({ name: 'text', description: 'text' }); // search
communitySchema.index({ isPrivate: 1, memberCount: -1 });      // public discovery sorted by size

module.exports = mongoose.model('Community', communitySchema);
