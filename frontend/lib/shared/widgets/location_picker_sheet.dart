import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/live_location_service.dart';
import '../../core/services/location_service.dart';

class LocationPickerSheet extends StatefulWidget {
  final ValueChanged<String> onLocationSelected;

  const LocationPickerSheet({
    super.key,
    required this.onLocationSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onLocationSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LocationPickerSheet(
        onLocationSelected: onLocationSelected,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  bool _fetchingGps = false;
  bool _startingLive = false;
  int _selectedDuration = 60; // default 60 minutes (1h)

  final List<Map<String, dynamic>> _durations = [
    {'label': '15 mins', 'minutes': 15},
    {'label': '1 hour', 'minutes': 60},
    {'label': '4 hours', 'minutes': 240},
    {'label': '8 hours', 'minutes': 480},
  ];

  Future<void> _pickCurrentLocation() async {
    setState(() => _fetchingGps = true);
    final url = await LocationService.getCurrentLocationUrl(context: context);
    if (mounted) setState(() => _fetchingGps = false);

    if (url != null && mounted) {
      widget.onLocationSelected('📍 Current Location: $url');
      Navigator.of(context).pop();
    }
  }

  Future<void> _startLiveLocation() async {
    setState(() => _startingLive = true);
    final session = await LiveLocationService().startLiveLocation(
      context: context,
      durationMinutes: _selectedDuration,
    );
    if (mounted) setState(() => _startingLive = false);

    if (session != null && mounted) {
      final label = _durations.firstWhere(
        (d) => d['minutes'] == _selectedDuration,
        orElse: () => {'label': '$_selectedDuration min'},
      )['label'];

      widget.onLocationSelected(
        '🔴 Live Location (Active for $label): ${session.shareUrl}',
      );
      Navigator.of(context).pop();
    }
  }

  void _pickSpot(CampusSpot spot) {
    widget.onLocationSelected('📍 ${spot.name}: ${spot.mapsUrl}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final itemBg = isDark ? const Color(0xFF151922) : const Color(0xFFF6F7F9);

    final activeLiveSession = LiveLocationService().activeSession;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Share Location',
                  style: AppTextStyles.headlineSm.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: subtitleColor, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Live location with expiration option
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x22EF4444) : const Color(0x12EF4444),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withAlpha(isDark ? 90 : 60),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: _startingLive
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Share Live Location',
                                      style: AppTextStyles.headlineSm.copyWith(
                                        color: titleColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Updates continuously until the expiration timer runs out',
                                  style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (activeLiveSession != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1417) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fiber_manual_record, color: Color(0xFFEF4444), size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Active session expires in ${activeLiveSession.remainingTime.inMinutes}m',
                                  style: AppTextStyles.bodyXs.copyWith(
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await LiveLocationService().stopLiveLocation();
                                  if (mounted) setState(() {});
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Stop Sharing',
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'SELECT DURATION',
                          style: AppTextStyles.monoXs.copyWith(
                            color: subtitleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _durations.map((d) {
                            final selected = _selectedDuration == d['minutes'];
                            return ChoiceChip(
                              label: Text(d['label']),
                              selected: selected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedDuration = d['minutes']);
                              },
                              selectedColor: const Color(0xFFEF4444),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : subtitleColor,
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              backgroundColor: isDark ? const Color(0xFF19202E) : const Color(0xFFECEFF5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: selected ? const Color(0xFFEF4444) : borderColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _startingLive ? null : _startLiveLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.share_location_rounded, size: 18),
                            label: const Text(
                              'Start Sharing Live Location',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Static 1-time GPS current location option
                InkWell(
                  onTap: _fetchingGps ? null : _pickCurrentLocation,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x1A6C7BF7) : const Color(0x145B63F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(isDark ? 80 : 50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: _fetchingGps
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Static Current Location',
                                style: AppTextStyles.headlineSm.copyWith(
                                  color: titleColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'One-time GPS snapshot on Google Maps',
                                style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: subtitleColor),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'CAMPUS LANDMARKS',
                  style: AppTextStyles.monoXs.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Campus landmarks list
                ...LocationService.campusSpots.map((spot) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _pickSpot(spot),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spot.name,
                                    style: AppTextStyles.headlineSm.copyWith(
                                      color: titleColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    spot.description,
                                    style: AppTextStyles.bodyXs.copyWith(
                                      color: subtitleColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: subtitleColor, size: 13),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
