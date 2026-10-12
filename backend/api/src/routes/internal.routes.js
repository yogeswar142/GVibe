/**
 * routes/internal.routes.js
 *
 * Internal routes consumed exclusively by the Cloudflare Worker.
 * All routes are protected by the internalAuth middleware (x-internal-secret header).
 *
 * These routes are NOT rate-limited by express-rate-limit because:
 *  1. They are only reachable by the Worker (secret-guarded).
 *  2. Traffic volume is bounded by Cloudflare's own queue throughput.
 *
 * Mount point in app.js: app.use('/internal', internalRoutes)
 */

const express = require('express');
const router = express.Router();

const { internalAuth } = require('../middleware/internal.middleware');
const {
  resolveShortLink,
  recordLinkClick,
  getLiveLocationForWorker,
} = require('../controllers/internal.controller');

// Worker → API: resolve a short code to its destination URL (for KV population)
router.get('/resolve/link/:code', internalAuth, resolveShortLink);

// Queue consumer → API: write batched click analytics durably to MongoDB
router.post('/analytics/link-click', internalAuth, recordLinkClick);

// Worker → API: fetch live session metadata (NO coordinates returned)
router.get('/live/:code', internalAuth, getLiveLocationForWorker);

module.exports = router;
