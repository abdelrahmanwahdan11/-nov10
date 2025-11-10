import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.passwordListenable});

  final TextEditingController passwordListenable;

  bool _check(String pattern) => RegExp(pattern).hasMatch(passwordListenable.text);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: passwordListenable,
      builder: (context, _) {
        final password = passwordListenable.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.translate('password_strength')),
            const SizedBox(height: 8),
            _RequirementRow(
              met: password.length >= 8,
              label: '8+ ${locale.translate('characters')}',
            ),
            _RequirementRow(
              met: _check(r'[A-Zأ-ي]'),
              label: locale.translate('uppercase'),
            ),
            _RequirementRow(
              met: _check(r'[0-9]'),
              label: locale.translate('numbers'),
            ),
            _RequirementRow(
              met: _check(r'[!@#\$&*~]'),
              label: locale.translate('symbols'),
            ),
          ],
        );
      },
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: met
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
