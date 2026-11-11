import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer_registry.dart';

/// The registry's contract is the page's survival: an unknown type, a declining renderer, and a
/// throwing renderer all cost exactly one section, never the page.
class _TextRenderer extends SectionRenderer {
  const _TextRenderer();

  @override
  List<String> get types => const ['works'];

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) =>
      Text('rendered-${section.uuid}');
}

class _DecliningRenderer extends SectionRenderer {
  const _DecliningRenderer();

  @override
  List<String> get types => const ['declines'];

  @override
  bool canRender(ThemeSectionSchema section) => false;

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) =>
      const Text('should-never-appear');
}

class _ThrowingRenderer extends SectionRenderer {
  const _ThrowingRenderer();

  @override
  List<String> get types => const ['throws'];

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) =>
      throw StateError('malformed section');
}

ThemeSectionSchema _section(String type, {String? uuid}) =>
    ThemeSectionSchema.fromJson({
      'uuid': uuid ?? 'u-$type',
      'id': 1,
      'type': type,
      'settings': const <String, dynamic>{},
    });

void main() {
  late SectionRendererRegistry registry;

  setUp(() {
    registry = SectionRendererRegistry()
      ..registerAll(const [_TextRenderer(), _DecliningRenderer(), _ThrowingRenderer()]);
  });

  testWidgets('a page with an unknown, a declining and a throwing section still renders the rest',
      (tester) async {
    final sections = [
      _section('works', uuid: 'first'),
      _section('unknown_future_type'),
      _section('declines'),
      _section('throws'),
      _section('works', uuid: 'last'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Column(
          children: [
            for (final section in sections)
              registry.render(context, section) ?? const SizedBox.shrink(),
          ],
        ),
      ),
    ));

    expect(find.text('rendered-first'), findsOneWidget);
    expect(find.text('rendered-last'), findsOneWidget,
        reason: 'sections after the broken one must keep rendering');
    expect(find.text('should-never-appear'), findsNothing);
    expect(tester.takeException(), isNull,
        reason: 'a renderer that throws is isolated, never rethrown into the page');
  });

  test('unknown types are recorded for diagnostics, known ones are not', () {
    expect(registry.supports('works'), isTrue);
    expect(registry.supports('unknown_future_type'), isFalse);
    expect(registry.unhandledTypes, isEmpty);
  });

  testWidgets('rendering an unknown type records it once', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          registry.render(context, _section('mystery'));
          registry.render(context, _section('mystery'));
          return const SizedBox.shrink();
        },
      ),
    ));

    expect(registry.unhandledTypes, {'mystery'});
  });
}
