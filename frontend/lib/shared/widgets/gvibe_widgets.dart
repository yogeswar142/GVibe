import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

// Noise texture overlay widget
class NoiseOverlay extends StatelessWidget {
  final Widget child;
  const NoiseOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Draw a subtle noise pattern using many tiny rects
    const step = 3.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final hash = ((x * 1234 + y * 5678).toInt() % 10);
        if (hash < 2) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// CutCorner Avatar — cut top-right corner by 12px
class CutCornerAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Widget? placeholder;

  const CutCornerAvatar({
    super.key,
    this.imageUrl,
    this.size = 56,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CutCornerClipper(12),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderWidget(),
              )
            : _placeholderWidget(),
      ),
    );
  }

  Widget _placeholderWidget() {
    return placeholder ??
        Container(
          color: AppColors.surfaceHigh,
          child: const Icon(Icons.person, color: AppColors.textSecondary),
        );
  }
}

class _CutCornerClipper extends CustomClipper<Path> {
  final double cutSize;
  _CutCornerClipper(this.cutSize);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - cutSize, 0);
    path.lineTo(size.width, cutSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_CutCornerClipper oldClipper) =>
      oldClipper.cutSize != cutSize;
}

// Primary Button with hard pink shadow effect on tap
class GVibeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const GVibeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<GVibeButton> createState() => _GVibeButtonState();
}

class _GVibeButtonState extends State<GVibeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ??
        (widget.isPrimary ? AppColors.accent : Colors.transparent);
    final tc = widget.textColor ??
        (widget.isPrimary ? AppColors.accentDark : AppColors.accent);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? (Matrix4.identity()..translate(-2.0, -2.0))
            : Matrix4.identity(),
        child: Stack(
          children: [
            // Hard shadow
            if (_pressed)
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(left: 2, top: 2),
                color: AppColors.pink,
              ),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                border: widget.isPrimary
                    ? null
                    : Border.all(color: AppColors.accent, width: 1),
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.accentDark,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.label.toUpperCase(),
                        style: AppTextStyles.buttonPrimary.copyWith(color: tc),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// GVibe text field
class GVibeTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? errorText;
  final void Function(String)? onChanged;

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTextStyles.monoMd.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            errorText: errorText,
            errorStyle: AppTextStyles.monoXs.copyWith(color: AppColors.pink),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outline),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outline),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Section header with vertical accent bar
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          color: AppColors.accent,
        ),
        const SizedBox(width: 12),
        Text(title.toUpperCase(), style: AppTextStyles.displaySm),
      ],
    );
  }
}

// GVibe app bar
class GVibeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenu;
  final bool showNotification;
  final bool showAvatar;
  final String? avatarUrl;
  final VoidCallback? onMenuTap;

  const GVibeAppBar({
    super.key,
    this.showMenu = true,
    this.showNotification = true,
    this.showAvatar = false,
    this.avatarUrl,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
      color: AppColors.background,
      child: Row(
        children: [
          if (showMenu)
            GestureDetector(
              onTap: onMenuTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _menuLine(),
                  const SizedBox(height: 5),
                  _menuLine(width: 20),
                  const SizedBox(height: 5),
                  _menuLine(),
                ],
              ),
            ),
          if (showMenu) const SizedBox(width: 16),
          Text(
            'GVIBE',
            style: AppTextStyles.displaySm.copyWith(
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(),
          if (showNotification) ...[
            const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 16),
          ],
          if (showAvatar) ...[
            CutCornerAvatar(imageUrl: avatarUrl, size: 36),
          ],
        ],
      ),
    );
  }

  Widget _menuLine({double width = 24}) {
    return Container(width: width, height: 2, color: AppColors.textPrimary);
  }

  @override
  Size get preferredSize => const Size.fromHeight(88);
}

// Bottom Navigation Bar
class GVibeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GVibeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.surface,
      child: Row(
        children: [
          _NavItem(icon: Icons.grid_view, label: 'POSTS', index: 0, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.bolt, label: 'VIBES', index: 1, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.chat_bubble_outline, label: 'DIRECT', index: 2, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.group_outlined, label: 'CLUBS', index: 3, current: currentIndex, onTap: onTap),
        ],
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
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          decoration: isActive
              ? const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.accent, width: 2),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.monoXs.copyWith(
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pink tag chip
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.pink,
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.monoXs.copyWith(
            color: isActive ? AppColors.accent : AppColors.pink,
          ),
        ),
      ),
    );
  }
}
