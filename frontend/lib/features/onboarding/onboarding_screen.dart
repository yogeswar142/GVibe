import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _handleController = TextEditingController();
  bool _saving = false;
  String? _error;

  // 02_FACULTY_BRANCH
  String? _selectedDept;
  final List<String> _departments = [
    'DEPARTMENT OF DESIGN',
    'DEPARTMENT OF CS',
    'DEPARTMENT OF ECE',
    'DEPARTMENT OF EEE',
    'DEPARTMENT OF MECH',
    'DEPARTMENT OF CIVIL',
    'DEPARTMENT OF IT',
    'DEPARTMENT OF AIDS',
  ];

  // 03_CHRONO_DATA (birthday)
  int _selectedMonth = 2; // MAR
  int _selectedDay = 14;
  int _selectedYear = 2004;

  // 04_ACADEMIC_LEVEL
  int? _selectedYearLevel;
  final List<String> _yearLabels = ['1ST', '2ND', '3RD', '4TH'];

  // 05_INTERESTS_TAGS
  final List<String> _allTags = [
    '#SKATER', '#TECH', '#VINYL', '#COFFEE', '#ZINES', '#FILM_PHOTO',
    '#CODING', '#MUSIC', '#GAMING', '#ART', '#SPORTS', '#ANIME',
  ];
  final Set<String> _selectedTags = {};
  static const int _maxTags = 3;

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final handle = _handleController.text.trim();
      final dept = _selectedDept ?? '';
      final year = _selectedYearLevel != null
          ? _yearLabels[_selectedYearLevel!]
          : '';
      final bio = _selectedTags.join(', ');

      await ApiService().dio.put('/users/profile', data: {
        'name': handle.isNotEmpty ? handle : null,
        'dept': dept,
        'year': year,
        'bio': bio,
      });

      if (mounted) context.go(AppRouter.home);
    } on DioException catch (e) {
      setState(() =>
          _error = e.response?.data?['message'] ?? 'Failed to save profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = _handleController.text.trim().isNotEmpty
        ? _handleController.text.trim()
        : 'VIBE_MASTER_42';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: GVIBE + AUTH_FLOW // 2024
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'GVIBE',
                      style: AppTextStyles.displaySm.copyWith(
                        color: AppColors.accent,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'AUTH_FLOW // 2024',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Step indicator bars
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _stepBar(AppColors.accent),
                    const SizedBox(width: 4),
                    _stepBar(AppColors.accent),
                    const SizedBox(width: 4),
                    _stepBar(AppColors.outline),
                    const SizedBox(width: 4),
                    _stepBar(AppColors.outline),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Scrollable content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // STEP 03 / 04
                    Text(
                      'STEP 03 / 04',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // COMPLETE YOUR PROFILE — big heading
                    Text(
                      'COMPLETE\nYOUR PROFILE',
                      style: AppTextStyles.displayXl.copyWith(
                        fontSize: 44,
                        height: 0.95,
                        letterSpacing: -1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 01_IDENTITY
                    _sectionLabel('01_IDENTITY'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      color: AppColors.surfaceHigh,
                      child: TextField(
                        controller: _handleController,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'CHOOSE_HANDLE',
                          hintStyle: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 20,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LIVE_PREVIEW: @${handle.toLowerCase().replaceAll(' ', '_')}',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 02_FACULTY_BRANCH
                    _sectionLabel('02_FACULTY_BRANCH'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDept,
                          hint: Row(
                            children: [
                              Text(
                                'Λ',
                                style: AppTextStyles.displaySm.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'DEPARTMENT OF DESIGN',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary),
                          isExpanded: true,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          items: _departments.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedDept = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 03_CHRONO_DATA
                    _sectionLabel('03_CHRONO_DATA'),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 32),

                    // 04_ACADEMIC_LEVEL
                    _sectionLabel('04_ACADEMIC_LEVEL'),
                    const SizedBox(height: 12),
                    _buildYearGrid(),
                    const SizedBox(height: 32),

                    // 05_INTERESTS_TAGS
                    Row(
                      children: [
                        _sectionLabel('05_INTERESTS_TAGS'),
                        const Spacer(),
                        Text(
                          'MAX_0$_maxTags',
                          style: AppTextStyles.monoXs.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else if (_selectedTags.length < _maxTags) {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.outline,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.monoXs.copyWith(
                                color: isSelected
                                    ? AppColors.accentDark
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),

                    // THIS IS YOU — preview card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.accent, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THIS IS YOU',
                            style: AppTextStyles.displaySm.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const CutCornerAvatar(size: 56),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'IDENTIFIER',
                                      style: AppTextStyles.monoXs.copyWith(
                                        color: AppColors.textMuted,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      '@${handle.toUpperCase().replaceAll(' ', '_')}',
                                      style: AppTextStyles.monoLg.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('BRANCH',
                                                style: AppTextStyles.monoXs.copyWith(
                                                    color: AppColors.textMuted)),
                                            Text(
                                              _selectedDept?.replaceAll('DEPARTMENT OF ', '') ??
                                                  'DES_DEP',
                                              style: AppTextStyles.monoSm.copyWith(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 24),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('LVL',
                                                style: AppTextStyles.monoXs.copyWith(
                                                    color: AppColors.textMuted)),
                                            Text(
                                              _selectedYearLevel != null
                                                  ? 'YEAR_0${_selectedYearLevel! + 1}'
                                                  : 'YEAR_02',
                                              style: AppTextStyles.monoSm.copyWith(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'STATUS: UNVERIFIED',
                                style: AppTextStyles.monoXs.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(3, (_) {
                                  return Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(left: 3),
                                    color: AppColors.accent,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.pink, width: 1),
                        ),
                        child: Text(
                          _error!,
                          style: AppTextStyles.monoSm.copyWith(color: AppColors.pink),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // INITIALIZE_ACCOUNT button — pink bg
                    GVibeButton(
                      label: 'INITIALIZE_ACCOUNT',
                      backgroundColor: AppColors.pink,
                      textColor: AppColors.textPrimary,
                      onPressed: _saveProfile,
                      isLoading: _saving,
                    ),
                    const SizedBox(height: 16),
                    // GO_BACK link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Text(
                          'GO_BACK_STEP_02',
                          style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Footer links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('PRIVACY_PROTOCOLS',
                            style: AppTextStyles.monoXs
                                .copyWith(color: AppColors.textMuted, fontSize: 9)),
                        Text('VIBE_GUIDELINES',
                            style: AppTextStyles.monoXs
                                .copyWith(color: AppColors.textMuted, fontSize: 9)),
                        Text('HELP_MATRIX',
                            style: AppTextStyles.monoXs
                                .copyWith(color: AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'SYSTEM_VER_4.2.0_STABLE',
                        style: AppTextStyles.monoXs.copyWith(
                          color: AppColors.accent,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBar(Color color) {
    return Expanded(
      child: Container(height: 3, color: color),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.monoXs.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  // Date picker — drum-roll style grid
  Widget _buildDatePicker() {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY'];
    final days = [12, 13, 14, 15, 16];
    final years = [2002, 2003, 2004, 2005, 2006];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Months column
          Expanded(
            child: Column(
              children: months.asMap().entries.map((e) {
                final isSelected = e.key == _selectedMonth;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMonth = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: isSelected ? Colors.transparent : Colors.transparent,
                    child: Center(
                      child: Text(
                        e.value,
                        style: AppTextStyles.monoMd.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Days column
          Expanded(
            child: Column(
              children: days.asMap().entries.map((e) {
                final isSelected = e.value == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = e.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        '${e.value}',
                        style: AppTextStyles.monoMd.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Years column
          Expanded(
            child: Column(
              children: years.asMap().entries.map((e) {
                final isSelected = e.value == _selectedYear;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = e.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        '${e.value}',
                        style: AppTextStyles.monoMd.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Year grid — 2x2
  Widget _buildYearGrid() {
    return Column(
      children: [
        Row(
          children: [
            _yearTile(0),
            const SizedBox(width: 8),
            _yearTile(1),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _yearTile(2),
            const SizedBox(width: 8),
            _yearTile(3),
          ],
        ),
      ],
    );
  }

  Widget _yearTile(int index) {
    final isSelected = _selectedYearLevel == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedYearLevel = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.outline,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              _yearLabels[index],
              style: AppTextStyles.displaySm.copyWith(
                fontSize: 22,
                color: isSelected ? AppColors.accentDark : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
