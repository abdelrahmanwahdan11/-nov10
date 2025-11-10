import 'package:flutter/material.dart';

import '../../../../core/models/item.dart';
import '../../../../l10n/app_localizations.dart';

class ComparisonBar extends StatelessWidget {
  const ComparisonBar({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onCompare,
  });

  final List<CatalogItem> items;
  final void Function(CatalogItem) onRemove;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final locale = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('compare'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Chip(
                  avatar: CircleAvatar(
                    backgroundImage: NetworkImage(item.imageUrl),
                  ),
                  label: Text(item.name),
                  onDeleted: () => onRemove(item),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: onCompare,
              child: Text(locale.translate('compare')),
            ),
          ),
        ],
      ),
    );
  }
}
