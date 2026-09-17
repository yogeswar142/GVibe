const express = require('express');
const {
  startLiveLocation,
  updateLiveLocation,
  stopLiveLocation,
  getLiveLocationStatus,
  redirectLiveLocation,
} = require('../controllers/live_location.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

// Public dynamic redirect route: /live/:code
router.get('/public/:code', redirectLiveLocation);

// Public status query route
router.get('/:code/status', getLiveLocationStatus);

// Protected endpoints for the person sharing location
router.post('/start', protect, startLiveLocation);
router.put('/update', protect, updateLiveLocation);
router.post('/stop', protect, stopLiveLocation);

module.exports = router;
