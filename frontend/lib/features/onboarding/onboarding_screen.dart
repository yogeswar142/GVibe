import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _handleController = TextEditingController();
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saving = false;
  String? _error;

  bool _isVerified = false;
  bool _isNameLocked = true;
  bool _isRegLocked = true;

  // 02_BRANCH
  String? _selectedDept;
  final List<String> _departments = [
    'COMPUTER SCIENCE & ENGINEERING',
    'ELECTRONICS & COMMUNICATION',
    'MECHANICAL ENGINEERING',
    'ELECTRICAL & ELECTRONICS',
    'CIVIL ENGINEERING',
    'INFORMATION TECHNOLOGY',
    'BIOTECHNOLOGY',
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
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await AuthService.getUser();
    if (user != null) {
      if (user['tempProfileData'] != null) {
        final temp = user['tempProfileData'];
        setState(() {
          _handleController.text = temp['handle'] ?? '';
          _nameController.text = temp['name'] ?? '';
          _regNumberController.text = temp['regNumber'] ?? '';
          _selectedDept = temp['dept'];
          _selectedYearLevel = temp['yearLevel'];
          _selectedMonth = temp['month'] ?? 2;
          _selectedDay = temp['day'] ?? 14;
          _selectedYear = temp['year'] ?? 2004;
          _selectedTags.clear();
          if (temp['tags'] != null) {
            _selectedTags.addAll(List<String>.from(temp['tags']));
          }
          _isVerified = temp['isVerified'] ?? false;
          _isNameLocked = _isVerified;
          _isRegLocked = _isVerified;
        });
      } else {
        final gmailName = user['name'] ?? '';
        final regExp = RegExp(r'^(.*?)\s+(\d{10})$');
        final match = regExp.firstMatch(gmailName);
        setState(() {
          if (match != null) {
            _nameController.text = match.group(1)?.trim() ?? '';
            _regNumberController.text = match.group(2) ?? '';
            _isVerified = true;
            _isNameLocked = true;
            _isRegLocked = true;
          } else {
            _nameController.text = gmailName;
            _regNumberController.text = '';
            _isVerified = false;
            _isNameLocked = false;
            _isRegLocked = false;
          }
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    final draft = {
      'handle': _handleController.text,
      'name': _nameController.text,
      'regNumber': _regNumberController.text,
      'dept': _selectedDept,
      'yearLevel': _selectedYearLevel,
      'month': _selectedMonth,
      'day': _selectedDay,
      'year': _selectedYear,
      'tags': _selectedTags.toList(),
      'isVerified': _isVerified,
    };
    try {
      await ApiService().dio.put('/users/profile/temp', data: {
        'tempProfileData': draft,
      });
      // Update local storage too so local copy stays warm
      final user = await AuthService.getUser();
      if (user != null) {
        user['tempProfileData'] = draft;
        await AuthService.saveUser(user);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _handleController.dispose();
    _nameController.dispose();
    _regNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final handle = _handleController.text.trim();
    final name = _nameController.text.trim();
    final regNumber = _regNumberController.text.trim();
    final password = _passwordController.text.trim();
    final branch = _selectedDept ?? '';
    final academicLevel = _selectedYearLevel != null ? _yearLabels[_selectedYearLevel!] : '';
    final dob = '${_selectedDay}/${_selectedMonth + 1}/${_selectedYear}';
    final bio = _selectedTags.join(', ');

    if (handle.isEmpty || name.isEmpty || regNumber.isEmpty || branch.isEmpty || academicLevel.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all profile fields and password');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters long');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await ApiService().dio.put('/users/profile', data: {
        'name': name,
        'username': handle,
        'registrationNumber': regNumber,
        'dob': dob,
        'branch': branch,
        'academicLevel': academicLevel,
        'interests': _selectedTags.toList(),
        'bio': bio,
        'isVerified': _isVerified,
        'password': password,
      });

      if (response.data['success'] == true) {
        // Update local cache to clear temp variables
        final user = await AuthService.getUser();
        if (user != null) {
          user['profileComplete'] = true;
          user['tempProfileData'] = null;
          await AuthService.saveUser(user);
        }
        if (mounted) context.go(AppRouter.home);
      } else {
        setState(() => _error = response.data['message'] ?? 'Failed to initialize account');
      }
    } on DioException catch (e) {
      setState(() => _error = ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showOverlayModal(String title, String content) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1011) : Colors.white,
              border: Border.all(color: isDark ? const Color(0xFF23252A) : const Color(0xFFEBEBEB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.monoLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isDark ? AppColors.textSecondary : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              // Top bar: GVIBE + AUTH_FLOW // year
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
                      'Account Setup',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.bold,
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
                    _sectionLabel('Username'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      color: AppColors.surfaceHigh,
                      child: TextField(
                        controller: _handleController,
                        onChanged: (_) {
                          setState(() {});
                          _saveDraft();
                        },
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Choose Handle',
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
                      'Live Preview: @${handle.toLowerCase().replaceAll(' ', '_')}',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 01_B_NAME (New requirement)
                    Row(
                      children: [
                        _sectionLabel('Name (as per ID card)'),
                        const Spacer(),
                        if (_isNameLocked)
                          GestureDetector(
                            onTap: () => setState(() {
                              _isNameLocked = false;
                              _isVerified = false;
                              _saveDraft();
                            }),
                            child: Text(
                              'Not Correct?',
                              style: AppTextStyles.monoXs.copyWith(color: AppColors.pink, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      color: AppColors.surfaceHigh,
                      child: TextField(
                        controller: _nameController,
                        enabled: !_isNameLocked,
                        onChanged: (_) => _saveDraft(),
                        style: AppTextStyles.bodyLg.copyWith(
                          color: _isNameLocked ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Full Name',
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
                    const SizedBox(height: 32),

                    // 01_C_REG_NUMBER (New requirement)
                    Row(
                      children: [
                        _sectionLabel('Registration Number'),
                        const Spacer(),
                        if (_isRegLocked)
                          GestureDetector(
                            onTap: () => setState(() {
                              _isRegLocked = false;
                              _isVerified = false;
                              _saveDraft();
                            }),
                            child: Text(
                              'Not Correct?',
                              style: AppTextStyles.monoXs.copyWith(color: AppColors.pink, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      color: AppColors.surfaceHigh,
                      child: TextField(
                        controller: _regNumberController,
                        enabled: !_isRegLocked,
                        onChanged: (_) => _saveDraft(),
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: _isRegLocked ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Registration Number',
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
                    const SizedBox(height: 32),

                    // Create Password
                    _sectionLabel('Create Password'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      color: AppColors.surfaceHigh,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onChanged: (_) => _saveDraft(),
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter a strong password',
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
                    const SizedBox(height: 32),

                    // 02_BRANCH
                    _sectionLabel('Branch'),
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
                                'Select Branch',
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
                          onChanged: (v) => setState(() {
                            _selectedDept = v;
                            _saveDraft();
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 03_CHRONO_DATA (DOB)
                    _sectionLabel('Date of Birth'),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 32),

                    // 04_ACADEMIC_LEVEL
                    _sectionLabel('Academic Level'),
                    const SizedBox(height: 12),
                    _buildYearGrid(),
                    const SizedBox(height: 32),

                    // 05_INTERESTS_TAGS
                    Row(
                      children: [
                        _sectionLabel('Interests'),
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
                              _saveDraft();
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
                                    ? Colors.white
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Branch',
                                                  style: AppTextStyles.monoXs.copyWith(
                                                      color: AppColors.textMuted)),
                                              Text(
                                                _selectedDept?.replaceAll('DEPARTMENT OF ', '') ??
                                                    'Branch / Dept',
                                                style: AppTextStyles.monoSm.copyWith(
                                                  color: AppColors.accent,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Lvl',
                                                style: AppTextStyles.monoXs.copyWith(
                                                    color: AppColors.textMuted)),
                                            Text(
                                              _selectedYearLevel != null
                                                  ? 'Year ${_selectedYearLevel! + 1}'
                                                  : 'Year 2',
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
                              Expanded(
                                child: Text(
                                  _isVerified ? 'Status: Verified' : 'Status: Verification Required',
                                  style: AppTextStyles.monoXs.copyWith(
                                    color: _isVerified ? AppColors.accent : AppColors.pink,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
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
                      label: 'Initialize Account',
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
                          'Go Back Step 02',
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
                        GestureDetector(
                          onTap: () => _showOverlayModal(
                            'Privacy Protocols',
                            'GVibe values student privacy. All personal registration data is end-to-end verified. Your information is securely stored inside GITAM systems and will never be shared with third parties or external advertising networks.',
                          ),
                          child: Text('Privacy Protocols',
                              style: AppTextStyles.monoXs
                                  .copyWith(color: AppColors.textMuted, fontSize: 9)),
                        ),
                        GestureDetector(
                          onTap: () => _showOverlayModal(
                            'GVibe Guidelines',
                            'Be respectful and authentic. GVibe is an exclusive platform for verified student interactions. Impersonation, hate speech, spam, harassment, or sharing of non-consensual media will result in immediate and permanent account suspension.',
                          ),
                          child: Text('GVibe Guidelines',
                              style: AppTextStyles.monoXs
                                  .copyWith(color: AppColors.textMuted, fontSize: 9)),
                        ),
                        GestureDetector(
                          onTap: () => _showOverlayModal(
                            'Help Matrix',
                            'Need assistance? Access our 24/7 student support desk. You can contact support at support@student.gitam.edu or visit the help desk located inside the IT & Systems department at the central administration block.',
                          ),
                          child: Text('Help Matrix',
                              style: AppTextStyles.monoXs
                                  .copyWith(color: AppColors.textMuted, fontSize: 9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'System Version 4.2.0 Stable',
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

  // Date picker — scrollable drums
  Widget _buildDatePicker() {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final days = List.generate(31, (i) => i + 1);
    final years = List.generate(20, (i) => DateTime.now().year - 27 + i);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        children: [
          // Months column
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: months.length,
              itemBuilder: (context, idx) {
                final isSelected = idx == _selectedMonth;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedMonth = idx;
                    _saveDraft();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isSelected ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
                    child: Center(
                      child: Text(
                        months[idx],
                        style: AppTextStyles.monoMd.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(width: 1, color: AppColors.outline),
          // Days column
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: days.length,
              itemBuilder: (context, idx) {
                final val = days[idx];
                final isSelected = val == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay = val;
                    _saveDraft();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isSelected ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
                    child: Center(
                      child: Text(
                        '$val',
                        style: AppTextStyles.monoMd.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(width: 1, color: AppColors.outline),
          // Years column
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: years.length,
              itemBuilder: (context, idx) {
                final val = years[idx];
                final isSelected = val == _selectedYear;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedYear = val;
                    _saveDraft();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isSelected ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
                    child: Center(
                      child: Text(
                        '$val',
                        style: AppTextStyles.monoMd.copyWith(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
        onTap: () => setState(() {
          _selectedYearLevel = index;
          _saveDraft();
        }),
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
