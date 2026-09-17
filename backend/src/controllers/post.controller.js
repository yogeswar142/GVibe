const Post = require('../models/Post');
const ShortLink = require('../models/ShortLink');
const UserAnalytics = require('../models/UserAnalytics');
const crypto = require('crypto');

const generateShortCode = () => {
  const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let code = '';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
};

const shortenUrlsInText = async (text, userId, req) => {
  if (!text) return text;
  let processed = text.trim();
  const urlRegex = /(https?:\/\/[^\s]+)/gi;
  const matchedUrls = processed.match(urlRegex) || [];

  const host = req.get('host');
  const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';

  for (const rawUrl of matchedUrls) {
    // Skip URLs already pointing to our shortlink or live location engine
    if (rawUrl.includes('/s/') || rawUrl.includes('/live/')) continue;

    let shortCode;
    let exists = true;
    while (exists) {
      shortCode = generateShortCode();
      exists = await ShortLink.findOne({ shortCode });
    }

    await ShortLink.create({
      shortCode,
      destinationUrl: rawUrl,
      creator: userId,
    });

    const shortUrl = `${protocol}://${host}/s/${shortCode}`;
    processed = processed.replace(rawUrl, shortUrl);
  }
  return processed;
};

// GET /api/posts — get all posts (newest first, optionally filtered by author or category)
exports.getPosts = async (req, res) => {
  try {
    const filter = {};
    if (req.query.author) {
      filter.author = req.query.author;
    }
    if (req.query.category && req.query.category !== 'all') {
      if (req.query.category === 'general') {
        filter.$or = [
          { category: 'general' },
          { category: null },
          { category: { $exists: false } },
        ];
      } else {
        filter.category = req.query.category;
      }
    }

    const posts = await Post.find(filter)
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar')
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({ success: true, data: posts });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/posts — create a new post with auto link shortening (Twitter/LinkedIn style)
exports.createPost = async (req, res) => {
  try {
    const { content, type, category } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: 'Post content is required' });
    }

    const processedContent = await shortenUrlsInText(content, req.user.id, req);
    const tags = (processedContent.match(/#\w+/g) || []).map(tag => tag.substring(1).toLowerCase());

    const validCategories = ['general', 'lost_found', 'ride_share', 'teammate'];
    const sanitizedCategory = category && validCategories.includes(String(category).trim().toLowerCase())
      ? String(category).trim().toLowerCase()
      : 'general';

    const post = await Post.create({
      author: req.user.id,
      content: processedContent,
      type: type || 'text',
      category: sanitizedCategory,
      tags,
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
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar');

    res.json({ success: true, data: populatedPost });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/posts/:id/comments — get post comments
exports.getComments = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('comments.user', 'name avatar dept year');

    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    res.json({ success: true, data: post.comments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/posts/:id/comment — add a comment
exports.addComment = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    const processedText = await shortenUrlsInText(text, req.user.id, req);

    post.comments.push({ user: req.user.id, text: processedText });
    await post.save();

    const updatedPost = await Post.findById(post._id)
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar dept year');

    res.status(201).json({ success: true, data: updatedPost });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/posts/:postId/comments/:commentId — delete a comment
exports.deleteComment = async (req, res) => {
  try {
    const { postId, commentId } = req.params;
    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    const comment = post.comments.id(commentId);
    if (!comment) {
      return res.status(404).json({ success: false, message: 'Comment not found' });
    }

    // Only comment author or post author can delete
    if (comment.user.toString() !== req.user.id && post.author.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this comment' });
    }

    post.comments.pull(commentId);
    await post.save();

    const updatedPost = await Post.findById(post._id)
      .populate('author', 'name avatar dept year')
      .populate('comments.user', 'name avatar dept year');

    res.json({ success: true, data: updatedPost });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/posts/:id/share — Share post and increment share analytics
exports.sharePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    post.sharesCount = (post.sharesCount || 0) + 1;
    await post.save();

    // Increment author's analytics
    await UserAnalytics.findOneAndUpdate(
      { user: post.author },
      { $inc: { sharesCount: 1 } },
      { upsert: true }
    );

    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';

    // Check if short link already exists for this post
    let shortLink = await ShortLink.findOne({ postId: post._id });
    if (!shortLink) {
      let shortCode;
      let exists = true;
      while (exists) {
        shortCode = generateShortCode();
        exists = await ShortLink.findOne({ shortCode });
      }
      shortLink = await ShortLink.create({
        shortCode,
        destinationUrl: `${protocol}://${host}/api/posts/${post._id}`,
        creator: req.user.id,
        postId: post._id,
      });
    }

    const shareUrl = `${protocol}://${host}/s/${shortLink.shortCode}`;

    res.json({
      success: true,
      data: {
        sharesCount: post.sharesCount,
        shareUrl,
        shortCode: shortLink.shortCode,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/posts/:id/view — Record post view
exports.recordView = async (req, res) => {
  try {
    await Post.findByIdAndUpdate(req.params.id, { $inc: { viewsCount: 1 } });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/posts/:id — delete a post
exports.deletePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    if (post.author.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this post' });
    }

    await Post.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Post deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
