import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';

/// One section type's renderer.
///
/// A renderer is asked for a widget and may decline by returning null — which is the normal way a
/// section with nothing to show disappears rather than leaving a padded empty band on the page.
/// It must not throw; the registry wraps every call, but a renderer that treats missing data as an
/// exception makes its own section's failure indistinguishable from a bug.
abstract class SectionRenderer {
  const SectionRenderer();

  /// The section types this renderer draws. One renderer commonly serves several: every banner
  /// arrangement is the same card list in a different layout, and every product rail is the same
  /// fetch behind a different source.
  List<String> get types;

  /// Whether this section has enough to be worth drawing, decided before any widget is built.
  ///
  /// Cheap and synchronous — it reads the payload, never the network. A product rail whose data
  /// has not arrived yet is still "renderable": it draws its own loading state.
  bool canRender(ThemeSectionSchema section) => true;

  /// The widget for this section, or null to skip it entirely.
  Widget? build(BuildContext context, ThemeSectionSchema section);
}
