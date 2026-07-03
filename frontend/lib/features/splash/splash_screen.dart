import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
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
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Quick responsive transition (800ms transition time)
    Future.delayed(const Duration(milliseconds: 1100), () {
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
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBackground(BuildContext context, bool isDark) {
    if (isDark) {
      // Linear dark theme: deep black + subtle center lavender glow
      return Stack(
        children: [
          Container(color: const Color(0xFF010102)),
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1F5E6AD2), // ~12% opacity lavender-blue
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90.0, sigmaY: 90.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      );
    } else {
      // Vercel light theme: soft blooming multi-stop mesh gradient
      return Stack(
        children: [
          Container(color: const Color(0xFFFAFAFA)),
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x2200DFD8), // Cyan
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFF0080), // Magenta
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 40,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1F7928CA), // Purple
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x18FAF089), // Soft amber/yellow
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 85.0, sigmaY: 85.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF7F8F8) : const Color(0xFF171717);

    return Scaffold(
      body: NoiseOverlay(
        child: Stack(
          children: [
            // Background gradient/glow
            Positioned.fill(
              child: _buildBackground(context, isDark),
            ),
            // Centered logo content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GVIBE',
                        style: AppTextStyles.displayXl.copyWith(
                          fontSize: 64, // Sleeker typography
                          color: textColor,
                          letterSpacing: -2.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'YOUR CAMPUS · YOUR PEOPLE · YOUR VIBE',
                        style: AppTextStyles.monoXs.copyWith(
                          color: isDark ? const Color(0xFF8A8F98) : const Color(0xFF8F8F8F),
                          letterSpacing: 2.0,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading and connection status
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            backgroundColor: isDark
                                ? const Color(0xFF141516)
                                : const Color(0xFFEBEBEB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? const Color(0xFF5E6AD2)
                                  : const Color(0xFF171717),
                            ),
                            minHeight: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CONNECTING TO CAMPUS_NET',
                        style: AppTextStyles.monoXs.copyWith(
                          color: isDark ? const Color(0xFF62666D) : const Color(0xFFA1A1A1),
                          letterSpacing: 1.5,
                          fontSize: 8,
                        ),
                      ),
                    ],
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
