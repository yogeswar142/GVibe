import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
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
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    final isOnline = await ApiService().checkConnection();
    if (!mounted) return;
    if (!isOnline) {
      context.go(AppRouter.backendDown);
    }
  }

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
        // BUG-01 fix: regenerate + upload a fresh E2EE key after every login
        // so device key and server key are guaranteed to be in sync.
        await AuthService.uploadFreshKeys(ApiService());
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

  Widget _buildBackground(BuildContext context, bool isDark) {
    if (isDark) {
      // Linear: extremely subtle ambient dark glow at the top center
      return Stack(
        children: [
          Container(color: const Color(0xFF010102)),
          Positioned(
            top: -150,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x135E6AD2), // Very soft lavender glow
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
      // Vercel: soft blooming multi-stop mesh gradient at the top/center
      return Stack(
        children: [
          Container(color: const Color(0xFFFAFAFA)),
          Positioned(
            top: -120,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1F00DFD8), // Cyan
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFF0080), // Magenta
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1A7928CA), // Purple
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
                      // GVibe Logo/Wordmark
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
                              'Campus Network Platform',
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

                      // Form Card
                      GVibeCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(isDark ? 12 : 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: AppTextStyles.displaySm.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue to your dashboard',
                              style: AppTextStyles.bodySm.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error banner
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

                            // Email field
                            GVibeTextField(
                              label: 'Email Address',
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
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Forgot password?',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: linkColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign In Button
                            GVibeButton(
                              label: 'Sign In',
                              onPressed: _login,
                              isLoading: _loading,
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

                            // Google Button
                            GVibeButton(
                              label: 'Google Account',
                              isPrimary: false,
                              icon: Icons.g_mobiledata_rounded,
                              onPressed: () async {
                                setState(() {
                                  _error = null;
                                });
                                final response = await AuthService.triggerGoogleAuth(
                                  context: context,
                                  action: 'login',
                                );
                                if (response != null && response['success'] == true) {
                                   final data = response['data'];
                                   await AuthService.saveToken(data['token']);
                                   await AuthService.saveUser(data);
                                   // BUG-01 fix: regenerate + upload fresh E2EE key
                                   await AuthService.uploadFreshKeys(ApiService());
                                   if (mounted) {
                                     if (data['profileComplete'] == true) {
                                       context.go(AppRouter.home);
                                     } else {
                                       context.go(AppRouter.onboarding);
                                     }
                                   }
                                 } else if (response != null) {
                                  setState(() => _error = response['message'] ?? 'Google login failed');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign up navigation
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "New to GVibe? ",
                              style: AppTextStyles.bodyMd.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRouter.signup),
                              child: Text(
                                'Create account',
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
