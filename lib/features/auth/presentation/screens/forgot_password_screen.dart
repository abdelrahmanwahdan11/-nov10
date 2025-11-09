import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('forgot_password')),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() => _submitted = false);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              locale.translate('reset_password'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: locale.translate('email'),
                prefixIcon: const Icon(IconlyLight.message),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => _submitted = true);
              },
              child: Text(locale.translate('reset_password')),
            ),
            if (_submitted) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '📬 ${locale.translate('reset_password')} email sent (mock).',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
