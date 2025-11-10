import 'package:flutter/material.dart';

enum ItemCategory { furniture, lighting, decor, technology }

enum ItemTag { newArrival, ecoFriendly, bestSeller, limited }

class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.tags,
    required this.colorOptions,
    required this.dimensions,
    required this.materials,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final ItemCategory category;
  final List<ItemTag> tags;
  final List<Color> colorOptions;
  final String dimensions;
  final String materials;

  CatalogItem copyWith({
    String? description,
    List<Color>? colorOptions,
  }) {
    return CatalogItem(
      id: id,
      name: name,
      description: description ?? this.description,
      imageUrl: imageUrl,
      price: price,
      category: category,
      tags: tags,
      colorOptions: colorOptions ?? this.colorOptions,
      dimensions: dimensions,
      materials: materials,
    );
  }
}

extension ItemCategoryLocalization on ItemCategory {
  String localized({required bool isArabic}) {
    switch (this) {
      case ItemCategory.furniture:
        return isArabic ? 'أثاث' : 'Furniture';
      case ItemCategory.lighting:
        return isArabic ? 'إضاءة' : 'Lighting';
      case ItemCategory.decor:
        return isArabic ? 'ديكور' : 'Decor';
      case ItemCategory.technology:
        return isArabic ? 'تقنية' : 'Technology';
    }
  }
}
