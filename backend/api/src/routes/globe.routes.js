const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const {
  upsertLocation,
  deleteLocation,
  getLocations,
  getSettings,
  updateSettings,
} = require('../controllers/globe.controller');

// All globe endpoints require valid campus student authentication
router.use(protect);

router.route('/location')
  .put(upsertLocation)
  .delete(deleteLocation);

router.get('/locations', getLocations);

router.route('/settings')
  .get(getSettings)
  .put(updateSettings);

module.exports = router;
