const UserAnalytics = require('../models/UserAnalytics');
const ShortLink = require('../models/ShortLink');
const Post = require('../models/Post');

// GET /api/analytics/me — 100% Real, Dynamic User & Content Analytics
exports.getMyAnalytics = async (req, res) => {
  try {
    const userId = req.user.id;

    // 1. Fetch or initialize UserAnalytics document
    let analytics = await UserAnalytics.findOne({ user: userId });
    if (!analytics) {
      analytics = await UserAnalytics.create({ user: userId });
    }

    // 2. Aggregate real post content metrics (views, unique viewers, likes, comments, shares)
    const posts = await Post.find({ author: userId });
    let totalViews = 0;
    let totalLikes = 0;
    let totalComments = 0;
    let totalShares = analytics.sharesCount || 0;
    const uniqueUserSet = new Set();

    posts.forEach(p => {
      totalViews += (p.viewsCount || 0);
      totalLikes += (p.likes?.length || 0);
      totalComments += (p.comments?.length || 0);
      totalShares += (p.sharesCount || 0);

      if (Array.isArray(p.likes)) {
        p.likes.forEach(id => uniqueUserSet.add(id.toString()));
      }
      if (Array.isArray(p.comments)) {
        p.comments.forEach(c => {
          if (c.user) uniqueUserSet.add(c.user.toString());
        });
      }
    });

    const uniqueViewers = uniqueUserSet.size;

    // 3. People found you for tags (only real recorded discovery tags)
    const tagMap = analytics.searchTagsFound || new Map();
    let totalTagHits = 0;
    const tagsArray = [];

    for (const [tag, count] of (tagMap instanceof Map ? tagMap.entries() : Object.entries(tagMap))) {
      totalTagHits += count;
      tagsArray.push({ tag, count });
    }

    tagsArray.sort((a, b) => b.count - a.count);
    const tagsWithPercent = tagsArray.slice(0, 5).map(item => ({
      tag: item.tag.startsWith('#') ? item.tag : `#${item.tag}`,
      percentage: totalTagHits > 0 ? Math.round((item.count / totalTagHits) * 100) : 0,
      count: item.count,
    }));

    // 4. Short links aggregated analytics (100% dynamic from DB)
    const shortLinks = await ShortLink.find({ creator: userId });
    let totalShortLinkClicks = 0;
    let totalShortLinkUniqueVisitors = 0;
    let linkClicksToday = 0;
    let linkClicksThisWeek = 0;
    let linkClicksThisMonth = 0;

    let deviceStats = { android: 0, iphone: 0, desktop: 0, other: 0 };
    let countryMap = new Map();

    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    shortLinks.forEach(link => {
      totalShortLinkClicks += (link.totalClicks || 0);
      totalShortLinkUniqueVisitors += (link.uniqueVisitorCount || 0);

      deviceStats.android += (link.devices?.android || 0);
      deviceStats.iphone += (link.devices?.iphone || 0);
      deviceStats.desktop += (link.devices?.desktop || 0);
      deviceStats.other += (link.devices?.other || 0);

      if (link.topCountries) {
        for (const [c, cnt] of (link.topCountries instanceof Map ? link.topCountries.entries() : Object.entries(link.topCountries))) {
          countryMap.set(c, (countryMap.get(c) || 0) + cnt);
        }
      }

      if (link.clicksByDate) {
        link.clicksByDate.forEach(entry => {
          const entryDate = new Date(entry.date);
          if (entry.date === todayStr) linkClicksToday += entry.count;
          if (entryDate >= sevenDaysAgo) linkClicksThisWeek += entry.count;
          if (entryDate >= thirtyDaysAgo) linkClicksThisMonth += entry.count;
        });
      }
    });

    // Real device breakdown percentages (0 if no clicks)
    const totalDeviceClicks = deviceStats.android + deviceStats.iphone + deviceStats.desktop + deviceStats.other;
    const devicePercentages = {
      android: totalDeviceClicks > 0 ? Math.round((deviceStats.android / totalDeviceClicks) * 100) : 0,
      iphone: totalDeviceClicks > 0 ? Math.round((deviceStats.iphone / totalDeviceClicks) * 100) : 0,
      desktop: totalDeviceClicks > 0 ? Math.round((deviceStats.desktop / totalDeviceClicks) * 100) : 0,
      other: totalDeviceClicks > 0 ? Math.round((deviceStats.other / totalDeviceClicks) * 100) : 0,
    };

    // Real country breakdown percentages (empty array if no clicks)
    const countryArray = [];
    let totalCountryHits = 0;
    for (const [c, cnt] of countryMap.entries()) {
      totalCountryHits += cnt;
      countryArray.push({ country: c, count: cnt });
    }
    countryArray.sort((a, b) => b.count - a.count);

    const topCountries = countryArray.slice(0, 5).map(item => {
      let flag = '🌐';
      let name = item.country;
      if (item.country === 'IN' || item.country === 'India') { flag = '🇮🇳'; name = 'India'; }
      else if (item.country === 'US' || item.country === 'USA') { flag = '🇺🇸'; name = 'USA'; }
      else if (item.country === 'GB' || item.country === 'UK') { flag = '🇬🇧'; name = 'UK'; }
      else if (item.country === 'CA') { flag = '🇨🇦'; name = 'Canada'; }
      else if (item.country === 'DE') { flag = '🇩🇪'; name = 'Germany'; }
      return {
        country: name,
        flag,
        percentage: totalCountryHits > 0 ? Math.round((item.count / totalCountryHits) * 100) : 0,
        count: item.count,
      };
    });

    // Real Click-Through Rate (CTR)
    const effectiveLinkClicks = Math.max(analytics.linkClicks || 0, totalShortLinkClicks);
    const ctr = totalViews > 0 ? ((effectiveLinkClicks / totalViews) * 100).toFixed(1) : '0.0';

    // Real profile views and clicks
    const profileViewsCount = analytics.profileViews?.total || 0;
    const searchAppearances = analytics.searchAppearances || 0;
    const profileClicks = analytics.profileClicks || 0;

    // Real recent short links
    const host = req.get('host');
    const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';
    const recentLinks = shortLinks.slice(0, 10).map(link => ({
      shortCode: link.shortCode,
      shortUrl: `${protocol}://${host}/s/${link.shortCode}`,
      destinationUrl: link.destinationUrl,
      totalClicks: link.totalClicks,
      uniqueVisitors: link.uniqueVisitorCount,
      createdAt: link.createdAt,
    }));

    res.json({
      success: true,
      data: {
        profileAnalytics: {
          profileViews: profileViewsCount,
          searchAppearances,
          profileClicks,
          tagsFound: tagsWithPercent,
        },
        contentAnalytics: {
          totalViews,
          uniqueViewers,
          totalLikes,
          totalComments,
          totalShares,
          profileVisits: profileClicks,
          followersGained: analytics.followersGained || 0,
          linkClicks: effectiveLinkClicks,
          ctr: `${ctr}%`,
        },
        shortLinkAnalytics: {
          totalShortLinks: shortLinks.length,
          totalClicks: totalShortLinkClicks,
          uniqueVisitors: totalShortLinkUniqueVisitors,
          timeBreakdown: {
            today: linkClicksToday,
            thisWeek: linkClicksThisWeek,
            thisMonth: linkClicksThisMonth,
          },
          devices: devicePercentages,
          topCountries,
          recentLinks,
        },
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/analytics/profile-view/:userId — Track profile view
exports.trackProfileView = async (req, res) => {
  try {
    const targetUserId = req.params.userId;
    if (targetUserId === req.user.id.toString()) {
      return res.json({ success: true, message: 'Self view ignored' });
    }

    const todayStr = new Date().toISOString().split('T')[0];
    const viewerHash = req.user.id.toString();

    let analytics = await UserAnalytics.findOne({ user: targetUserId });
    if (!analytics) {
      analytics = await UserAnalytics.create({ user: targetUserId });
    }

    analytics.profileViews.total += 1;
    analytics.profileClicks += 1;

    if (!analytics.profileViews.uniqueVisitors.includes(viewerHash)) {
      analytics.profileViews.uniqueVisitors.push(viewerHash);
    }

    // Views history by date
    const historyEntry = analytics.viewsHistory.find(h => h.date === todayStr);
    if (historyEntry) {
      historyEntry.views += 1;
    } else {
      analytics.viewsHistory.push({ date: todayStr, views: 1 });
    }

    await analytics.save();

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
