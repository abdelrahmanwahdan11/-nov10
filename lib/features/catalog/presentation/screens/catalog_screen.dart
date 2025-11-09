import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/controllers/catalog_controller.dart';
import '../../../../core/models/item.dart';
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
}
