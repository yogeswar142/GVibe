const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  reporter: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  targetType: {
    type: String,
    enum: ['message', 'post', 'user', 'community'],
    required: true,
  },
  targetId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true,
  },
  reason: {
    type: String,
    required: true,
    trim: true,
    maxlength: 500,
  },
  details: {
    type: String,
    trim: true,
    maxlength: 2000,
    default: '',
  },
  // Immutable snapshot captured at the moment the report was filed
  snapshot: {
    content: { type: String, default: null },
    authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    authorIp: { type: String, default: null },
    authorDeviceInfo: { type: String, default: null },
    targetCreatedAt: { type: Date, default: null },
  },
  reporterIp: {
    type: String,
    default: null,
    select: false,
  },
  status: {
    type: String,
    enum: ['pending', 'reviewed', 'resolved', 'dismissed'],
    default: 'pending',
    index: true,
  },
  reviewedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  resolutionNotes: {
    type: String,
    default: null,
  },
}, { timestamps: true });

reportSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Report', reportSchema);
