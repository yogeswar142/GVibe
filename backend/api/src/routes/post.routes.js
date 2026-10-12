const express = require('express');
const {
  getPosts,
  createPost,
  toggleLike,
  getComments,
  addComment,
  deleteComment,
  sharePost,
  recordView,
  deletePost,
} = require('../controllers/post.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getPosts)
  .post(createPost);

router.delete('/:id', deletePost);
router.put('/:id/like', toggleLike);
router.post('/:id/share', sharePost);
router.post('/:id/view', recordView);

router.get('/:id/comments', getComments);
router.post('/:id/comment', addComment);
router.delete('/:postId/comments/:commentId', deleteComment);

module.exports = router;
