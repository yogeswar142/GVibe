const mongoose = require('mongoose');

const shortLinkSchema = new mongoose.Schema({
  shortCode: {
    type: String,
    required: true,
    unique: true,
    index: true,
    trim: true,
  },
  destinationUrl: {
    type: String,
    required: [true, 'Destination URL is required'],
    trim: true,
  },
  creator: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  postId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Post',
    default: null,
  },
  totalClicks: {
    type: Number,
    default: 0,
  },
  uniqueVisitors: [{
    type: String, // SHA-256 hash of IP + User-Agent
  }],
  uniqueVisitorCount: {
    type: Number,
    default: 0,
  },
  devices: {
    android: { type: Number, default: 0 },
    iphone: { type: Number, default: 0 },
    desktop: { type: Number, default: 0 },
    other: { type: Number, default: 0 },
  },
  browsers: {
    chrome: { type: Number, default: 0 },
    safari: { type: Number, default: 0 },
    firefox: { type: Number, default: 0 },
    edge: { type: Number, default: 0 },
    other: { type: Number, default: 0 },
  },
  topCountries: {
    type: Map,
    of: Number,
    default: {},
  },
  referrers: {
    type: Map,
    of: Number,
    default: {},
  },
  clicksByDate: [{
    date: { type: String }, // 'YYYY-MM-DD'
    count: { type: Number, default: 0 },
  }],
  firstClickedAt: {
    type: Date,
    default: null,
  },
  lastClickedAt: {
    type: Date,
    default: null,
  },
}, { timestamps: true });

shortLinkSchema.index({ creator: 1, createdAt: -1 });

module.exports = mongoose.model('ShortLink', shortLinkSchema);
