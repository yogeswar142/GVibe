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
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _lineController;
  late Animation<double> _fadeAnim;
  late Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _lineController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final token = await AuthService.getToken();
    if (!mounted) return;
    if (token != null) {
      context.go(AppRouter.home);
    } else {
      context.go(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lineController.dispose();
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
              child: CustomPaint(painter: _SplashGridPainter()),
            ),
            // Centered content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GVIBE logo — massive display
                    Text(
                      'GVIBE',
                      style: AppTextStyles.displayXl.copyWith(
                        fontSize: 96,
                        color: AppColors.textPrimary,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Animated accent line — yellow portion + grey portion
                    AnimatedBuilder(
                      animation: _lineAnim,
                      builder: (context, child) {
                        return SizedBox(
                          width: 280,
                          height: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 280 * 0.55 * _lineAnim.value,
                                height: 4,
                                color: AppColors.accent,
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: AppColors.textMuted.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Tagline
                    Text(
                      'YOUR CAMPUS. YOUR PEOPLE. YOUR VIBE.',
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 2.5,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom left system text
            Positioned(
              bottom: 40,
              left: 24,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM_INITIALIZATION',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'V4.2.0_CAMPUS_NET',
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 1.0,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.25)
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
