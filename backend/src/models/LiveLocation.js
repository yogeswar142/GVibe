const mongoose = require('mongoose');

const liveLocationSchema = new mongoose.Schema({
  liveCode: {
    type: String,
    required: true,
    unique: true,
    index: true,
    trim: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  userName: {
    type: String,
    default: 'GVibe Student',
  },
  userAvatar: {
    type: String,
    default: '',
  },
  latitude: {
    type: Number,
    required: true,
  },
  longitude: {
    type: Number,
    required: true,
  },
  accuracy: {
    type: Number,
    default: 0,
  },
  durationMinutes: {
    type: Number,
    default: 60,
  },
  expiresAt: {
    type: Date,
    required: true,
    index: true,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  lastUpdatedAt: {
    type: Date,
    default: Date.now,
  },
  viewsCount: {
    type: Number,
    default: 0,
  },
  history: [{
    latitude: Number,
    longitude: Number,
    timestamp: {
      type: Date,
      default: Date.now,
    },
  }],
}, {
  timestamps: true,
});

// TTL index: clean up expired live location documents 24 hours after expiration
liveLocationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 86400 });

module.exports = mongoose.model('LiveLocation', liveLocationSchema);
