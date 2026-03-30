const express = require('express');
const { getTrendingVibes, discoverPeople } = require('../controllers/discovery.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/trending', getTrendingVibes);
router.get('/people', discoverPeople);

module.exports = router;
