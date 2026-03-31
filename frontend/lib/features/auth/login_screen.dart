import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
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
      setState(() => _error = e.response?.data?['message'] ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Stack(
          children: [
            // Grid bg
            Positioned.fill(
              child: CustomPaint(painter: _LoginGridPainter()),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // GVIBE logo top-left
                      Text(
                        'GVIBE',
                        style: AppTextStyles.displaySm.copyWith(
                          color: AppColors.accent,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // WELCOME BACK — massive heading
                      Text(
                        'WELCOME\nBACK',
                        style: AppTextStyles.displayXl.copyWith(
                          fontSize: 72,
                          height: 0.95,
                          letterSpacing: -2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ACCESS YOUR CAMPUS FREQUENCY',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 2.0,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Error message
                      if (_error != null) ...[
                        Container(
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
                        const SizedBox(height: 20),
                      ],
                      // CONTINUE WITH GOOGLE button — big with yellow border
                      Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textMuted, width: 1),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            Text(
                              'GOOGLE',
                              style: AppTextStyles.displaySm.copyWith(
                                color: AppColors.accent,
                                fontSize: 24,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'CONTINUE',
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1.5,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'WITH GOOGLE',
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1.5,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // OR MANUAL LOG divider
                      Row(
                        children: [
                          Expanded(
                              child: Container(height: 1, color: AppColors.outline)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR MANUAL LOG',
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
                      const SizedBox(height: 28),
                      // IDENTIFIER / USERNAME field
                      Text(
                        'IDENTIFIER / USERNAME',
                        style: AppTextStyles.monoXs.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'VIBE_OPERATOR_42',
                          hintStyle: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            fontSize: 20,
                          ),
                          filled: false,
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.outline),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.accent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.only(bottom: 12),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // SECRET_KEY field
                      Text(
                        'SECRET_KEY',
                        style: AppTextStyles.monoXs.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            fontSize: 20,
                          ),
                          filled: false,
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.outline),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.accent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.only(bottom: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // FORGOT PASSWORD?
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'FORGOT PASSWORD?',
                          style: AppTextStyles.monoXs.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // SIGN IN button — acid yellow
                      GVibeButton(
                        label: 'SIGN IN',
                        onPressed: _login,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 28),
                      // Divider
                      Container(height: 1, color: AppColors.outline),
                      const SizedBox(height: 20),
                      // NEW HERE? CREATE ACCOUNT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'NEW HERE?  ',
                            style: AppTextStyles.monoSm.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRouter.signup),
                            child: Text(
                              'CREATE ACCOUNT',
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
          ],
        ),
      ),
    );
  }
}

class _LoginGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
