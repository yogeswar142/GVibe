import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.data['success'] == true) {
        final data = response.data['data'];
        await AuthService.saveToken(data['token']);
        await AuthService.saveUser(data);
        if (mounted) context.go(AppRouter.home);
      } else {
        setState(() => _error = response.data['message'] ?? 'Login failed');
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
          // Subtle radial glow background
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withOpacity(isDark ? 0.12 : 0.08),
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
                  // Brand
                  GradientText(
                    'GVibe',
                    style: AppTextStyles.displaySm.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 40),
                  // Heading
                  Text(
                    'Welcome\nback',
                    style: AppTextStyles.displayXl.copyWith(
                      color: cs.onBackground,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to your campus network',
                    style: AppTextStyles.bodyMd.copyWith(
                        color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 36),
                  // Error banner
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cs.error.withOpacity(0.3)),
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
                  // Email field
                  GVibeTextField(
                    label: 'Email',
                    hint: 'you@university.edu',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  GVibeTextField(
                    label: 'Password',
                    hint: '••••••••',
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.bodySm.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GVibeButton(
                    label: 'Sign In',
                    onPressed: _login,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 24),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: ext.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: AppTextStyles.bodyXs.copyWith(
                              color: cs.onSurfaceVariant),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: ext.outline)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Google button
                  GVibeButton(
                    label: 'Continue with Google',
                    isPrimary: false,
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 32),
                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "New to GVibe? ",
                          style: AppTextStyles.bodyMd.copyWith(
                              color: cs.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRouter.signup),
                          child: Text(
                            'Create account',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
