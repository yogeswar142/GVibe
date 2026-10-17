const GlobeLocation = require('../models/GlobeLocation');
const User = require('../models/User');

// GITAM Visakhapatnam Campus official landmarks
const CAMPUS_LANDMARKS = [
  {
    id: 'campus_ict_bhavan',
    name: 'GITAM ICT Bhavan',
    lat: 17.7818,
    lng: 83.3768,
    type: 'event',
    avatarUrl: '',
    subtitle: 'Campus Tech Hub & Laboratories',
  },
  {
    id: 'campus_krc_library',
    name: 'Knowledge Resource Centre (KRC)',
    lat: 17.7809,
    lng: 83.3765,
    type: 'event',
    avatarUrl: '',
    subtitle: 'Central Library & Group Study Halls',
  },
  {
    id: 'campus_oat',
    name: 'Open Air Theatre (OAT)',
    lat: 17.7825,
    lng: 83.3789,
    type: 'event',
    avatarUrl: '',
    subtitle: 'Cultural Events & Campus Fest Venue',
  },
  {
    id: 'campus_food_court',
    name: 'GITAM Food Court',
    lat: 17.7831,
    lng: 83.3772,
    type: 'event',
    avatarUrl: '',
    subtitle: 'Student Cafeterias & Social Hangouts',
  },
  {
    id: 'campus_indoor_stadium',
    name: 'GITAM Indoor Stadium',
    lat: 17.7801,
    lng: 83.3749,
    type: 'event',
    avatarUrl: '',
    subtitle: 'Sports Complex, Arena & Gym',
  },
];

/**
 * PUT /api/globe/location
 * Upsert the caller's location with rounded coordinates and 6-hour TTL.
 */
const upsertLocation = async (req, res) => {
  try {
    const { latitude, longitude, accuracy } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required.',
      });
    }

    const lat = Number(latitude);
    const lng = Number(longitude);

    if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinate values.',
      });
    }

    // Preserve privacy by rounding coordinates to 3 decimal places (~111m)
    const roundedLat = Math.round(lat * 1000) / 1000;
    const roundedLng = Math.round(lng * 1000) / 1000;

    // 6-hour TTL expiry
    const expiresAt = new Date(Date.now() + 6 * 60 * 60 * 1000);

    // Ensure user has opted in
    await User.findByIdAndUpdate(req.user._id, {
      globeSharingEnabled: true,
    });

    const locationDoc = await GlobeLocation.findOneAndUpdate(
      { userId: req.user._id },
      {
        userId: req.user._id,
        location: {
          type: 'Point',
          coordinates: [roundedLng, roundedLat],
        },
        accuracy: Number(accuracy) || 0,
        expiresAt,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    return res.status(200).json({
      success: true,
      message: 'Location updated successfully.',
      data: {
        lat: roundedLat,
        lng: roundedLng,
        expiresAt: locationDoc.expiresAt,
      },
    });
  } catch (error) {
    console.error('[GlobeController] upsertLocation error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update globe location.',
    });
  }
};

/**
 * DELETE /api/globe/location
 * Immediately disable sharing and purge caller's location document.
 */
const deleteLocation = async (req, res) => {
  try {
    await GlobeLocation.deleteOne({ userId: req.user._id });
    await User.findByIdAndUpdate(req.user._id, {
      globeSharingEnabled: false,
    });

    return res.status(200).json({
      success: true,
      message: 'Location sharing disabled and removed.',
    });
  } catch (error) {
    console.error('[GlobeController] deleteLocation error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to remove globe location.',
    });
  }
};

/**
 * GET /api/globe/locations
 * Return visible friends and campus event/landmark markers.
 */
const getLocations = async (req, res) => {
  try {
    const callerId = req.user._id;

    // Load caller's network relations
    const me = await User.findById(callerId)
      .select('followers following')
      .lean();

    const myFollowers = new Set((me.followers || []).map(id => id.toString()));
    const myFollowing = new Set((me.following || []).map(id => id.toString()));

    // Query active non-expired location documents
    const activeLocations = await GlobeLocation.find({
      expiresAt: { $gt: new Date() },
    })
      .populate('userId', 'name username avatar globeSharingEnabled globeVisibleTo followers following')
      .limit(200)
      .lean();

    const resultMarkers = [];

    for (const record of activeLocations) {
      const target = record.userId;
      if (!target || !target.globeSharingEnabled) continue;

      const targetIdStr = target._id.toString();
      const isSelf = targetIdStr === callerId.toString();

      if (isSelf) {
        resultMarkers.push({
          id: targetIdStr,
          name: target.name + ' (You)',
          avatarUrl: target.avatar,
          lat: record.location.coordinates[1],
          lng: record.location.coordinates[0],
          type: 'self',
          subtitle: 'Your active location',
        });
        continue;
      }

      // Check visibility mode configured by target
      const visibility = target.globeVisibleTo || 'mutual';
      const targetFollowers = new Set((target.followers || []).map(id => id.toString()));
      const targetFollowing = new Set((target.following || []).map(id => id.toString()));

      let isAllowed = false;

      if (visibility === 'everyone') {
        isAllowed = true;
      } else if (visibility === 'followers') {
        // Allowed if caller follows target
        isAllowed = myFollowing.has(targetIdStr) || targetFollowers.has(callerId.toString());
      } else {
        // 'mutual' (DEFAULT): Allowed ONLY IF both users follow each other
        const callerFollowsTarget = myFollowing.has(targetIdStr) || targetFollowers.has(callerId.toString());
        const targetFollowsCaller = myFollowers.has(targetIdStr) || targetFollowing.has(callerId.toString());
        isAllowed = callerFollowsTarget && targetFollowsCaller;
      }

      if (isAllowed) {
        resultMarkers.push({
          id: targetIdStr,
          name: target.name,
          avatarUrl: target.avatar,
          lat: record.location.coordinates[1],
          lng: record.location.coordinates[0],
          type: 'friend',
          subtitle: 'Active near GITAM campus',
        });
      }
    }

    // Merge campus landmarks
    const allMarkers = [...CAMPUS_LANDMARKS, ...resultMarkers];

    return res.status(200).json({
      success: true,
      count: allMarkers.length,
      markers: allMarkers,
    });
  } catch (error) {
    console.error('[GlobeController] getLocations error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve globe locations.',
    });
  }
};

/**
 * GET /api/globe/settings
 * Read current user's globe sharing preferences.
 */
const getSettings = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('globeSharingEnabled globeVisibleTo');
    return res.status(200).json({
      success: true,
      data: {
        globeSharingEnabled: user.globeSharingEnabled || false,
        globeVisibleTo: user.globeVisibleTo || 'mutual',
      },
    });
  } catch (error) {
    console.error('[GlobeController] getSettings error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch globe settings.',
    });
  }
};

/**
 * PUT /api/globe/settings
 * Update globe sharing preferences.
 */
const updateSettings = async (req, res) => {
  try {
    const { globeSharingEnabled, globeVisibleTo } = req.body;
    const updates = {};

    if (globeSharingEnabled !== undefined) {
      updates.globeSharingEnabled = Boolean(globeSharingEnabled);
      if (!updates.globeSharingEnabled) {
        // Purge location record immediately if user disables sharing
        await GlobeLocation.deleteOne({ userId: req.user._id });
      }
    }

    if (globeVisibleTo && ['mutual', 'followers', 'everyone'].includes(globeVisibleTo)) {
      updates.globeVisibleTo = globeVisibleTo;
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updates },
      { new: true }
    ).select('globeSharingEnabled globeVisibleTo');

    return res.status(200).json({
      success: true,
      message: 'Globe privacy settings updated.',
      data: {
        globeSharingEnabled: updatedUser.globeSharingEnabled,
        globeVisibleTo: updatedUser.globeVisibleTo,
      },
    });
  } catch (error) {
    console.error('[GlobeController] updateSettings error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update globe settings.',
    });
  }
};

module.exports = {
  upsertLocation,
  deleteLocation,
  getLocations,
  getSettings,
  updateSettings,
};
