const Report = require('../models/Report');
const Message = require('../models/Message');
const Post = require('../models/Post');
const User = require('../models/User');
const { getClientIp } = require('../utils/ip.util');

/**
 * POST /api/reports
 * Submit a report against a message, post, or user.
 * Captures an immutable snapshot with IP and device context for administration.
 */
exports.createReport = async (req, res) => {
  try {
    const { targetType, targetId, reason, details } = req.body;

    if (!targetType || !targetId || !reason?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'targetType, targetId, and reason are required',
      });
    }

    if (!['message', 'post', 'user', 'community'].includes(targetType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid targetType. Must be message, post, user, or community',
      });
    }

    const reporterId = req.user._id;
    const reporterIp = getClientIp(req);

    // Build immutable snapshot
    const snapshot = {};

    if (targetType === 'message') {
      const message = await Message.findById(targetId).select('+ipAddress').lean();
      if (!message) {
        return res.status(404).json({ success: false, message: 'Reported message not found' });
      }
      snapshot.content = message.content;
      snapshot.authorId = message.sender;
      snapshot.authorIp = message.ipAddress;
      snapshot.targetCreatedAt = message.createdAt;

      // Fetch sender device info if available
      const sender = await User.findById(message.sender).select('+deviceInfo').lean();
      if (sender) snapshot.authorDeviceInfo = sender.deviceInfo;
    } else if (targetType === 'post') {
      const post = await Post.findById(targetId).select('+ipAddress').lean();
      if (!post) {
        return res.status(404).json({ success: false, message: 'Reported post not found' });
      }
      snapshot.content = post.content;
      snapshot.authorId = post.author;
      snapshot.authorIp = post.ipAddress;
      snapshot.targetCreatedAt = post.createdAt;

      const author = await User.findById(post.author).select('+deviceInfo').lean();
      if (author) snapshot.authorDeviceInfo = author.deviceInfo;
    } else if (targetType === 'user') {
      const targetUser = await User.findById(targetId).select('+lastActiveIp +deviceInfo').lean();
      if (!targetUser) {
        return res.status(404).json({ success: false, message: 'Reported user not found' });
      }
      snapshot.authorId = targetUser._id;
      snapshot.authorIp = targetUser.lastActiveIp;
      snapshot.authorDeviceInfo = targetUser.deviceInfo;
      snapshot.targetCreatedAt = targetUser.createdAt;
    }

    const report = await Report.create({
      reporter: reporterId,
      targetType,
      targetId,
      reason: reason.trim(),
      details: details ? String(details).trim() : '',
      snapshot,
      reporterIp,
    });

    res.status(201).json({
      success: true,
      message: 'Report submitted successfully. Thank you for keeping GVibe safe.',
      data: { reportId: report._id },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/reports/mine
 * Get the history of reports filed by current user.
 */
exports.getMyReports = async (req, res) => {
  try {
    const reports = await Report.find({ reporter: req.user._id })
      .sort({ createdAt: -1 })
      .select('targetType targetId reason status createdAt')
      .limit(30)
      .lean();

    res.json({ success: true, data: reports });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
