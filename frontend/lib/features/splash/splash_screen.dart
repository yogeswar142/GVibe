import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Check auth status and navigate accordingly
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      final isLoggedIn = await AuthService.isLoggedIn();
      if (mounted) {
        context.go(isLoggedIn ? AppRouter.home : AppRouter.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Stack(
          children: [
            // Grid lines
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // Center content
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lightning bolt icon (deco)
                      Container(
                        width: 80,
                        height: 80,
                        color: AppColors.accent,
                        child: const Icon(
                          Icons.bolt,
                          color: AppColors.accentDark,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'GVIBE',
                        style: AppTextStyles.displayXl.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CAMPUS_FREQUENCY // V2.0',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom version
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'GVIBE_CORE_SYSTEM_V2.0.4',
                  style: AppTextStyles.monoXs.copyWith(color: AppColors.textMuted),
                ),
              ),
            ),
            // Pink accent line at bottom
            Positioned(
              bottom: 0,
              right: 0,
              left: MediaQuery.of(context).size.width * 0.4,
              child: Container(height: 2, color: AppColors.pink),
            ),
            Positioned(
              bottom: 4,
              right: 0,
              left: MediaQuery.of(context).size.width * 0.6,
              child: Container(height: 1, color: AppColors.accent),
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
      ..color = const Color(0xFF1A1A22).withOpacity(0.8)
      ..strokeWidth = 0.5;

    const step = 40.0;
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
