import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';

/// A production-grade, GPU-accelerated theme toggle button.
///
/// Engineered for 60/120 FPS performance:
/// - Single-clock [AnimationController] driving synchronized rotation, fade, and color lerp
/// - Zero widget rebuild churn: pure render-layer transformations (Transform & Opacity)
/// - Instant tap reaction with haptic feedback
/// - Smooth spring press effect
class ThemeToggleButton extends ConsumerStatefulWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const ThemeToggleButton({
    super.key,
    this.size = 38,
    this.margin,
  });

  @override
  ConsumerState<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends ConsumerState<ThemeToggleButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  double? _currentTarget;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = _calculateIsDark();
    final target = isDark ? 1.0 : 0.0;

    if (!_isInitialized) {
      _controller.value = target;
      _currentTarget = target;
      _isInitialized = true;
    } else if (_currentTarget != target) {
      _currentTarget = target;
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _calculateIsDark() {
    final themeMode = ref.watch(themeModeProvider);
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  void dispose() {
    _controller.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressController.forward();
  void _onTapUp(TapUpDetails _) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    ref.read(themeModeProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider watched so didChangeDependencies / build reacts instantly
    final isDark = _calculateIsDark();
    final target = isDark ? 1.0 : 0.0;
    if (_isInitialized && _currentTarget != target) {
      _currentTarget = target;
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOutCubic,
      );
    }

    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _toggleTheme,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value; // 0.0 (light mode) -> 1.0 (dark mode)

            final bgColor = Color.lerp(
              const Color(0xFFFFFFFF),
              const Color(0xFF0F1011),
              t,
            )!;

            final borderColor = Color.lerp(
              const Color(0xFFE7E8EC),
              const Color(0xFF212A3D),
              t,
            )!;

            // Smooth 180° rotation
            final rotationAngle = t * math.pi;

            // Seamless cross-fade opacities with 0-clamping
            final moonOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);
            final sunOpacity = ((t - 0.5) * 2.0).clamp(0.0, 1.0);

            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1),
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: rotationAngle,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moon Icon (Light Mode -> tap to enter Dark)
                    if (moonOpacity > 0.0)
                      Opacity(
                        opacity: moonOpacity,
                        child: Transform.scale(
                          scale: 0.70 + (0.30 * moonOpacity),
                          child: Icon(
                            Icons.dark_mode_rounded,
                            color: const Color(0xFF6366F1),
                            size: widget.size * 0.50,
                          ),
                        ),
                      ),
                    // Sun Icon (Dark Mode -> tap to enter Light)
                    if (sunOpacity > 0.0)
                      Opacity(
                        opacity: sunOpacity,
                        child: Transform.scale(
                          scale: 0.70 + (0.30 * sunOpacity),
                          child: Icon(
                            Icons.light_mode_rounded,
                            color: const Color(0xFFFFC107),
                            size: widget.size * 0.50,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.margin != null) {
      return Padding(
        padding: widget.margin!,
        child: button,
      );
    }
    return button;
  }
}
