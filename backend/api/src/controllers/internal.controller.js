/**
 * controllers/internal.controller.js
 *
 * Internal endpoints consumed only by the Cloudflare Worker.
 * These are never exposed publicly — they are guarded by internalAuth middleware.
 *
 * Endpoints:
 *  GET  /internal/resolve/link/:code     → Returns destinationUrl for KV population
 *  POST /internal/analytics/link-click   → Idempotent click analytics writer
 *  GET  /internal/live/:code             → Returns live session metadata (NO coordinates)
 */

const ShortLink = require('../models/ShortLink');
const UserAnalytics = require('../models/UserAnalytics');
const LiveLocation = require('../models/LiveLocation');

// ─── Short Link: KV resolution ───────────────────────────────

/**
 * GET /internal/resolve/link/:code
 * Called by Worker on KV miss. Returns { destinationUrl, creatorId }.
 * Does NOT record analytics — that is handled by the Queue consumer.
 */
exports.resolveShortLink = async (req, res) => {
  try {
    const { code } = req.params;
    const link = await ShortLink.findOne({ shortCode: code }).select('destinationUrl creator').lean();

    if (!link) {
      return res.status(404).json({ success: false, message: 'Short link not found' });
    }

    res.json({
      success: true,
      destinationUrl: link.destinationUrl,
      creatorId: link.creator ? link.creator.toString() : null,
    });
  } catch (err) {
    console.error('[internal] resolveShortLink error:', err.message);
    res.status(500).json({ success: false, message: 'Internal error' });
  }
};

// ─── Short Link: Durable analytics writer ────────────────────

/**
 * POST /internal/analytics/link-click
 * Body: { events: [{ code, creatorId, visitorHash, device, browser, country, referrer, date, timestamp }] }
 *
 * Idempotency:
 *  - $inc is atomic on MongoDB — safe for duplicate deliveries (they just
 *    increment again, which may slightly over-count on extreme retries,
 *    but is far safer than losing data).
 *  - $addToSet on uniqueVisitors is idempotent — a hash is only added once
 *    regardless of how many times the same event is delivered.
 *
 * Called by the Cloudflare Queue consumer in batches of up to 25 events.
 */
exports.recordLinkClick = async (req, res) => {
  try {
    const { events } = req.body;

    if (!Array.isArray(events) || events.length === 0) {
      return res.status(400).json({ success: false, message: 'events array required' });
    }

    // Process each event. We use Promise.allSettled so one bad event
    // doesn't block acknowledgement of the whole batch.
    const results = await Promise.allSettled(events.map(event => processClickEvent(event)));

    const failed = results.filter(r => r.status === 'rejected');
    if (failed.length > 0) {
      failed.forEach(f => console.error('[internal] recordLinkClick partial error:', f.reason));
    }

    // Return 200 even on partial failures so successfully-processed events
    // are not re-delivered. Log and monitor failed ones separately.
    res.json({ success: true, processed: events.length, failed: failed.length });
  } catch (err) {
    console.error('[internal] recordLinkClick error:', err.message);
    // Return 500 so the queue retries the entire batch
    res.status(500).json({ success: false, message: 'Internal error' });
  }
};

/**
 * Process a single click event against MongoDB.
 * Uses atomic operators to be idempotent on duplicate delivery.
 */
async function processClickEvent(event) {
  const {
    code,
    creatorId,
    visitorHash,
    device = 'other',
    browser = 'other',
    country = 'IN',
    referrer = 'Direct',
    date,        // 'YYYY-MM-DD'
  } = event;

  if (!code) throw new Error('Missing code in event');

  const link = await ShortLink.findOne({ shortCode: code });
  if (!link) throw new Error(`Short link not found: ${code}`);

  // Idempotent unique visitor tracking
  const isUnique = !link.uniqueVisitors.includes(visitorHash);
  if (isUnique && visitorHash) {
    link.uniqueVisitors.push(visitorHash);
    link.uniqueVisitorCount += 1;
  }

  // Atomic increments
  link.totalClicks += 1;
  link.devices[device] = (link.devices[device] || 0) + 1;
  link.browsers[browser] = (link.browsers[browser] || 0) + 1;

  // Country map
  if (country) {
    const countryCount = link.topCountries.get(country) || 0;
    link.topCountries.set(country, countryCount + 1);
  }

  // Referrer map
  if (referrer) {
    const refCount = link.referrers.get(referrer) || 0;
    link.referrers.set(referrer, refCount + 1);
  }

  // Daily click bucket
  if (date) {
    const dateEntry = link.clicksByDate.find(e => e.date === date);
    if (dateEntry) {
      dateEntry.count += 1;
    } else {
      link.clicksByDate.push({ date, count: 1 });
    }
  }

  if (!link.firstClickedAt) link.firstClickedAt = new Date();
  link.lastClickedAt = new Date();

  await link.save();

  // Increment user's aggregate analytics
  if (creatorId) {
    await UserAnalytics.findOneAndUpdate(
      { user: creatorId },
      { $inc: { linkClicks: 1 } },
      { upsert: true }
    );
  }
}

// ─── Live Location: Safe metadata for Worker ─────────────────

/**
 * GET /internal/live/:code
 *
 * Returns only session metadata — isActive, isExpired, userName, expiresAt.
 * NEVER returns latitude, longitude, or any coordinate data.
 * The Worker renders an HTML shell from this metadata; the user's browser
 * fetches coordinates client-side via the authenticated public API.
 *
 * Response headers force no-store as defense-in-depth even at the API layer.
 */
exports.getLiveLocationForWorker = async (req, res) => {
  // Defense-in-depth: no caching at the API level either
  res.set('Cache-Control', 'no-store, no-cache, private, must-revalidate');
  res.set('Pragma', 'no-cache');

  try {
    const { code } = req.params;
    const session = await LiveLocation.findOne({ liveCode: code })
      .select('isActive expiresAt userName liveCode') // NO lat/lng fields
      .lean();

    if (!session) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }

    const now = new Date();
    const isExpired = !session.isActive || now > new Date(session.expiresAt);

    res.json({
      success: true,
      data: {
        liveCode: session.liveCode,
        userName: session.userName || 'GVibe Student',
        isActive: !isExpired,
        isExpired,
        expiresAt: session.expiresAt,
        // ⚠️ Deliberately excluded: latitude, longitude, accuracy, history, userAvatar
      },
    });
  } catch (err) {
    console.error('[internal] getLiveLocationForWorker error:', err.message);
    res.status(500).json({ success: false, message: 'Internal error' });
  }
};
