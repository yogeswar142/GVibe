const crypto = require('crypto');
const LiveLocation = require('../models/LiveLocation');

// Generate 6-char unique code for live location
const generateLiveCode = () => {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz';
  let code = '';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
};

// POST /api/live-location/start
exports.startLiveLocation = async (req, res) => {
  try {
    const { latitude, longitude, accuracy = 0, durationMinutes = 60 } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required to share live location.',
      });
    }

    // Limit duration between 5 minutes and 1440 minutes (24h)
    const validDuration = Math.max(5, Math.min(Number(durationMinutes) || 60, 1440));
    const expiresAt = new Date(Date.now() + validDuration * 60 * 1000);

    let liveCode;
    let exists = true;
    while (exists) {
      liveCode = generateLiveCode();
      exists = await LiveLocation.findOne({ liveCode });
    }

    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';
    const shareUrl = `${protocol}://${host}/live/${liveCode}`;

    const session = await LiveLocation.create({
      liveCode,
      user: req.user._id,
      userName: req.user.name || 'GVibe Student',
      userAvatar: req.user.avatar || '',
      latitude,
      longitude,
      accuracy,
      durationMinutes: validDuration,
      expiresAt,
      isActive: true,
      lastUpdatedAt: new Date(),
      history: [{ latitude, longitude, timestamp: new Date() }],
    });

    res.status(201).json({
      success: true,
      data: {
        sessionId: session._id,
        liveCode,
        shareUrl,
        expiresAt,
        durationMinutes: validDuration,
        initialLatitude: latitude,
        initialLongitude: longitude,
      },
    });
  } catch (err) {
    console.error('startLiveLocation error:', err);
    res.status(500).json({ success: false, message: 'Could not start live location sharing.' });
  }
};

// PUT /api/live-location/update
exports.updateLiveLocation = async (req, res) => {
  try {
    const { liveCode, latitude, longitude, accuracy = 0 } = req.body;

    if (!liveCode || latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'liveCode, latitude, and longitude are required.',
      });
    }

    const session = await LiveLocation.findOne({ liveCode });

    if (!session) {
      return res.status(404).json({ success: false, message: 'Live location session not found.' });
    }

    if (session.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized to update this session.' });
    }

    const now = new Date();
    if (!session.isActive || now > session.expiresAt) {
      session.isActive = false;
      await session.save();
      return res.status(410).json({
        success: false,
        message: 'Live location session has already expired.',
        isExpired: true,
      });
    }

    session.latitude = latitude;
    session.longitude = longitude;
    session.accuracy = accuracy;
    session.lastUpdatedAt = now;
    session.history.push({ latitude, longitude, timestamp: now });

    // Keep history capped at 100 recent updates
    if (session.history.length > 100) {
      session.history = session.history.slice(-100);
    }

    await session.save();

    res.json({
      success: true,
      data: {
        liveCode: session.liveCode,
        latitude: session.latitude,
        longitude: session.longitude,
        lastUpdatedAt: session.lastUpdatedAt,
        expiresAt: session.expiresAt,
        remainingSeconds: Math.max(0, Math.floor((session.expiresAt - now) / 1000)),
      },
    });
  } catch (err) {
    console.error('updateLiveLocation error:', err);
    res.status(500).json({ success: false, message: 'Could not update live location.' });
  }
};

// POST /api/live-location/stop
exports.stopLiveLocation = async (req, res) => {
  try {
    const { liveCode } = req.body;
    const session = await LiveLocation.findOne({ liveCode });

    if (!session) {
      return res.status(404).json({ success: false, message: 'Session not found.' });
    }

    if (session.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized.' });
    }

    session.isActive = false;
    await session.save();

    res.json({ success: true, message: 'Live location sharing stopped.' });
  } catch (err) {
    console.error('stopLiveLocation error:', err);
    res.status(500).json({ success: false, message: 'Could not stop live location.' });
  }
};

// GET /api/live-location/:code/status (JSON status for in-app render)
exports.getLiveLocationStatus = async (req, res) => {
  try {
    const { code } = req.params;
    const session = await LiveLocation.findOne({ liveCode: code });

    if (!session) {
      return res.status(404).json({ success: false, message: 'Live location not found.' });
    }

    const now = new Date();
    const isExpired = !session.isActive || now > session.expiresAt;

    res.json({
      success: true,
      data: {
        liveCode: session.liveCode,
        userName: session.userName,
        userAvatar: session.userAvatar,
        latitude: session.latitude,
        longitude: session.longitude,
        accuracy: session.accuracy,
        lastUpdatedAt: session.lastUpdatedAt,
        expiresAt: session.expiresAt,
        isActive: !isExpired,
        isExpired,
        remainingSeconds: isExpired ? 0 : Math.max(0, Math.floor((session.expiresAt - now) / 1000)),
        viewsCount: session.viewsCount,
      },
    });
  } catch (err) {
    console.error('getLiveLocationStatus error:', err);
    res.status(500).json({ success: false, message: 'Could not retrieve status.' });
  }
};

// GET /live/:code (PUBLIC DYNAMIC REDIRECT)
exports.redirectLiveLocation = async (req, res) => {
  try {
    const { code } = req.params;
    const session = await LiveLocation.findOne({ liveCode: code });

    if (!session) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html>
          <head><title>Live Location Not Found - GVibe</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
          <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; text-align: center; padding: 60px 20px; background: #0B0F17; color: #fff;">
            <h1 style="color: #6366F1; font-size: 32px; margin-bottom: 8px;">GVibe</h1>
            <h2 style="font-weight: 500;">Link Not Found</h2>
            <p style="color: #8E9BAE;">This live location link does not exist.</p>
          </body>
        </html>
      `);
    }

    const now = new Date();
    const isExpired = !session.isActive || now > session.expiresAt;

    if (isExpired) {
      const lastUpdateStr = session.lastUpdatedAt ? new Date(session.lastUpdatedAt).toLocaleTimeString() : 'earlier';
      const mapsFallback = `https://maps.google.com/?q=${session.latitude},${session.longitude}`;

      return res.status(200).send(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Live Location Expired - GVibe</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 40px 20px; background: #0B0F17; color: #fff; text-align: center; }
              .card { max-width: 440px; margin: 40px auto; background: #131823; border: 1px solid #232B3E; border-radius: 16px; padding: 32px 24px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
              .badge { display: inline-block; padding: 6px 14px; background: rgba(239, 68, 68, 0.15); color: #EF4444; border-radius: 20px; font-weight: 600; font-size: 13px; margin-bottom: 16px; }
              h2 { margin: 0 0 10px 0; font-size: 22px; font-weight: 700; }
              p { color: #8E9BAE; font-size: 14px; line-height: 1.6; margin-bottom: 24px; }
              .btn { display: block; width: 100%; box-sizing: border-box; padding: 14px 20px; margin: 8px 0; border-radius: 10px; font-size: 14px; font-weight: 600; text-decoration: none; transition: 0.2s; }
              .btn-primary { background: #6366F1; color: #fff; }
              .btn-secondary { background: #1E2638; color: #BAC4D6; }
            </style>
          </head>
          <body>
            <div class="card">
              <div class="badge">🔴 Live Sharing Ended</div>
              <h2>Live Location Expired</h2>
              <p>
                <strong>${session.userName}</strong>'s live location sharing session has concluded.<br>
                Last known position was recorded at <strong>${lastUpdateStr}</strong>.
              </p>
              <a class="btn btn-primary" href="${mapsFallback}">View Last Known Location on Maps</a>
              <a class="btn btn-secondary" href="https://gvibe.onrender.com">Open GVibe App</a>
            </div>
          </body>
        </html>
      `);
    }

    // Increment click counter asynchronously
    setImmediate(async () => {
      try {
        session.viewsCount += 1;
        await session.save();
      } catch (_) {}
    });

    // HTTP 302 Redirect to the student's latest real-time coordinates on Google Maps
    const mapsUrl = `https://maps.google.com/?q=${session.latitude},${session.longitude}`;
    res.redirect(302, mapsUrl);
  } catch (err) {
    console.error('redirectLiveLocation error:', err);
    res.status(500).send('Error resolving live location.');
  }
};
