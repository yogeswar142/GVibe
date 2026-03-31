const User = require('../models/User');

// GET /api/users — list all users (for discovery)
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({ _id: { $ne: req.user.id } })
      .select('name avatar dept year bio level followers following')
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({ success: true, data: users });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/users/profile — own profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/users/profile — update own profile
exports.updateProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.name = req.body.name || user.name;
    user.dept = req.body.dept || user.dept;
    user.year = req.body.year || user.year;
    user.bio = req.body.bio !== undefined ? req.body.bio : user.bio;
    user.avatar = req.body.avatar || user.avatar;

    if (req.body.password) {
      user.password = req.body.password;
    }

    const updatedUser = await user.save();
    
    res.json({
      success: true,
      data: {
        _id: updatedUser._id,
        name: updatedUser.name,
        email: updatedUser.email,
        dept: updatedUser.dept,
        year: updatedUser.year,
        bio: updatedUser.bio,
        avatar: updatedUser.avatar,
        level: updatedUser.level,
      }
    });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/users/:id — get any user's public profile
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const isFollowing = user.followers.includes(req.user.id);

    res.json({
      success: true,
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        dept: user.dept,
        year: user.year,
        bio: user.bio,
        avatar: user.avatar,
        level: user.level,
        followersCount: user.followers.length,
        followingCount: user.following.length,
        isFollowing,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/users/:id/follow — toggle follow / unfollow
exports.toggleFollow = async (req, res) => {
  try {
    if (req.params.id === req.user.id.toString()) {
      return res.status(400).json({ success: false, message: 'You cannot follow yourself' });
    }

    const targetUser = await User.findById(req.params.id);
    if (!targetUser) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentUser = await User.findById(req.user.id);
    const isFollowing = targetUser.followers.includes(req.user.id);

    if (isFollowing) {
      // Unfollow
      targetUser.followers = targetUser.followers.filter(
        (id) => id.toString() !== req.user.id.toString()
      );
      currentUser.following = currentUser.following.filter(
        (id) => id.toString() !== req.params.id
      );
    } else {
      // Follow
      targetUser.followers.push(req.user.id);
      currentUser.following.push(req.params.id);
    }

    await targetUser.save();
    await currentUser.save();

    res.json({
      success: true,
      data: {
        isFollowing: !isFollowing,
        followersCount: targetUser.followers.length,
        followingCount: targetUser.following.length,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/users/:id/followers
exports.getFollowers = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('followers', 'name avatar bio dept year level');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: user.followers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/users/:id/following
exports.getFollowing = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('following', 'name avatar bio dept year level');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: user.following });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
