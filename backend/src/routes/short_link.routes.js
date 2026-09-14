const express = require('express');
const {
  redirectShortLink,
  createShortLink,
  getUserShortLinks,
  getShortLinkAnalytics,
} = require('../controllers/short_link.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

// Public redirect route: /s/:code
router.get('/:code', redirectShortLink);

// Protected routes for managing and viewing links
router.post('/shorten', protect, createShortLink);
router.get('/my-links', protect, getUserShortLinks);
router.get('/:code/analytics', protect, getShortLinkAnalytics);

module.exports = router;
