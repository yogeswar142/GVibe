const express = require('express');
const {
  getProfile,
  updateProfile,
  getUserById,
  toggleFollow,
  getFollowers,
  getFollowing,
} = require('../controllers/user.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

// Own profile
router.route('/profile')
  .get(getProfile)
  .put(updateProfile);

// Public profile by ID
router.get('/:id', getUserById);

// Follow / unfollow toggle
router.post('/:id/follow', toggleFollow);

// Followers & following lists
router.get('/:id/followers', getFollowers);
router.get('/:id/following', getFollowing);

module.exports = router;
