import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true, period: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            Column(
              children: [
                // 404 hero
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Ghost/wing illustration placeholder
                      Positioned(
                        top: 40,
                        right: 16,
                        child: Opacity(
                          opacity: 0.15,
                          child: const Icon(
                            Icons.flutter_dash,
                            size: 120,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Big 404 glitch text
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _glitchController,
                          builder: (context, child) {
                            final offset =
                                _glitchController.value > 0.95 ? 3.0 : 0.0;
                            return Stack(
                              children: [
                                // Pink shadow
                                Positioned(
                                  left: 16 + offset,
                                  bottom: 0,
                                  child: Text(
                                    '404',
                                    style: AppTextStyles.displayXl.copyWith(
                                      fontSize: 140,
                                      color: AppColors.pink.withOpacity(0.6),
                                      letterSpacing: -4,
                                    ),
                                  ),
                                ),
                                // White main
                                Positioned(
                                  left: 16,
                                  bottom: 0,
                                  child: Text(
                                    '404',
                                    style: AppTextStyles.displayXl.copyWith(
                                      fontSize: 140,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -4,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Yellow divider line
                Container(height: 2, color: AppColors.accent),
                // Content section
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "THIS VIBE DOESN'T EXIST.",
                          style: AppTextStyles.displaySm.copyWith(
                            color: AppColors.accent,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Pink side bar quote
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 100,
                              color: AppColors.pink,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "The page you're looking for ghosted us. It might have been deleted, moved, or never existed in this dimension.",
                                style: AppTextStyles.monoSm.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Go Back Home button (pink)
                        GVibeButton(
                          label: 'GO BACK HOME',
                          backgroundColor: AppColors.pink,
                          textColor: AppColors.textPrimary,
                          onPressed: () => context.go(AppRouter.home),
                        ),
                        const SizedBox(height: 20),
                        // Try refreshing
                        Center(
                          child: GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh,
                                    color: AppColors.textSecondary, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'TRY REFRESHING',
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Bottom bar lines
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 120,
                                height: 2,
                                color: AppColors.pink,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 80,
                                height: 1,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'GVIBE_CORE_SYSTEM_V2.0.4',
                            style: AppTextStyles.monoXs
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        // Rotated ERROR label
                        Row(
                          children: [
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                'ERROR',
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A22).withOpacity(0.6)
      ..strokeWidth = 0.5;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
