const express = require('express');
const {
  getItems,
  getMyItems,
  getItemById,
  createItem,
  updateItem,
  resolveItem,
  deleteItem,
} = require('../controllers/lost_item.controller');
const { protect }        = require('../middleware/auth.middleware');
const { messageLimiter } = require('../middleware/security.middleware'); // reuse 60/min limit for posts

const router = express.Router();
router.use(protect);

// Feed & search (GET /api/lost-items?status=lost&category=electronics&q=iphone)
router.get('/',       getItems);
router.get('/mine',   getMyItems);
router.get('/:id',    getItemById);

// Create — rate limited to prevent spam
router.post('/', messageLimiter, createItem);

// Mutations — author-only (enforced in controller)
router.put('/:id',         updateItem);
router.put('/:id/resolve', resolveItem);
router.delete('/:id',      deleteItem);

module.exports = router;
