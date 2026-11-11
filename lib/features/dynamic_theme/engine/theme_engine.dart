import 'package:syriapharmacy/features/dynamic_theme/engine/capability_registry.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer_registry.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/banner_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/chrome_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/content_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/product_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/taxonomy_section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/renderers/utility_section_renderer.dart';

/// Where the engine is assembled.
///
/// Adding a section type to this app is two steps and neither of them touches a `switch`: write a
/// [SectionRenderer], add it to [renderers], and add its type to
/// [ThemeCapabilities.components] so the server knows to send it. A test asserts those two lists
/// agree, which is what stops the two most likely mistakes — a renderer the server never sends,
/// and a type the server sends with nothing to draw it.
class ThemeEngine {
  const ThemeEngine._();

  static int get schemaVersion => ThemeCapabilities.schemaVersion;
  static int get engineVersion => ThemeCapabilities.engineVersion;

  /// Every renderer this build ships. One entry commonly covers several section types.
  static const List<SectionRenderer> renderers = [
    BannerSectionRenderer(),
    ProductSectionRenderer(),
    TaxonomySectionRenderer(),
    ContentSectionRenderer(),
    UtilitySectionRenderer(),
    AnnouncementSectionRenderer(),
    SpacerSectionRenderer(),
  ];

  static SectionRendererRegistry buildRegistry() =>
      SectionRendererRegistry()..registerAll(renderers);
}
