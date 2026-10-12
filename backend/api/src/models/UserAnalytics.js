const mongoose = require('mongoose');

const userAnalyticsSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true,
  },
  profileViews: {
    total: { type: Number, default: 0 },
    uniqueVisitors: [{ type: String }],
  },
  searchAppearances: {
    type: Number,
    default: 0,
  },
  profileClicks: {
    type: Number,
    default: 0,
  },
  searchTagsFound: {
    type: Map,
    of: Number,
    default: {},
  },
  sharesCount: {
    type: Number,
    default: 0,
  },
  linkClicks: {
    type: Number,
    default: 0,
  },
  followersGained: {
    type: Number,
    default: 0,
  },
  viewsHistory: [{
    date: { type: String }, // 'YYYY-MM-DD'
    views: { type: Number, default: 0 },
  }],
}, { timestamps: true });

module.exports = mongoose.model('UserAnalytics', userAnalyticsSchema);
