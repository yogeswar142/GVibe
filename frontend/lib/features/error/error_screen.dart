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
      duration: const Duration(milliseconds: 100),
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
            // Main content — centered layout matching 404page.png
            Column(
              children: [
                // Top spacer
                const Spacer(flex: 2),
                // Giant 404 with glitch effect
                AnimatedBuilder(
                  animation: _glitchController,
                  builder: (context, child) {
                    final offset =
                        _glitchController.value > 0.95 ? 3.0 : 0.0;
                    return Stack(
                      children: [
                        // Pink shadow offset
                        Transform.translate(
                          offset: Offset(offset, offset),
                          child: Text(
                            '404',
                            style: AppTextStyles.displayXl.copyWith(
                              fontSize: 160,
                              color: AppColors.pink.withValues(alpha: 0.5),
                              letterSpacing: -6,
                              height: 0.9,
                            ),
                          ),
                        ),
                        // White main text
                        Text(
                          '404',
                          style: AppTextStyles.displayXl.copyWith(
                            fontSize: 160,
                            color: AppColors.textPrimary,
                            letterSpacing: -6,
                            height: 0.9,
                          ),
                        ),
                        // Glitch stripe through the middle
                        Positioned(
                          top: 70,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Accent yellow line divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    width: double.infinity,
                    height: 3,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                // THIS VIBE DOESN'T EXIST.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "THIS VIBE DOESN'T EXIST.",
                      style: AppTextStyles.displaySm.copyWith(
                        color: AppColors.accent,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Pink bar + description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 3, height: 80, color: AppColors.pink),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "The page you're looking for\nghosted us. It might have\nbeen deleted, moved, or never\nexisted in this dimension.",
                          style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // GO BACK HOME — pink button with yellow text & border
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: GestureDetector(
                    onTap: () => context.go(AppRouter.home),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        border: Border.all(color: AppColors.accent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'GO BACK HOME',
                          style: AppTextStyles.monoMd.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // TRY REFRESHING
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                const Spacer(flex: 3),
                // Bottom decorative lines
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(width: 120, height: 2, color: AppColors.pink),
                        const SizedBox(height: 4),
                        Container(
                            width: 80, height: 1, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'GVIBE_CORE_SYSTEM_V2.0.4',
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
                // Rotated ERROR label
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'ERROR',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
      ..color = AppColors.outline.withValues(alpha: 0.2)
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
