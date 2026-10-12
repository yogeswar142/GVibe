const express = require('express');
const {
  getTrendingVibes,
  discoverPeople,
  getTrendingTags,
  getPostsByTag,
  discoverCommunities,
  unifiedSearch
} = require('../controllers/discovery.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/trending', getTrendingVibes);
router.get('/people', discoverPeople);
router.get('/communities', discoverCommunities);
router.get('/tags/trending', getTrendingTags);
router.get('/tags/:tag/posts', getPostsByTag);
router.get('/search', unifiedSearch);

module.exports = router;
