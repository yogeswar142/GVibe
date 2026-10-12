/**
 * middleware/internal.middleware.js
 *
 * Guards all /internal/* routes with a shared secret header.
 * This is NOT JWT — it's a simpler server-to-server token
 * used exclusively for Worker → API communication.
 *
 * The secret must be identical in:
 *   - backend/api/.env  (INTERNAL_SECRET)
 *   - backend/worker/.dev.vars  (INTERNAL_SECRET)
 *   - Cloudflare Worker secrets (set via: npx wrangler secret put INTERNAL_SECRET)
 */

const internalAuth = (req, res, next) => {
  const provided = req.headers['x-internal-secret'];

  if (!provided || !process.env.INTERNAL_SECRET) {
    return res.status(403).json({ success: false, message: 'Forbidden' });
  }

  // Constant-time comparison to prevent timing attacks
  if (provided.length !== process.env.INTERNAL_SECRET.length) {
    return res.status(403).json({ success: false, message: 'Forbidden' });
  }

  // Simple byte-by-byte XOR comparison (constant-time equivalent in JS)
  let mismatch = 0;
  for (let i = 0; i < provided.length; i++) {
    mismatch |= provided.charCodeAt(i) ^ process.env.INTERNAL_SECRET.charCodeAt(i);
  }

  if (mismatch !== 0) {
    return res.status(403).json({ success: false, message: 'Forbidden' });
  }

  next();
};

module.exports = { internalAuth };
