const mongoose = require('mongoose');
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
    const userInterests = (currentUser?.interests || []).map(i => i.toLowerCase());

    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const finalUsers = await User.aggregate([
      {
        $match: {
          _id: { $ne: new mongoose.Types.ObjectId(req.user.id) }
        }
      },
      {
        $addFields: {
          followersCount: { $size: { $ifNull: ["$followers", []] } },
          followingCount: { $size: { $ifNull: ["$following", []] } },
          commonInterests: {
            $setIntersection: [
              {
                $map: {
                  input: { $ifNull: ["$interests", []] },
                  as: "i",
                  in: { $toLower: "$$i" }
                }
              },
              userInterests
            ]
          }
        }
      },
      {
        $addFields: {
          popularityScore: { $multiply: ["$followersCount", 2] },
          activenessScore: {
            $switch: {
              branches: [
                { case: { $eq: ["$lastSeen", null] }, then: 50 },
                { case: { $gte: ["$lastSeen", oneDayAgo] }, then: 30 },
                { case: { $gte: ["$lastSeen", sevenDaysAgo] }, then: 10 }
              ],
              default: 0
            }
          },
          interestScore: {
            $multiply: [
              { $size: { $ifNull: ["$commonInterests", []] } },
              15
            ]
          }
        }
      },
      {
        $addFields: {
          score: { $add: ["$popularityScore", "$activenessScore", "$interestScore"] }
        }
      },
      {
        $sort: { score: -1, _id: 1 }
      },
      {
        $limit: 30
      },
      {
        $project: {
          name: 1,
          username: 1,
          avatar: 1,
          dept: 1,
          year: 1,
          bio: 1,
          level: 1,
          followers: 1,
          following: 1,
          interests: 1,
          lastSeen: 1,
          score: 1,
          followersCount: 1
        }
      }
    ]);

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

    // 1. Try text index search for Users
    let users = await User.find({
      $text: { $search: q },
      _id: { $ne: req.user.id }
    })
      .select('name username avatar dept year bio level followers following')
      .limit(20);

    // Fall back to regex scan if no exact word matches
    if (users.length === 0) {
      users = await User.find({
        _id: { $ne: req.user.id },
        $or: [
          { name: regex },
          { username: regex },
          { dept: regex },
          { interests: regex }
        ]
      })
        .select('name username avatar dept year bio level followers following')
        .limit(20);
    }

    // 2. Try text index search for Communities
    let communities = await Community.find({
      isPrivate: false,
      $text: { $search: q }
    })
      .select('name handle avatar description memberCount messageCount isPrivate')
      .limit(20);

    // Fall back to regex scan if no exact word matches
    if (communities.length === 0) {
      communities = await Community.find({
        isPrivate: false,
        $or: [
          { name: regex },
          { handle: regex },
          { description: regex }
        ]
      })
        .select('name handle avatar description memberCount messageCount isPrivate')
        .limit(20);
    }

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
