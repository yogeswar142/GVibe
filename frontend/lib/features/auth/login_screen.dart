import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.post(
        '/auth/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        await AuthService.saveToken(data['data']['token']);
        await AuthService.saveUser(data['data']);
      }
      if (mounted) context.go(AppRouter.home);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'LOGIN_FAILED. TRY AGAIN.';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Text(
                  'GVIBE',
                  style: AppTextStyles.displaySm.copyWith(
                    color: AppColors.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
                // Hero text
                Text(
                  'WELCOME\nBACK',
                  style: AppTextStyles.displayXl.copyWith(
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ACCESS YOUR CAMPUS FREQUENCY',
                  style: AppTextStyles.monoSm.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                // Google button
                _buildGoogleButton(),
                const SizedBox(height: 32),
                // Divider
                _buildDivider('OR MANUAL LOG'),
                const SizedBox(height: 32),
                // Email
                GVibeTextField(
                  label: 'EMAIL',
                  hint: 'you@student.gitam.edu',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                // Password
                GVibeTextField(
                  label: 'SECRET_KEY',
                  hint: '············',
                  obscureText: _obscure,
                  controller: _passwordController,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'FORGOT PASSWORD?',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style:
                          AppTextStyles.monoXs.copyWith(color: AppColors.pink)),
                ],
                const SizedBox(height: 32),
                GVibeButton(
                  label: 'SIGN IN',
                  onPressed: _signIn,
                  isLoading: _loading,
                ),
                const SizedBox(height: 48),
                // Footer divider
                Container(height: 1, color: AppColors.outline),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('NEW HERE?  ',
                        style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1)),
                    GestureDetector(
                      onTap: () => context.go(AppRouter.signup),
                      child: Text(
                        'CREATE ACCOUNT',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.pink,
                          letterSpacing: 1,
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
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 64,
        color: AppColors.surface,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  'GOOGLE',
                  style: AppTextStyles.displaySm.copyWith(
                    color: AppColors.accent,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: double.infinity,
              color: AppColors.outline,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONTINUE',
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.textPrimary, letterSpacing: 2)),
                  Text('WITH GOOGLE',
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.textPrimary, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
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
              style: AppTextStyles.monoXs.copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.outline)),
      ],
    );
  }
}
