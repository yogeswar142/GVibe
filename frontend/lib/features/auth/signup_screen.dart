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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final name = email.split('@').first.toUpperCase().replaceAll('.', '_');
      final response = await ApiService().dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await AuthService.saveToken(data['token']);
        await AuthService.saveUser(data);
        if (mounted) context.go(AppRouter.onboarding);
      } else {
        setState(() => _error = response.data['message'] ?? 'Signup failed');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Signup failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // JOIN GVIBE — huge centered heading with accent bolt behind
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Accent bolt graphic behind text
                      Positioned(
                        right: 80,
                        top: 20,
                        child: Transform.rotate(
                          angle: -0.3,
                          child: Icon(
                            Icons.bolt,
                            size: 160,
                            color: AppColors.accent.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      // JOIN GVIBE text
                      Text(
                        'JOIN GVIBE',
                        style: AppTextStyles.displayXl.copyWith(
                          fontSize: 56,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                // Full-width accent yellow divider bar
                Container(
                  width: double.infinity,
                  height: 4,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 36),
                // Error
                if (_error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.pink, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.pink, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.monoSm
                                    .copyWith(color: AppColors.pink)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // CONTINUE WITH GOOGLE button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textMuted, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'G',
                          style: AppTextStyles.displaySm.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'CONTINUE WITH GOOGLE',
                          style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // OR CREATE WITH EMAIL divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                          child: Container(height: 1, color: AppColors.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR CREATE WITH EMAIL',
                          style: AppTextStyles.monoXs.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Container(height: 1, color: AppColors.outline)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                // CAMPUS EMAIL field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.monoMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'CAMPUS EMAIL',
                      hintStyle: AppTextStyles.monoMd.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                      filled: false,
                      suffixIcon: const Icon(Icons.alternate_email,
                          color: AppColors.textMuted, size: 20),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.only(bottom: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // PASSWORD field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: AppTextStyles.monoMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'PASSWORD',
                      hintStyle: AppTextStyles.monoMd.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                      filled: false,
                      suffixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textMuted, size: 20),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.only(bottom: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // CREATE ACCOUNT button — acid yellow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GVibeButton(
                    label: 'CREATE ACCOUNT',
                    onPressed: _signup,
                    isLoading: _loading,
                  ),
                ),
                const SizedBox(height: 20),
                // Secure enrollment notice
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'SECURE ENROLLMENT: ONLY @STUDENT.GITAM.EDU EMAILS ACCEPTED',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoXs.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // ALREADY HAVE AN ACCOUNT? SIGN IN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ALREADY HAVE AN ACCOUNT?  ',
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: Text(
                        'SIGN IN',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.pink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
