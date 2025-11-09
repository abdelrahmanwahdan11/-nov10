import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/widgets/language_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onGuest,
    required this.onLoginSuccess,
    required this.onSignUpTap,
    required this.onForgotTap,
  });

  final VoidCallback onGuest;
  final VoidCallback onLoginSuccess;
  final VoidCallback onSignUpTap;
  final VoidCallback onForgotTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await AppScope.of(context)
        .authController
        .signIn(email: _emailController.text.trim());
    setState(() => _loading = false);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            if (mounted) setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: const LanguageSwitcher(),
              ),
              const SizedBox(height: 40),
              Text(
                locale.translate('login'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: locale.translate('email'),
                        prefixIcon: const Icon(IconlyLight.message),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!value.contains('@')) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: locale.translate('password'),
                        prefixIcon: const Icon(IconlyLight.lock),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            _obscure = !_obscure;
                          }),
                          icon: Icon(_obscure ? IconlyLight.show : IconlyBold.show),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 8) {
                          return 'Use 8+ characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _PasswordStrengthIndicator(controller: _passwordController),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: widget.onForgotTap,
                        child: Text(locale.translate('forgot_password')),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(IconlyBold.login),
                      label: Text(locale.translate('login')),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: widget.onSignUpTap,
                      child: Text(locale.translate('signup')),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: widget.onGuest,
                      icon: const Icon(IconlyLight.user),
                      label: Text(locale.translate('guest')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.controller});

  final TextEditingController controller;

  double _calculateStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.3;
    if (RegExp(r'[A-Zأ-ي]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength += 0.3;
    return strength.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final strength = _calculateStrength(value.text);
        String label;
        if (strength < 0.4) {
          label = locale.translate('strength_weak');
        } else if (strength < 0.7) {
          label = locale.translate('strength_medium');
        } else {
          label = locale.translate('strength_strong');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: strength),
            const SizedBox(height: 4),
            Text('\${locale.translate('password_strength')}: \$label'),
          ],
        );
      },
    );
  }
}
