const mongoose = require('mongoose');

const vibeSchema = new mongoose.Schema({
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  post: {
    type: String,
    required: [true, 'Please add some text to your vibe'],
    maxlength: 1000,
  },
  media: [{
    type: String, // URLs to images/videos
  }],
  likes: [{ // Array of User ObjectIds who liked the vibe
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
}, { timestamps: true });

module.exports = mongoose.model('Vibe', vibeSchema);
