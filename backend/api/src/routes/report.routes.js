const express = require('express');
const { createReport, getMyReports } = require('../controllers/report.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.post('/', createReport);
router.get('/mine', getMyReports);

module.exports = router;
