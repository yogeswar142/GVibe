const mongoose = require('mongoose');

const globeLocationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true,
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
      required: true,
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
    },
  },
  accuracy: {
    type: Number,
    default: 0,
  },
  expiresAt: {
    type: Date,
    required: true,
    index: true,
  },
}, {
  timestamps: true,
});

// 2D sphere index for fast geospatial radius / bounding box queries
globeLocationSchema.index({ location: '2dsphere' });

// TTL index: MongoDB auto-purges stale locations when expiresAt has passed
globeLocationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('GlobeLocation', globeLocationSchema);
