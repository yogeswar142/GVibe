import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
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
  bool _obscurePassword = true;

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
      setState(() => _error = ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildBackground(BuildContext context, bool isDark) {
    if (isDark) {
      // Linear: subtle ambient glow at bottom center/right
      return Stack(
        children: [
          Container(color: const Color(0xFF010102)),
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x115E6AD2), // soft lavender glow
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      );
    } else {
      // Vercel: soft blooming multi-stop mesh gradient at bottom/right
      return Stack(
        children: [
          Container(color: const Color(0xFFFAFAFA)),
          Positioned(
            bottom: -120,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1CFF0080), // Magenta
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1700DFD8), // Cyan
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 95.0, sigmaY: 95.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? cs.primary : const Color(0xFF0070F3);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button / Sign In link
                      GestureDetector(
                        onTap: () => context.go(AppRouter.login),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded,
                                  color: cs.onSurfaceVariant, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Sign in',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Wordmark
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'GVIBE',
                              style: AppTextStyles.displayLg.copyWith(
                                color: isDark ? const Color(0xFFF7F8F8) : const Color(0xFF171717),
                                letterSpacing: -2.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create Campus Account',
                              style: AppTextStyles.monoXs.copyWith(
                                color: isDark ? const Color(0xFF8A8F98) : const Color(0xFF8F8F8F),
                                letterSpacing: 1.0,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Card form
                      GVibeCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(isDark ? 12 : 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join GVibe',
                              style: AppTextStyles.displaySm.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect with your campus community today',
                              style: AppTextStyles.bodySm.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error Display
                            if (_error != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                                  border: Border.all(
                                    color: cs.error.withValues(alpha: 0.20),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        color: cs.error, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: AppTextStyles.bodyXs.copyWith(
                                          color: cs.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Address Field
                            GVibeTextField(
                              label: 'Campus Email',
                              hint: 'you@university.edu',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              suffix: Icon(Icons.alternate_email_rounded,
                                  color: cs.onSurfaceVariant, size: 16),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            GVibeTextField(
                              label: 'Password',
                              hint: 'Min. 6 characters',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffix: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: cs.onSurfaceVariant,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            GVibeButton(
                              label: 'Create Account',
                              onPressed: _signup,
                              isLoading: _loading,
                            ),
                            const SizedBox(height: 14),

                            // Student domain disclaimer
                            Center(
                              child: Text(
                                'Only verified student emails accepted',
                                style: AppTextStyles.bodyXs.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: cs.outline)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'or continue with',
                                    style: AppTextStyles.bodyXs.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: cs.outline)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google button
                            GVibeButton(
                              label: 'Google Account',
                              isPrimary: false,
                              icon: Icons.g_mobiledata_rounded,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Already have an account? Sign in
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRouter.login),
                              child: Text(
                                'Sign in',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: linkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
