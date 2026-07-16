const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide a name'],
    trim: true,
  },
  username: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'Please provide an email'],
    unique: true,
  },
  password: {
    type: String,
    required: false,
    minlength: 6,
    select: false,
  },
  googleId: { type: String, unique: true, sparse: true },
  registrationNumber: { type: String, trim: true },
  isVerified: { type: Boolean, default: false },
  profileComplete: { type: Boolean, default: false },
  tempProfileData: {
    type: Object,
    default: null
  },
  tempProfileUpdatedAt: {
    type: Date,
    default: null
  },
  dob: { type: String, trim: true },
  branch: { type: String, trim: true },
  academicLevel: { type: String, trim: true },
  interests: [{ type: String }],
  dept: { type: String, trim: true },
  year: { type: String, trim: true },
  bio: { type: String, default: '', maxlength: 500 },
  avatar: { type: String, default: '' },
  level: { type: Number, default: 1 },
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  // E2EE: X25519 public key uploaded by the Flutter client at login.
  // The matching private key is stored ONLY in FlutterSecureStorage on-device.
  publicKey: {
    x25519: { type: String, default: null },
    updatedAt: { type: Date, default: null },
  },

  // Socket.io presence (last seen, used for "Online" indicators)
  lastSeen: { type: Date, default: null },

  // Privacy setting: public or private
  privacy: { type: String, enum: ['public', 'private'], default: 'public' },

}, { timestamps: true });

// Compound text index for search optimization
userSchema.index({ name: 'text', username: 'text', dept: 'text', interests: 'text' });

// Hash password before saving if present
userSchema.pre('save', async function (next) {
  if (!this.password || !this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare user password
userSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password) return false;
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
