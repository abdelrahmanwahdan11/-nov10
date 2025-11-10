import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/controllers/catalog_controller.dart';
import '../../../../core/controllers/showroom_controller.dart';
import '../../../../core/models/item.dart';
import '../../../../core/models/showroom_scene.dart';
import '../../../../l10n/app_localizations.dart';

class ShowroomScreen extends StatefulWidget {
  const ShowroomScreen({super.key, required this.onSelectItem});

  final ValueChanged<CatalogItem> onSelectItem;

  @override
  State<ShowroomScreen> createState() => _ShowroomScreenState();
}

class _ShowroomScreenState extends State<ShowroomScreen> {
  late ShowroomController _controller;
  late CatalogController _catalogController;
  late final PageController _pageController;
  bool _initialized = false;
  int? _lastSyncedPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final scope = AppScope.of(context);
      _controller = scope.showroomController;
      _catalogController = scope.catalogController;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scenes = _controller.scenes;
        if (scenes.isNotEmpty && _pageController.hasClients) {
          final target = _controller.currentIndex;
          if (_lastSyncedPage != target) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_pageController.hasClients) return;
              _pageController.animateToPage(
                target,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            });
            _lastSyncedPage = target;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            _controller.setMood(null);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _buildMoodSelector(localization),
              const SizedBox(height: 16),
              SizedBox(
                height: 340,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: scenes.length,
                  onPageChanged: (index) {
                    _lastSyncedPage = index;
                    _controller.setIndex(index);
                  },
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return _SceneCard(
                      scene: scene,
                      controller: _controller,
                      onViewItems: () => _openSceneItems(scene),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPageIndicators(scenes.length),
              const SizedBox(height: 24),
              _buildStorySection(localization),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _controller.toggleAutoCycle,
                icon: Icon(
                  _controller.isAutoCycling ? IconlyBold.play : IconlyLight.play,
                ),
                label: Text(
                  _controller.isAutoCycling
                      ? localization.translate('stop_auto_cycle')
                      : localization.translate('start_auto_cycle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodSelector(AppLocalizations localization) {
    final isArabic = localization.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localization.translate('showroom_moods'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<String?>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<String?>(
              value: null,
              label: Text(localization.translate('mood_all')),
            ),
            ...SceneMood.values.map(
              (mood) => ButtonSegment<String?>(
                value: mood.storageKey,
                label: Text(mood.localizedLabel(isArabic: isArabic)),
              ),
            ),
          ],
          selected: {_controller.activeMood?.storageKey},
          onSelectionChanged: (value) {
            final key = value.first;
            if (key == null) {
              _controller.setMood(null);
            } else {
              final mood = SceneMood.values
                  .firstWhere((element) => element.storageKey == key);
              _controller.setMood(mood);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _controller.currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 28 : 12,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _buildStorySection(AppLocalizations localization) {
    final scenes = _controller.scenes;
    if (scenes.isEmpty) {
      return const SizedBox.shrink();
    }
    final scene = scenes[_controller.currentIndex];
    final featuredItems = _controller.resolveItems(scene).take(3).toList();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey(scene.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localization.translate('scene_story_title'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(scene.story),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scene.highlights
                .map(
                  (highlight) => Chip(
                    avatar: const Icon(IconlyLight.star),
                    label: Text(highlight),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(localization.translate('featured_items'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featuredItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = featuredItems[index];
                return GestureDetector(
                  onTap: () => widget.onSelectItem(item),
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondaryContainer,
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSceneItems(ShowroomScene scene) {
    final items = _controller.resolveItems(scene);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: _catalogController,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(scene.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(item.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.description),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: Icon(
                              _catalogController.isFavorite(item)
                                  ? IconlyBold.heart
                                  : IconlyLight.heart,
                            ),
                            onPressed: () => _catalogController.toggleFavorite(item),
                          ),
                          IconButton(
                            icon: Icon(
                              _catalogController.isInComparison(item)
                                  ? IconlyBold.swap
                                  : IconlyLight.swap,
                            ),
                            onPressed: () => _catalogController.toggleCompare(item),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onSelectItem(item);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.controller,
    required this.onViewItems,
  });

  final ShowroomScene scene;
  final ShowroomController controller;
  final VoidCallback onViewItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.network(
                  '${scene.heroImage}?auto=format&fit=crop&w=1080&q=80',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(
                      scene.mood.localizedLabel(
                        isArabic: Directionality.of(context) == TextDirection.rtl,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    scene.title,
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scene.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: onViewItems,
                    child: Text(AppLocalizations.of(context).translate('view_scene_items')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
