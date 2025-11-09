import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final locale = scope.localeNotifier.value;
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(value: 'ar', label: Text('العربية')),
        ButtonSegment<String>(value: 'en', label: Text('English')),
      ],
      selected: {locale.languageCode},
      onSelectionChanged: (value) {
        final code = value.first;
        scope.localeNotifier.value = Locale(code);
      },
    );
  }
}
