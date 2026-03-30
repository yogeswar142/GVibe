const Message = require('../models/Message');
const Community = require('../models/Community');

// Get Direct Messages with a specific user
exports.getDMs = async (req, res) => {
  try {
    const { userId } = req.params;
    
    const messages = await Message.find({
      $or: [
        { sender: req.user.id, receiver: userId },
        { sender: userId, receiver: req.user.id }
      ]
    })
    .sort({ createdAt: 1 }) // Chronological order
    .populate('sender', 'name avatar')
    .populate('receiver', 'name avatar');

    res.json({ success: true, data: messages });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Send a Direct Message
exports.sendDM = async (req, res) => {
  try {
    const { receiverId, content } = req.body;

    if (!receiverId || !content) {
      return res.status(400).json({ success: false, message: 'Receiver and content are required' });
    }

    const message = await Message.create({
      sender: req.user.id,
      receiver: receiverId,
      content
    });

    const populatedMessage = await Message.findById(message._id)
      .populate('sender', 'name avatar')
      .populate('receiver', 'name avatar');

    res.status(201).json({ success: true, data: populatedMessage });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Create a new Community
exports.createCommunity = async (req, res) => {
  try {
    const { name, description } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'Community name is required' });
    }

    const communityExists = await Community.findOne({ name });
    if (communityExists) {
      return res.status(400).json({ success: false, message: 'Community name already taken' });
    }

    const community = await Community.create({
      name,
      description,
      creator: req.user.id,
      members: [req.user.id] // Creator is the first member
    });

    res.status(201).json({ success: true, data: community });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all Communities User is part of
exports.getMyCommunities = async (req, res) => {
  try {
    const communities = await Community.find({ members: req.user.id });
    res.json({ success: true, data: communities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get Messages for a Community
exports.getCommunityMessages = async (req, res) => {
  try {
    const { communityId } = req.params;

    // Check if user is a member
    const community = await Community.findById(communityId);
    if (!community) {
      return res.status(404).json({ success: false, message: 'Community not found' });
    }
    
    if (!community.members.includes(req.user.id)) {
      return res.status(403).json({ success: false, message: 'Not a member of this community' });
    }

    const messages = await Message.find({ community: communityId })
      .sort({ createdAt: 1 })
      .populate('sender', 'name avatar');

    res.json({ success: true, data: messages });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Send a Message to a Community
exports.sendCommunityMessage = async (req, res) => {
  try {
    const { communityId, content } = req.body;

    if (!communityId || !content) {
      return res.status(400).json({ success: false, message: 'Community ID and content are required' });
    }

    // Verify membership
    const community = await Community.findById(communityId);
    if (!community || !community.members.includes(req.user.id)) {
      return res.status(403).json({ success: false, message: 'Not authorized or community not found' });
    }

    const message = await Message.create({
      sender: req.user.id,
      community: communityId,
      content
    });

    const populatedMessage = await Message.findById(message._id).populate('sender', 'name avatar');

    res.status(201).json({ success: true, data: populatedMessage });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Join a Community
exports.joinCommunity = async (req, res) => {
  try {
    const { communityId } = req.params;

    const community = await Community.findById(communityId);
    if (!community) {
      return res.status(404).json({ success: false, message: 'Community not found' });
    }

    if (!community.members.includes(req.user.id)) {
      community.members.push(req.user.id);
      await community.save();
    }

    res.json({ success: true, data: community });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
