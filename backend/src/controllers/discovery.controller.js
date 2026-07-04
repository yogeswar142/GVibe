const Vibe = require('../models/Vibe');
const User = require('../models/User');
const Post = require('../models/Post');
const Community = require('../models/Community');

exports.getTrendingVibes = async (req, res) => {
  try {
    // Trending based on number of likes (simple metric)
    const vibes = await Vibe.aggregate([
      {
        $addFields: { likesCount: { $size: "$likes" } }
      },
      { $sort: { likesCount: -1, createdAt: -1 } },
      { $limit: 20 }
    ]);

    await Vibe.populate(vibes, { path: 'author', select: 'name avatar dept' });

    res.json({ success: true, data: vibes });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.discoverPeople = async (req, res) => {
  try {
    const currentUser = await User.findById(req.user.id).select('interests');
    const userInterests = currentUser?.interests || [];

    // Fetch all other users
    const allUsers = await User.find({ _id: { $ne: req.user.id } })
      .select('name username avatar dept year bio level followers following interests lastSeen')
      .lean();

    // Map each user to calculate recommendation score
    const scoredUsers = allUsers.map(user => {
      let score = 0;

      // 1. Popularity (followers count)
      const followersCount = user.followers?.length || 0;
      score += followersCount * 2; // 2 points per follower

      // 2. Activeness (lastSeen)
      if (user.lastSeen === null) {
        score += 50; // 50 points if currently online
      } else {
        const lastSeenDate = new Date(user.lastSeen);
        const diffMs = Date.now() - lastSeenDate.getTime();
        const diffHours = diffMs / (1000 * 60 * 60);
        if (diffHours < 24) {
          score += 30; // 30 points if active in the last 24h
        } else if (diffHours < 24 * 7) {
          score += 10; // 10 points if active in the last week
        }
      }

      // 3. Recommendation System: Mutual Interest Match
      const otherInterests = user.interests || [];
      const commonInterests = userInterests.filter(interest => 
        otherInterests.some(i => i.toLowerCase() === interest.toLowerCase())
      );
      score += commonInterests.length * 15; // 15 points per matching interest

      return {
        ...user,
        score,
        followersCount,
      };
    });

    // Sort by score descending
    scoredUsers.sort((a, b) => b.score - a.score);

    // Limit to top 30
    const finalUsers = scoredUsers.slice(0, 30);

    res.json({ success: true, data: finalUsers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getTrendingTags = async (req, res) => {
  try {
    const trending = await Post.aggregate([
      { $unwind: '$tags' },
      { $group: { _id: '$tags', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 15 }
    ]);
    // Format into simpler array of objects
    const formatted = trending.map(t => ({ tag: t._id, count: t.count }));
    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getPostsByTag = async (req, res) => {
  try {
    const { tag } = req.params;
    const posts = await Post.find({ tags: tag.toLowerCase() })
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar')
      .sort({ createdAt: -1 })
      .limit(50);
    res.json({ success: true, data: posts });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.discoverCommunities = async (req, res) => {
  try {
    // Return public communities
    const communities = await Community.find({ isPrivate: false })
      .select('name handle avatar banner description memberCount messageCount isPrivate')
      .sort({ memberCount: -1 })
      .limit(30);
    res.json({ success: true, data: communities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.unifiedSearch = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || !q.trim()) {
      return res.json({ success: true, data: { users: [], communities: [] } });
    }

    const regex = new RegExp(q, 'i');

    const users = await User.find({
      $and: [
        { _id: { $ne: req.user.id } },
        {
          $or: [
            { name: regex },
            { username: regex },
            { dept: regex },
            { interests: regex }
          ]
        }
      ]
    })
      .select('name username avatar dept year bio level followers following')
      .limit(20);

    const communities = await Community.find({
      isPrivate: false,
      $or: [
        { name: regex },
        { handle: regex },
        { description: regex }
      ]
    })
      .select('name handle avatar description memberCount messageCount isPrivate')
      .limit(20);

    res.json({
      success: true,
      data: {
        users,
        communities
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
