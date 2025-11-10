import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/app_preferences.dart';

class CatalogController extends ChangeNotifier {
  CatalogController({required AppPreferences preferences})
      : _preferences = preferences,
        _favoriteIds = preferences.getFavoriteIds(),
        _comparisonIds = preferences.getComparisonIds() {
    _seedData();
    _applyFilters();
  }

  final List<CatalogItem> _allItems = <CatalogItem>[];
  final List<CatalogItem> _visibleItems = <CatalogItem>[];
  final List<CatalogItem> _comparisonItems = <CatalogItem>[];
  final AppPreferences _preferences;
  final Set<String> _favoriteIds;
  final Set<String> _comparisonIds;
  final Set<ItemCategory> _activeCategories = ItemCategory.values.toSet();
  String _searchQuery = '';
  bool _onlyFavorites = false;
  int _page = 0;
  final int _pageSize = 8;
  bool _hasMore = true;
  bool _isLoading = false;

  List<CatalogItem> get items => List.unmodifiable(_visibleItems);
  List<CatalogItem> get comparisonItems => List.unmodifiable(_comparisonItems);
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get onlyFavorites => _onlyFavorites;
  Set<ItemCategory> get activeCategories => _activeCategories;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  CatalogItem? findById(String id) {
    try {
      return _allItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _page = 0;
    _visibleItems.clear();
    _hasMore = true;
    _applyFilters();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _appendPage();
    _isLoading = false;
    notifyListeners();
  }

  void toggleCategory(ItemCategory category) {
    if (_activeCategories.contains(category)) {
      _activeCategories.remove(category);
    } else {
      _activeCategories.add(category);
    }
    _page = 0;
    _visibleItems.clear();
    _hasMore = true;
    _applyFilters();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _page = 0;
    _visibleItems.clear();
    _hasMore = true;
    _applyFilters();
  }

  void toggleFavorites() {
    _onlyFavorites = !_onlyFavorites;
    _page = 0;
    _visibleItems.clear();
    _hasMore = true;
    _applyFilters();
  }

  void toggleCompare(CatalogItem item) {
    if (_comparisonItems.contains(item)) {
      _comparisonItems.remove(item);
      _comparisonIds.remove(item.id);
    } else {
      if (_comparisonItems.length >= 3) {
        final removed = _comparisonItems.removeAt(0);
        _comparisonIds.remove(removed.id);
      }
      _comparisonItems.add(item);
      _comparisonIds.add(item.id);
    }
    unawaited(_preferences.setComparisonIds(_comparisonIds));
    notifyListeners();
  }

  bool isInComparison(CatalogItem item) => _comparisonItems.contains(item);

  bool isFavorite(CatalogItem item) => _favoriteIds.contains(item.id);

  void toggleFavorite(CatalogItem item) {
    if (_favoriteIds.contains(item.id)) {
      _favoriteIds.remove(item.id);
    } else {
      _favoriteIds.add(item.id);
    }
    unawaited(_preferences.setFavoriteIds(_favoriteIds));
    notifyListeners();
  }

  List<CatalogItem> get filteredItems {
    final filters = _allItems.where((item) {
      final matchesCategory = _activeCategories.contains(item.category);
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFavorites = !_onlyFavorites || _favoriteIds.contains(item.id);
      return matchesCategory && matchesQuery && matchesFavorites;
    }).toList();
    return filters;
  }

  void _applyFilters() {
    _visibleItems.clear();
    _hasMore = true;
    _appendPage();
    notifyListeners();
  }

  void _appendPage() {
    final items = filteredItems;
    final start = _page * _pageSize;
    if (start >= items.length) {
      _hasMore = false;
      return;
    }
    final end = min(start + _pageSize, items.length);
    _visibleItems.addAll(items.sublist(start, end));
    _page++;
    if (_visibleItems.length >= items.length) {
      _hasMore = false;
    }
  }

  void _seedData() {
    final lorem = 'تصميم إبداعي يلائم مختلف المساحات مع تفاصيل دقيقة.';
    final random = Random(4);
    final categories = ItemCategory.values;
    for (var i = 0; i < 32; i++) {
      final category = categories[i % categories.length];
      final item = CatalogItem(
        id: 'item_$i',
        name: 'عنصر ${i + 1}',
        description: '$lorem ${i + 1}',
        imageUrl: 'https://picsum.photos/seed/neo_$i/600/400',
        price: 150 + (i * 12.5),
        category: category,
        tags: <ItemTag>{
          if (i.isEven) ItemTag.bestSeller,
          if (i % 3 == 0) ItemTag.ecoFriendly,
          if (i % 4 == 0) ItemTag.newArrival,
          if (i % 5 == 0) ItemTag.limited,
        }.toList(),
        colorOptions: List<Color>.generate(
          3,
          (index) => Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1),
        ),
        dimensions: '120x80x60 cm',
        materials: 'خشب مطلي ومواد مركبة',
      );
      _allItems.add(item);
      if (_comparisonIds.contains(item.id)) {
        _comparisonItems.add(item);
      }
    }
  }
}
