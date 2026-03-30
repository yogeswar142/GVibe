const Vibe = require('../models/Vibe');

exports.getFeed = async (req, res) => {
  try {
    // Basic feed: Latest vibes from everyone
    const vibes = await Vibe.find()
      .populate('author', 'name avatar dept')
      .sort({ createdAt: -1 })
      .limit(50);
      
    res.json({ success: true, data: vibes });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createVibe = async (req, res) => {
  try {
    const { post, media } = req.body;
    
    if (!post) {
      return res.status(400).json({ success: false, message: 'Post content is required' });
    }

    const vibe = await Vibe.create({
      author: req.user.id,
      post,
      media: media || []
    });

    const populatedVibe = await Vibe.findById(vibe._id).populate('author', 'name avatar dept');

    res.status(201).json({ success: true, data: populatedVibe });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.toggleLike = async (req, res) => {
  try {
    const vibe = await Vibe.findById(req.params.id);
    if (!vibe) {
      return res.status(404).json({ success: false, message: 'Vibe not found' });
    }

    const alreadyLiked = vibe.likes.includes(req.user.id);

    if (alreadyLiked) {
      vibe.likes = vibe.likes.filter(id => id.toString() !== req.user.id.toString());
    } else {
      vibe.likes.push(req.user.id);
    }

    await vibe.save();
    res.json({ success: true, data: vibe });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.addComment = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    const vibe = await Vibe.findById(req.params.id);
    if (!vibe) {
      return res.status(404).json({ success: false, message: 'Vibe not found' });
    }

    const comment = {
      user: req.user.id,
      text
    };

    vibe.comments.push(comment);
    await vibe.save();
    
    const updatedVibe = await Vibe.findById(vibe._id).populate('comments.user', 'name avatar');

    res.status(201).json({ success: true, data: updatedVibe });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
