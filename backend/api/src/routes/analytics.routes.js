const express = require('express');
const { getMyAnalytics, trackProfileView } = require('../controllers/analytics.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/me', getMyAnalytics);
router.post('/profile-view/:userId', trackProfileView);

module.exports = router;
