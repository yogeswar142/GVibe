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

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
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
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY'];
    final days = [12, 13, 14, 15, 16];
    final years = [2002, 2003, 2004, 2005, 2006];
    const activeIndex = 2;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: _drumColumn(months, activeIndex)),
          Expanded(child: _drumColumn(days.map((d) => '$d').toList(), activeIndex)),
          Expanded(child: _drumColumn(years.map((y) => '$y').toList(), activeIndex)),
        ],
      ),
    );
  }

  Widget _drumColumn(List<String> items, int activeIndex) {
    return Column(
      children: items.asMap().entries.map((e) {
        final isActive = e.key == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            e.value,
            style: (isActive ? AppTextStyles.monoMd : AppTextStyles.monoXs).copyWith(
              color: isActive ? AppColors.accent : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
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
