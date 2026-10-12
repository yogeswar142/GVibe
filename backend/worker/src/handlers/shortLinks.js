/**
 * handlers/shortLinks.js
 *
 * Handles GET /s/:code
 *
 * Flow:
 *  1. Look up shortCode in Cloudflare KV (O(1), edge-cached).
 *  2a. KV HIT  → 302 redirect immediately, then enqueue analytics event
 *               to ANALYTICS_QUEUE (durable, retried up to 3×).
 *  2b. KV MISS → fetch /internal/resolve/link/:code from the API,
 *               cache result in KV with 24-hour TTL,
 *               302 redirect, then enqueue analytics event.
 *  3.  Code not found in API → return branded 404 HTML.
 *
 * Analytics durability notes (free plan):
 *  - Cloudflare Queues is available on the Free plan (as of Feb 2026).
 *  - Free quota: 10,000 operations/day (3 ops per message = ~3,333 events/day).
 *  - Message retention: 24 hours on free plan.
 *  - On queue failure the runtime retries up to max_retries (3) before
 *    moving the message to a dead-letter state — no silent drops.
 *  - If ANALYTICS_QUEUE.send() itself throws (extremely rare), we log the
 *    error and continue — the redirect still succeeds. This is the only
 *    possible data-loss scenario on the free tier and is documented below.
 */

import { parseDevice, parseBrowser, parseReferrer, computeVisitorHash } from '../utils/geo.js';

/** Branded 404 HTML page returned when a short code is unknown. */
const notFoundHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <title>Link Not Found - GVibe</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;text-align:center;padding:50px 20px;background:#0B0F17;color:#fff;">
  <h1 style="color:#6366F1;font-size:36px;margin-bottom:8px;">GVibe</h1>
  <h2 style="font-weight:500;">Link Not Found</h2>
  <p style="color:#8E9BAE;">This shortened link is either invalid or has expired.</p>
</body>
</html>`;

/**
 * Main handler for /s/:code
 * @param {Request} request
 * @param {object} env  — Cloudflare bindings (SHORT_LINKS_KV, ANALYTICS_QUEUE, INTERNAL_SECRET, API_BASE_URL)
 * @param {ExecutionContext} ctx
 * @returns {Promise<Response>}
 */
export async function handleShortLink(request, env, ctx) {
  const url = new URL(request.url);
  // pathname = '/s/abc123'  →  code = 'abc123'
  const code = url.pathname.replace(/^\/s\//, '').split('/')[0];

  if (!code) {
    return new Response(notFoundHtml, { status: 404, headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
  }

  // ── 1. KV lookup ────────────────────────────────────────────
  let destinationUrl = null;
  let creatorId = null;

  const cached = await env.SHORT_LINKS_KV.get(code, { type: 'json' });
  if (cached) {
    destinationUrl = cached.destinationUrl;
    creatorId = cached.creatorId || null;
  } else {
    // ── 2b. KV miss: fetch from API ──────────────────────────
    try {
      const apiRes = await fetch(
        `${env.API_BASE_URL}/internal/resolve/link/${encodeURIComponent(code)}`,
        {
          headers: { 'x-internal-secret': env.INTERNAL_SECRET },
          // No CF cache — this is an authenticated internal call
          cf: { cacheEverything: false },
        }
      );

      if (apiRes.ok) {
        const body = await apiRes.json();
        destinationUrl = body.destinationUrl;
        creatorId = body.creatorId || null;

        // Cache in KV for 24 hours (short links are immutable once created)
        // expirationTtl is in seconds: 86400 = 24 hours
        ctx.waitUntil(
          env.SHORT_LINKS_KV.put(
            code,
            JSON.stringify({ destinationUrl, creatorId }),
            { expirationTtl: 86400 }
          )
        );
      }
    } catch (fetchErr) {
      console.error(`[shortLinks] API resolve error for code=${code}:`, fetchErr.message);
    }
  }

  // ── 3. Not found ────────────────────────────────────────────
  if (!destinationUrl) {
    return new Response(notFoundHtml, { status: 404, headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
  }

  // Ensure destination always has a scheme
  const destination = /^https?:\/\//i.test(destinationUrl)
    ? destinationUrl
    : `https://${destinationUrl}`;

  // ── 4. Redirect first, enqueue analytics after ──────────────
  // ctx.waitUntil ensures the queue send continues after the response
  // is sent to the user. If send() throws, we log but do NOT fail the
  // redirect. This is explicitly documented as the only possible loss
  // scenario on the free plan.
  ctx.waitUntil(enqueueClickEvent(request, env, code, creatorId));

  return Response.redirect(destination, 302);
}

/**
 * Build and enqueue a click analytics event to ANALYTICS_QUEUE.
 * Cloudflare Queues guarantees at-least-once delivery with up to 3 retries.
 *
 * @param {Request} request
 * @param {object} env
 * @param {string} code
 * @param {string|null} creatorId
 */
async function enqueueClickEvent(request, env, code, creatorId) {
  try {
    const ua = request.headers.get('user-agent') || '';
    const ip = request.headers.get('cf-connecting-ip')
      || request.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
      || '0.0.0.0';
    const referer = request.headers.get('referer') || '';

    // cf object is populated by Cloudflare's network — no extra API needed
    const country = (request.cf?.country || 'IN').toUpperCase();
    const visitorHash = await computeVisitorHash(ip, ua);
    const todayStr = new Date().toISOString().split('T')[0]; // 'YYYY-MM-DD'

    const event = {
      code,
      creatorId,
      visitorHash,
      device: parseDevice(ua),
      browser: parseBrowser(ua),
      referrer: parseReferrer(referer),
      country,
      date: todayStr,
      // timestamp helps the API detect & deduplicate retried deliveries
      timestamp: Date.now(),
    };

    await env.ANALYTICS_QUEUE.send(event);
  } catch (err) {
    // Log but don't throw — redirect already succeeded.
    // Documented limitation: this click event is lost if queue send fails.
    console.error(`[shortLinks] Failed to enqueue analytics for code=${code}:`, err.message);
  }
}
