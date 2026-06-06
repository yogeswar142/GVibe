import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.background,
      body: Stack(
        children: [
          // Radial glow (bottom-right)
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.secondary.withOpacity(isDark ? 0.1 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Back button
                  GestureDetector(
                    onTap: () => context.go(AppRouter.login),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded,
                            color: cs.onSurfaceVariant, size: 20),
                        const SizedBox(width: 6),
                        Text('Sign in',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Heading
                  Text(
                    'Join\nGVibe',
                    style: AppTextStyles.displayXl.copyWith(
                      color: cs.onBackground,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connect with your campus community',
                    style: AppTextStyles.bodyMd.copyWith(
                        color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 36),
                  // Error
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: cs.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: cs.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: cs.error)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Email
                  GVibeTextField(
                    label: 'Campus Email',
                    hint: 'you@university.edu',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    suffix: Icon(Icons.alternate_email_rounded,
                        color: cs.onSurfaceVariant, size: 18),
                  ),
                  const SizedBox(height: 16),
                  // Password
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
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GVibeButton(
                    label: 'Create Account',
                    onPressed: _signup,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Only @student emails accepted',
                      style: AppTextStyles.bodyXs.copyWith(
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: ext.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: AppTextStyles.bodyXs.copyWith(
                                color: cs.onSurfaceVariant)),
                      ),
                      Expanded(child: Divider(color: ext.outline)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GVibeButton(
                    label: 'Continue with Google',
                    isPrimary: false,
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Already have an account? ',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: cs.onSurfaceVariant)),
                        GestureDetector(
                          onTap: () => context.go(AppRouter.login),
                          child: Text('Sign in',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
