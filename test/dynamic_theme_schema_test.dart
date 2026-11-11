import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/repositories/dynamic_theme_repository.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/capability_registry.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_engine.dart';

/// The parser's whole contract is "never throw, never crash the page". Every test here feeds it
/// something a real backend or a hand-edited row could produce and asserts the model degrades
/// instead of failing.
void main() {
  group('ThemePayload parsing', () {
    test('parses a complete payload', () {
      final payload = ThemePayload.fromJson({
        'page': 'home',
        'revision': 42,
        'schema_version': 1,
        'engine_version': 1,
        'checksum': 'abc123',
        'published_at': '2026-08-30T10:00:00+00:00',
        'tokens': {
          'colors': {'primary': '#7B3FE4'},
          'layout': {'border_radius': 12},
        },
        'sections': [
          {
            'uuid': 'u-1',
            'id': 7,
            'type': 'product_slider',
            'settings': {'title': 'Featured', 'limit': 6},
            'blocks': [],
            'cards': null,
            'source': {
              'kind': 'api',
              'endpoint': '/api/v1/products/featured',
              'params': {'limit': 6, 'offset': 1},
            },
          },
        ],
        'compatibility': {
          'delivered': 1,
          'withheld': {'custom_html': 'arbitrary_markup'},
        },
      });

      expect(payload.revision, 42);
      expect(payload.isRenderable, isTrue);
      expect(payload.sections.single.uuid, 'u-1');
      expect(payload.sections.single.settings.integer('limit', 0), 6);
      expect(payload.sections.single.source.requestPath,
          '/api/v1/products/featured?limit=6&offset=1');
      expect(payload.withheld['custom_html'], 'arbitrary_markup');
    });

    test('an empty object is a non-renderable payload, not an error', () {
      final payload = ThemePayload.fromJson(const {});

      expect(payload.revision, 0);
      expect(payload.isRenderable, isFalse);
      expect(payload.sections, isEmpty);
    });

    test('wrong types everywhere still parse', () {
      final payload = ThemePayload.fromJson({
        'revision': '42',
        'sections': [
          {
            'id': 'not-a-number',
            'type': 'spacer',
            'settings': {'height': '30', 'visible': 'true'},
            'blocks': 'not-a-list',
            'source': 'not-a-map',
          },
          'not-even-a-map',
          {'type': ''},
        ],
      });

      expect(payload.revision, 42);
      // The malformed entries are dropped; the parseable one survives.
      expect(payload.sections, hasLength(1));
      expect(payload.sections.single.settings.integer('height', 0), 30);
      expect(payload.sections.single.settings.flag('visible', false), isTrue);
    });

    test('a section without a uuid still gets an identity', () {
      final payload = ThemePayload.fromJson({
        'revision': 1,
        'sections': [
          {'id': 9, 'type': 'spacer', 'settings': {}},
        ],
      });

      expect(payload.sections.single.uuid, 'section-9');
    });
  });

  group('ThemeRevision sync decision', () {
    const held = ThemePayload(
      page: 'home',
      revision: 41,
      schemaVersion: 1,
      engineVersion: 1,
      checksum: 'aaa',
      contentStamp: null,
      publishedAt: null,
      tokens: ThemeTokens.empty,
      sections: [],
      withheld: {},
    );

    test('a higher revision means refetch', () {
      const remote = ThemeRevision(
          revision: 42, checksum: 'bbb', schemaVersion: 1, engineVersion: 1);
      expect(remote.isNewerThan(held), isTrue);
    });

    test('the same revision and checksum means keep what is held', () {
      const remote = ThemeRevision(
          revision: 41, checksum: 'aaa', schemaVersion: 1, engineVersion: 1);
      expect(remote.isNewerThan(held), isFalse);
    });

    test('a rollback (same revision id logic, different checksum) means refetch', () {
      const remote = ThemeRevision(
          revision: 41, checksum: 'ccc', schemaVersion: 1, engineVersion: 1);
      expect(remote.isNewerThan(held), isTrue);
    });

    test('revision zero never triggers a fetch', () {
      const remote = ThemeRevision(
          revision: 0, checksum: null, schemaVersion: 1, engineVersion: 1);
      expect(remote.isNewerThan(held), isFalse);
    });
  });

  group('section variant and version', () {
    test('the variant arrives as its own key', () {
      final section = ThemeSectionSchema.fromJson(const {
        'uuid': 'sec-1',
        'type': 'product_slider',
        'variant': 'carousel',
        'component_version': 2,
        'settings': {'style': 'rail'},
      });

      expect(section.variant, 'carousel',
          reason: 'the delivered variant wins over the settings key it was lifted from');
      expect(section.componentVersion, 2);
    });

    test('a payload from an older server still yields a variant', () {
      // Servers that predate the variant key still send the setting the renderers used to read,
      // and a build that branches on `variant` has to keep working against them.
      final byStyle = ThemeSectionSchema.fromJson(const {
        'uuid': 'sec-2', 'type': 'product_slider', 'settings': {'style': 'grid'},
      });
      final byLayout = ThemeSectionSchema.fromJson(const {
        'uuid': 'sec-3', 'type': 'store_banner', 'settings': {'layout': 'mosaic'},
      });

      expect(byStyle.variant, 'grid');
      expect(byLayout.variant, 'mosaic');
      expect(byStyle.componentVersion, 1, reason: 'an unversioned payload is version one');
    });

    test('a type with one look has nothing to branch on', () {
      final section = ThemeSectionSchema.fromJson(const {
        'uuid': 'sec-4', 'type': 'spacer', 'settings': {'height': 24},
      });

      expect(section.variant, isNull);
    });
  });

  group('where a section leads', () {
    test('the delivered destination wins over the local guess', () {
      // The server is the only side that knows a rail is scoped to one category rather than to
      // the catalogue — the app had been sending every product rail to "all products".
      final section = ThemeSectionSchema.fromJson(const {
        'uuid': 'sec-1',
        'type': 'product_slider',
        'settings': {'source': 'category', 'source_id': 11},
        'view_all': {
          'type': 'category',
          'id': 11,
          'label': 'Vitamins',
          'url': 'https://shop.test/products?category_id=11&data_from=category',
        },
      });

      expect(section.viewAll.type, 'category');
      expect(section.viewAll.id, 11);
    });

    test('a payload from an older server leads nowhere new, not nowhere at all', () {
      final section = ThemeSectionSchema.fromJson(const {
        'uuid': 'sec-2', 'type': 'product_slider', 'settings': {},
      });

      expect(section.viewAll.isNone, isTrue,
          reason: 'and the widget then falls back to its own per-type guess');
    });
  });

  group('ThemeAction', () {
    test('null and empty parse to none', () {
      expect(ThemeAction.fromJson(null).isNone, isTrue);
      expect(ThemeAction.fromJson(const {}).isNone, isTrue);
      expect(ThemeAction.fromJson(const {'type': ''}).isNone, isTrue);
    });

    test('a product action carries its slug', () {
      final action = ThemeAction.fromJson(const {
        'type': 'product',
        'slug': 'aspirin-100mg',
        'url': 'https://shop.test/product/aspirin-100mg',
      });

      expect(action.type, 'product');
      expect(action.slug, 'aspirin-100mg');
    });
  });

  group('guest credential on section fetches', () {
    test('a credential-less cached hint is completed, a complete one untouched', () {
      expect(DynamicThemeRepository.withGuestCredential('/api/v1/products/featured?limit=10'),
          '/api/v1/products/featured?limit=10&guest_id=1');
      expect(DynamicThemeRepository.withGuestCredential('/api/v1/products/by-ids'),
          '/api/v1/products/by-ids?guest_id=1');
      expect(
          DynamicThemeRepository.withGuestCredential(
              '/api/v1/products/featured?limit=10&guest_id=1'),
          '/api/v1/products/featured?limit=10&guest_id=1',
          reason: 'a hint that already names its guest must not name it twice');
    });
  });

  group('experiment tag', () {
    test('a variant section carries key:variant for its impression', () {
      final section = ThemeSectionSchema.fromJson({
        'uuid': 'u1', 'id': 7, 'type': 'hero_banner',
        'experiment': {'key': 'hero-copy', 'variant': 'b'},
      });

      expect(section.experimentTag, 'hero-copy:b');
    });

    test('no experiment, half an experiment, and junk all stay null', () {
      expect(ThemeSectionSchema.fromJson({'uuid': 'u', 'id': 1, 'type': 'spacer'}).experimentTag,
          isNull);
      expect(
          ThemeSectionSchema.fromJson({
            'uuid': 'u', 'id': 1, 'type': 'spacer',
            'experiment': {'key': 'hero-copy'},
          }).experimentTag,
          isNull,
          reason: 'a tag without a variant would count exposures against nothing');
      expect(
          ThemeSectionSchema.fromJson({
            'uuid': 'u', 'id': 1, 'type': 'spacer', 'experiment': 'not-a-map',
          }).experimentTag,
          isNull);
    });
  });

  group('capability contract', () {
    test('every declared capability has a renderer, and every renderer is declared', () {
      final registry = ThemeEngine.buildRegistry();

      expect(
        registry.registeredTypes.toSet(),
        ThemeCapabilities.components.toSet(),
        reason: 'A renderer not declared is never sent; a declaration without a '
            'renderer arrives with nothing to draw it. The two lists must be '
            'the same set.',
      );
    });

    test('headers name every component', () {
      final headers = ThemeCapabilities.headers;

      expect(headers['X-UI-Engine'], '${ThemeCapabilities.engineVersion}');
      for (final type in ThemeCapabilities.components) {
        expect(headers['X-UI-Components'], contains(type));
      }
    });
  });

  group('card frames', () {
    test('one image means one frame, extra frames ride along in order', () {
      final single = ThemeCard.fromJson(const {'image': 'https://x/a.png'});
      expect(single.frames, ['https://x/a.png']);

      final multi = ThemeCard.fromJson(const {
        'image': 'https://x/a.png',
        'image_2': 'https://x/b.png',
        'image_3': 'https://x/c.png',
      });
      expect(multi.frames, [
        'https://x/a.png',
        'https://x/b.png',
        'https://x/c.png',
      ]);
    });

    test('the phone-preferred image leads the frames', () {
      final card = ThemeCard.fromJson(const {
        'image': 'https://x/web.png',
        'image_mobile': 'https://x/phone.png',
        'image_2': 'https://x/b.png',
      });
      expect(card.frames.first, 'https://x/phone.png');
      expect(card.frames.length, 2);
    });
  });
}
