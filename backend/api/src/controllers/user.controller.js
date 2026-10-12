const User = require('../models/User');

// GET /api/users — list all users (for discovery)
exports.getAllUsers = async (req, res) => {
  try {
    const currentUser = await User.findById(req.user.id).select('followers following');
    if (!currentUser) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const connectedUserIds = [
      ...currentUser.followers.map(id => id.toString()),
      ...currentUser.following.map(id => id.toString())
    ];
    // De-duplicate and cast to ObjectIds
    const uniqueConnectedUserIds = [...new Set(connectedUserIds)].map(id => new (require('mongoose')).Types.ObjectId(id));

    const users = await User.find({ 
      _id: { $in: uniqueConnectedUserIds } 
    })
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
    user.username = req.body.username || user.username;
    user.dept = req.body.branch || req.body.dept || user.dept;
    user.year = req.body.academicLevel || req.body.year || user.year;
    user.bio = req.body.bio !== undefined ? req.body.bio : user.bio;
    user.avatar = req.body.avatar || user.avatar;
    if (req.body.privacy !== undefined) {
      user.privacy = req.body.privacy;
    }

    // Save extra fields
    user.registrationNumber = req.body.registrationNumber || user.registrationNumber;
    user.dob = req.body.dob || user.dob;
    user.branch = req.body.branch || user.branch;
    user.academicLevel = req.body.academicLevel || user.academicLevel;
    user.interests = req.body.interests || user.interests;
    
    // Set profile as complete and clear temp state
    user.profileComplete = true;
    user.tempProfileData = null;
    user.tempProfileUpdatedAt = null;

    if (req.body.password) {
      user.password = req.body.password;
    }

    const updatedUser = await user.save();
    
    res.json({
      success: true,
      data: {
        _id: updatedUser._id,
        name: updatedUser.name,
        username: updatedUser.username,
        email: updatedUser.email,
        dept: updatedUser.dept,
        year: updatedUser.year,
        bio: updatedUser.bio,
        avatar: updatedUser.avatar,
        level: updatedUser.level,
        registrationNumber: updatedUser.registrationNumber,
        dob: updatedUser.dob,
        branch: updatedUser.branch,
        academicLevel: updatedUser.academicLevel,
        interests: updatedUser.interests,
        profileComplete: updatedUser.profileComplete,
        isVerified: updatedUser.isVerified,
        privacy: updatedUser.privacy,
      }
    });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/users/profile/temp — save temporary profile progress
exports.saveTempProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.tempProfileData = req.body.tempProfileData;
    user.tempProfileUpdatedAt = new Date();

    await user.save();

    res.json({
      success: true,
      message: 'Temporary profile progress saved successfully'
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

    // Asynchronously record profile view and click analytics
    if (req.user && req.user.id.toString() !== req.params.id) {
      setImmediate(async () => {
        try {
          const UserAnalytics = require('../models/UserAnalytics');
          const todayStr = new Date().toISOString().split('T')[0];
          const viewerHash = req.user.id.toString();
          let analytics = await UserAnalytics.findOne({ user: req.params.id });
          if (!analytics) analytics = await UserAnalytics.create({ user: req.params.id });
          analytics.profileViews.total += 1;
          analytics.profileClicks += 1;
          if (!analytics.profileViews.uniqueVisitors.includes(viewerHash)) {
            analytics.profileViews.uniqueVisitors.push(viewerHash);
          }
          const historyEntry = analytics.viewsHistory.find(h => h.date === todayStr);
          if (historyEntry) {
            historyEntry.views += 1;
          } else {
            analytics.viewsHistory.push({ date: todayStr, views: 1 });
          }
          await analytics.save();
        } catch (_) {}
      });
    }
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

      // Asynchronously increment followers gained analytics
      setImmediate(async () => {
        try {
          const UserAnalytics = require('../models/UserAnalytics');
          await UserAnalytics.findOneAndUpdate(
            { user: req.params.id },
            { $inc: { followersGained: 1 } },
            { upsert: true }
          );
        } catch (_) {}
      });
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
