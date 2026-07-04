import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';

/// Shows a bottom sheet with two tabs:
///   - Create: name, description, private toggle
///   - Join:   public browse + invite-code entry
///
/// Returns the newly created/joined community map on pop, or null if cancelled.
Future<Map<String, dynamic>?> showCommunitySheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CommunitySheet(),
  );
}

class _CommunitySheet extends StatefulWidget {
  const _CommunitySheet();

  @override
  State<_CommunitySheet> createState() => _CommunitySheetState();
}

class _CommunitySheetState extends State<_CommunitySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? const Color(0xFF0C0D0F) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final nameColor   = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Communities',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: nameColor, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: nameColor, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1011) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F4D) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: accentColor,
                unselectedLabelColor: isDark ? const Color(0xFF838EA6) : const Color(0xFF888888),
                labelStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.bodySm,
                tabs: const [Tab(text: 'Create'), Tab(text: 'Join')],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _CreateTab(onCreated: (c) => Navigator.of(context).pop(c)),
                  _JoinTab(onJoined: (c) => Navigator.of(context).pop(c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Tab ────────────────────────────────────────────────────────────────

class _CreateTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onCreated;
  const _CreateTab({required this.onCreated});

  @override
  State<_CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends State<_CreateTab> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPrivate = false;
  bool _loading   = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Community name is required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().dio.post('/messages/communities', data: {
        'name': name,
        'description': _descCtrl.text.trim(),
        'isPrivate': _isPrivate,
      });
      if (r.data['success'] == true) {
        widget.onCreated(Map<String, dynamic>.from(r.data['data']));
      } else {
        setState(() { _error = r.data['message']?.toString() ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = ApiService.getErrorMessage(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final inputBg     = isDark ? const Color(0xFF0F1011) : const Color(0xFFF9F9FB);
    final nameColor   = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subColor    = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final errorColor  = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text('Name', style: AppTextStyles.bodySm.copyWith(color: subColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _InputField(controller: _nameCtrl, hint: 'e.g. Coding Club', inputBg: inputBg, borderColor: borderColor, nameColor: nameColor),
          const SizedBox(height: 16),

          // Description
          Text('Description', style: AppTextStyles.bodySm.copyWith(color: subColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _InputField(controller: _descCtrl, hint: 'What is this community about?', maxLines: 3, inputBg: inputBg, borderColor: borderColor, nameColor: nameColor),
          const SizedBox(height: 20),

          // Private toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: subColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Private community', style: AppTextStyles.bodySm.copyWith(color: nameColor, fontWeight: FontWeight.w600)),
                      Text('Members join via invite code only', style: AppTextStyles.bodyXs.copyWith(color: subColor)),
                    ],
                  ),
                ),
                Switch(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                  activeThumbColor: accentColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_error != null) ...[
            Text(_error!, style: AppTextStyles.bodyXs.copyWith(color: errorColor)),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: _loading ? 'Creating...' : 'Create Community',
              onTap: _loading ? null : _create,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Join Tab ──────────────────────────────────────────────────────────────────

class _JoinTab extends StatefulWidget {
  final void Function(Map<String, dynamic>) onJoined;
  const _JoinTab({required this.onJoined});

  @override
  State<_JoinTab> createState() => _JoinTabState();
}

class _JoinTabState extends State<_JoinTab> {
  final _searchCtrl = TextEditingController();
  final _codeCtrl   = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _joining   = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() { _searching = true; _error = null; });
    try {
      final r = await ApiService().dio.get('/messages/communities/search', queryParameters: {'q': q.trim()});
      if (r.data['success'] == true) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(r.data['data'] ?? []);
          _searching = false;
        });
      }
    } catch (e) {
      setState(() { _error = ApiService.getErrorMessage(e); _searching = false; });
    }
  }

  Future<void> _join(String communityId, {String? inviteCode}) async {
    setState(() { _joining = true; _error = null; });
    try {
      final r = await ApiService().dio.put(
        '/messages/communities/$communityId/join',
        data: inviteCode != null ? {'inviteCode': inviteCode} : {},
      );
      if (r.data['success'] == true) {
        widget.onJoined(Map<String, dynamic>.from(r.data['data']));
      } else {
        setState(() { _error = r.data['message']?.toString() ?? 'Failed to join'; _joining = false; });
      }
    } catch (e) {
      setState(() { _error = ApiService.getErrorMessage(e); _joining = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final inputBg     = isDark ? const Color(0xFF0F1011) : const Color(0xFFF9F9FB);
    final nameColor   = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subColor    = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final errorColor  = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);
    final cardBg      = isDark ? const Color(0xFF0F1011) : const Color(0xFFF9F9FB);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          _InputField(
            controller: _searchCtrl,
            hint: 'Search communities...',
            prefix: Icon(Icons.search_rounded, color: subColor, size: 18),
            inputBg: inputBg,
            borderColor: borderColor,
            nameColor: nameColor,
            onChanged: _search,
          ),
          const SizedBox(height: 16),

          if (_searching)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_results.isNotEmpty) ...[
            Text('Results', style: AppTextStyles.bodySm.copyWith(color: subColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._results.map((c) => _CommunitySearchCard(
              community: c,
              cardBg: cardBg,
              borderColor: borderColor,
              nameColor: nameColor,
              subColor: subColor,
              accentColor: accentColor,
              onJoin: () => _join(c['_id'].toString()),
            )),
            const SizedBox(height: 20),
          ],

          // Private invite code
          Text('Have an invite code?', style: AppTextStyles.bodySm.copyWith(color: subColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _codeCtrl,
                  hint: 'Enter code (e.g. AB12CD34)',
                  inputBg: inputBg,
                  borderColor: borderColor,
                  nameColor: nameColor,
                  inputFormatters: [UpperCaseTextFormatter()],
                ),
              ),
              const SizedBox(width: 10),
              _PrimaryButton(
                label: _joining ? '...' : 'Join',
                onTap: _joining ? null : () {
                  // Private join requires communityId — simplified: search first, then join
                  if (_codeCtrl.text.trim().isEmpty) return;
                  setState(() => _error = 'Search for the community first, then join with code');
                },
                accentColor: accentColor,
                width: 70,
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.bodyXs.copyWith(color: errorColor)),
          ],
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _CommunitySearchCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final Color cardBg, borderColor, nameColor, subColor, accentColor;
  final VoidCallback onJoin;

  const _CommunitySearchCard({
    required this.community,
    required this.cardBg,
    required this.borderColor,
    required this.nameColor,
    required this.subColor,
    required this.accentColor,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final name        = community['name']?.toString() ?? '';
    final desc        = community['description']?.toString() ?? '';
    final memberCount = community['memberCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '#',
                style: AppTextStyles.headlineMd.copyWith(color: accentColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.headlineSm.copyWith(color: nameColor, fontWeight: FontWeight.w700)),
                if (desc.isNotEmpty)
                  Text(desc, style: AppTextStyles.bodyXs.copyWith(color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$memberCount members', style: AppTextStyles.bodyXs.copyWith(color: subColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Join', style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  final int? maxLines;
  final Color inputBg, borderColor, nameColor;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.hint,
    this.prefix,
    this.maxLines = 1,
    required this.inputBg,
    required this.borderColor,
    required this.nameColor,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              onChanged: onChanged,
              inputFormatters: inputFormatters,
              style: AppTextStyles.bodyMd.copyWith(color: nameColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMd.copyWith(color: hintColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color accentColor;
  final double? width;

  const _PrimaryButton({required this.label, required this.onTap, required this.accentColor, this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? accentColor.withValues(alpha: 0.5) : accentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
