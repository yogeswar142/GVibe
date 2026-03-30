const express = require('express');
const { 
  getDMs, 
  sendDM, 
  createCommunity, 
  getMyCommunities, 
  getCommunityMessages, 
  sendCommunityMessage,
  joinCommunity 
} = require('../controllers/message.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

// Direct Messages
router.get('/dms/:userId', getDMs);
router.post('/send', sendDM);

// Communities
router.route('/communities')
  .get(getMyCommunities)
  .post(createCommunity);

router.put('/communities/:communityId/join', joinCommunity);

router.route('/communities/:communityId/messages')
  .get(getCommunityMessages)
  .post(sendCommunityMessage);

module.exports = router;
