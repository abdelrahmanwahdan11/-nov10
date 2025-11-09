import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/controllers/experience_controller.dart';
import '../../../../core/models/experience_blueprint.dart';
import '../../../../core/models/item.dart';
import '../../../../l10n/app_localizations.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key, required this.onSelectItem});

  final ValueChanged<CatalogItem> onSelectItem;

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  late ExperienceController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _controller = AppScope.of(context).experienceController;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _controller.refreshBlueprints,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final blueprints = _controller.blueprints;
          final pinned = _controller.pinnedBlueprint;
          final signals = _controller.signals;
          return CustomScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: _ExperiencePulse(signals: signals),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PinnedBlueprintCard(
                    blueprint: pinned,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final blueprint = blueprints[index];
                      final progress = _controller.blueprintProgress(blueprint);
                      final isPinned = pinned?.id == blueprint.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _BlueprintCard(
                          blueprint: blueprint,
                          progress: progress,
                          controller: _controller,
                          localization: localization,
                          onSelectItem: widget.onSelectItem,
                          isPinned: isPinned,
                        ),
                      );
                    },
                    childCount: blueprints.length,
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

class _ExperiencePulse extends StatelessWidget {
  const _ExperiencePulse({required this.signals});

  final List<ExperienceSignal> signals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    final latest = signals.isNotEmpty ? signals.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: latest == null
              ? Container(
                  key: const ValueKey('empty_pulse'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(IconlyLight.activity),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localization
                              .translate('experience_timeline_empty'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : _PulseHighlight(signal: latest),
        ),
        if (signals.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final signal = signals[index];
                return Chip(
                  label: Text(signal.headline),
                  avatar: const Icon(IconlyLight.time_circle, size: 18),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: signals.length > 6 ? 6 : signals.length,
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseHighlight extends StatelessWidget {
  const _PulseHighlight({required this.signal});

  final ExperienceSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey(signal.id),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(IconlyBold.activity),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.headline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  signal.body,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedBlueprintCard extends StatelessWidget {
  const _PinnedBlueprintCard({
    required this.blueprint,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceBlueprint? blueprint;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (blueprint == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate('experience_pin_prompt'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              localization.translate('experience_pin_description'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final progress = controller.blueprintProgress(blueprint!);
    final scene = controller.resolveMoodScene(blueprint!);
    final items = controller.resolveItems(blueprint!);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(
          image: NetworkImage(blueprint!.primaryImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.surface.withOpacity(0.78),
            BlendMode.srcATop,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  blueprint!.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: localization.translate('unpin'),
                onPressed: controller.unpinBlueprint,
                icon: const Icon(IconlyLight.close_square),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            blueprint!.subtitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (scene != null)
            Chip(
              avatar: const Icon(IconlyLight.category),
              label: Text(scene.title),
            ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress == 0 ? null : progress),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: blueprint!.highlightedInsights
                .map(
                  (insight) => Chip(
                    label: Text(insight),
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.08),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () => onSelectItem(item),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.surface.withOpacity(0.85),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.price.toStringAsFixed(0)} SAR',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: items.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintCard extends StatefulWidget {
  const _BlueprintCard({
    required this.blueprint,
    required this.progress,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
    required this.isPinned,
  });

  final ExperienceBlueprint blueprint;
  final double progress;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;
  final bool isPinned;

  @override
  State<_BlueprintCard> createState() => _BlueprintCardState();
}

class _BlueprintCardState extends State<_BlueprintCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.controller.resolveItems(widget.blueprint);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.blueprint.title,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(widget.blueprint.subtitle,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    widget.controller.pinBlueprint(widget.blueprint),
                icon: Icon(
                  widget.isPinned
                      ? IconlyBold.star
                      : IconlyLight.star,
                ),
                tooltip: widget.isPinned
                    ? widget.localization.translate('pinned')
                    : widget.localization.translate('pin'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: widget.progress == 0 ? null : widget.progress,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${(widget.progress * 100).clamp(0, 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: widget.blueprint.highlightedInsights
                .map((insight) => Chip(label: Text(insight)))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: items.isEmpty
                    ? null
                    : () => widget.onSelectItem(items.first),
                icon: const Icon(IconlyLight.show),
                label: Text(widget.localization.translate('experience_preview')),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded
                    ? IconlyLight.arrow_up_2
                    : IconlyLight.arrow_down_2),
                label: Text(widget.localization.translate('experience_phases')),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: widget.blueprint.phases.map((phase) {
                final phaseProgress = widget.controller.phaseProgress(
                  widget.blueprint.id,
                  phase.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _PhaseTile(
                    blueprintId: widget.blueprint.id,
                    phase: phase,
                    progress: phaseProgress,
                    controller: widget.controller,
                  ),
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PhaseTile extends StatelessWidget {
  const _PhaseTile({
    required this.blueprintId,
    required this.phase,
    required this.progress,
    required this.controller,
  });

  final String blueprintId;
  final ExperiencePhase phase;
  final double progress;
  final ExperienceController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withOpacity(0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phase.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () =>
                    controller.stepPhase(blueprintId, phase.id, step: 0.5),
                icon: const Icon(IconlyLight.play),
                tooltip: localization.translate('experience_mark'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            phase.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress == 0 ? null : progress),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              Chip(
                avatar: const Icon(IconlyLight.time_circle, size: 16),
                label: Text(
                  '${phase.estimatedMinutes} ${localization.translate('minutes_short')}',
                ),
              ),
              ...phase.focusTags
                  .map(
                    (tag) => Chip(
                      label: Text('#$tag'),
                    ),
                  )
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }
}
