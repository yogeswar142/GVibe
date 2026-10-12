const crypto = require('crypto');
const ShortLink = require('../models/ShortLink');
const UserAnalytics = require('../models/UserAnalytics');

// Generate unique 6-character alphanumeric code
const generateShortCode = () => {
  const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let code = '';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
};

// Helper: Determine device category from User-Agent
const parseDevice = (ua = '') => {
  const userAgent = ua.toLowerCase();
  if (/android/i.test(userAgent)) return 'android';
  if (/(iphone|ipad|ipod)/i.test(userAgent)) return 'iphone';
  if (/windows|macintosh|linux/i.test(userAgent)) return 'desktop';
  return 'other';
};

// Helper: Determine browser from User-Agent
const parseBrowser = (ua = '') => {
  const userAgent = ua.toLowerCase();
  if (/edg/i.test(userAgent)) return 'edge';
  if (/chrome|crios/i.test(userAgent) && !/edg/i.test(userAgent)) return 'chrome';
  if (/safari/i.test(userAgent) && !/chrome/i.test(userAgent)) return 'safari';
  if (/firefox|fxios/i.test(userAgent)) return 'firefox';
  return 'other';
};

// Helper: Normalize referrer
const parseReferrer = (ref = '') => {
  if (!ref || ref.trim() === '') return 'Direct';
  try {
    const url = new URL(ref);
    const host = url.hostname.toLowerCase();
    if (host.includes('linkedin')) return 'LinkedIn';
    if (host.includes('whatsapp')) return 'WhatsApp';
    if (host.includes('google')) return 'Google';
    if (host.includes('instagram')) return 'Instagram';
    if (host.includes('twitter') || host.includes('t.co') || host.includes('x.com')) return 'X';
    if (host.includes('facebook') || host.includes('fb.com')) return 'Facebook';
    if (host.includes('youtube')) return 'YouTube';
    return url.hostname.replace('www.', '');
  } catch (_) {
    return 'Other';
  }
};

// GET /s/:code — Redirect short link and record analytics
exports.redirectShortLink = async (req, res) => {
  try {
    const { code } = req.params;
    const shortLink = await ShortLink.findOne({ shortCode: code });

    if (!shortLink) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html>
          <head><title>Link Not Found - GVibe</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
          <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; text-align: center; padding: 50px 20px; background: #0B0F17; color: #fff;">
            <h1 style="color: #6366F1; font-size: 36px; margin-bottom: 8px;">GVibe</h1>
            <h2 style="font-weight: 500;">Link Not Found</h2>
            <p style="color: #8E9BAE;">This shortened link is either invalid or expired.</p>
          </body>
        </html>
      `);
    }

    const destination = shortLink.destinationUrl.startsWith('http://') || shortLink.destinationUrl.startsWith('https://')
      ? shortLink.destinationUrl
      : `https://${shortLink.destinationUrl}`;

    // Perform HTTP 302 Redirect immediately for low latency
    res.redirect(302, destination);

    // Asynchronously record click analytics without blocking the user
    setImmediate(async () => {
      try {
        const ua = req.get('user-agent') || '';
        const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.ip || req.connection.remoteAddress || '127.0.0.1';
        const visitorHash = crypto.createHash('sha256').update(`${ip}-${ua}`).digest('hex').substring(0, 16);

        const device = parseDevice(ua);
        const browser = parseBrowser(ua);
        const referrer = parseReferrer(req.get('referer'));
        const country = (req.headers['cf-ipcountry'] || req.headers['x-country-code'] || 'IN').toUpperCase();
        const todayStr = new Date().toISOString().split('T')[0];

        // Check if visitor is unique
        const isUnique = !shortLink.uniqueVisitors.includes(visitorHash);
        if (isUnique) {
          shortLink.uniqueVisitors.push(visitorHash);
          shortLink.uniqueVisitorCount += 1;
        }

        shortLink.totalClicks += 1;
        shortLink.devices[device] = (shortLink.devices[device] || 0) + 1;
        shortLink.browsers[browser] = (shortLink.browsers[browser] || 0) + 1;

        // Update country map
        const countryCount = shortLink.topCountries.get(country) || 0;
        shortLink.topCountries.set(country, countryCount + 1);

        // Update referrer map
        const refCount = shortLink.referrers.get(referrer) || 0;
        shortLink.referrers.set(referrer, refCount + 1);

        // Update clicks by date
        const dateEntry = shortLink.clicksByDate.find(entry => entry.date === todayStr);
        if (dateEntry) {
          dateEntry.count += 1;
        } else {
          shortLink.clicksByDate.push({ date: todayStr, count: 1 });
        }

        if (!shortLink.firstClickedAt) {
          shortLink.firstClickedAt = new Date();
        }
        shortLink.lastClickedAt = new Date();

        await shortLink.save();

        // Increment user's global link click analytics
        if (shortLink.creator) {
          await UserAnalytics.findOneAndUpdate(
            { user: shortLink.creator },
            { $inc: { linkClicks: 1 } },
            { upsert: true }
          );
        }
      } catch (analyticsErr) {
        console.error('Error logging short link analytics:', analyticsErr.message);
      }
    });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/links/shorten — Create a shortened URL
exports.createShortLink = async (req, res) => {
  try {
    const { destinationUrl, postId } = req.body;

    if (!destinationUrl || !destinationUrl.trim()) {
      return res.status(400).json({ success: false, message: 'destinationUrl is required' });
    }

    let shortCode;
    let exists = true;
    while (exists) {
      shortCode = generateShortCode();
      exists = await ShortLink.findOne({ shortCode });
    }

    const shortLink = await ShortLink.create({
      shortCode,
      destinationUrl: destinationUrl.trim(),
      creator: req.user.id,
      postId: postId || null,
    });

    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';
    const shortUrl = `${protocol}://${host}/s/${shortCode}`;

    res.status(201).json({
      success: true,
      data: {
        shortCode: shortLink.shortCode,
        destinationUrl: shortLink.destinationUrl,
        shortUrl,
        totalClicks: shortLink.totalClicks,
        createdAt: shortLink.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/links/my-links — Get current user's short links
exports.getUserShortLinks = async (req, res) => {
  try {
    const links = await ShortLink.find({ creator: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50);

    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';

    const formatted = links.map(link => ({
      _id: link._id,
      shortCode: link.shortCode,
      destinationUrl: link.destinationUrl,
      shortUrl: `${protocol}://${host}/s/${link.shortCode}`,
      totalClicks: link.totalClicks,
      uniqueVisitors: link.uniqueVisitorCount,
      createdAt: link.createdAt,
      lastClickedAt: link.lastClickedAt,
    }));

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/links/:code/analytics — Detailed analytics for a short link
exports.getShortLinkAnalytics = async (req, res) => {
  try {
    const { code } = req.params;
    const shortLink = await ShortLink.findOne({ shortCode: code });

    if (!shortLink) {
      return res.status(404).json({ success: false, message: 'Short link not found' });
    }

    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';

    // Calculate today, this week, this month clicks
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    let todayClicks = 0;
    let thisWeekClicks = 0;
    let thisMonthClicks = 0;

    for (const entry of shortLink.clicksByDate) {
      const entryDate = new Date(entry.date);
      if (entry.date === todayStr) todayClicks += entry.count;
      if (entryDate >= sevenDaysAgo) thisWeekClicks += entry.count;
      if (entryDate >= thirtyDaysAgo) thisMonthClicks += entry.count;
    }

    // Devices breakdown percentage
    const totalDeviceClicks = (shortLink.devices.android || 0) + (shortLink.devices.iphone || 0) + (shortLink.devices.desktop || 0) + (shortLink.devices.other || 0) || 1;
    const devicesPercent = {
      android: Math.round(((shortLink.devices.android || 0) / totalDeviceClicks) * 100),
      iphone: Math.round(((shortLink.devices.iphone || 0) / totalDeviceClicks) * 100),
      desktop: Math.round(((shortLink.devices.desktop || 0) / totalDeviceClicks) * 100),
      other: Math.round(((shortLink.devices.other || 0) / totalDeviceClicks) * 100),
    };

    // Convert top countries map to sorted array with percentages
    const countriesArray = [];
    let totalCountryClicks = 0;
    for (const [country, count] of shortLink.topCountries.entries()) {
      totalCountryClicks += count;
      countriesArray.push({ country, count });
    }
    countriesArray.sort((a, b) => b.count - a.count);
    const topCountries = countriesArray.slice(0, 5).map(c => ({
      country: c.country,
      percentage: totalCountryClicks > 0 ? Math.round((c.count / totalCountryClicks) * 100) : 0,
      count: c.count,
    }));

    // Convert referrers map to sorted array
    const referrersArray = [];
    for (const [referrer, count] of shortLink.referrers.entries()) {
      referrersArray.push({ referrer, count });
    }
    referrersArray.sort((a, b) => b.count - a.count);

    res.json({
      success: true,
      data: {
        shortCode: shortLink.shortCode,
        destinationUrl: shortLink.destinationUrl,
        shortUrl: `${protocol}://${host}/s/${shortLink.shortCode}`,
        totalClicks: shortLink.totalClicks,
        uniqueVisitors: shortLink.uniqueVisitorCount,
        timeBreakdown: {
          today: todayClicks,
          thisWeek: thisWeekClicks,
          thisMonth: thisMonthClicks,
        },
        devices: devicesPercent,
        topCountries,
        referrers: referrersArray.slice(0, 5),
        firstClickedAt: shortLink.firstClickedAt,
        lastClickedAt: shortLink.lastClickedAt,
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
