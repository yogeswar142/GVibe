const Vibe = require('../models/Vibe');
const User = require('../models/User');

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
    // Find people in the same department as the current user, excluding themselves
    const currentUser = await User.findById(req.user.id);
    let people = await User.find({ 
      dept: currentUser.dept,
      _id: { $ne: req.user.id }
    })
    .select('name avatar dept bio year')
    .limit(20);

    // If not enough people in dept, fill with random others
    if (people.length < 5) {
      const others = await User.find({
        dept: { $ne: currentUser.dept },
        _id: { $ne: req.user.id }
      })
      .select('name avatar dept bio year')
      .limit(20 - people.length);
      people = [...people, ...others];
    }

    res.json({ success: true, data: people });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
