/**
 * lost_item.controller.js
 * Handles all Lost & Found CRUD with search, filter, and pagination.
 */

const LostItem = require('../models/LostItem');

const PAGE_SIZE = 20;

// ── GET /api/lost-items  ──────────────────────────────────────────────────────
// Query params: status, category, q (full-text), resolved, before (cursor id)
exports.getItems = async (req, res) => {
  try {
    const { status, category, q, resolved, before } = req.query;

    const filter = {};

    if (status && ['lost', 'found'].includes(status))       filter.status = status;
    if (category)                                           filter.category = category;
    if (resolved !== undefined)                             filter.isResolved = resolved === 'true';

    // Full-text search takes priority; otherwise use the indexed sort path
    if (q && q.trim()) {
      filter.$text = { $search: q.trim() };
    }

    // Cursor-based pagination
    if (before) {
      const pivot = await LostItem.findById(before).select('createdAt').lean();
      if (pivot) filter.createdAt = { $lt: pivot.createdAt };
    }

    const sortBy = q?.trim() ? { score: { $meta: 'textScore' } } : { createdAt: -1 };
    const projection = q?.trim() ? { score: { $meta: 'textScore' } } : {};

    const items = await LostItem.find(filter, projection)
      .sort(sortBy)
      .limit(PAGE_SIZE)
      .populate('author', 'name avatar branch year')
      .lean();

    res.json({
      success: true,
      data: items,
      hasMore: items.length === PAGE_SIZE,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── GET /api/lost-items/mine  ─────────────────────────────────────────────────
exports.getMyItems = async (req, res) => {
  try {
    const items = await LostItem.find({ author: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json({ success: true, data: items });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── GET /api/lost-items/:id  ──────────────────────────────────────────────────
exports.getItemById = async (req, res) => {
  try {
    const item = await LostItem.findById(req.params.id)
      .populate('author', 'name avatar branch year')
      .lean();
    if (!item) return res.status(404).json({ success: false, message: 'Item not found' });
    res.json({ success: true, data: item });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── POST /api/lost-items  ─────────────────────────────────────────────────────
exports.createItem = async (req, res) => {
  try {
    const { title, description, status, category, location, images } = req.body;

    if (!title?.trim()) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }
    if (!['lost', 'found'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Status must be "lost" or "found"' });
    }

    const item = await LostItem.create({
      author:      req.user.id,
      title:       title.trim(),
      description: description?.trim() || '',
      status,
      category:    category || 'other',
      location:    location?.trim() || '',
      images:      Array.isArray(images) ? images.slice(0, 5) : [],
    });

    const populated = await LostItem.findById(item._id)
      .populate('author', 'name avatar branch year')
      .lean();

    res.status(201).json({ success: true, data: populated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── PUT /api/lost-items/:id  ──────────────────────────────────────────────────
// Only author can edit
exports.updateItem = async (req, res) => {
  try {
    const item = await LostItem.findById(req.params.id);
    if (!item) return res.status(404).json({ success: false, message: 'Item not found' });
    if (item.author.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not your post' });
    }

    const allowed = ['title', 'description', 'category', 'location', 'images', 'status'];
    allowed.forEach(key => {
      if (req.body[key] !== undefined) item[key] = req.body[key];
    });

    await item.save();
    res.json({ success: true, data: item });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── PUT /api/lost-items/:id/resolve  ─────────────────────────────────────────
// Mark as returned/claimed — only author
exports.resolveItem = async (req, res) => {
  try {
    const item = await LostItem.findById(req.params.id);
    if (!item) return res.status(404).json({ success: false, message: 'Item not found' });
    if (item.author.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not your post' });
    }

    item.isResolved = true;
    item.resolvedAt = new Date();
    await item.save();

    res.json({ success: true, data: item });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── DELETE /api/lost-items/:id  ───────────────────────────────────────────────
exports.deleteItem = async (req, res) => {
  try {
    const item = await LostItem.findById(req.params.id);
    if (!item) return res.status(404).json({ success: false, message: 'Item not found' });
    if (item.author.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not your post' });
    }

    await item.deleteOne();
    res.json({ success: true, message: 'Post deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
