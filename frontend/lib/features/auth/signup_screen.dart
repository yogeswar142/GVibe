import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _loading = false;
  String? _error;

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
    super.dispose();
  }

  Widget _buildBackground(BuildContext context, bool isDark) {
    if (isDark) {
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
                color: Color(0x115E6AD2),
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
                color: Color(0x1CFF0080),
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
                color: Color(0x1700DFD8),
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
            child: Column(
              children: [
                // ── Fixed top: Back button ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  ),
                ),

                // ── Flexible middle: wordmark + card ──────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Wordmark
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'GVIBE',
                                  style: AppTextStyles.displayLg.copyWith(
                                    color: isDark
                                        ? const Color(0xFFF7F8F8)
                                        : const Color(0xFF171717),
                                    letterSpacing: -2.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create Campus Account',
                                  style: AppTextStyles.monoXs.copyWith(
                                    color: isDark
                                        ? const Color(0xFF8A8F98)
                                        : const Color(0xFF8F8F8F),
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
                                  'Verify student identity via Google Auth to continue',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Error display
                                if (_error != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.error.withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(isDark ? 8 : 6),
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

                                // Google button
                                GVibeButton(
                                  label: 'Continue with Google',
                                  isPrimary: true,
                                  icon: Icons.g_mobiledata_rounded,
                                  onPressed: () async {
                                    setState(() => _error = null);
                                    final response =
                                        await AuthService.triggerGoogleAuth(
                                      context: context,
                                      action: 'register',
                                    );
                                    if (response != null &&
                                        response['success'] == true) {
                                      final data = response['data'];
                                      await AuthService.saveToken(data['token']);
                                      await AuthService.saveUser(data);
                                      // BUG-01 fix: regenerate + upload fresh E2EE key on registration
                                      await AuthService.uploadFreshKeys(ApiService());
                                      if (mounted) {
                                        context.go(AppRouter.onboarding);
                                      }
                                    } else if (response != null) {
                                      final msg = response['message'] ?? '';
                                      if (response['code'] == 'USER_EXISTS' ||
                                          msg.contains('already exists')) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Account already exists! Redirecting to login...'),
                                          ));
                                          context.go(AppRouter.login);
                                        }
                                      } else {
                                        setState(() => _error = msg.isNotEmpty
                                            ? msg
                                            : 'Google registration failed');
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'Only @student.gitam.edu emails are accepted',
                                    style: AppTextStyles.bodyXs.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
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

                // ── Fixed bottom: Already have account ─────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 16),
                  child: Center(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
