const mongoose = require('mongoose');

const postSchema = new mongoose.Schema({
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  content: {
    type: String,
    required: [true, 'Post content is required'],
    maxlength: 2000,
  },
  type: {
    type: String,
    enum: ['text', 'image', 'video'],
    default: 'text',
  },
  category: {
    type: String,
    enum: ['general', 'lost_found', 'ride_share', 'teammate'],
    default: 'general',
  },
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  comments: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    }
  }],
  tags: [{
    type: String,
    lowercase: true,
    trim: true
  }],
  sharesCount: {
    type: Number,
    default: 0,
  },
  viewsCount: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

// ── Indexes ───────────────────────────────────────────────────────────────────
postSchema.index({ createdAt: -1 });
postSchema.index({ category: 1, createdAt: -1 });
postSchema.index({ tags: 1, createdAt: -1 });

module.exports = mongoose.model('Post', postSchema);
