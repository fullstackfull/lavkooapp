import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/data/services/analytics_reporter.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer_registry.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_engine.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';

/// The published home content, embedded INSIDE the app's own home screen.
///
/// This deliberately does not scroll, own a Scaffold, or draw any chrome: the app bar, the search
/// field, the drawer and the bottom navigation belong to the app and are never builder-controlled.
/// The Theme Builder replaces only the CONTENT of the home page — the rails, banners and blocks
/// below the app's own header — which is what a merchant editing "the home page" means.
///
/// Triggers a sync on first build (resume syncs come from the controller's own lifecycle
/// observer), and renders header-page sections first so the announcement bar still lands on top
/// of the content.
class DynamicHomeSections extends StatefulWidget {
  const DynamicHomeSections({super.key});

  @override
  State<DynamicHomeSections> createState() => _DynamicHomeSectionsState();
}

class _DynamicHomeSectionsState extends State<DynamicHomeSections> {
  /// The experiment tag each anchored section carries, so its impression reports the variant.
  final Map<String, String> _experimentTags = {};

  GlobalKey? _registerAnchor(ThemeSectionSchema section) {
    final entity = _entityFor(section);
    if (entity == null) return null;

    final tag = section.experimentTag;
    if (tag != null) {
      _experimentTags[entity] = tag;
    } else {
      _experimentTags.remove(entity);
    }

    return _anchors.putIfAbsent(entity, GlobalKey.new);
  }

  /// What this section's impression reports as: a stored section's row id, or a campaign
  /// overlay's `campaign-{id}` — the one non-numeric identity the shop's ingest accepts. A
  /// section with neither has no identity to count.
  static String? _entityFor(ThemeSectionSchema section) {
    if (section.id > 0) return '${section.id}';

    final match = RegExp(r'^campaign-(\d+)').firstMatch(section.uuid);
    return match == null ? null : 'campaign-${match.group(1)}';
  }

  /// One key per section id, so the impression check can ask where each one actually is.
  final Map<String, GlobalKey> _anchors = {};

  ScrollPosition? _position;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DynamicThemeController>().sync();
      _watchScrolling();
      // What is on screen before anybody scrolls is also seen — and for a short page it is
      // everything that will ever be seen.
      _reportVisible();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The idiomatic place to find an ancestor, and the one that runs again if the screen is
    // rebuilt under a different scroll view.
    _watchScrolling();
  }

  @override
  void dispose() {
    _settle?.cancel();
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  /// Listen to the screen's own scroll view, from inside it.
  ///
  /// One listener for the whole page rather than one per section: a scroll notification fires on
  /// every frame of a fling, and fifteen listeners each measuring themselves would be a real cost
  /// on a phone for a number nobody reads in real time.
  void _watchScrolling() {
    try {
      final position = Scrollable.maybeOf(context)?.position;
      if (position == null || identical(position, _position)) return;

      _position?.removeListener(_onScroll);
      _position = position..addListener(_onScroll);
    } catch (_) {
      // A screen that does not scroll reports what was visible on the first frame and no more.
    }
  }

  void _onScroll() {
    // Measured when the scroll settles, not on every frame of it: what a shopper flew past at
    // speed is not what they saw, and the geometry costs a walk over the sections.
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 220), _reportVisible);
  }

  /// Report every section whose box currently overlaps the screen.
  void _reportVisible() {
    if (!mounted) return;

    try {
      final screen = MediaQuery.sizeOf(context).height;

      _anchors.forEach((entity, key) {
        final box = key.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.hasSize || box.size.height <= 0) return;

        final top = box.localToGlobal(Offset.zero).dy;
        final bottom = top + box.size.height;
        final onScreen = bottom.clamp(0.0, screen) - top.clamp(0.0, screen);

        // A quarter of the section — or half the viewport, whichever is SMALLER: a hero taller
        // than four screens can never show a quarter of itself at once, and the old rule made
        // such a section invisible to measurement no matter how long anyone looked at it.
        final needed = math.min(box.size.height * 0.25, screen * 0.5);
        if (onScreen >= needed) {
          AnalyticsReporter.sectionSeen(entity, experiment: _experimentTags[entity]);
        }
      });
    } catch (_) {
      // Measuring a page never breaks it.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicThemeController>(
      builder: (context, controller, _) {
        if (!controller.hasPublishedTheme) return const SizedBox.shrink();

        final registry = context.read<SectionRendererRegistry>();

        return ThemeStyle(
          tokens: controller.tokens,
          fallback: Theme.of(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in [
                ...controller.headerSections,
                ...controller.sections,
              ])
                SectionBoundary(
                  key: ValueKey(section.uuid),
                  // The anchor the impression check measures. Kept out here rather than inside the
                  // boundary so one map holds every section's position and one pass reads them.
                  anchor: _registerAnchor(section),
                  section: section,
                  registry: registry,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One section, isolated from the rest of the page.
///
/// Shared with the composed-page screen: a section behaves the same wherever a merchant put it,
/// and a second copy of the error boundary would be a second place for one to be missing.
class SectionBoundary extends StatelessWidget {
  const SectionBoundary({
    super.key,
    required this.section,
    required this.registry,
    this.anchor,
  });

  final ThemeSectionSchema section;
  final SectionRendererRegistry registry;

  /// Where this section is on screen, for the page's impression check. Null for a section with no
  /// server id — there would be nothing to report it against.
  final GlobalKey? anchor;

  @override
  Widget build(BuildContext context) {
    // Construction errors are caught by the registry's own try/catch. Errors thrown DEEPER —
    // inside a descendant's build, after this method has returned — can only be softened by the
    // app-level ErrorWidget.builder installed at startup (release builds collapse the broken
    // subtree to nothing; debug builds keep Flutter's red screen so developers see the error).
    // A builder swapped here and restored in a finally never covered them: descendants build
    // later in the frame, after the restore.
    final rendered = registry.render(context, section) ?? const SizedBox.shrink();

    // The anchor wraps rather than replaces: a KeyedSubtree adds no box and no layout, so a
    // section measures exactly what it drew.
    return anchor == null ? rendered : KeyedSubtree(key: anchor, child: rendered);
  }
}

/// What the engine is currently doing, for a debug build or an internal diagnostics screen.
///
/// Deliberately not shown to shoppers: "3 sections were withheld from this build" is a sentence
/// for whoever is deciding when to ship the next release, not for someone buying medicine.
class ThemeEngineDiagnostics extends StatelessWidget {
  const ThemeEngineDiagnostics({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DynamicThemeController>();
    final registry = context.read<SectionRendererRegistry>();
    final payload = controller.payload;

    final rows = <String, String>{
      'revision': '${payload.revision}',
      'schema': '${payload.schemaVersion} (client ${ThemeEngine.schemaVersion})',
      'engine': '${payload.engineVersion} (client ${ThemeEngine.engineVersion})',
      'checksum': payload.checksum ?? '—',
      'published': payload.publishedAt ?? '—',
      'sections': '${payload.sections.length}',
      'renderers': '${registry.registeredTypes.length}',
      if (payload.withheld.isNotEmpty)
        'withheld_by_server': payload.withheld.entries
            .map((entry) => '${entry.key} (${entry.value})')
            .join(', '),
      if (registry.unhandledTypes.isNotEmpty)
        'no_local_renderer': registry.unhandledTypes.join(', '),
      if (controller.lastError != null) 'last_error': controller.lastError!,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final row in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    row.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: Text(row.value)),
              ],
            ),
          ),
      ],
    );
  }
}
