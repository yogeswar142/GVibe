import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _progressAnim;
  late Future<bool> _connectionCheck;

  @override
  void initState() {
    super.initState();
    
    // Start backend connection check in parallel with animation
    _connectionCheck = ApiService().checkConnection();

    // 2.5 second total duration — matches the loading bar sweep
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Fade in during first 600ms
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    // Progress bar fills from 0 → 1 over the full duration
    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Navigate after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    // Await the connection check running in parallel
    final isOnline = await _connectionCheck;
    if (!mounted) return;

    if (!isOnline) {
      context.go(AppRouter.backendDown);
      return;
    }

    final token = await AuthService.getToken();
    if (!mounted) return;
    if (token != null) {
      final user = await AuthService.getUser();
      if (!mounted) return;
      if (user != null && user['profileComplete'] == false) {
        context.go(AppRouter.onboarding);
      } else {
        context.go(AppRouter.home);
      }
    } else {
      context.go(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080C0B) : const Color(0xFFF5FAF9);
    final progressBgColor = isDark ? const Color(0xFF1A2E2B) : const Color(0xFFDDF0EC);
    final progressValColor = isDark ? AppColors.bayTeal : AppColors.lightTeal;
    final taglineColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final footerColor = isDark ? const Color(0xFF3D5C58) : const Color(0xFF6B9E99);

    final gGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFFD97706)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFFB45309)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    final hairlineGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFFD97706)],
          )
        : const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFFB45309)],
          );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Ambient Glow behind wordmark (Dark mode)
          if (isDark)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45 - 50,
              left: (MediaQuery.of(context).size.width - 240) / 2,
              child: Container(
                width: 240,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.elliptical(120, 60)),
                  gradient: RadialGradient(
                    colors: [
                      Color(0x1F0D9488), // rgba(13, 148, 136, 0.12)
                      Color(0x000D9488),
                    ],
                  ),
                ),
              ),
            ),

          // Wordmark + Tagline + Hairline cluster (centered at 45% of height)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45 - 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Wordmark with decorative ring in light mode
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (!isDark)
                        Positioned(
                          left: -20,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'G',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.0,
                                foreground: Paint()
                                  ..shader = gGradient.createShader(
                                    const Rect.fromLTWH(0, 0, 44, 44),
                                  ),
                              ),
                            ),
                            TextSpan(
                              text: 'Vibe',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.0,
                                color: isDark
                                    ? const Color(0xFFE8F4F2)
                                    : const Color(0xFF0C1F1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tagline
                  Text(
                    'your campus, your people',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: taglineColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gradient Hairline
                  Opacity(
                    opacity: isDark ? 0.65 : 0.50,
                    child: Container(
                      width: 52,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: hairlineGradient,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated loading bar at bottom
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _progressAnim.value,
                            backgroundColor: progressBgColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressValColor,
                            ),
                            minHeight: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CONNECTING TO CAMPUS_NET',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 8.5,
                          letterSpacing: 1.4,
                          color: footerColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Footer (32px above bottom edge)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'GITAM University · Visakhapatnam',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: footerColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
