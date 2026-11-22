import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// The last answer is kept so a cold start with no network still knows which storefronts may sell. Whatever is found on the device
/// is read defensively: anything that is not the list this code wrote is no answer at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  String describe(StorefrontCountry storefront) =>
      '${storefront.code} ${storefront.path} ${storefront.currency} '
      '${storefront.sellable ? 'sellable' : 'browse-only'}';

  const StorefrontCountry sellableEmirates = StorefrontCountry(
    code: 'AE',
    path: '/ae',
    currency: 'AED',
    sellable: true,
  );

  group('the round trip', () {
    test('nothing stored reads as no answer', () async {
      final preferences = await preferencesWith({});

      expect(StoredStorefronts(preferences).read(), isEmpty);
    });

    test('a saved list is read back as it was saved', () async {
      final preferences = await preferencesWith({});
      final stored = StoredStorefronts(preferences);

      final saved = await stored.save(<StorefrontCountry>[
        StorefrontCountry.saudiArabia,
        sellableEmirates,
        StorefrontCountry.oman,
      ]);

      expect(saved, isTrue);
      expect(stored.read().map(describe), <String>[
        'SA /sa SAR sellable',
        'AE /ae AED sellable',
        'OM /om OMR browse-only',
      ]);
    });

    test('survives a new instance over the same preferences, as a restart does',
        () async {
      final preferences = await preferencesWith({});
      await StoredStorefronts(preferences)
          .save(<StorefrontCountry>[sellableEmirates]);

      final reopened = StoredStorefronts(preferences);

      expect(reopened.read().map(describe), <String>['AE /ae AED sellable']);
    });

    test('saving again replaces the previous answer instead of adding to it',
        () async {
      final preferences = await preferencesWith({});
      final stored = StoredStorefronts(preferences);
      await stored.save(<StorefrontCountry>[
        StorefrontCountry.saudiArabia,
        sellableEmirates,
      ]);

      await stored.save(<StorefrontCountry>[StorefrontCountry.saudiArabia]);

      expect(stored.read().map(describe), <String>['SA /sa SAR sellable']);
    });

    test(
        'is kept under its own key, apart from the storefront the customer chose',
        () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'KW'});

      await StoredStorefronts(preferences)
          .save(<StorefrontCountry>[sellableEmirates]);

      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
      expect(preferences.containsKey(AppConstants.storefrontList), isTrue);
    });

    test('is written in the shape of the server\'s answer', () async {
      final preferences = await preferencesWith({});

      await StoredStorefronts(preferences)
          .save(<StorefrontCountry>[sellableEmirates]);

      expect(jsonDecode(preferences.getString(AppConstants.storefrontList)!), {
        'storefronts': [
          {
            'country': 'AE',
            'path': '/ae',
            'currency': 'AED',
            'sellable': true,
          },
        ],
      });
    });
  });

  group('finding a storefront in the stored answer', () {
    test('matches the code regardless of case and surrounding spaces',
        () async {
      final preferences = await preferencesWith({});
      final stored = StoredStorefronts(preferences);
      await stored.save(<StorefrontCountry>[sellableEmirates]);

      expect(stored.find('AE')?.sellable, isTrue);
      expect(stored.find('ae')?.sellable, isTrue);
      expect(stored.find(' Ae ')?.sellable, isTrue);
    });

    test('finds nothing for a country the answer does not list', () async {
      final preferences = await preferencesWith({});
      final stored = StoredStorefronts(preferences);
      await stored.save(<StorefrontCountry>[sellableEmirates]);

      expect(stored.find('KW'), isNull);
    });

    test('finds nothing when nothing is stored', () async {
      final preferences = await preferencesWith({});

      expect(StoredStorefronts(preferences).find('SA'), isNull);
    });
  });

  group('a stored value that cannot be used', () {
    test('is no answer when it is not text', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontList: 7});

      expect(StoredStorefronts(preferences).read(), isEmpty);
    });

    test('is no answer when it is not JSON', () async {
      final preferences = await preferencesWith(
          {AppConstants.storefrontList: '{"storefronts"'});

      expect(StoredStorefronts(preferences).read(), isEmpty);
    });

    test('is no answer when it is JSON of another shape', () async {
      for (final String stored in <String>[
        '',
        'null',
        '[]',
        '"AE"',
        '{}',
        '{"storefronts": 3}',
        '{"storefronts": {"country": "AE"}}',
      ]) {
        final preferences =
            await preferencesWith({AppConstants.storefrontList: stored});

        expect(StoredStorefronts(preferences).read(), isEmpty,
            reason: 'stored: $stored');
      }
    });

    test('does not stop a new answer from being saved over it', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontList: 'garbage'});
      final stored = StoredStorefronts(preferences);

      await stored.save(<StorefrontCountry>[sellableEmirates]);

      expect(stored.read().map(describe), <String>['AE /ae AED sellable']);
    });
  });
}
