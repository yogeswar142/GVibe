import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

class BackendDownScreen extends StatefulWidget {
  const BackendDownScreen({super.key});

  @override
  State<BackendDownScreen> createState() => _BackendDownScreenState();
}

class _BackendDownScreenState extends State<BackendDownScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  int _dotCount = 1;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() => _dotCount = _dotCount >= 3 ? 1 : _dotCount + 1);
          }
          _dotsController.forward(from: 0);
        }
      });
    _dotsController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      context.go(AppRouter.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF000004) : const Color(0xFFFDFDFD);
    final accentColor = isDark ? const Color(0xFF8B5CF6) : const Color(0xFF2563EB);
    final badgeBg = isDark
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
        : const Color(0xFF2563EB).withValues(alpha: 0.08);
    final badgeBorder = isDark
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
        : const Color(0xFF2563EB).withValues(alpha: 0.25);
    final badgeText = isDark ? const Color(0xFF8B5CF6) : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // ── System Status Maintenance Bar ─────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFFFFB800)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SYSTEM STATUS  ·  MAINTENANCE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          letterSpacing: 1.8,
                          color: badgeText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lower the image by adding space below the status bar
              const SizedBox(height: 80),

              // ── Hero Image fitted to width ─────────────────
              Image.asset(
                isDark
                    ? 'assets/maintenance_dark.png'
                    : 'assets/maintenance_light.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),

              const Spacer(),

              // Bottom Area containing the Retry Button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _retrying ? null : _retry,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _retrying
                            ? accentColor.withValues(alpha: 0.6)
                            : accentColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _retrying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Try Again${'.' * _dotCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
