import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 1;
  final int _totalSteps = 4;

  // Step 3 data (shown in design)
  final TextEditingController _handleController = TextEditingController();
  String _selectedDept = 'DEPARTMENT OF DESIGN';
  int _selectedYear = 2;
  final Set<String> _selectedTags = {'SKATER', 'TECH'};

  // Date picker state
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  int _selectedMonth = 2; // MAR (0-indexed)
  int _selectedDay = 14; // day value (1-31)
  int _selectedBirthYear = 2004; // year value

  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _yearController;

  final List<String> _departments = [
    'DEPARTMENT OF DESIGN',
    'COMPUTER SCIENCE',
    'MECHANICAL ENG',
    'CIVIL ENG',
    'ARCHITECTURE',
    'BUSINESS ADMIN',
  ];

  final List<String> _tags = [
    '#SKATER', '#TECH', '#VINYL', '#COFFEE', '#ZINES', '#FILM_PHOTO',
    '#MUSIC', '#ART', '#CODE', '#SPORTS',
  ];

  int _daysInMonth(int month, int year) {
    // month is 0-indexed (0=JAN, 11=DEC)
    final daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 1) {
      // February leap year check
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) return 29;
    }
    return daysPerMonth[month];
  }

  @override
  void initState() {
    super.initState();
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth);
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _yearController = FixedExtentScrollController(initialItem: _selectedBirthYear - 1990);
  }

  @override
  void dispose() {
    _handleController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final day = _selectedDay.toString().padLeft(2, '0');
    return '${_months[_selectedMonth]}_${day}_$_selectedBirthYear';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GVIBE',
                        style: AppTextStyles.displaySm.copyWith(
                          color: AppColors.accent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        'AUTH_FLOW // 2024',
                        style: AppTextStyles.monoXs.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Step indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'STEP 0${_step} / 0$_totalSteps',
                    style: AppTextStyles.monoMd.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Heading
                  Text(
                    'COMPLETE\nYOUR PROFILE',
                    style: AppTextStyles.displayLg.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 01_IDENTITY
                  _buildSectionLabel('01_IDENTITY'),
                  const SizedBox(height: 8),
                  GVibeTextField(
                    label: '',
                    hint: 'CHOOSE_HANDLE',
                    controller: _handleController,
                    onChanged: (v) => setState(() {}),
                  ),
                  if (_handleController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'LIVE_PREVIEW: @${_handleController.text.toLowerCase().replaceAll(' ', '_')}',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // 02_FACULTY_BRANCH
                  _buildSectionLabel('02_FACULTY_BRANCH'),
                  const SizedBox(height: 8),
                  _buildDropdown(),

                  const SizedBox(height: 28),

                  // 03_CHRONO_DATA — date picker drum
                  _buildSectionLabel('03_CHRONO_DATA'),
                  const SizedBox(height: 8),
                  _buildDateDrum(),
                  // Selected date preview
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'DOB_SET: $_formattedDate',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 04_ACADEMIC_LEVEL
                  _buildSectionLabel('04_ACADEMIC_LEVEL'),
                  const SizedBox(height: 12),
                  _buildYearSelector(),

                  const SizedBox(height: 28),

                  // 05_INTERESTS_TAGS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('05_INTERESTS_TAGS'),
                      Text(
                        'MAX_03',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags
                        .map((t) => GVibeTag(
                              label: t,
                              isActive: _selectedTags.contains(
                                  t.replaceAll('#', '')),
                              onTap: () {
                                setState(() {
                                  final key = t.replaceAll('#', '');
                                  if (_selectedTags.contains(key)) {
                                    _selectedTags.remove(key);
                                  } else if (_selectedTags.length < 3) {
                                    _selectedTags.add(key);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 32),

                  // "THIS IS YOU" preview card
                  _buildProfilePreviewCard(),

                  const SizedBox(height: 32),

                  // CTA
                  GVibeButton(
                    label: 'INITIALIZE_ACCOUNT',
                    onPressed: () => context.go(AppRouter.home),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: Text(
                        'GO_BACK_STEP_02',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _footerLink('PRIVACY_PROTOCOLS'),
                      const SizedBox(width: 16),
                      _footerLink('VIBE_GUIDELINES'),
                      const SizedBox(width: 16),
                      _footerLink('HELP_MATRIX'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'GVIBE_V2.0.4_STAB',
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final active = i < _step;
        return Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
            color: active ? AppColors.accent : AppColors.outline,
          ),
        );
      }),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.monoXs.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedDept,
              isExpanded: true,
              dropdownColor: AppColors.surfaceHigh,
              underline: const SizedBox(),
              style: AppTextStyles.monoMd.copyWith(color: AppColors.textPrimary),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary),
              items: _departments
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d, style: AppTextStyles.monoSm),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedDept = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDrum() {
    const double itemExtent = 36.0;
    const double drumHeight = 180.0;
    final int maxDays = _daysInMonth(_selectedMonth, _selectedBirthYear);

    // Generate year range (1990–2010)
    final years = List.generate(21, (i) => 1990 + i);

    return Container(
      height: drumHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          // Highlight band for selected row
          Center(
            child: Container(
              height: itemExtent,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                border: Border(
                  top: BorderSide(color: AppColors.accent.withOpacity(0.4), width: 1),
                  bottom: BorderSide(color: AppColors.accent.withOpacity(0.4), width: 1),
                ),
              ),
            ),
          ),
          Row(
            children: [
              // Month drum
              Expanded(
                child: _buildWheelColumn(
                  controller: _monthController,
                  itemCount: _months.length,
                  itemExtent: itemExtent,
                  labelBuilder: (i) => _months[i],
                  selectedIndex: _selectedMonth,
                  onChanged: (i) {
                    setState(() {
                      _selectedMonth = i;
                      // Clamp day if needed
                      final maxD = _daysInMonth(_selectedMonth, _selectedBirthYear);
                      if (_selectedDay > maxD) {
                        _selectedDay = maxD;
                        _dayController.jumpToItem(_selectedDay - 1);
                      }
                    });
                  },
                ),
              ),
              Container(width: 1, color: AppColors.outline.withOpacity(0.3)),
              // Day drum
              Expanded(
                child: _buildWheelColumn(
                  controller: _dayController,
                  itemCount: maxDays,
                  itemExtent: itemExtent,
                  labelBuilder: (i) => '${i + 1}'.padLeft(2, '0'),
                  selectedIndex: _selectedDay - 1,
                  onChanged: (i) {
                    setState(() => _selectedDay = i + 1);
                  },
                ),
              ),
              Container(width: 1, color: AppColors.outline.withOpacity(0.3)),
              // Year drum
              Expanded(
                child: _buildWheelColumn(
                  controller: _yearController,
                  itemCount: years.length,
                  itemExtent: itemExtent,
                  labelBuilder: (i) => '${years[i]}',
                  selectedIndex: _selectedBirthYear - 1990,
                  onChanged: (i) {
                    setState(() {
                      _selectedBirthYear = years[i];
                      // Clamp day if needed (e.g. Feb 29 on non-leap year)
                      final maxD = _daysInMonth(_selectedMonth, _selectedBirthYear);
                      if (_selectedDay > maxD) {
                        _selectedDay = maxD;
                        _dayController.jumpToItem(_selectedDay - 1);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          // Column labels at top
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text('MONTH',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textMuted, fontSize: 8)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('DAY',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textMuted, fontSize: 8)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('YEAR',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textMuted, fontSize: 8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required double itemExtent,
    required String Function(int) labelBuilder,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      diameterRatio: 1.6,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isActive = index == selectedIndex;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: (isActive ? AppTextStyles.monoMd : AppTextStyles.monoSm).copyWith(
                color: isActive ? AppColors.accent : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(labelBuilder(index)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearSelector() {
    final years = ['1ST', '2ND', '3RD', '4TH'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: years.asMap().entries.map((e) {
        final isSelected = e.key + 1 == _selectedYear;
        return GestureDetector(
          onTap: () => setState(() => _selectedYear = e.key + 1),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.outline,
              ),
            ),
            child: Center(
              child: Text(
                e.value,
                style: AppTextStyles.monoMd.copyWith(
                  color: isSelected ? AppColors.accentDark : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfilePreviewCard() {
    final handle = _handleController.text.isEmpty
        ? 'VIBE_MASTER_42'
        : _handleController.text.toUpperCase().replaceAll(' ', '_');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS IS YOU',
            style: AppTextStyles.displaySm.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CutCornerAvatar(size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IDENTIFIER',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textMuted)),
                    Text('@$handle',
                        style: AppTextStyles.monoMd
                            .copyWith(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BRANCH',
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textMuted)),
                            Text('DES_DEP',
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LVL',
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textMuted)),
                            Text('YEAR_0${_selectedYear}',
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DOB',
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textMuted)),
                            Text(_formattedDate,
                                style: AppTextStyles.monoXs
                                    .copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATUS: UNVERIFIED',
                  style: AppTextStyles.monoXs
                      .copyWith(color: AppColors.textMuted)),
              Row(
                children: List.generate(
                    3,
                    (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          color: AppColors.accent,
                        )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: AppTextStyles.monoXs.copyWith(color: AppColors.textMuted),
    );
  }
}
