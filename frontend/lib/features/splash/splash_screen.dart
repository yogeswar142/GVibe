import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imagePath = isDark ? 'assets/splash_dark.png' : 'assets/splash_light.png';
    final bgColor = isDark ? AppColors.darkCanvas : const Color(0xFFFEFEFE);
    final progressBgColor = isDark ? const Color(0xFF1A1D22) : const Color(0xFFEBEBEB);
    final progressValColor = isDark ? AppColors.accentIndigo : AppColors.lightAccent;
    final textColor = isDark ? const Color(0xFF62666D) : const Color(0xFFA1A1A1);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Centered splash logo image matching native splash
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Image.asset(
                imagePath,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Animated loading bar at the bottom
          Positioned(
            bottom: 64,
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
                            minHeight: 2.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CONNECTING TO CAMPUS_NET',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          letterSpacing: 1.5,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
