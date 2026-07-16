/**
 * message.controller.js
 * REST endpoints (complementing real-time socket events):
 *  - Paginated DM & community history fetch
 *  - Community CRUD (create, join, leave, list, search)
 *  - Public key upload/fetch for E2EE DMs
 */

const Message = require('../models/Message');
const Community = require('../models/Community');
const User = require('../models/User');

const PAGE_SIZE = 30; // messages per page (cursor-based)

// ─── DIRECT MESSAGES ─────────────────────────────────────────────────────────

/**
 * GET /api/messages/dms/:userId?before=<messageId>
 * Cursor-based: pass `before` param to fetch older messages (infinite scroll).
 */
exports.getDMs = async (req, res) => {
  try {
    const { userId } = req.params;
    const { before } = req.query;

    const filter = {
      deletedAt: null,
      $or: [
        { sender: req.user.id, receiver: userId },
        { sender: userId,      receiver: req.user.id },
      ],
    };

    if (before) {
      const pivot = await Message.findById(before).select('createdAt').lean();
      if (pivot) filter.createdAt = { $lt: pivot.createdAt };
    }

    const messages = await Message.find(filter)
      .sort({ createdAt: -1 })           // newest first → client reverses
      .limit(PAGE_SIZE)
      .select('sender receiver ciphertext nonce mac read senderPublicKey receiverPublicKey createdAt')
      .populate('sender', 'name avatar')
      .lean();

    res.json({ success: true, data: messages.reverse(), hasMore: messages.length === PAGE_SIZE });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/messages/conversations
 * Returns the latest DM per conversation partner (inbox preview).
 * Uses aggregation with $group — called rarely (once per inbox open), so fine.
 */
exports.getConversations = async (req, res) => {
  try {
    const uid = req.user._id;

    // Fetch the list of users this user is connected with (following or followed by)
    const currentUser = await User.findById(uid).select('followers following privacy').lean();
    if (!currentUser) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const convos = await Message.aggregate([
      { 
        $match: { 
          deletedAt: null, 
          community: null, // DMs only — exclude community messages from inbox
          $or: [
            { sender: uid },
            { receiver: uid }
          ] 
        } 
      },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $cond: [{ $lt: ['$sender', '$receiver'] },
              { a: '$sender', b: '$receiver' },
              { a: '$receiver', b: '$sender' }]
          },
          lastMessage: { $first: '$$ROOT' },
        },
      },
      { $replaceRoot: { newRoot: '$lastMessage' } },
      { $sort: { createdAt: -1 } },
      { $limit: 50 },
    ]);

    await Message.populate(convos, { path: 'sender receiver', select: 'name avatar lastSeen followers following' });

    // Filter out conversations where sender or receiver is null (user was deleted)
    const validConvos = convos.filter(c => c.sender && c.receiver);

    // Check mutual follower relationship for each convo if privacy is private
    const myFollowersSet = new Set((currentUser.followers || []).map(id => id.toString()));
    const myFollowingSet = new Set((currentUser.following || []).map(id => id.toString()));

    if (currentUser.privacy === 'private') {
      validConvos.sort((a, b) => {
        const partnerAObj = a.sender._id.toString() === uid.toString() ? a.receiver : a.sender;
        const partnerBObj = b.sender._id.toString() === uid.toString() ? b.receiver : b.sender;

        if (!partnerAObj || !partnerBObj) return 0;

        const partnerAId = partnerAObj._id.toString();
        const partnerBId = partnerBObj._id.toString();

        const isFriendA = myFollowersSet.has(partnerAId) && myFollowingSet.has(partnerAId);
        const isFriendB = myFollowersSet.has(partnerBId) && myFollowingSet.has(partnerBId);

        if (isFriendA && !isFriendB) return -1;
        if (!isFriendA && isFriendB) return 1;

        // If both are friends or both are not, sort by latest message time
        return new Date(b.createdAt) - new Date(a.createdAt);
      });
    }

    res.json({ success: true, data: validConvos });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─── COMMUNITIES ─────────────────────────────────────────────────────────────

/**
 * POST /api/messages/communities
 */
exports.createCommunity = async (req, res) => {
  try {
    const { name, description, isPrivate } = req.body;

    if (!name) return res.status(400).json({ success: false, message: 'Community name is required' });

    const exists = await Community.exists({ name });
    if (exists) return res.status(400).json({ success: false, message: 'Community name already taken' });

    const inviteCode = isPrivate
      ? Math.random().toString(36).substring(2, 10).toUpperCase()
      : null;

    const community = await Community.create({
      name,
      description,
      isPrivate: !!isPrivate,
      inviteCode,
      creator: req.user.id,
      members: [{ user: req.user.id, role: 'owner' }],
      memberCount: 1,
    });

    res.status(201).json({ success: true, data: community });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/messages/communities  — communities this user belongs to
 */
exports.getMyCommunities = async (req, res) => {
  try {
    const communities = await Community.find(
      { 'members.user': req.user.id },
      { name: 1, handle: 1, avatar: 1, description: 1, memberCount: 1, isPrivate: 1, updatedAt: 1 }
    ).sort({ updatedAt: -1 }).lean();

    res.json({ success: true, data: communities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/messages/communities/search?q=<query>
 */
exports.searchCommunities = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.json({ success: true, data: [] });

    const communities = await Community.find(
      { $text: { $search: q }, isPrivate: false },
      { score: { $meta: 'textScore' }, name: 1, avatar: 1, description: 1, memberCount: 1 }
    ).sort({ score: { $meta: 'textScore' } }).limit(20).lean();

    res.json({ success: true, data: communities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PUT /api/messages/communities/:communityId/join
 * Public join (or invite-code join for private)
 */
exports.joinCommunity = async (req, res) => {
  try {
    const { communityId } = req.params;
    const { inviteCode } = req.body;

    const community = await Community.findById(communityId);
    if (!community) return res.status(404).json({ success: false, message: 'Community not found' });

    if (community.isPrivate && community.inviteCode !== inviteCode) {
      return res.status(403).json({ success: false, message: 'Invalid invite code' });
    }

    const alreadyMember = community.members.some(m => m.user.toString() === req.user.id);
    if (!alreadyMember) {
      community.members.push({ user: req.user.id, role: 'member' });
      community.memberCount += 1;
      await community.save();
    }

    res.json({ success: true, data: { _id: community._id, name: community.name } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * PUT /api/messages/communities/:communityId/leave
 */
exports.leaveCommunity = async (req, res) => {
  try {
    const { communityId } = req.params;

    const community = await Community.findById(communityId);
    if (!community) return res.status(404).json({ success: false, message: 'Community not found' });

    const memberIndex = community.members.findIndex(m => m.user.toString() === req.user.id);
    if (memberIndex === -1) return res.status(400).json({ success: false, message: 'Not a member' });

    if (community.members[memberIndex].role === 'owner') {
      return res.status(400).json({ success: false, message: 'Owner cannot leave. Transfer ownership first.' });
    }

    community.members.splice(memberIndex, 1);
    community.memberCount = Math.max(0, community.memberCount - 1);
    await community.save();

    res.json({ success: true, message: 'Left community' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/messages/communities/:communityId/messages?before=<messageId>
 * Cursor-based paginated community message history.
 */
exports.getCommunityMessages = async (req, res) => {
  try {
    const { communityId } = req.params;
    const { before } = req.query;

    // Membership check (lean for speed)
    const isMember = await Community.exists({ _id: communityId, 'members.user': req.user.id });
    if (!isMember) return res.status(403).json({ success: false, message: 'Not a member' });

    const filter = { community: communityId, deletedAt: null };

    if (before) {
      const pivot = await Message.findById(before).select('createdAt').lean();
      if (pivot) filter.createdAt = { $lt: pivot.createdAt };
    }

    const messages = await Message.find(filter)
      .sort({ createdAt: -1 })
      .limit(PAGE_SIZE)
      .select('sender content createdAt')
      .populate('sender', 'name avatar')
      .lean();

    res.json({ success: true, data: messages.reverse(), hasMore: messages.length === PAGE_SIZE });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─── E2EE PUBLIC KEY ─────────────────────────────────────────────────────────

/**
 * PUT /api/messages/keys/public
 * Flutter uploads the user's X25519 public key after generating it locally.
 */
exports.uploadPublicKey = async (req, res) => {
  try {
    const { x25519 } = req.body;
    if (!x25519) return res.status(400).json({ success: false, message: 'x25519 key required' });

    await User.findByIdAndUpdate(req.user.id, {
      'publicKey.x25519': x25519,
      'publicKey.updatedAt': new Date(),
    });

    res.json({ success: true, message: 'Public key saved' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * GET /api/messages/keys/:userId
 * Fetch another user's public key so we can encrypt a DM for them.
 */
exports.getPublicKey = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('publicKey').lean();
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    res.json({ success: true, data: user.publicKey });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─── COMMUNITY MEMBER MANAGEMENT ENDPOINTS ───────────────────────────────────

exports.getCommunityDetails = async (req, res) => {
  try {
    const { communityId } = req.params;
    // verify if user is member
    const isMember = await Community.exists({ _id: communityId, 'members.user': req.user.id });
    if (!isMember) return res.status(403).json({ success: false, message: 'Not a member of this community' });

    const community = await Community.findById(communityId)
      .populate('members.user', 'name username avatar bio dept year followers following level')
      .lean();

    if (!community) return res.status(404).json({ success: false, message: 'Community not found' });

    res.json({ success: true, data: community });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.kickCommunityMember = async (req, res) => {
  try {
    const { communityId, userId } = req.params;
    const community = await Community.findById(communityId);
    if (!community) return res.status(404).json({ success: false, message: 'Community not found' });

    // Check caller's role (caller must be owner or admin/moderator)
    const callerMember = community.members.find(m => m.user.toString() === req.user.id);
    if (!callerMember || (callerMember.role !== 'owner' && callerMember.role !== 'admin')) {
      return res.status(403).json({ success: false, message: 'Only owners or moderators can kick members' });
    }

    // Find target member
    const targetIndex = community.members.findIndex(m => m.user.toString() === userId);
    if (targetIndex === -1) {
      return res.status(400).json({ success: false, message: 'User is not a member' });
    }

    const targetMember = community.members[targetIndex];
    
    // Prevent admin from kicking owner or another admin
    if (callerMember.role === 'admin' && (targetMember.role === 'owner' || targetMember.role === 'admin')) {
      return res.status(403).json({ success: false, message: 'Moderators cannot kick the owner or other moderators' });
    }
    // Prevent owner from kicking themselves
    if (targetMember.role === 'owner') {
      return res.status(400).json({ success: false, message: 'Owner cannot be kicked' });
    }

    community.members.splice(targetIndex, 1);
    community.memberCount = Math.max(0, community.members.length);
    await community.save();

    res.json({ success: true, message: 'Member kicked successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateMemberRole = async (req, res) => {
  try {
    const { communityId, userId } = req.params;
    const { role } = req.body; // 'admin' or 'member'

    if (!['admin', 'member'].includes(role)) {
      return res.status(400).json({ success: false, message: 'Invalid role' });
    }

    const community = await Community.findById(communityId);
    if (!community) return res.status(404).json({ success: false, message: 'Community not found' });

    // Caller must be owner to change roles
    const callerMember = community.members.find(m => m.user.toString() === req.user.id);
    if (!callerMember || callerMember.role !== 'owner') {
      return res.status(403).json({ success: false, message: 'Only the owner can update roles' });
    }

    const targetMember = community.members.find(m => m.user.toString() === userId);
    if (!targetMember) {
      return res.status(400).json({ success: false, message: 'User is not a member' });
    }

    if (targetMember.role === 'owner') {
      return res.status(400).json({ success: false, message: 'Cannot change the owner\'s role' });
    }

    targetMember.role = role;
    await community.save();

    res.json({ success: true, message: `Member role updated to ${role}` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * POST /api/messages/debug/log-decrypt-failure
 * Logs detailed client-side E2EE decryption failure context on the server.
 */
exports.logDecryptFailure = async (req, res) => {
  try {
    const { messageId, remotePartyId, remotePartyPublicKey, myPublicKeyUsed, errorDetails } = req.body;
    
    // Fetch current keys/names for debugging comparison
    const me = await User.findById(req.user.id).select('publicKey name').lean();
    const remote = await User.findById(remotePartyId).select('publicKey name').lean();

    console.error(`\n🔒 [E2EE Decrypt Failure Report]`);
    console.error(`   - Reporter: ${me?.name || 'Unknown'} (${req.user.id})`);
    console.error(`   - Reporter Current DB Pub Key: ${me?.publicKey?.x25519 || 'none'}`);
    console.error(`   - Reporter Local Pub Key Used: ${myPublicKeyUsed || 'none'}`);
    console.error(`   - Partner: ${remote?.name || 'Unknown'} (${remotePartyId})`);
    console.error(`   - Partner Current DB Pub Key: ${remote?.publicKey?.x25519 || 'none'}`);
    console.error(`   - Partner Pub Key Used by Reporter: ${remotePartyPublicKey || 'none'}`);
    console.error(`   - Message ID: ${messageId}`);
    console.error(`   - Error Details: ${errorDetails || 'none'}\n`);

    res.json({ success: true, message: 'Failure reported successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
