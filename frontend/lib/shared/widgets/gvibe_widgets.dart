import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';

// ════════════════════════════════════════════════════════════════════════════
// GVibe — Shared Widget Library (Navy/Indigo Design System)
// All public constructor APIs are frozen — call sites need zero changes.
// ════════════════════════════════════════════════════════════════════════════

// ─── GVibe Avatar ────────────────────────────────────────────────────────────
/// Full circle avatar. showGlow=true → accent ring (story/active state).
/// Default: no ring — clean circle, no border noise.
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
        border: showGlow
            ? Border.all(color: cs.primary, width: 2)
            : null, // no ring when inactive
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

// ─── Legacy alias ─────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) =>
      GVibeAvatar(imageUrl: imageUrl, size: size);
}

// ─── GVibe Button ─────────────────────────────────────────────────────────────
/// Primary: accent flat fill · Secondary: surface-2 + hairline · Ghost: transparent.
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
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            ? _buildPrimary(context, cs)
            : _buildSecondary(context, cs),
      ),
    );
  }

  Widget _buildPrimary(BuildContext context, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.backgroundColor ?? cs.primary; // flat accent fill
    return Container(
      height: 44, // spec: 44px min tap height
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 22), // md for dark (8px), pill for light (22px)
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
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
                        color: widget.textColor ?? Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondary(BuildContext context, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cs.surfaceContainerHigh : cs.surface;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isDark ? 8 : 22),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: cs.primary, strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: cs.onSurface, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.buttonSecondary.copyWith(
                        color: widget.textColor ?? cs.onSurface),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── GVibe Text Field ─────────────────────────────────────────────────────────
/// surface-2 fill · radius sm=10 · 2px accent ring at 30% on focus.
/// No fill-color change on focus — spec exact.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = isDark ? 8.0 : 6.0;
    final fillColor = isDark ? cs.surfaceContainerHigh : cs.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppTextStyles.label.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius), // sm
            // 2px accent ring at 30% when focused — no extra shadow needed
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
              // Fill color does NOT change on focus — theme handles border only
              fillColor: fillColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── GVibe App Bar ────────────────────────────────────────────────────────────
/// Canvas bg · no shadow at rest · hairline appears only when content scrolls under.
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
    // canvas color — matches scaffoldBackground, no elevation
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 10),
      color: bg,
      child: Row(
        children: [
          Text(
            'GVibe',
            style: AppTextStyles.displaySm.copyWith(color: cs.primary),
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
            _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
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
          color: cs.surfaceContainerHigh, // surface-2
          borderRadius: BorderRadius.circular(10), // sm
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Icon(icon, color: cs.onSurfaceVariant, size: 20),
      ),
    );
  }
}

// ─── GVibe Nav Bar ────────────────────────────────────────────────────────────
/// surface-1 bg · hairline top border · active = accent color shift only.
/// No pill background on active — spec exact.
class GVibeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GVibeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (activeIcon: Icons.home_rounded,     inactiveIcon: Icons.home_outlined,        label: 'Feed'),
    (activeIcon: Icons.explore_rounded,  inactiveIcon: Icons.explore_outlined,     label: 'Discover'),
    (activeIcon: Icons.chat_bubble,      inactiveIcon: Icons.chat_bubble_outline,  label: 'Messages'),
    (activeIcon: Icons.person_rounded,   inactiveIcon: Icons.person_outlined,       label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF010102) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => _NavItem(
                activeIcon: _items[i].activeIcon,
                inactiveIcon: _items[i].inactiveIcon,
                label: _items[i].label,
                index: i,
                current: currentIndex,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);
    final inactiveColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final color = isActive ? activeColor : inactiveColor;
    final icon = isActive ? activeIcon : inactiveIcon;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, key: ValueKey(isActive), size: 22, color: color),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.bodyXs.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                fontSize: 10,
                letterSpacing: 0.1,
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
        Text(title,
            style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── GVibe Tag / Chip ─────────────────────────────────────────────────────────
/// pill radius · selected = accent fill + on-accent text · default = surface-2 + hairline.
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
          color: isActive ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999), // pill
          border: Border.all(
            color: isActive ? cs.primary : cs.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isActive ? Colors.white : cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Animated Like Button ─────────────────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 200));
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
              widget.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark: surface-1 → surface-2 shimmer · Light: canvas → surface-sunken
    final base = isDark ? AppColors.surface : AppColors.lightSurface;
    final shine = isDark ? AppColors.surfaceHigh : AppColors.lightSurfaceHigh;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: [
              base,
              Color.lerp(base, shine, _anim.value)!,
              base,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── Post Card Skeleton ───────────────────────────────────────────────────────
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, // surface-1
        borderRadius: BorderRadius.circular(20), // lg
        border: Border.all(color: cs.outline, width: 1),
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

// ─── GVibe Card ───────────────────────────────────────────────────────────────
/// surface-1 bg · 1px hairline · radius lg=20 · 16px padding · no drop shadow.
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
    final radius = borderRadius ?? BorderRadius.circular(20); // lg

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface, // surface-1
          borderRadius: radius,
          border: Border.all(color: cs.outline, width: 1), // hairline
          // No drop shadow — spec: flat + hairline everywhere
        ),
        child: child,
      ),
    );
  }
}

// ─── NoiseOverlay (no-op passthrough) ────────────────────────────────────────
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

  const GradientText(this.text, {super.key, this.style, this.gradient});

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
