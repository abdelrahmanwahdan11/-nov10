import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/models/item.dart';
import '../../../../core/widgets/immersive_item_viewer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  CatalogItem? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final pages = [
      CatalogScreen(onSelectItem: (item) {
        setState(() => _selectedItem = item);
      }),
      SearchScreen(onSelectItem: (item) {
        setState(() => _selectedItem = item);
      }),
      SettingsScreen(onColorChanged: (color) {
        scope.themeController.updateSeedColor(color);
        scope.preferences.setPrimaryColor(color);
      }, onModeChanged: (mode) {
        scope.themeController.setMode(mode);
        scope.preferences.setThemeMode(mode);
      }, onSignOut: widget.onSignOut),
    ];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(localization.translate('app_title')),
            actions: [
              IconButton(
                onPressed: () async {
                  await scope.authController.signOut();
                  if (context.mounted) {
                    widget.onSignOut();
                  }
                },
                icon: const Icon(IconlyLight.logout),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(IconlyLight.category),
                selectedIcon: const Icon(IconlyBold.category),
                label: localization.translate('catalog'),
              ),
              NavigationDestination(
                icon: const Icon(IconlyLight.search),
                selectedIcon: const Icon(IconlyBold.search),
                label: localization.translate('search_hint'),
              ),
              NavigationDestination(
                icon: const Icon(IconlyLight.setting),
                selectedIcon: const Icon(IconlyBold.setting),
                label: localization.translate('settings'),
              ),
            ],
          ),
        ),
        if (_selectedItem != null)
          ImmersiveItemViewer(
            item: _selectedItem!,
            onClose: () => setState(() => _selectedItem = null),
          ),
      ],
    );
  }
}
