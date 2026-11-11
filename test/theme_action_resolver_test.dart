import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';

/// What a tap is allowed to promise.
///
/// Renderers ask [ThemeActionResolver.isNavigable] before making anything tappable, so this is
/// the contract that decides which cards a shopper can press. The cases that matter are the
/// refusals: a card that promises a destination and then does nothing is the bug these pin out.
void main() {
  const resolver = ThemeActionResolver();

  ThemeAction action(Map<String, dynamic> json) => ThemeAction.fromJson(json);

  group('a composed page action', () {
    test('is navigable when the server named the page', () {
      expect(
        resolver.isNavigable(action({'type': 'page', 'slug': 'ramadan-offers'})),
        isTrue,
      );
    });

    test('is inert without a slug — there is no page to open', () {
      expect(resolver.isNavigable(action({'type': 'page'})), isFalse);
      expect(resolver.isNavigable(action({'type': 'page', 'slug': ''})), isFalse);
    });
  });

  group('the fall-through that keeps old builds working', () {
    test('a type this build has never heard of still navigates by its url', () {
      expect(
        resolver.isNavigable(
            action({'type': 'hologram', 'url': 'https://shop.example/x'})),
        isTrue,
      );
    });

    test('a foreign type without a url is a dead tap, not a crash', () {
      expect(resolver.isNavigable(action({'type': 'hologram'})), isFalse);
    });

    test('no action at all is never tappable', () {
      expect(resolver.isNavigable(ThemeAction.none), isFalse);
    });
  });
}
