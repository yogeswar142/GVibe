const Post = require('../models/Post');

// GET /api/posts — get all posts (newest first)
exports.getPosts = async (req, res) => {
  try {
    const posts = await Post.find()
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar')
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({ success: true, data: posts });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/posts — create a new post
exports.createPost = async (req, res) => {
  try {
    const { content, type } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: 'Post content is required' });
    }

    const post = await Post.create({
      author: req.user.id,
      content: content.trim(),
      type: type || 'text',
    });

    const populatedPost = await Post.findById(post._id)
      .populate('author', 'name avatar dept year');

    res.status(201).json({ success: true, data: populatedPost });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/posts/:id/like — toggle like
exports.toggleLike = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    const alreadyLiked = post.likes.includes(req.user.id);

    if (alreadyLiked) {
      post.likes = post.likes.filter(id => id.toString() !== req.user.id.toString());
    } else {
      post.likes.push(req.user.id);
    }

    await post.save();

    const populatedPost = await Post.findById(post._id)
      .populate('author', 'name avatar dept year');

    res.json({ success: true, data: populatedPost });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/posts/:id/comment — add a comment
exports.addComment = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    post.comments.push({ user: req.user.id, text });
    await post.save();

    const updatedPost = await Post.findById(post._id)
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar');

    res.status(201).json({ success: true, data: updatedPost });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
