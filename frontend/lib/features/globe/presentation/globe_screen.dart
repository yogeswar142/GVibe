import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/globe_service.dart';
import 'globe_controller.dart';
import 'globe_view.dart';

class GlobeScreen extends ConsumerStatefulWidget {
  const GlobeScreen({super.key});

  @override
  ConsumerState<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends ConsumerState<GlobeScreen>
    with WidgetsBindingObserver {
  GlobeViewController? _globeController;
  bool _isMapLoaded = false;
  bool _isLocating = false;
  String? _errorMessage;
  int _activeModalsCount = 0;

  void _onModalOpened() {
    _activeModalsCount++;
    _globeController?.setPointerEvents(false);
  }

  void _onModalClosed() {
    _activeModalsCount--;
    if (_activeModalsCount <= 0) {
      _activeModalsCount = 0;
      _globeController?.setPointerEvents(true);
    }
  }

  Timer? _refreshTimer;
  bool _sharingEnabled = false;
  String _visibleTo = 'mutual';
  Map<String, double>? _currentUserCoordinates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLight = Theme.of(context).brightness == Brightness.light;
    _globeController?.setTheme(isLight ? 'light' : 'dark');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentTab = ref.read(homeNavIndexProvider);
      if (currentTab == 4 && _isMapLoaded) {
        _fetchLocationsAndSettings();
        _startPeriodicRefresh();
      }
    } else {
      _stopPeriodicRefresh();
    }
  }

  void _startPeriodicRefresh() {
    _stopPeriodicRefresh();
    // Refresh visible friends' locations periodically every 30s while Globe is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _isMapLoaded) {
        _fetchLocationsAndSettings();
      }
    });
  }

  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPeriodicRefresh();
    _globeController?.setPointerEvents(true);
    super.dispose();
  }

  Future<void> _fetchLocationsAndSettings() async {
    try {
      final settings = await GlobeService().getSettings();
      if (settings != null && mounted) {
        setState(() {
          _sharingEnabled = settings['globeSharingEnabled'] == true;
          _visibleTo = settings['globeVisibleTo'] ?? 'mutual';
        });
      }

      final locations = await GlobeService().getGlobeLocations();
      final hasSelf = locations.any((m) => m['type'] == 'self');
      if (!hasSelf && _currentUserCoordinates != null && _sharingEnabled) {
        locations.add({
          'id': 'self_current',
          'name': 'You',
          'avatarUrl': '',
          'lat': _currentUserCoordinates!['lat'],
          'lng': _currentUserCoordinates!['lng'],
          'type': 'self',
          'subtitle': 'Your active location',
        });
      }
      if (mounted) {
        _globeController?.updateMarkers(locations);
      }
    } catch (e) {
      debugPrint('[Globe] _fetchLocationsAndSettings error: $e');
    }
  }

  void _returnToMessages() {
    // Index 2 is the Messages tab
    ref.read(homeNavIndexProvider.notifier).state = 2;
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final coords =
          await LocationService.getCurrentCoordinates(context: context);
      if (coords != null) {
        _currentUserCoordinates = coords;
        _globeController?.flyToUser(coords['lng']!, coords['lat']!, 16.0);
        // If sharing is already enabled, update backend location
        if (_sharingEnabled) {
          await GlobeService().updateLocation(
            latitude: coords['lat']!,
            longitude: coords['lng']!,
          );
        }
        await _fetchLocationsAndSettings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location access is required to center the map on your position. Check device permissions.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Globe] Failed to get user location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not obtain current location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _centerOnCampus() async {
    _globeController?.flyToCampus();
  }

  void _showMarkerDetails(Map<String, dynamic> marker) {
    _onModalOpened();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isEvent = marker['type'] == 'event';
        final isSelf = marker['type'] == 'self';
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        final cardBg = isDark ? const Color(0xFF0C141E) : Colors.white;
        final borderColor = isSelf
            ? (isDark ? const Color(0xFF00FFFF) : const Color(0xFF0F766E))
            : (isEvent
                ? const Color(0xFFFF007F).withValues(alpha: isDark ? 0.5 : 0.6)
                : (isDark
                    ? AppColors.bayTeal.withValues(alpha: 0.5)
                    : AppColors.lightPrimary.withValues(alpha: 0.45)));
        final shadowColor = isSelf
            ? (isDark
                ? const Color(0xFF00FFFF).withValues(alpha: 0.25)
                : const Color(0xFF0F766E).withValues(alpha: 0.2))
            : (isEvent
                ? const Color(0xFFFF007F).withValues(alpha: isDark ? 0.2 : 0.15)
                : (isDark
                    ? AppColors.bayTeal.withValues(alpha: 0.2)
                    : AppColors.lightPrimary.withValues(alpha: 0.12)));

        final titleColor = isDark ? Colors.white : AppColors.lightTextPrimary;
        final subtitleColor =
            isDark ? Colors.white70 : AppColors.lightTextSecondary;
        final closeBtnBg = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);
        final closeBtnBorder = isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.1);
        final closeIconColor =
            isDark ? Colors.white : AppColors.lightTextPrimary;

        final mq = MediaQuery.of(sheetContext);
        final screenWidth = mq.size.width;
        final screenHeight = mq.size.height;
        final isSmall = screenWidth < 380;
        final horizontalMargin =
            screenWidth > 540 ? 0.0 : (isSmall ? 12.0 : 16.0);
        final bottomMargin =
            mq.padding.bottom > 0 ? mq.padding.bottom + 8 : 16.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (screenHeight * 0.85).clamp(200.0, 680.0),
                maxWidth: (screenWidth > 540 ? 480.0 : screenWidth)
                    .clamp(280.0, 500.0),
              ),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                    horizontalMargin, 12, horizontalMargin, bottomMargin),
                padding: EdgeInsets.all(isSmall ? 16 : 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: isSmall ? 44 : 52,
                            height: isSmall ? 44 : 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isSelf
                                    ? [
                                        isDark
                                            ? const Color(0xFF00FFFF)
                                            : const Color(0xFF0F766E),
                                        isDark
                                            ? const Color(0xFF0D9488)
                                            : const Color(0xFF047857),
                                      ]
                                    : (isEvent
                                        ? [
                                            const Color(0xFFFF007F),
                                            const Color(0xFF7928CA)
                                          ]
                                        : [
                                            isDark
                                                ? AppColors.bayTeal
                                                : AppColors.lightPrimary,
                                            isDark
                                                ? const Color(0xFF0077FF)
                                                : const Color(0xFF0D9488)
                                          ]),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSelf
                                          ? (isDark
                                              ? const Color(0xFF00FFFF)
                                              : const Color(0xFF0F766E))
                                          : (isEvent
                                              ? const Color(0xFFFF007F)
                                              : (isDark
                                                  ? AppColors.bayTeal
                                                  : AppColors.lightPrimary)))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipOval(
                              child: marker['avatarUrl'] != null &&
                                      marker['avatarUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      marker['avatarUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        isSelf
                                            ? Icons.person_pin_circle_rounded
                                            : (isEvent
                                                ? Icons.event
                                                : Icons.person),
                                        color: Colors.white,
                                        size: isSmall ? 20 : 24,
                                      ),
                                    )
                                  : Container(
                                      color: isDark
                                          ? const Color(0xFF0B1320)
                                          : const Color(0xFFEDF7F5),
                                      child: Icon(
                                        isSelf
                                            ? Icons.person_pin_circle_rounded
                                            : (isEvent
                                                ? Icons.event
                                                : Icons.person),
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightPrimary,
                                        size: isSmall ? 20 : 24,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(width: isSmall ? 10 : 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  marker['name'] ?? '',
                                  style: AppTextStyles.headlineSm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 16 : 18,
                                    color: titleColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  marker['subtitle'] ?? 'GITAM Campus Location',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: subtitleColor,
                                    fontSize: isSmall ? 11 : 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: isSmall ? 36 : 40,
                                height: isSmall ? 36 : 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: closeBtnBg,
                                  border: Border.all(
                                    color: closeBtnBorder,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.close_rounded,
                                  color: closeIconColor,
                                  size: isSmall ? 18 : 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 14 : 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppColors.bayTeal
                                    : AppColors.lightPrimary,
                                side: BorderSide(
                                  color: (isDark
                                          ? AppColors.bayTeal
                                          : AppColors.lightPrimary)
                                      .withValues(alpha: 0.6),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: isSmall ? 10 : 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _globeController?.flyToUser(
                                  marker['lng'],
                                  marker['lat'],
                                  16.5,
                                );
                              },
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Focus',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmall ? 8 : 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelf
                                    ? (isDark
                                        ? const Color(0xFF00FFFF)
                                        : const Color(0xFF0F766E))
                                    : (isEvent
                                        ? const Color(0xFFFF007F)
                                        : (isDark
                                            ? AppColors.bayTeal
                                            : AppColors.lightPrimary)),
                                foregroundColor: isSelf && isDark
                                    ? Colors.black
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: isSmall ? 10 : 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                if (isSelf) {
                                  _showPrivacySettingsSheet();
                                } else if (isEvent) {
                                  _showEventDetailsSheet(marker);
                                } else if (marker['id'] != null) {
                                  // View profile or chat
                                  context.push('/chat/${marker['id']}');
                                }
                              },
                              icon: Icon(
                                  isSelf
                                      ? Icons.shield_outlined
                                      : (isEvent
                                          ? Icons.info_outline
                                          : Icons.chat_bubble_outline),
                                  size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isSelf
                                      ? 'Privacy'
                                      : (isEvent ? 'Details' : 'Message'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

      },
    ).whenComplete(_onModalClosed);
  }


  void _showEventDetailsSheet(Map<String, dynamic> marker) {
    _onModalOpened();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF0C141E) : Colors.white;
        final titleColor = isDark ? Colors.white : AppColors.lightTextPrimary;
        final subtitleColor =
            isDark ? Colors.white70 : AppColors.lightTextSecondary;
        final closeBtnBg = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);
        final closeBtnBorder = isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.1);
        final closeIconColor =
            isDark ? Colors.white : AppColors.lightTextPrimary;

        final name = marker['name']?.toString() ?? 'Campus Landmark';
        final subtitle =
            marker['subtitle']?.toString() ?? 'GITAM Campus Location';
        final lat = (marker['lat'] is num) ? (marker['lat'] as num).toDouble() : 17.7818;
        final lng = (marker['lng'] is num) ? (marker['lng'] as num).toDouble() : 83.3768;

        String description =
            'Official GITAM Deemed University campus facility supporting student life, academics, and collaborative activities.';
        if (name.contains('ICT')) {
          description =
              'GITAM Information & Communication Technology Bhavan houses state-of-the-art computer labs, high-performance computing centers, developer club spaces, and IT infrastructure. Open for tech events, hackathons, and lab sessions.';
        } else if (name.contains('Library') || name.contains('KRC')) {
          description =
              'The Knowledge Resource Centre (KRC) spans multiple floors offering silent study zones, group discussion cubicles, digital catalog access, research journals, and 24/7 exam-week reading rooms.';
        } else if (name.contains('Theatre') || name.contains('OAT')) {
          description =
              'The central campus Open Air Theatre (OAT) is the premier venue for student cultural festivals, music performances, annual day gatherings, club presentations, and open-mic sessions.';
        } else if (name.contains('Food') || name.contains('Cafeteria')) {
          description =
              'Multi-cuisine campus dining hub featuring student cafes, juice bars, healthy bites, and casual social seating for students and faculty.';
        } else if (name.contains('Stadium') || name.contains('Sports')) {
          description =
              'Multi-sport indoor arena equipped with badminton courts, table tennis, basketball, fitness gym, and inter-collegiate tournament facilities.';
        }

        final mq = MediaQuery.of(sheetContext);
        final screenWidth = mq.size.width;
        final screenHeight = mq.size.height;
        final isSmall = screenWidth < 380;
        final horizontalMargin =
            screenWidth > 540 ? 0.0 : (isSmall ? 12.0 : 16.0);
        final bottomMargin =
            mq.padding.bottom > 0 ? mq.padding.bottom + 8 : 16.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (screenHeight * 0.85).clamp(200.0, 680.0),
                maxWidth: (screenWidth > 540 ? 480.0 : screenWidth)
                    .clamp(280.0, 500.0),
              ),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                    horizontalMargin, 12, horizontalMargin, bottomMargin),
                padding: EdgeInsets.all(isSmall ? 16 : 22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFF007F)
                        .withValues(alpha: isDark ? 0.5 : 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF007F)
                          .withValues(alpha: isDark ? 0.2 : 0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmall ? 8 : 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF007F), Color(0xFF7928CA)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF007F)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(Icons.event_available_rounded,
                                color: Colors.white, size: isSmall ? 20 : 24),
                          ),
                          SizedBox(width: isSmall ? 10 : 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: AppTextStyles.headlineSm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 16 : 18,
                                    color: titleColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: subtitleColor,
                                    fontSize: isSmall ? 11 : 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(sheetContext).pop(),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: isSmall ? 36 : 40,
                                height: isSmall ? 36 : 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: closeBtnBg,
                                  border: Border.all(
                                      color: closeBtnBorder, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.close_rounded,
                                    color: closeIconColor,
                                    size: isSmall ? 18 : 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 12 : 18),
                      Container(
                        padding: EdgeInsets.all(isSmall ? 10 : 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF07101B)
                              : const Color(0xFFEDF7F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : AppColors.lightOutline,
                          ),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 13,
                            height: 1.45,
                            color: isDark
                                ? Colors.white70
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 10 : 14),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16, color: Color(0xFFFF007F)),
                              const SizedBox(width: 6),
                              Text(
                                '8:00 AM – 8:00 PM',
                                style: TextStyle(
                                  fontSize: isSmall ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_outlined,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.bayTeal
                                      : AppColors.lightPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Main Campus Zone',
                                style: TextStyle(
                                  fontSize: isSmall ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 14 : 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF007F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: isSmall ? 10 : 12),
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _globeController?.flyToUser(lng, lat, 16.5);
                          },
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Focus on 3D Globe',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

      },
    ).whenComplete(_onModalClosed);
  }

  void _showPrivacySettingsSheet() {
    _onModalOpened();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final mq = MediaQuery.of(sheetContext);
            final screenWidth = mq.size.width;
            final screenHeight = mq.size.height;
            final isSmall = screenWidth < 380;
            final horizontalMargin =
                screenWidth > 540 ? 0.0 : (isSmall ? 12.0 : 16.0);
            final bottomMargin =
                mq.padding.bottom > 0 ? mq.padding.bottom + 8 : 16.0;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (screenHeight * 0.85).clamp(200.0, 680.0),
                    maxWidth: (screenWidth > 540 ? 480.0 : screenWidth)
                        .clamp(280.0, 500.0),
                  ),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                        horizontalMargin, 12, horizontalMargin, bottomMargin),
                    padding: EdgeInsets.all(isSmall ? 16 : 22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C141E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.bayTeal.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bayTeal.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmall ? 6 : 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      AppColors.bayTeal.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  Icons.security_rounded,
                                  color: AppColors.bayTeal,
                                  size: isSmall ? 18 : 22,
                                ),
                              ),
                              SizedBox(width: isSmall ? 8 : 12),
                              Expanded(
                                child: Text(
                                  'Globe Privacy Controls',
                                  style: AppTextStyles.headlineSm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 15 : 17,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    width: isSmall ? 36 : 40,
                                    height: isSmall ? 36 : 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black
                                              .withValues(alpha: 0.06),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.14)
                                            : Colors.black
                                                .withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                      size: isSmall ? 18 : 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmall ? 12 : 18),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: (isDark
                            ? AppColors.bayTeal
                            : AppColors.lightPrimary)
                        .withValues(alpha: 0.6),
                    activeThumbColor: isDark
                        ? AppColors.bayTeal
                        : AppColors.lightPrimary,
                    title: Text(
                      'Share Location on Globe',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Allow peers to see your avatar near campus.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    value: _sharingEnabled,
                    onChanged: (val) async {
                      if (val) {
                        final bool? confirmed = await _showConsentDialog();
                        if (confirmed != true) {
                          setSheetState(() => _sharingEnabled = false);
                          setState(() => _sharingEnabled = false);
                          return;
                        }
                        setSheetState(() => _sharingEnabled = true);
                        setState(() => _sharingEnabled = true);

                        if (!mounted) return;
                        final coords =
                            await LocationService.getCurrentCoordinates(
                                context: context);
                        if (coords != null) {
                          _currentUserCoordinates = coords;
                          await GlobeService().updateLocation(
                            latitude: coords['lat']!,
                            longitude: coords['lng']!,
                          );
                          await GlobeService().updateSettings(
                            globeSharingEnabled: true,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Location sharing enabled. Your location is visible to authorized peers.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          setSheetState(() => _sharingEnabled = false);
                          setState(() => _sharingEnabled = false);
                          await GlobeService().updateSettings(
                            globeSharingEnabled: false,
                          );
                        }
                      } else {
                        setSheetState(() => _sharingEnabled = false);
                        setState(() => _sharingEnabled = false);
                        _currentUserCoordinates = null;
                        await GlobeService().removeLocation();
                        await GlobeService().updateSettings(
                          globeSharingEnabled: false,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Location sharing disabled. Your marker was removed from the globe.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                      _fetchLocationsAndSettings();
                    },
                  ),
                  Divider(
                    color: isDark ? Colors.white12 : AppColors.lightOutline,
                    height: 24,
                  ),
                  Text(
                    'WHO CAN SEE YOU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.bayTeal
                          : AppColors.lightPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: isDark
                        ? AppColors.bayTeal
                        : AppColors.lightPrimary,
                    title: Text(
                      'Mutual Followers (Default)',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Only friends who both follow you and you follow back.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: 'mutual',
                    groupValue: _visibleTo,
                    onChanged: (val) async {
                      if (val == null) return;
                      setSheetState(() => _visibleTo = val);
                      setState(() => _visibleTo = val);
                      await GlobeService().updateSettings(globeVisibleTo: val);
                      _fetchLocationsAndSettings();
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: isDark
                        ? AppColors.bayTeal
                        : AppColors.lightPrimary,
                    title: Text(
                      'All Followers',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Anyone following your campus profile.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: 'followers',
                    groupValue: _visibleTo,
                    onChanged: (val) async {
                      if (val == null) return;
                      setSheetState(() => _visibleTo = val);
                      setState(() => _visibleTo = val);
                      await GlobeService().updateSettings(globeVisibleTo: val);
                      _fetchLocationsAndSettings();
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: isDark
                        ? AppColors.bayTeal
                        : AppColors.lightPrimary,
                    title: Text(
                      'Everyone on Campus',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Visible to all registered students.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: 'everyone',
                    groupValue: _visibleTo,
                    onChanged: (val) async {
                      if (val == null) return;
                      setSheetState(() => _visibleTo = val);
                      setState(() => _visibleTo = val);
                      await GlobeService().updateSettings(globeVisibleTo: val);
                      _fetchLocationsAndSettings();
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF07101B)
                          : const Color(0xFFEDF7F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : AppColors.lightOutline,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDark
                              ? AppColors.bayTeal
                              : AppColors.lightPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GVibe automatically rounds coordinates to ~111m precision and expires shared locations after 6 hours.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_sharingEnabled) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                              color: Colors.redAccent, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          setState(() => _sharingEnabled = false);
                          _currentUserCoordinates = null;
                          await GlobeService().removeLocation();
                          await GlobeService().updateSettings(
                            globeSharingEnabled: false,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Location sharing stopped immediately.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _fetchLocationsAndSettings();
                          }
                        },
                        icon: const Icon(Icons.location_off_rounded, size: 18),
                        label: const Text(
                          'Stop Sharing Immediately',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(_onModalClosed);
  }

  Future<bool?> _showConsentDialog() {
    _onModalOpened();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0C141E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? AppColors.bayTeal.withValues(alpha: 0.4)
                  : AppColors.lightPrimary.withValues(alpha: 0.3),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: isDark ? AppColors.bayTeal : AppColors.lightPrimary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Share Campus Location?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'By turning on location sharing, your approximate position near campus will be visible on the 3D Globe to your chosen audience (mutual friends by default).',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF07101B)
                      : const Color(0xFFEDF7F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppColors.lightOutline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color:
                          isDark ? AppColors.bayTeal : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'GVibe rounds coordinates to ~111m precision and automatically expires your location after 6 hours.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.bayTeal : AppColors.lightPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Agree & Share'),
            ),
          ],
        );
      },
    ).whenComplete(_onModalClosed);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final themeStr = isLight ? 'light' : 'dark';

    ref.listen<int>(homeNavIndexProvider, (previous, next) {
      if (next == 4) {
        if (_isMapLoaded) {
          _fetchLocationsAndSettings();
          _startPeriodicRefresh();
        }
      } else {
        _stopPeriodicRefresh();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _returnToMessages();
        }
      },
      child: Scaffold(
        backgroundColor:
            isLight ? const Color(0xFFF5FAF9) : const Color(0xFF000103),
        body: Stack(
          children: [
            // 3D Globe WebEngine
            Positioned(
              top: kIsWeb ? 68 : 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GlobePlatformView(
                theme: themeStr,
                onControllerCreated: (controller) =>
                    _globeController = controller,
                onMapLoaded: () async {
                  setState(() {
                    _isMapLoaded = true;
                    _errorMessage = null;
                  });
                  _globeController?.setTheme(themeStr);
                  await _fetchLocationsAndSettings();
                  _startPeriodicRefresh();
                  if (_sharingEnabled && _currentUserCoordinates == null) {
                    final coords = await LocationService.getCurrentCoordinates();
                    if (coords != null && mounted) {
                      _currentUserCoordinates = coords;
                      await GlobeService().updateLocation(
                        latitude: coords['lat']!,
                        longitude: coords['lng']!,
                      );
                      _fetchLocationsAndSettings();
                    }
                  }
                },
                onEdgeSwipeBack: _returnToMessages,
                onMarkerTapped: (marker) => _showMarkerDetails(marker),
                onMapError: (msg) => setState(() => _errorMessage = msg),
              ),
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isLight
                                ? const Color(0xFFF5FAF9)
                                : Colors.black)
                            .withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top Control Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Builder(
                  builder: (context) {
                    final topMq = MediaQuery.of(context);
                    final topWidth = topMq.size.width;
                    final isSmallScreen = topWidth < 380;
                    final btnSize = isSmallScreen ? 36.0 : 40.0;
                    final iconSpacing = isSmallScreen ? 6.0 : 8.0;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Back Button
                          _GlassIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            isLight: isLight,
                            size: btnSize,
                            onPressed: _returnToMessages,
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),

                          // Title Pill (responsive, flexible)
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 14,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : const Color(0xFF0B141F)
                                        .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isLight
                                      ? AppColors.lightOutlineStrong
                                      : AppColors.bayTeal
                                          .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isLight
                                        ? Colors.black.withValues(alpha: 0.05)
                                        : AppColors.bayTeal
                                            .withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: isSmallScreen ? 6 : 8,
                                    height: isSmallScreen ? 6 : 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isLight
                                          ? AppColors.lightPrimary
                                          : AppColors.bayTeal,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isLight
                                              ? AppColors.lightPrimary
                                              : AppColors.bayTeal,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  Flexible(
                                    child: Text(
                                      'Campus Globe',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.headlineSm.copyWith(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        fontWeight: FontWeight.bold,
                                        color: isLight
                                            ? AppColors.lightTextPrimary
                                            : Colors.white,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Campus Center Button
                          _GlassIconButton(
                            icon: Icons.school_outlined,
                            tooltip: 'GITAM Campus',
                            isLight: isLight,
                            size: btnSize,
                            onPressed: _isMapLoaded ? _centerOnCampus : () {},
                          ),
                          SizedBox(width: iconSpacing),

                          // Locate Button
                          _GlassIconButton(
                            icon: _isLocating
                                ? Icons.hourglass_top_rounded
                                : Icons.my_location_rounded,
                            tooltip: 'My Location',
                            isLight: isLight,
                            size: btnSize,
                            onPressed:
                                _isMapLoaded ? _centerOnCurrentLocation : () {},
                          ),
                          SizedBox(width: iconSpacing),

                          // Privacy Settings Button
                          _GlassIconButton(
                            icon: _sharingEnabled
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            tooltip: 'Privacy & Sharing',
                            isLight: isLight,
                            size: btnSize,
                            onPressed: _showPrivacySettingsSheet,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Error message banner if any
            if (_errorMessage != null)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  setState(() => _errorMessage = null),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool isLight;
  final double size;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isLight = false,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.92)
            : const Color(0xFF0B141F).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: isLight
              ? AppColors.lightOutlineStrong
              : AppColors.bayTeal.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          icon,
          color: isLight ? AppColors.lightPrimary : AppColors.bayTeal,
          size: size * 0.48,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
