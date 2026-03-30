const express = require('express');
const { getFeed, createVibe, toggleLike, addComment } = require('../controllers/vibe.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/feed', getFeed);
router.post('/', createVibe);
router.put('/:id/like', toggleLike);
router.post('/:id/comment', addComment);

module.exports = router;
