/**
 * handlers/liveLocation.js
 *
 * Handles GET /live/:code
 *
 * Security design (per user requirement):
 *  - The Worker NEVER embeds raw coordinates in the HTML response.
 *  - Coordinates are fetched client-side via JS from the API, authenticated
 *    by the viewer's own JWT — so they never touch the edge cache.
 *  - The Worker only fetches session metadata (isActive, isExpired, userName,
 *    expiresAt) from the API's internal endpoint.
 *  - All responses set Cache-Control: no-store, private so Cloudflare's
 *    edge cache and any intermediary CDN will never cache this page.
 *  - The API's internal endpoint also sets no-store to provide defense-in-depth.
 */

/** Common no-cache headers applied to every response from this handler. */
const NO_CACHE_HEADERS = {
  'Content-Type': 'text/html;charset=UTF-8',
  'Cache-Control': 'no-store, no-cache, private, must-revalidate',
  'Pragma': 'no-cache',
};

/**
 * Main handler for GET /live/:code
 * @param {Request} request
 * @param {object} env  — Cloudflare bindings (API_BASE_URL, INTERNAL_SECRET)
 * @returns {Promise<Response>}
 */
export async function handleLiveLocation(request, env) {
  const url = new URL(request.url);
  const code = url.pathname.replace(/^\/live\//, '').split('/')[0];

  if (!code) {
    return new Response(buildNotFoundHtml(), { status: 404, headers: NO_CACHE_HEADERS });
  }

  // ── Fetch session metadata from API (NEVER cached) ──────────
  let session = null;
  try {
    const apiRes = await fetch(
      `${env.API_BASE_URL}/internal/live/${encodeURIComponent(code)}`,
      {
        headers: { 'x-internal-secret': env.INTERNAL_SECRET },
        // Disable CF edge caching for this authenticated call
        cf: { cacheEverything: false },
      }
    );

    if (apiRes.ok) {
      const body = await apiRes.json();
      session = body.data; // { isActive, isExpired, userName, expiresAt }
    } else if (apiRes.status === 404) {
      session = null;
    }
  } catch (fetchErr) {
    console.error(`[liveLocation] API fetch error for code=${code}:`, fetchErr.message);
    return new Response(buildErrorHtml(), { status: 503, headers: NO_CACHE_HEADERS });
  }

  // ── Not found ────────────────────────────────────────────────
  if (!session) {
    return new Response(buildNotFoundHtml(), { status: 404, headers: NO_CACHE_HEADERS });
  }

  // ── Expired ──────────────────────────────────────────────────
  if (session.isExpired || !session.isActive) {
    return new Response(
      buildExpiredHtml(session.userName, session.expiresAt, env.API_BASE_URL),
      { status: 200, headers: NO_CACHE_HEADERS }
    );
  }

  // ── Active — render shell; coords fetched by client JS ───────
  // The HTML shell calls the API's PUBLIC status endpoint client-side.
  // Coordinates are NOT in this HTML at all. The user must authenticate
  // with their JWT in the Flutter app to see coordinates on the map.
  return new Response(
    buildActiveLiveHtml(code, session.userName, session.expiresAt, env.API_BASE_URL),
    { status: 200, headers: NO_CACHE_HEADERS }
  );
}

// ─── HTML Builders ────────────────────────────────────────────

function buildNotFoundHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <title>Live Location Not Found - GVibe</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>${baseStyles()}</style>
</head>
<body>
  <div class="card">
    <h1 class="brand">GVibe</h1>
    <h2>Link Not Found</h2>
    <p>This live location link does not exist.</p>
  </div>
</body>
</html>`;
}

function buildExpiredHtml(userName, expiresAt, apiBaseUrl) {
  const expiredTime = expiresAt ? new Date(expiresAt).toLocaleString() : 'earlier';
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <title>Live Location Expired - GVibe</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>${baseStyles()}</style>
</head>
<body>
  <div class="card">
    <div class="badge expired">🔴 Live Sharing Ended</div>
    <h2>${escapeHtml(userName)}'s Location</h2>
    <p>
      This live location session ended at <strong>${escapeHtml(expiredTime)}</strong>.<br>
      Last known position is no longer available via this link.
    </p>
    <a class="btn btn-secondary" href="${escapeHtml(apiBaseUrl)}">Open GVibe</a>
  </div>
</body>
</html>`;
}

/**
 * Renders an active live-location page.
 * Coordinates are NOT embedded here. The page displays a "View in app" CTA.
 * The GVibe Flutter app uses the JWT-authenticated API to show the live map.
 */
function buildActiveLiveHtml(code, userName, expiresAt, apiBaseUrl) {
  const remainingMs = expiresAt ? (new Date(expiresAt).getTime() - Date.now()) : 0;
  const remainingMin = Math.max(0, Math.floor(remainingMs / 60000));

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <title>${escapeHtml(userName)} is sharing live location - GVibe</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex, nofollow">
  <style>${baseStyles()}</style>
</head>
<body>
  <div class="card">
    <div class="badge active">🟢 Live Now</div>
    <h2>${escapeHtml(userName)} is sharing location</h2>
    <p>
      This session is active for another <strong id="countdown">${remainingMin} min</strong>.<br>
      Open the GVibe app to view their real-time location on the map.
    </p>
    <a class="btn btn-primary" href="gvibe://live/${escapeHtml(code)}">View in GVibe App</a>
    <a class="btn btn-secondary" href="${escapeHtml(apiBaseUrl)}">Download GVibe</a>
  </div>
  <script>
    // Countdown timer — purely cosmetic, no coordinates involved
    let seconds = ${Math.max(0, Math.floor(remainingMs / 1000))};
    const el = document.getElementById('countdown');
    if (el && seconds > 0) {
      setInterval(() => {
        seconds = Math.max(0, seconds - 1);
        const m = Math.floor(seconds / 60);
        const s = seconds % 60;
        el.textContent = m + ' min ' + s + 's';
        if (seconds === 0) el.textContent = 'Expired';
      }, 1000);
    }
  </script>
</body>
</html>`;
}

function buildErrorHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <title>Error - GVibe</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>${baseStyles()}</style>
</head>
<body>
  <div class="card">
    <h1 class="brand">GVibe</h1>
    <h2>Something went wrong</h2>
    <p>We could not load this live location page. Please try again in a moment.</p>
  </div>
</body>
</html>`;
}

function baseStyles() {
  return `
    *{box-sizing:border-box}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
         margin:0;padding:40px 20px;background:#0B0F17;color:#fff;text-align:center}
    .brand{color:#6366F1;font-size:32px;margin-bottom:8px}
    .card{max-width:440px;margin:40px auto;background:#131823;border:1px solid #232B3E;
          border-radius:16px;padding:32px 24px;box-shadow:0 10px 30px rgba(0,0,0,.5)}
    .badge{display:inline-block;padding:6px 14px;border-radius:20px;
           font-weight:600;font-size:13px;margin-bottom:16px}
    .badge.active{background:rgba(34,197,94,.15);color:#22C55E}
    .badge.expired{background:rgba(239,68,68,.15);color:#EF4444}
    h2{margin:0 0 10px;font-size:22px;font-weight:700}
    p{color:#8E9BAE;font-size:14px;line-height:1.6;margin-bottom:24px}
    .btn{display:block;padding:14px 20px;margin:8px 0;border-radius:10px;
         font-size:14px;font-weight:600;text-decoration:none;transition:.2s}
    .btn-primary{background:#6366F1;color:#fff}
    .btn-secondary{background:#1E2638;color:#BAC4D6}
  `;
}

/** Prevent XSS in dynamic content interpolated into HTML. */
function escapeHtml(str = '') {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
