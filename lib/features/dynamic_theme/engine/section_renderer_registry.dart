import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';

/// Type → renderer, resolved by lookup rather than by a chain of conditionals.
///
/// The point is not tidiness. A `switch` over section types puts every future section type in the
/// same function, which means every new section is a change to a file every other section depends
/// on — and an unknown type falls through to a default that somebody has to remember to write. A
/// registry inverts both: a renderer registers itself, an unknown type is simply absent, and
/// "absent" has one well-defined behaviour that is written once, here.
///
/// That behaviour is: skip the section, record why, keep rendering the rest of the page. A home
/// page that loses one rail because the server sent something this build has never heard of is a
/// working home page. A home page that throws is not.
class SectionRendererRegistry {
  SectionRendererRegistry();

  final Map<String, SectionRenderer> _renderers = {};

  /// Types that arrived but had no renderer, collected for the diagnostics screen.
  final Set<String> _unhandled = {};

  Set<String> get unhandledTypes => Set.unmodifiable(_unhandled);

  /// Every type this registry can draw — the source of truth the capability list is asserted
  /// against, so a renderer nobody declared cannot silently never be sent.
  List<String> get registeredTypes => _renderers.keys.toList(growable: false)..sort();

  void register(SectionRenderer renderer) {
    for (final type in renderer.types) {
      _renderers[type] = renderer;
    }
  }

  void registerAll(Iterable<SectionRenderer> renderers) {
    renderers.forEach(register);
  }

  bool supports(String type) => _renderers.containsKey(type);

  /// The widget for one section, or null when it should not appear.
  ///
  /// Four ways a section legitimately produces nothing, and none of them is an error the page has
  /// to survive as an error: no renderer for the type, the renderer declining, the renderer
  /// returning null, or the renderer throwing. The last one is the reason for the try/catch — a
  /// malformed section from a hand-edited row must cost that section and nothing else.
  Widget? render(BuildContext context, ThemeSectionSchema section) {
    final renderer = _renderers[section.type];

    if (renderer == null) {
      _unhandled.add(section.type);
      if (kDebugMode) {
        debugPrint('[theme] no renderer for section type "${section.type}" — skipped');
      }
      return null;
    }

    try {
      if (!renderer.canRender(section)) return null;
      return renderer.build(context, section);
    } catch (error, stack) {
      // Isolation happens here, at construction time, because this is the boundary the page owns.
      // Errors thrown deeper — inside a child's own build, after this returns — are caught by the
      // ErrorWidget override the host screen installs.
      if (kDebugMode) {
        debugPrint('[theme] section "${section.type}" (${section.uuid}) failed to build: $error');
        debugPrintStack(stackTrace: stack);
      }
      return null;
    }
  }
}
