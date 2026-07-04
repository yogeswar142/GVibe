const jwt = require('jsonwebtoken');
const User = require('../models/User');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

exports.register = async (req, res) => {
  try {
    const { name, email, password, dept, year } = req.body;

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
    const { email, name, googleId, action } = req.body;

    if (!email || !email.endsWith('@student.gitam.edu')) {
      return res.status(400).json({
        success: false,
        message: 'Only GITAM student emails (@student.gitam.edu) are allowed'
      });
    }

    let user = await User.findOne({ email });

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
        isVerified: false
      });
    } else if (action === 'login') {
      if (!user) {
        return res.status(404).json({
          success: false,
          code: 'USER_NOT_FOUND',
          message: 'No account found with this email. Please create an account first.'
        });
      }

      // Ensure googleId is mapped if not already
      if (!user.googleId) {
        user.googleId = googleId;
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
