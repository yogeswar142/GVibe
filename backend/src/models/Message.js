const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  receiver: { // If this is a direct message, receiver is set. If community msg, this might be null.
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  community: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Community', // Populated if it's a community message
  },
  content: {
    type: String,
    required: true,
  },
  read: {
    type: Boolean,
    default: false,
  }
}, { timestamps: true });

module.exports = mongoose.model('Message', messageSchema);
