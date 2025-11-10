import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/controllers/catalog_controller.dart';
import '../../../../core/models/item.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.onSelectItem});

  final ValueChanged<CatalogItem> onSelectItem;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late CatalogController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppScope.of(context).catalogController;
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          final results = _controller.filteredItems;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: locale.translate('search_hint'),
                  prefixIcon: const Icon(IconlyLight.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _controller.updateSearch('');
                    },
                    icon: const Icon(IconlyLight.close_square),
                  ),
                ),
                onChanged: _controller.updateSearch,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ItemTag.values
                    .map((tag) => FilterChip(
                          label: Text(tag.name),
                          selected: _controller.filteredItems
                              .where((item) => item.tags.contains(tag))
                              .length == results.length,
                          onSelected: (selected) {
                            if (selected) {
                              _controller.updateSearch(tag.name);
                            } else {
                              _controller.updateSearch('');
                            }
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (_controller.isLoading)
                const SkeletonBox(height: 120)
              else
                ...results.map(
                  (item) => ListTile(
                    onTap: () => widget.onSelectItem(item),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(item.imageUrl, width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    title: Text(item.name),
                    subtitle: Text(item.description),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller.isFavorite(item)
                                ? IconlyBold.heart
                                : IconlyLight.heart,
                          ),
                          onPressed: () => _controller.toggleFavorite(item),
                        ),
                        IconButton(
                          icon: Icon(
                            _controller.isInComparison(item)
                                ? IconlyBold.swap
                                : IconlyLight.swap,
                          ),
                          onPressed: () => _controller.toggleCompare(item),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
