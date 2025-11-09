import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../core/models/item.dart';

class CatalogItemCard extends StatelessWidget {
  const CatalogItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.isComparing,
    required this.onCompareToggle,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final CatalogItem item;
  final VoidCallback onTap;
  final bool isComparing;
  final VoidCallback onCompareToggle;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'item-${item.id}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                scheme.surfaceVariant,
                scheme.surface,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 600),
                          scale: isComparing ? 1.02 : 1.0,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: IconButton.filled(
                          onPressed: onFavoriteToggle,
                          icon: Icon(
                            isFavorite ? IconlyBold.heart : IconlyLight.heart,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton.filledTonal(
                          onPressed: onCompareToggle,
                          icon: Icon(
                            isComparing ? IconlyBold.swap : IconlyLight.swap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('\$${item.price.toStringAsFixed(0)}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      children: item.tags
                          .map((tag) => Chip(
                                label: Text(tag.name),
                              ))
                          .toList(),
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
