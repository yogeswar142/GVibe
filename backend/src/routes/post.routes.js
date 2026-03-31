const express = require('express');
const { getPosts, createPost, toggleLike, addComment } = require('../controllers/post.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getPosts)
  .post(createPost);

router.put('/:id/like', toggleLike);
router.post('/:id/comment', addComment);

module.exports = router;
