const express = require('express');
const {
  getDMs,
  getConversations,
  createCommunity,
  getMyCommunities,
  searchCommunities,
  getCommunityMessages,
  joinCommunity,
  leaveCommunity,
  uploadPublicKey,
  getPublicKey,
  getCommunityDetails,
  updateMemberRole,
  kickCommunityMember,
  logDecryptFailure,
} = require('../controllers/message.controller');
const { protect }         = require('../middleware/auth.middleware');
const { messageLimiter }  = require('../middleware/security.middleware');

const router = express.Router();

// All message routes require authentication
router.use(protect);

// ── Direct Messages ──────────────────────────────────────────────────────────
router.get('/conversations',          getConversations);        // inbox list
router.get('/dms/:userId',            getDMs);                  // ?before=<id>

// ── E2EE Public Keys ─────────────────────────────────────────────────────────
router.put('/keys/public',            uploadPublicKey);
router.get('/keys/:userId',           getPublicKey);
router.post('/debug/log-decrypt-failure', logDecryptFailure);

// ── Communities ──────────────────────────────────────────────────────────────
router.route('/communities')
  .get(getMyCommunities)
  .post(createCommunity);

router.get('/communities/search',                              searchCommunities);  // ?q=
router.put('/communities/:communityId/join',                   joinCommunity);
router.put('/communities/:communityId/leave',                  leaveCommunity);
router.get('/communities/:communityId/messages',               getCommunityMessages); // ?before=<id>

// ── Community Member Management ──────────────────────────────────────────────
router.get('/communities/:communityId/details',                getCommunityDetails);
router.put('/communities/:communityId/members/:userId/role',     updateMemberRole);
router.delete('/communities/:communityId/members/:userId',       kickCommunityMember);

module.exports = router;
