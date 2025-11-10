import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/controllers/catalog_controller.dart';
import '../../../../core/controllers/showroom_controller.dart';
import '../../../../core/models/item.dart';
import '../../../../core/models/showroom_scene.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/catalog_item_card.dart';
import '../widgets/comparison_bar.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.onSelectItem});

  final ValueChanged<CatalogItem> onSelectItem;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late CatalogController _controller;
  late ShowroomController _showroomController;
  late final ScrollController _scrollController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_controller.hasMore &&
            _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200) {
          _controller.loadMore();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _controller = AppScope.of(context).catalogController;
      _showroomController = AppScope.of(context).showroomController;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final items = _controller.items;
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _controller.onlyFavorites
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Chip(
                                        key: const ValueKey('favorites_chip'),
                                        avatar: const Icon(IconlyBold.heart, size: 18),
                                        label: Text(locale.translate('favorites_active')),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: ItemCategory.values
                                  .map((category) => FilterChip(
                                        label: Text(category.localized(
                                    isArabic: locale.locale.languageCode == 'ar',
                                  )),
                                  selected: _controller.activeCategories.contains(category),
                                  onSelected: (_) => _controller.toggleCategory(category),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilterChip(
                            label: Text(locale.translate('favorites_only')),
                            selected: _controller.onlyFavorites,
                            onSelected: (_) => _controller.toggleFavorites(),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(IconlyBold.info_circle),
                            label: Text(locale.translate('ai_soon')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_showroomController.recommendedScenes.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 190,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _showroomController.recommendedScenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final scene = _showroomController.recommendedScenes[index];
                        return _ScenePreview(
                          scene: scene,
                          onTap: () => _openScenePreview(scene),
                        );
                      },
                    ),
                  ),
                ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return CatalogItemCard(
                          item: item,
                          isComparing: _controller.isInComparison(item),
                          onCompareToggle: () => _controller.toggleCompare(item),
                          isFavorite: _controller.isFavorite(item),
                          onFavoriteToggle: () => _controller.toggleFavorite(item),
                          onTap: () => widget.onSelectItem(item),
                        );
                      },
                      childCount: items.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                  ),
                ),
              if (_controller.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: const [
                        SkeletonBox(height: 220),
                        SizedBox(height: 16),
                        SkeletonBox(height: 220),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _controller.hasMore ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(_controller.hasMore
                          ? '...'
                          : locale.translate('catalog')),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ComparisonBar(
                  items: _controller.comparisonItems,
                  onRemove: _controller.toggleCompare,
                  onCompare: () {
                    if (_controller.comparisonItems.isEmpty) return;
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _controller.comparisonItems.length,
                          itemBuilder: (context, index) {
                            final item = _controller.comparisonItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Text(item.description),
                                    const SizedBox(height: 8),
                                    Text('Price: \${item.price.toStringAsFixed(2)}'),
                                    const SizedBox(height: 8),
                                    Text('Materials: \${item.materials}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openScenePreview(ShowroomScene scene) {
    final items = _showroomController.resolveItems(scene);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _SceneDetailSheet(
          scene: scene,
          items: items,
          controller: _controller,
          onSelectItem: widget.onSelectItem,
        );
      },
    );
  }
}

class _ScenePreview extends StatelessWidget {
  const _ScenePreview({required this.scene, required this.onTap});

  final ShowroomScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceVariant,
              theme.colorScheme.surface,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  '${scene.heroImage}?auto=format&fit=crop&w=600&q=80',
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.8),
                      label: Text(scene.mood.localizedLabel(
                        isArabic: Directionality.of(context) == TextDirection.rtl,
                      )),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scene.title,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
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

class _SceneDetailSheet extends StatelessWidget {
  const _SceneDetailSheet({
    required this.scene,
    required this.items,
    required this.controller,
    required this.onSelectItem,
  });

  final ShowroomScene scene;
  final List<CatalogItem> items;
  final CatalogController controller;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scene.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(scene.subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scene.highlights
                  .map((highlight) => Chip(
                        avatar: const Icon(IconlyBold.star, size: 16),
                        label: Text(highlight),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isFavorite = controller.isFavorite(item);
                  final isComparing = controller.isInComparison(item);
                  return Card(
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
                            icon: Icon(isFavorite ? IconlyBold.heart : IconlyLight.heart),
                            onPressed: () => controller.toggleFavorite(item),
                          ),
                          IconButton(
                            icon: Icon(isComparing ? IconlyBold.swap : IconlyLight.swap),
                            onPressed: () => controller.toggleCompare(item),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectItem(item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
