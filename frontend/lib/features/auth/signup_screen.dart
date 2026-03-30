import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (!_emailController.text.endsWith('@student.gitam.edu')) {
      setState(() => _error = 'ONLY @student.gitam.edu EMAILS ACCEPTED');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'PASSWORD MUST BE AT LEAST 6 CHARACTERS');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.post(
        '/auth/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        await AuthService.saveToken(data['data']['token']);
        await AuthService.saveUser(data['data']);
      }
      if (mounted) context.go(AppRouter.onboarding);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'SIGNUP_FAILED. TRY AGAIN.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Column(
          children: [
            // Top section — black with JOIN GVIBE
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // Large decorative lightning bolt
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Text(
                      '⚡',
                      style: TextStyle(
                        fontSize: 180,
                        color: AppColors.accentDark.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Text(
                        'JOIN GVIBE',
                        style: AppTextStyles.displayXl.copyWith(
                          color: AppColors.accent,
                          shadows: [
                            const Shadow(
                              color: AppColors.pink,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(height: 2, color: AppColors.accent),
            // Bottom section — form
            Expanded(
              flex: 4,
              child: Container(
                color: AppColors.surface,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Google button (outlined style)
                      _buildGoogleButton(),
                      const SizedBox(height: 24),
                      // Divider
                      _buildDivider('OR CREATE WITH EMAIL'),
                      const SizedBox(height: 24),
                      // Name field
                      GVibeTextField(
                        label: 'YOUR NAME',
                        hint: 'FULL NAME',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      // Email field
                      GVibeTextField(
                        label: 'CAMPUS EMAIL',
                        hint: 'you@student.gitam.edu',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        suffix: const Icon(Icons.alternate_email,
                            color: AppColors.textSecondary, size: 18),
                      ),
                      const SizedBox(height: 20),
                      // Password field
                      GVibeTextField(
                        label: 'PASSWORD',
                        hint: 'MIN 6 CHARACTERS',
                        obscureText: _obscure,
                        controller: _passwordController,
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure ? Icons.lock_outline : Icons.lock_open,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: AppTextStyles.monoXs
                                .copyWith(color: AppColors.pink)),
                      ],
                      const SizedBox(height: 24),
                      GVibeButton(
                        label: 'CREATE ACCOUNT',
                        onPressed: _createAccount,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'SECURE ENROLLMENT: ONLY @student.gitam.edu EMAILS\nACCEPTED',
                          style: AppTextStyles.monoXs
                              .copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ALREADY HAVE AN ACCOUNT?  ',
                              style: AppTextStyles.monoSm
                                  .copyWith(color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: () => context.go(AppRouter.login),
                            child: Text(
                              'SIGN IN',
                              style: AppTextStyles.monoSm.copyWith(
                                color: AppColors.pink,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.pink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.g_mobiledata,
              color: AppColors.textPrimary, size: 28),
          const SizedBox(width: 12),
          Text(
            'CONTINUE WITH GOOGLE',
            style: AppTextStyles.buttonSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style:
                  AppTextStyles.monoXs.copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.outline)),
      ],
    );
  }
}
