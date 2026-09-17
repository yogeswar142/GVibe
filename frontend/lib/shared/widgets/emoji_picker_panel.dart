import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// WhatsApp-style categorized emoji data
class EmojiCategory {
  final String name;
  final IconData icon;
  final List<String> emojis;

  const EmojiCategory({
    required this.name,
    required this.icon,
    required this.emojis,
  });
}

class EmojiData {
  EmojiData._();

  static const List<EmojiCategory> categories = [
    EmojiCategory(
      name: 'Smileys',
      icon: Icons.sentiment_satisfied_alt_rounded,
      emojis: [
        '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🥹', '☺️',
        '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗',
        '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓',
        '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕',
        '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤',
        '😮‍💨', '😶‍🌫️', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🫢',
        '🫣', '🤫', '🫡', '🤐', '🤨', '😐', '😑', '😶', '🫥', '😯',
      ],
    ),
    EmojiCategory(
      name: 'Gestures',
      icon: Icons.thumb_up_alt_outlined,
      emojis: [
        '👍', '👎', '👏', '🙌', '👐', '🤲', '🤝', '✌️', '🤞', '🤟',
        '🤘', '👌', '🤌', '🤏', '👈', '👉', '👆', '👇', '☝️', '✋',
        '🤚', '🖐️', '🖖', '👋', '🤙', '💪', '🦾', '🖕', '✍️', '🙏',
        '🫶', '🦶', '🦵', '👂', '👃', '👀', '👁️', '👅', '👄', '🫦',
      ],
    ),
    EmojiCategory(
      name: 'Campus & Vibes',
      icon: Icons.school_outlined,
      emojis: [
        '🎓', '📚', '📖', '📝', '✏️', '💻', '💡', '🎒', '🔬', '🧪',
        '📐', '🏛️', '🏫', '🏆', '🥇', '🥈', '🥉', '🎯', '🚀', '🔥',
        '✨', '💯', '🎉', '🎊', '🎈', '⚡', '🌟', '💥', '🎵', '🎶',
        '☕', '🍕', '🍔', '🍟', '🥪', '🍜', '🍩', '🥤', '⚽', '🏀',
      ],
    ),
    EmojiCategory(
      name: 'Hearts & Mood',
      icon: Icons.favorite_border_rounded,
      emojis: [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
        '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
        '💟', '💌', '💤', '💢', '💬', '💭', '🗯️', '♨️', '📍', '📌',
      ],
    ),
  ];
}

/// WhatsApp-style emoji picker panel widget.
class EmojiPickerPanel extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onBackspace;
  final double height;

  const EmojiPickerPanel({
    super.key,
    required this.onEmojiSelected,
    this.onBackspace,
    this.height = 240,
  });

  /// Helper to insert emoji at current cursor position in a TextEditingController
  static void insertEmoji(TextEditingController controller, String emoji) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      final newPosition = selection.start + emoji.length;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPosition),
      );
    } else {
      controller.value = TextEditingValue(
        text: text + emoji,
        selection: TextSelection.collapsed(offset: text.length + emoji.length),
      );
    }
  }

  /// Helper to delete the last character or emoji at the cursor
  static void backspace(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;

    if (text.isEmpty) return;

    if (selection.start > 0) {
      if (selection.start != selection.end) {
        // Delete selected range
        final newText = text.replaceRange(selection.start, selection.end, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start),
        );
      } else {
        // Delete one rune/character back
        final prevChar = text.characters.take(
          text.characters.length - 1,
        ).string;
        controller.value = TextEditingValue(
          text: prevChar,
          selection: TextSelection.collapsed(offset: prevChar.length),
        );
      }
    } else if (selection.start == -1 && text.isNotEmpty) {
      final prevChar = text.characters.take(
        text.characters.length - 1,
      ).string;
      controller.value = TextEditingValue(
        text: prevChar,
        selection: TextSelection.collapsed(offset: prevChar.length),
      );
    }
  }

  @override
  State<EmojiPickerPanel> createState() => _EmojiPickerPanelState();
}

class _EmojiPickerPanelState extends State<EmojiPickerPanel> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF10131B) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE5E7EB);
    const activeIconColor = AppColors.primary;
    final inactiveIconColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF9CA3AF);

    final currentCategory = EmojiData.categories[_selectedCategoryIndex];

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Emoji Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: currentCategory.emojis.length,
              itemBuilder: (context, index) {
                final emoji = currentCategory.emojis[index];
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onEmojiSelected(emoji);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Category Navigation + Backspace
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C0E14) : const Color(0xFFE9EBEF),
              border: Border(top: BorderSide(color: borderColor.withAlpha(128), width: 0.8)),
            ),
            child: Row(
              children: [
                ...List.generate(EmojiData.categories.length, (index) {
                  final cat = EmojiData.categories[index];
                  final isSelected = index == _selectedCategoryIndex;
                  return IconButton(
                    icon: Icon(
                      cat.icon,
                      size: 20,
                      color: isSelected ? activeIconColor : inactiveIconColor,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: cat.name,
                    onPressed: () {
                      setState(() => _selectedCategoryIndex = index);
                    },
                  );
                }),
                const Spacer(),
                if (widget.onBackspace != null)
                  IconButton(
                    icon: Icon(Icons.backspace_outlined, size: 20, color: inactiveIconColor),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Backspace',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onBackspace!();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
