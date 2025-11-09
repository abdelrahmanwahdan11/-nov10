import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../../app/app_scope.dart';
import '../../../../core/controllers/experience_controller.dart';
import '../../../../core/models/experience_aurora.dart';
import '../../../../core/models/experience_constellation.dart';
import '../../../../core/models/experience_horizon.dart';
import '../../../../core/models/experience_moment.dart';
import '../../../../core/models/experience_nebula.dart';
import '../../../../core/models/experience_nova.dart';
import '../../../../core/models/experience_quasar.dart';
import '../../../../core/models/experience_blueprint.dart';
import '../../../../core/models/experience_orbit.dart';
import '../../../../core/models/item.dart';
import '../../../../core/models/showroom_scene.dart';
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
          final chronicle = _controller.chronicle;
          final orbits = _controller.orbits;
          final activeOrbit = _controller.activeOrbit;
          final constellations = _controller.constellations;
          final activeConstellation = _controller.activeConstellation;
          final horizons = _controller.horizons;
          final activeHorizon = _controller.activeHorizon;
          final auroras = _controller.auroras;
          final activeAurora = _controller.activeAurora;
          final nebulas = _controller.nebulas;
          final activeNebula = _controller.activeNebula;
          final novas = _controller.novas;
          final activeNova = _controller.activeNova;
          final quasars = _controller.quasars;
          final activeQuasar = _controller.activeQuasar;
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _OrbitNavigator(
                    orbits: orbits,
                    activeOrbit: activeOrbit,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _ConstellationDeck(
                    constellations: constellations,
                    activeConstellation: activeConstellation,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _HorizonBridge(
                    horizons: horizons,
                    activeHorizon: activeHorizon,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _AuroraCascade(
                    auroras: auroras,
                    activeAurora: activeAurora,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _NebulaSymphony(
                    nebulas: nebulas,
                    activeNebula: activeNebula,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _NovaRadiance(
                    novas: novas,
                    activeNova: activeNova,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _QuasarObservatory(
                    quasars: quasars,
                    activeQuasar: activeQuasar,
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _FocusDeck(
                    controller: _controller,
                    localization: localization,
                    onSelectItem: widget.onSelectItem,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: _ChronicleSection(
                    controller: _controller,
                    localization: localization,
                    moments: chronicle,
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

class _OrbitNavigator extends StatelessWidget {
  const _OrbitNavigator({
    required this.orbits,
    required this.activeOrbit,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceOrbit> orbits;
  final ExperienceOrbit? activeOrbit;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    localization.translate('experience_orbits_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.translate('experience_orbits_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  orbits.isEmpty ? null : () => controller.cycleOrbit(manual: true),
              tooltip: localization.translate('experience_orbit_cycle'),
              icon: const Icon(IconlyLight.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (orbits.isEmpty)
          _OrbitEmptyState(localization: localization)
        else
          SizedBox(
            height: 172,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: orbits.length,
              itemBuilder: (context, index) {
                final orbit = orbits[index];
                final isActive = activeOrbit?.id == orbit.id;
                return _OrbitCard(
                  orbit: orbit,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _OrbitCard extends StatelessWidget {
  const _OrbitCard({
    required this.orbit,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceOrbit orbit;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = localization.locale.languageCode == 'ar';
    final items = controller.resolveOrbitItems(orbit).take(3).toList();
    final relative = _relativeLabel(orbit.lastActivated);
    final phaseLabel =
        '${orbit.phaseIds.length} phases • ${orbit.phaseIds.length} مراحل';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.24),
                  theme.colorScheme.primary.withOpacity(0.08),
                ]
              : [
                  theme.colorScheme.surface.withOpacity(0.72),
                  theme.colorScheme.surfaceVariant.withOpacity(0.42),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary
              .withOpacity(isActive ? 0.8 : 0.25),
          width: isActive ? 2 : 1.2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => controller.activateOrbit(orbit, manual: true),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        orbit.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (orbit.hasFocus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          localization.translate('experience_focus_start'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(IconlyLight.discovery, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      orbit.mood
                          .localizedLabel(isArabic: isArabic),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${localization.translate('experience_orbit_intensity')} '
                  '${(orbit.intensity * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: orbit.intensity.clamp(0.05, 1),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  phaseLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 10),
                if (items.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items
                        .map(
                          (item) => ActionChip(
                            label: Text(item.name),
                            avatar: const Icon(IconlyLight.image, size: 18),
                            onPressed: () => onSelectItem(item),
                          ),
                        )
                        .toList(),
                  ),
                const Spacer(),
                Text(
                  '${localization.translate('experience_orbit_last')} $relative',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeLabel(DateTime? timestamp) {
    if (timestamp == null) {
      return localization.translate('experience_orbit_last_never');
    }
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'just now • حالاً';
    }
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes m • $minutes دقيقة';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours h • $hours ساعة';
    }
    final days = difference.inDays;
    return '$days d • $days يوم';
  }
}

class _OrbitEmptyState extends StatelessWidget {
  const _OrbitEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.paper, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localization.translate('experience_orbits_empty'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstellationDeck extends StatelessWidget {
  const _ConstellationDeck({
    required this.constellations,
    required this.activeConstellation,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceConstellation> constellations;
  final ExperienceConstellation? activeConstellation;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orbitLookup = {for (final orbit in controller.orbits) orbit.id: orbit};
    return Column(
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
                    localization.translate('experience_constellations_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization
                        .translate('experience_constellations_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: constellations.isEmpty
                  ? null
                  : () => controller.cycleConstellation(manual: true),
              tooltip:
                  localization.translate('experience_constellation_cycle'),
              icon: const Icon(IconlyLight.swap),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (constellations.isEmpty)
          _ConstellationEmptyState(localization: localization)
        else
          SizedBox(
            height: 212,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: constellations.length,
              itemBuilder: (context, index) {
                final constellation = constellations[index];
                final isActive = activeConstellation?.id == constellation.id;
                return _ConstellationCard(
                  constellation: constellation,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  orbitLookup: orbitLookup,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConstellationCard extends StatelessWidget {
  const _ConstellationCard({
    required this.constellation,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.orbitLookup,
    required this.onSelectItem,
  });

  final ExperienceConstellation constellation;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final Map<String, ExperienceOrbit> orbitLookup;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final energy = constellation.energy(orbitLookup).clamp(0.0, 1.0);
    final synergyPercent = (constellation.synergy * 100).clamp(0, 100);
    final items = controller
        .resolveConstellationItems(constellation)
        .take(3)
        .toList();
    final lastAligned = constellation.lastAligned;
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final lastLabel = lastAligned == null
        ? localization.translate('experience_constellation_last_never')
        : '${localization.translate('experience_constellation_last')} '
            '${materialLocalizations.formatMediumDate(lastAligned)} · '
            '${materialLocalizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(lastAligned),
              alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            )}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 292,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.24),
                  theme.colorScheme.secondary.withOpacity(0.16),
                ]
              : [
                  theme.colorScheme.surface.withOpacity(0.72),
                  theme.colorScheme.surfaceVariant.withOpacity(0.44),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isActive ? 0.9 : 0.25),
          width: isActive ? 2 : 1.2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => controller.alignConstellation(constellation, manual: true),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        constellation.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      IconlyBold.star,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${localization.translate('experience_constellation_energy')} '
                  '${(energy * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: energy.clamp(0.05, 1),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${localization.translate('experience_constellation_synergy')} '
                  '${synergyPercent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 12),
                if (items.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items
                        .map(
                          (item) => ActionChip(
                            avatar: const Icon(IconlyLight.image, size: 18),
                            label: Text(item.name),
                            onPressed: () => onSelectItem(item),
                          ),
                        )
                        .toList(),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lastLabel,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                    TextButton(
                      onPressed: () =>
                          controller.alignConstellation(constellation, manual: true),
                      child: Text(
                        localization
                            .translate('experience_constellation_align'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizonBridge extends StatelessWidget {
  const _HorizonBridge({
    required this.horizons,
    required this.activeHorizon,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceHorizon> horizons;
  final ExperienceHorizon? activeHorizon;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    localization.translate('experience_horizons_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.translate('experience_horizons_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  horizons.isEmpty ? null : () => controller.cycleHorizon(manual: true),
              tooltip: localization.translate('experience_horizon_cycle'),
              icon: const Icon(IconlyLight.discovery),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (horizons.isEmpty)
          _HorizonEmptyState(localization: localization)
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: horizons.length,
              itemBuilder: (context, index) {
                final horizon = horizons[index];
                final isActive = activeHorizon?.id == horizon.id;
                return _HorizonCard(
                  horizon: horizon,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HorizonCard extends StatelessWidget {
  const _HorizonCard({
    required this.horizon,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceHorizon horizon;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intensity = controller.horizonIntensity(horizon).clamp(0.0, 1.0);
    final coherencePercent =
        (horizon.coherence * 100).clamp(0, 100).toDouble();
    final items = controller.resolveHorizonItems(horizon).take(4).toList();
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final lastExpanded = horizon.lastExpanded;
    final lastLabel = lastExpanded == null
        ? localization.translate('experience_horizon_last_never')
        : '${localization.translate('experience_horizon_last')} '
            '${materialLocalizations.formatMediumDate(lastExpanded)} · '
            '${materialLocalizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(lastExpanded),
              alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            )}';
    final moodText = horizon.moodHints.isEmpty
        ? ''
        : horizon.moodHints.map((mood) => mood.name).join(' • ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 292,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.26),
                  theme.colorScheme.secondary.withOpacity(0.18),
                ]
              : [
                  theme.colorScheme.surface.withOpacity(0.74),
                  theme.colorScheme.surfaceVariant.withOpacity(0.44),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isActive ? 0.9 : 0.28),
          width: isActive ? 2 : 1.2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => controller.openHorizon(horizon, manual: true),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                            horizon.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (moodText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              moodText,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      isActive ? IconlyBold.discovery : IconlyLight.discovery,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${localization.translate('experience_horizon_intensity')} ${(intensity * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: intensity,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(IconlyLight.chart, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${localization.translate('experience_horizon_coherence')} '
                      '${coherencePercent.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => ActionChip(
                          label: Text(item.name),
                          avatar: const Icon(IconlyLight.image, size: 18),
                          onPressed: () => onSelectItem(item),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                Text(
                  lastLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizonEmptyState extends StatelessWidget {
  const _HorizonEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.discovery, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localization.translate('experience_horizons_empty'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraCascade extends StatelessWidget {
  const _AuroraCascade({
    required this.auroras,
    required this.activeAurora,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceAurora> auroras;
  final ExperienceAurora? activeAurora;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    localization.translate('experience_auroras_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.translate('experience_auroras_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  auroras.isEmpty ? null : () => controller.cycleAurora(manual: true),
              tooltip: localization.translate('experience_aurora_cycle'),
              icon: const Icon(IconlyLight.star),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (auroras.isEmpty)
          _AuroraEmptyState(localization: localization)
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: auroras.length,
              itemBuilder: (context, index) {
                final aurora = auroras[index];
                final isActive = activeAurora?.id == aurora.id;
                return _AuroraCard(
                  aurora: aurora,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AuroraCard extends StatelessWidget {
  const _AuroraCard({
    required this.aurora,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceAurora aurora;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final luminance = controller.auroraLuminance(aurora).clamp(0.0, 1.0);
    final resonancePercent = (aurora.resonance * 100).clamp(0, 100).toDouble();
    final items = controller.resolveAuroraItems(aurora).take(6).toList();
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final lastGlide = aurora.lastGlide;
    final lastLabel = lastGlide == null
        ? localization.translate('experience_aurora_last_never')
        : '${localization.translate('experience_aurora_last')} '
            '${materialLocalizations.formatMediumDate(lastGlide)} · '
            '${materialLocalizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(lastGlide),
              alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            )}';
    final moodText = aurora.moodHints.isEmpty
        ? ''
        : aurora.moodHints.map((mood) => mood.name).join(' • ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 292,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.28),
                  theme.colorScheme.secondary.withOpacity(0.2),
                ]
              : [
                  theme.colorScheme.surface.withOpacity(0.7),
                  theme.colorScheme.surfaceVariant.withOpacity(0.38),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isActive ? 0.95 : 0.28),
          width: isActive ? 2 : 1.2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 22,
              offset: const Offset(0, 18),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => controller.openAurora(aurora, manual: true),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                            aurora.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (moodText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              moodText,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      isActive ? IconlyBold.star : IconlyLight.star,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${localization.translate('experience_aurora_radiance')} '
                  '${(luminance * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: luminance,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(IconlyLight.category, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${localization.translate('experience_aurora_resonance')} '
                      '${resonancePercent.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => ActionChip(
                          label: Text(item.name),
                          avatar: const Icon(IconlyLight.image, size: 18),
                          onPressed: () => onSelectItem(item),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                Text(
                  lastLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuroraEmptyState extends StatelessWidget {
  const _AuroraEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.star, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localization.translate('experience_auroras_empty'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NebulaSymphony extends StatelessWidget {
  const _NebulaSymphony({
    required this.nebulas,
    required this.activeNebula,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceNebula> nebulas;
  final ExperienceNebula? activeNebula;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    localization.translate('experience_nebulas_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.translate('experience_nebulas_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  nebulas.isEmpty ? null : () => controller.cycleNebula(manual: true),
              tooltip: localization.translate('experience_nebula_cycle'),
              icon: const Icon(IconlyLight.sun),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (nebulas.isEmpty)
          _NebulaEmptyState(localization: localization)
        else
          SizedBox(
            height: 236,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: nebulas.length,
              itemBuilder: (context, index) {
                final nebula = nebulas[index];
                final isActive = activeNebula?.id == nebula.id;
                return _NebulaCard(
                  nebula: nebula,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NebulaCard extends StatelessWidget {
  const _NebulaCard({
    required this.nebula,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceNebula nebula;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clarity = controller.nebulaClarity(nebula).clamp(0.0, 1.0);
    final luminosityPercent = (nebula.luminosity * 100).clamp(0, 100).toDouble();
    final cohesionPercent = (nebula.cohesion * 100).clamp(0, 100).toDouble();
    final items = controller.resolveNebulaItems(nebula).take(8).toList();
    final blueprint = nebula.spotlightBlueprintId == null
        ? null
        : controller.findById(nebula.spotlightBlueprintId!);
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final lastSurge = nebula.lastSurge;
    final lastLabel = lastSurge == null
        ? localization.translate('experience_nebula_last_never')
        : '${localization.translate('experience_nebula_last')} '
            '${materialLocalizations.formatMediumDate(lastSurge)} · '
            '${materialLocalizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(lastSurge),
              alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            )}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 300,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.secondary.withOpacity(0.28),
                  theme.colorScheme.tertiary.withOpacity(0.24),
                ]
              : [
                  theme.colorScheme.surface.withOpacity(0.66),
                  theme.colorScheme.surfaceVariant.withOpacity(0.34),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(isActive ? 0.9 : 0.24),
          width: isActive ? 2 : 1.1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.secondary.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => controller.openNebula(nebula, manual: true),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nebula.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (nebula.spectrumHints.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              nebula.spectrumHints
                                  .map((mood) => mood.name)
                                  .join(' • '),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      isActive ? IconlyBold.sun : IconlyLight.sun,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${localization.translate('experience_nebula_luminosity')} '
                  '${luminosityPercent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: nebula.luminosity.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.secondary.withOpacity(0.15),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${localization.translate('experience_nebula_cohesion')} '
                  '${cohesionPercent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: nebula.cohesion.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.tertiary.withOpacity(0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(IconlyLight.activity, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${localization.translate('experience_nebula_clarity')} '
                      '${(clarity * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (blueprint != null) ...[
                  Text(
                    localization.translate('experience_nebula_spotlight'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    blueprint.title,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => GestureDetector(
                          onTap: () => onSelectItem(item),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  item.name,
                                  style: theme.textTheme.labelSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                Text(
                  lastLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NebulaEmptyState extends StatelessWidget {
  const _NebulaEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.discovery, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localization.translate('experience_nebulas_empty'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NovaRadiance extends StatelessWidget {
  const _NovaRadiance({
    required this.novas,
    required this.activeNova,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceNova> novas;
  final ExperienceNova? activeNova;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    localization.translate('experience_novas_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.translate('experience_novas_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: novas.isEmpty ? null : () => controller.cycleNova(manual: true),
              tooltip: localization.translate('experience_nova_cycle'),
              icon: const Icon(IconlyLight.star),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (novas.isEmpty)
          _NovaEmptyState(localization: localization)
        else
          SizedBox(
            height: 244,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: novas.length,
              itemBuilder: (context, index) {
                final nova = novas[index];
                final isActive = activeNova?.id == nova.id;
                return _NovaCard(
                  nova: nova,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NovaCard extends StatelessWidget {
  const _NovaCard({
    required this.nova,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceNova nova;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brilliance = controller.novaBrilliance(nova).clamp(0.0, 1.0);
    final intensityPercent = (nova.intensity * 100).clamp(0, 100).toDouble();
    final stabilityPercent = (nova.stability * 100).clamp(0, 100).toDouble();
    final items = controller.resolveNovaItems(nova).take(8).toList();
    ExperienceNebula? featuredNebula;
    if (nova.featuredNebulaId != null) {
      try {
        featuredNebula = controller.nebulas
            .firstWhere((entry) => entry.id == nova.featuredNebulaId);
      } catch (_) {
        featuredNebula = null;
      }
    }
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final lastIgnition = nova.lastIgnition;
    final lastLabel = lastIgnition == null
        ? localization.translate('experience_nova_last_never')
        : '${localization.translate('experience_nova_last')} '
            '${materialLocalizations.formatMediumDate(lastIgnition)} · '
            '${materialLocalizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(lastIgnition),
              alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            )}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      width: 300,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.32),
                  theme.colorScheme.secondary.withOpacity(0.26),
                ]
              : [
                  theme.colorScheme.surface.withOpacity(0.6),
                  theme.colorScheme.surfaceVariant.withOpacity(0.28),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isActive ? 0.9 : 0.22),
          width: isActive ? 2 : 1.1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 18),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => controller.openNova(nova, manual: true),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nova.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (nova.sequenceHints.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              nova.sequenceHints.map((mood) => mood.name).join(' • '),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      isActive ? IconlyBold.star : IconlyLight.star,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${localization.translate('experience_nova_intensity')} '
                  '${intensityPercent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: nova.intensity.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.18),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${localization.translate('experience_nova_stability')} '
                  '${stabilityPercent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: nova.stability.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.secondary.withOpacity(0.16),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(IconlyLight.activity, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${localization.translate('experience_nova_brilliance')} '
                      '${(brilliance * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (featuredNebula != null) ...[
                  Text(
                    featuredNebula!.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => GestureDetector(
                          onTap: () => onSelectItem(item),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  item.name,
                                  style: theme.textTheme.labelSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                Text(
                  lastLabel,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NovaEmptyState extends StatelessWidget {
  const _NovaEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.38),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            IconlyLight.star,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localization.translate('experience_novas_empty'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuasarObservatory extends StatelessWidget {
  const _QuasarObservatory({
    required this.quasars,
    required this.activeQuasar,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final List<ExperienceQuasar> quasars;
  final ExperienceQuasar? activeQuasar;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                    localization.translate('experience_quasars_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.translate('experience_quasars_subtitle'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  quasars.isEmpty ? null : () => controller.cycleQuasar(manual: true),
              tooltip: localization.translate('experience_quasar_cycle'),
              icon: const Icon(IconlyLight.discovery),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (quasars.isEmpty)
          _QuasarEmptyState(localization: localization)
        else
          SizedBox(
            height: 256,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quasars.length,
              itemBuilder: (context, index) {
                final quasar = quasars[index];
                final isActive = activeQuasar?.id == quasar.id;
                return _QuasarCard(
                  quasar: quasar,
                  isActive: isActive,
                  controller: controller,
                  localization: localization,
                  onSelectItem: onSelectItem,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _QuasarCard extends StatelessWidget {
  const _QuasarCard({
    required this.quasar,
    required this.isActive,
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceQuasar quasar;
  final bool isActive;
  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flarePercent = (quasar.flare * 100).clamp(0, 100).toDouble();
    final steadinessPercent = (quasar.steadiness * 100).clamp(0, 100).toDouble();
    final fluxPercent = (quasar.flux * 100).clamp(0, 100).toDouble();
    final items = controller.resolveQuasarItems(quasar).take(10).toList();
    ExperienceNova? featuredNova;
    if (quasar.featuredNovaId != null) {
      try {
        featuredNova = controller.novas
            .firstWhere((entry) => entry.id == quasar.featuredNovaId);
      } catch (_) {
        featuredNova = null;
      }
    }
    final materialLocalizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final lastBeacon = quasar.lastBeacon;
    final lastLabel = lastBeacon == null
        ? localization.translate('experience_quasar_last_never')
        : '${localization.translate('experience_quasar_last')} '
            '${materialLocalizations.formatMediumDate(lastBeacon)} · '
            '${materialLocalizations.formatTimeOfDay(',
              TimeOfDay.fromDateTime(lastBeacon),
              alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            )}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      width: 312,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.dividerColor.withOpacity(0.4),
        ),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.18),
                  theme.colorScheme.secondary.withOpacity(0.12),
                ]
              : [
                  theme.colorScheme.surfaceVariant.withOpacity(0.1),
                  theme.colorScheme.surfaceVariant.withOpacity(0.04),
                ],
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => controller.openQuasar(quasar, manual: true),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quasar.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (featuredNova != null)
                          Text(
                            featuredNova!.title,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isActive ? IconlyBold.discovery : IconlyLight.discovery,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${localization.translate('experience_quasar_flare')} '
                '${flarePercent.toStringAsFixed(0)}%',
                style:
                    theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: quasar.flare.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${localization.translate('experience_quasar_steadiness')} '
                '${steadinessPercent.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: quasar.steadiness.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.secondary.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(IconlyLight.activity, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${localization.translate('experience_quasar_flux')} '
                    '${fluxPercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (item) => GestureDetector(
                        onTap: () => onSelectItem(item),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                item.imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              child: Text(
                                item.name,
                                style: theme.textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              Text(
                lastLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuasarEmptyState extends StatelessWidget {
  const _QuasarEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.translate('experience_quasars_title'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('experience_quasars_empty'),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _ConstellationEmptyState extends StatelessWidget {
  const _ConstellationEmptyState({required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.graph, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localization.translate('experience_constellations_empty'),
              style: theme.textTheme.bodyMedium,
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
    final isFocused = controller.activeFocus?.phaseId == phase.id &&
        controller.activeFocus?.blueprintId == blueprintId;
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
              IconButton(
                onPressed: isFocused
                    ? controller.releaseFocus
                    : () => controller.focusPhase(blueprintId, phase.id),
                icon: Icon(
                  isFocused ? IconlyBold.heart : IconlyLight.discovery,
                ),
                tooltip: localization.translate(
                  isFocused
                      ? 'experience_focus_release'
                      : 'experience_focus_start',
                ),
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

class _FocusDeck extends StatefulWidget {
  const _FocusDeck({
    required this.controller,
    required this.localization,
    required this.onSelectItem,
  });

  final ExperienceController controller;
  final AppLocalizations localization;
  final ValueChanged<CatalogItem> onSelectItem;

  @override
  State<_FocusDeck> createState() => _FocusDeckState();
}

class _FocusDeckState extends State<_FocusDeck> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focus = widget.controller.activeFocus;
    if (focus == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
        ),
        child: Row(
          children: [
            const Icon(IconlyLight.voice),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.localization.translate('experience_focus_empty'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    final blueprint = widget.controller.findById(focus.blueprintId);
    final phase =
        widget.controller.resolvePhase(focus.blueprintId, focus.phaseId);
    if (blueprint == null || phase == null) {
      return const SizedBox.shrink();
    }
    final progress =
        widget.controller.phaseProgress(blueprint.id, phase.id);
    final items = widget.controller.resolveItems(blueprint);
    final elapsed = DateTime.now().difference(focus.startedAt);
    final elapsedLabel =
        '${elapsed.inMinutes.toString().padLeft(2, '0')}m ${
            (elapsed.inSeconds % 60).toString().padLeft(2, '0')}s';
    final isArabic = widget.localization.locale.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.28),
            theme.colorScheme.surface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  blueprint.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: widget.controller.releaseFocus,
                icon: const Icon(IconlyLight.close_square),
                label: Text(
                  widget.localization.translate('experience_focus_release'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            phase.title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            phase.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress == 0 ? null : progress,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                avatar: const Icon(IconlyLight.time_circle, size: 16),
                label: Text(
                  '${widget.localization.translate('experience_focus_elapsed')} $elapsedLabel',
                ),
              ),
              Chip(
                avatar: const Icon(IconlyLight.calendar, size: 16),
                label: Text(
                  focus.startedAt
                      .toLocal()
                      .toString()
                      .split('.')
                      .first,
                ),
              ),
              Chip(
                label: Text(
                  blueprint.focusMood.localizedLabel(isArabic: isArabic),
                ),
              ),
              ...phase.focusTags.map(
                (tag) => Chip(
                  label: Text('#$tag'),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () => widget.onSelectItem(item),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                itemCount: items.length > 4 ? 4 : items.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChronicleSection extends StatelessWidget {
  const _ChronicleSection({
    required this.controller,
    required this.localization,
    required this.moments,
  });

  final ExperienceController controller;
  final AppLocalizations localization;
  final List<ExperienceMoment> moments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = localization.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(IconlyLight.chart),
            const SizedBox(width: 8),
            Text(
              localization.translate('experience_chronicle_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (moments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
            ),
            child: Row(
              children: [
                const Icon(IconlyLight.document),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localization.translate('experience_chronicle_empty'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: moments.length > 8 ? 8 : moments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final moment = moments[index];
                final blueprint = controller.findById(moment.blueprintId);
                final phase = moment.phaseId == null
                    ? null
                    : controller.resolvePhase(
                        moment.blueprintId,
                        moment.phaseId!,
                      );
                final accent = _accentFor(moment.kind, theme);
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: accent.withOpacity(0.08),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: accent.withOpacity(0.18),
                            child: Icon(
                              _iconFor(moment.kind),
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _labelFor(moment.kind),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(moment.timestamp),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        blueprint?.title ?? moment.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phase != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          phase.title,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        moment.detail,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              (blueprint?.focusMood ?? SceneMood.serene)
                                  .localizedLabel(isArabic: isArabic),
                            ),
                          ),
                          if (phase != null)
                            ActionChip(
                              avatar:
                                  const Icon(IconlyLight.discovery, size: 18),
                              label: Text(
                                localization
                                    .translate('experience_focus_start'),
                              ),
                              onPressed: () => controller.focusPhase(
                                moment.blueprintId,
                                phase.id,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _iconFor(ExperienceMomentKind kind) {
    switch (kind) {
      case ExperienceMomentKind.pulse:
        return IconlyLight.activity;
      case ExperienceMomentKind.progress:
        return IconlyLight.tick_square;
      case ExperienceMomentKind.focus:
        return IconlyLight.discovery;
      case ExperienceMomentKind.reflection:
        return IconlyLight.paper;
      case ExperienceMomentKind.orbit:
        return IconlyLight.location;
      case ExperienceMomentKind.constellation:
        return IconlyLight.graph;
      case ExperienceMomentKind.horizon:
        return IconlyLight.category;
      case ExperienceMomentKind.aurora:
        return IconlyLight.star;
      case ExperienceMomentKind.nebula:
        return IconlyLight.sun;
      case ExperienceMomentKind.nova:
        return IconlyBold.star;
      case ExperienceMomentKind.quasar:
        return IconlyBold.discovery;
    }
  }

  Color _accentFor(ExperienceMomentKind kind, ThemeData theme) {
    switch (kind) {
      case ExperienceMomentKind.pulse:
        return theme.colorScheme.secondary;
      case ExperienceMomentKind.progress:
        return theme.colorScheme.primary;
      case ExperienceMomentKind.focus:
        return theme.colorScheme.tertiary;
      case ExperienceMomentKind.reflection:
        return theme.colorScheme.error;
      case ExperienceMomentKind.orbit:
        return theme.colorScheme.primaryContainer;
      case ExperienceMomentKind.constellation:
        return theme.colorScheme.secondaryContainer;
      case ExperienceMomentKind.horizon:
        return theme.colorScheme.surfaceTint;
      case ExperienceMomentKind.aurora:
        return theme.colorScheme.tertiaryContainer;
      case ExperienceMomentKind.nebula:
        return theme.colorScheme.secondary;
      case ExperienceMomentKind.nova:
        return theme.colorScheme.primary;
      case ExperienceMomentKind.quasar:
        return theme.colorScheme.tertiary;
    }
  }

  String _labelFor(ExperienceMomentKind kind) {
    switch (kind) {
      case ExperienceMomentKind.pulse:
        return localization.translate('experience_moment_pulse');
      case ExperienceMomentKind.progress:
        return localization.translate('experience_moment_progress');
      case ExperienceMomentKind.focus:
        return localization.translate('experience_moment_focus');
      case ExperienceMomentKind.reflection:
        return localization.translate('experience_moment_reflection');
      case ExperienceMomentKind.orbit:
        return localization.translate('experience_moment_orbit');
      case ExperienceMomentKind.constellation:
        return localization.translate('experience_moment_constellation');
      case ExperienceMomentKind.horizon:
        return localization.translate('experience_moment_horizon');
      case ExperienceMomentKind.aurora:
        return localization.translate('experience_moment_aurora');
      case ExperienceMomentKind.nebula:
        return localization.translate('experience_moment_nebula');
      case ExperienceMomentKind.nova:
        return localization.translate('experience_moment_nova');
      case ExperienceMomentKind.quasar:
        return localization.translate('experience_moment_quasar');
    }
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day · $hours:$minutes';
  }
}
