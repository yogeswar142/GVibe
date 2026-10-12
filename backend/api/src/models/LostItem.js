const mongoose = require('mongoose');

const lostItemSchema = new mongoose.Schema({
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // ── Core fields ───────────────────────────────────────────────────────────
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: 120,
  },
  description: {
    type: String,
    trim: true,
    maxlength: 1000,
    default: '',
  },

  // ── Classification ────────────────────────────────────────────────────────
  status: {
    type: String,
    enum: ['lost', 'found'],
    required: true,
  },
  category: {
    type: String,
    enum: [
      'electronics',   // phone, laptop, earbuds…
      'id_cards',      // student ID, library card…
      'keys',
      'wallet',
      'clothing',
      'books',
      'bags',
      'jewellery',
      'sports',
      'other',
    ],
    default: 'other',
  },

  // ── Location ──────────────────────────────────────────────────────────────
  location: {
    type: String,
    trim: true,
    maxlength: 200,
    default: '',       // e.g. "Block-C Cafeteria", "Library 2nd floor"
  },

  // ── Images (Cloudinary URLs or empty) ────────────────────────────────────
  images: [{ type: String }],

  // ── Resolved / claimed ────────────────────────────────────────────────────
  isResolved: { type: Boolean, default: false },
  resolvedAt: { type: Date,    default: null  },

}, { timestamps: true });

// ── Indexes ───────────────────────────────────────────────────────────────────
lostItemSchema.index({ status: 1, isResolved: 1, createdAt: -1 }); // main feed
lostItemSchema.index({ category: 1, status: 1, createdAt: -1 });   // category filter
lostItemSchema.index({ author: 1, createdAt: -1 });                 // "my posts"
lostItemSchema.index({ title: 'text', description: 'text', location: 'text' }); // full-text search

module.exports = mongoose.model('LostItem', lostItemSchema);
