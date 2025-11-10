import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/item.dart';

class ImmersiveItemViewer extends StatefulWidget {
  const ImmersiveItemViewer({
    super.key,
    required this.item,
    required this.onClose,
  });

  final CatalogItem item;
  final VoidCallback onClose;

  @override
  State<ImmersiveItemViewer> createState() => _ImmersiveItemViewerState();
}

class _ImmersiveItemViewerState extends State<ImmersiveItemViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFace() {
    setState(() {
      _showBack = !_showBack;
      if (_showBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFace,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.65),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final angle = _controller.value * math.pi;
                    final isUnder = angle > math.pi / 2;
                    final transformAngle = angle > math.pi
                        ? angle - math.pi
                        : angle;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(transformAngle),
                      alignment: Alignment.center,
                      child: isUnder
                          ? _ItemBack(item: widget.item)
                          : _ItemFront(item: widget.item),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemFront extends StatelessWidget {
  const _ItemFront({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'item-${item.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white70),
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

class _ItemBack extends StatelessWidget {
  const _ItemBack({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Hero(
      tag: 'item-${item.id}',
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags
                  .map((tag) => Chip(
                        label: Text(tag.name),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('السعر / Price: \$${item.price.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Text('المواد / Materials: ${item.materials}'),
            const SizedBox(height: 12),
            Text('الأبعاد / Dimensions: ${item.dimensions}'),
            const Spacer(),
            Text(
              'اضغط للاستكشاف المدعوم بالذكاء الاصطناعي قريباً',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
