import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';

// ════════════════════════════════════════════════════════════════════════════
// GVibe — Premium Widget Library (Royal Indigo Design System)
// ════════════════════════════════════════════════════════════════════════════

// ─── GVibe Avatar ────────────────────────────────────────────────────────────
/// Circular avatar with optional indigo glow ring for active/self users.
class GVibeAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showGlow;
  final String? initials;

  const GVibeAvatar({
    super.key,
    this.imageUrl,
    this.size = 44,
    this.showGlow = false,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.ext;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showGlow ? ext.avatarGlow : null,
        border: Border.all(
          color: showGlow ? cs.primary : cs.outline.withOpacity(0.4),
          width: showGlow ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: initials != null
            ? Text(
                initials!.substring(0, initials!.length.clamp(0, 2)).toUpperCase(),
                style: AppTextStyles.headlineSm.copyWith(color: cs.primary),
              )
            : Icon(Icons.person_rounded, color: cs.primary, size: size * 0.5),
      ),
    );
  }
}

// ─── Legacy CutCornerAvatar alias ────────────────────────────────────────────
/// Backward-compatible alias — now renders as GVibeAvatar (circle).
class CutCornerAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Widget? placeholder;

  const CutCornerAvatar({
    super.key,
    this.imageUrl,
    this.size = 44,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return GVibeAvatar(imageUrl: imageUrl, size: size);
  }
}

// ─── GVibe Button ────────────────────────────────────────────────────────────
/// Premium gradient button with scale-on-press micro-animation.
class GVibeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const GVibeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  State<GVibeButton> createState() => _GVibeButtonState();
}

class _GVibeButtonState extends State<GVibeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.ext;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.isPrimary
            ? _buildPrimary(context, ext, cs, isDark)
            : _buildSecondary(context, cs),
      ),
    );
  }

  Widget _buildPrimary(BuildContext context, AppThemeExtension ext,
      ColorScheme cs, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: widget.backgroundColor == null
            ? ext.primaryGradient
            : null,
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ext.glowShadow,
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: widget.textColor ?? Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondary(BuildContext context, ColorScheme cs) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary, width: 1.5),
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: cs.primary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.buttonSecondary.copyWith(
                      color: widget.textColor ?? cs.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── GVibe Text Field ─────────────────────────────────────────────────────────
/// Premium filled rounded text field with focus glow.
class GVibeTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? errorText;
  final void Function(String)? onChanged;
  final int? maxLines;

  const GVibeTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.errorText,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<GVibeTextField> createState() => _GVibeTextFieldState();
}

class _GVibeTextFieldState extends State<GVibeTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.label.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            focusNode: _focus,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: widget.suffix,
              errorText: widget.errorText,
              errorStyle: AppTextStyles.bodyXs.copyWith(color: cs.error),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── GVibe App Bar ────────────────────────────────────────────────────────────
/// Clean premium app bar with theme toggle support.
class GVibeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenu;
  final bool showNotification;
  final bool showAvatar;
  final String? avatarUrl;
  final VoidCallback? onMenuTap;
  final VoidCallback? onThemeToggle;
  final bool isDark;

  const GVibeAppBar({
    super.key,
    this.showMenu = false,
    this.showNotification = true,
    this.showAvatar = false,
    this.avatarUrl,
    this.onMenuTap,
    this.onThemeToggle,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 10),
      color: cs.surface,
      child: Row(
        children: [
          // Brand name
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'GVibe',
              style: AppTextStyles.displaySm.copyWith(
                color: Colors.white,
                fontSize: 26,
              ),
            ),
          ),
          const Spacer(),
          if (onThemeToggle != null) ...[
            _IconBtn(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              onTap: onThemeToggle!,
            ),
            const SizedBox(width: 8),
          ],
          if (showNotification)
            _IconBtn(
              icon: Icons.notifications_outlined,
              onTap: () {},
            ),
          if (showAvatar) ...[
            const SizedBox(width: 12),
            GVibeAvatar(imageUrl: avatarUrl, size: 36, showGlow: true),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(92);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cs.onSurface, size: 20),
      ),
    );
  }
}

// ─── GVibe Nav Bar ────────────────────────────────────────────────────────────
/// Floating pill nav bar with animated sliding active indicator.
class GVibeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GVibeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_rounded,      label: 'Feed'),
    (icon: Icons.explore_rounded,   label: 'Discover'),
    (icon: Icons.chat_bubble_rounded, label: 'Messages'),
    (icon: Icons.person_rounded,    label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        height: 68,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceHigh.withOpacity(0.85)
                    : AppColors.lightSurface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.lightOutline,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Sliding pill indicator
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment(
                      -0.75 + (currentIndex * 0.5),
                      0,
                    ),
                    child: Container(
                      width: 52,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  // Nav items
                  Row(
                    children: List.generate(
                      _items.length,
                      (i) => _NavItem(
                        icon: _items[i].icon,
                        label: _items[i].label,
                        index: i,
                        current: currentIndex,
                        onTap: onTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.bodyXs.copyWith(
                color: isActive ? cs.primary : cs.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title, style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── GVibe Tag / Chip ─────────────────────────────────────────────────────────
class GVibeTag extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const GVibeTag({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? cs.primary.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isActive ? cs.primary : cs.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Animated Like Button ─────────────────────────────────────────────────────
/// Heart button with scale + color pulse on tap (dopamine loop).
class AnimatedLikeButton extends StatefulWidget {
  final int count;
  final bool isLiked;
  final VoidCallback? onTap;

  const AnimatedLikeButton({
    super.key,
    required this.count,
    this.isLiked = false,
    this.onTap,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.ext;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.isLiked ? ext.like : cs.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(widget.count),
            style: AppTextStyles.monoSm.copyWith(
              color: widget.isLiked ? ext.like : cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

// ─── Skeleton Loader ──────────────────────────────────────────────────────────
/// Shimmer skeleton for loading states — no blank screens.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.surfaceHigh,
                      Color.lerp(AppColors.surfaceHigh,
                          AppColors.surfaceHighest, _anim.value)!,
                      AppColors.surfaceHigh,
                    ]
                  : [
                      AppColors.lightSurfaceHigh,
                      Color.lerp(AppColors.lightSurfaceHigh,
                          AppColors.lightSurfaceHighest, _anim.value)!,
                      AppColors.lightSurfaceHigh,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Full post card skeleton
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.ext.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 44, height: 44, borderRadius: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          const SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          const SkeletonBox(width: 180, height: 14),
          const SizedBox(height: 16),
          Row(
            children: const [
              SkeletonBox(width: 48, height: 18, borderRadius: 9),
              SizedBox(width: 16),
              SkeletonBox(width: 48, height: 18, borderRadius: 9),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── GVibe Gradient Card ──────────────────────────────────────────────────────
/// Premium card with subtle box shadow — adapts to theme.
class GVibeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const GVibeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    final radius = borderRadius ?? BorderRadius.circular(16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: radius,
          boxShadow: ext.cardShadow,
          border: Border.all(
            color: ext.outline.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─── NoiseOverlay (kept for backward compat, now a no-op passthrough) ─────────
class NoiseOverlay extends StatelessWidget {
  final Widget child;
  const NoiseOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

// ─── Gradient Text ────────────────────────────────────────────────────────────
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.ext;
    return ShaderMask(
      shaderCallback: (bounds) =>
          (gradient ?? ext.primaryGradient).createShader(bounds),
      child: Text(
        text,
        style: (style ?? AppTextStyles.displaySm).copyWith(color: Colors.white),
      ),
    );
  }
}
