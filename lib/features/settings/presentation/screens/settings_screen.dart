import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/language_switcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onColorChanged,
    required this.onModeChanged,
    required this.onSignOut,
  });

  final ValueChanged<Color> onColorChanged;
  final ValueChanged<ThemeMode> onModeChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = [
      Colors.deepPurple,
      Colors.teal,
      Colors.orange,
      Colors.blueGrey,
      Colors.pink,
      Colors.green,
    ];
    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(IconlyLight.moon),
            title: Text(localization.translate('dark_mode')),
            trailing: Switch(
              value: scope.themeController.mode == ThemeMode.dark,
              onChanged: (value) => onModeChanged(
                value ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(localization.translate('primary_color'),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors
                .map(
                  (color) => GestureDetector(
                    onTap: () => onColorChanged(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: scope.themeController.seedColor == color
                              ? theme.colorScheme.onPrimary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(localization.translate('language'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const LanguageSwitcher(),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(IconlyLight.info_circle),
            title: Text(localization.translate('ai_soon')),
            subtitle: const Text('ميزة الذكاء الاصطناعي ستدمج لاحقاً.'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSignOut,
            icon: const Icon(IconlyLight.logout),
            label: Text(localization.translate('logout')),
          ),
        ],
      ),
    );
  }
}
