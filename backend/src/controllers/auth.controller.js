const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '102660971528-qp48pr3151d6sit1f1bch7s4hln68fr5.apps.googleusercontent.com';
const googleClient = new OAuth2Client(CLIENT_ID);

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

exports.register = async (req, res) => {
  try {
    const { name, email, password, dept, year } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Please provide a name' });
    }
    if (!email || !email.trim()) {
      return res.status(400).json({ success: false, message: 'Please provide an email' });
    }
    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters long' });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ success: false, message: 'User already exists' });
    }

    const user = await User.create({
      name,
      email,
      password,
      dept,
      year,
    });

    if (user) {
      res.status(201).json({
        success: true,
        data: { 
          _id: user._id,
          name: user.name,
          email: user.email,
          token: generateToken(user._id),
          profileComplete: user.profileComplete,
        },
      });
    } else {
      res.status(400).json({ success: false, message: 'Invalid user data' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !email.trim()) {
      return res.status(400).json({ success: false, message: 'Please provide an email or username' });
    }
    if (!password) {
      return res.status(400).json({ success: false, message: 'Please provide a password' });
    }

    // Check for user by email OR username (handle)
    const user = await User.findOne({
      $or: [
        { email: email },
        { username: email }
      ]
    }).select('+password');

    if (user && (await user.matchPassword(password))) {
      res.json({
        success: true,
        data: {
          _id: user._id,
          name: user.name,
          username: user.username,
          email: user.email,
          token: generateToken(user._id),
          profileComplete: user.profileComplete,
        },
      });
    } else {
      res.status(401).json({ success: false, message: 'Invalid email or password' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.googleAuth = async (req, res) => {
  try {
    const { idToken, action } = req.body;

    if (!idToken) {
      return res.status(400).json({ success: false, message: 'Google ID Token is required' });
    }

    // Verify Google ID Token
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, name, sub: googleId } = payload;

    if (!email || !email.endsWith('@student.gitam.edu')) {
      return res.status(400).json({
        success: false,
        message: 'Only GITAM student emails (@student.gitam.edu) are allowed'
      });
    }

    let user = await User.findOne({ email });

    const regExp = /^(.*?)\s+(\d{10})$/;
    const isNameVerified = regExp.test(name);

    if (action === 'register') {
      if (user) {
        return res.status(400).json({
          success: false,
          code: 'USER_EXISTS',
          message: 'An account with this email already exists. Please log in.'
        });
      }

      // Create new user
      user = await User.create({
        name,
        email,
        googleId,
        profileComplete: false,
        isVerified: isNameVerified
      });
    } else if (action === 'login') {
      if (!user) {
        return res.status(404).json({
          success: false,
          code: 'USER_NOT_FOUND',
          message: 'No account found with this email. Please create an account first.'
        });
      }

      // Ensure googleId is mapped if not already, and update verification if applicable
      let updated = false;
      if (!user.googleId) {
        user.googleId = googleId;
        updated = true;
      }
      if (isNameVerified && !user.isVerified) {
        user.isVerified = true;
        updated = true;
      }
      if (updated) {
        await user.save();
      }
    } else {
      return res.status(400).json({ success: false, message: 'Invalid action' });
    }

    // Clean up tempProfileData if older than 1 day
    if (user.tempProfileData && user.tempProfileUpdatedAt) {
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      if (user.tempProfileUpdatedAt < oneDayAgo) {
        user.tempProfileData = null;
        user.tempProfileUpdatedAt = null;
        await user.save();
      }
    }

    res.json({
      success: true,
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        token: generateToken(user._id),
        profileComplete: user.profileComplete,
        tempProfileData: user.tempProfileData,
        isVerified: user.isVerified
      }
    });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
