import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Whether a storefront may sell follows the answer the server last gave, kept on the device. A storefront the server marks sellable
/// may sell and every other one stays browse-only. With no answer, or with an answer that does not list it, the built-in default
/// holds, so only Saudi Arabia may sell.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  /// The server's own shape, as the repository keeps it.
  String answerOf(Map<String, bool> sellableByCountry) => jsonEncode({
        'storefronts': [
          for (final MapEntry<String, bool> entry in sellableByCountry.entries)
            {
              'country': entry.key,
              'path': entry.key.toLowerCase(),
              'currency': 'XXX',
              'sellable': entry.value,
            },
        ],
      });

  Future<StorefrontChoice> choiceWith({
    required bool enabled,
    Map<String, bool>? answer,
  }) async {
    final preferences = await preferencesWith({
      if (answer != null) AppConstants.storefrontList: answerOf(answer),
    });

    return StorefrontChoice(preferences, enabled: enabled);
  }

  group('while storefronts are off', () {
    test('every storefront may sell, whatever the stored answer says',
        () async {
      final choice = await choiceWith(
        enabled: false,
        answer: {'SA': false, 'AE': false, 'OM': false},
      );

      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(choice.canSell(storefront), isTrue, reason: storefront.code);
      }
    });

    test('every storefront may sell when there is no answer either', () async {
      final choice = await choiceWith(enabled: false);

      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(choice.canSell(storefront), isTrue, reason: storefront.code);
      }
    });
  });

  group('while storefronts are on, with the server\'s answer', () {
    test('a storefront it marks sellable may sell', () async {
      final choice =
          await choiceWith(enabled: true, answer: {'SA': true, 'AE': true});

      expect(choice.canSell(StorefrontCountry.unitedArabEmirates), isTrue);
    });

    test('a storefront it marks browse-only may not sell', () async {
      final choice =
          await choiceWith(enabled: true, answer: {'SA': true, 'AE': false});

      expect(choice.canSell(StorefrontCountry.unitedArabEmirates), isFalse);
    });

    test('Saudi Arabia may sell when it is marked sellable', () async {
      final choice =
          await choiceWith(enabled: true, answer: {'SA': true, 'AE': false});

      expect(choice.canSell(StorefrontCountry.saudiArabia), isTrue);
    });

    test('the server\'s word wins even for Saudi Arabia', () async {
      final choice = await choiceWith(enabled: true, answer: {'SA': false});

      expect(choice.canSell(StorefrontCountry.saudiArabia), isFalse);
    });

    test('a storefront it does not list keeps its default: browse-only',
        () async {
      final choice = await choiceWith(enabled: true, answer: {'SA': true});

      expect(choice.canSell(StorefrontCountry.kuwait), isFalse);
    });

    test('Saudi Arabia, when it is not listed, keeps its default: sellable',
        () async {
      final choice = await choiceWith(enabled: true, answer: {'AE': true});

      expect(choice.canSell(StorefrontCountry.saudiArabia), isTrue);
    });

    test('each storefront gets its own answer', () async {
      final choice = await choiceWith(
        enabled: true,
        answer: {'SA': true, 'AE': true, 'KW': false, 'QA': true, 'OM': false},
      );

      expect(<String, bool>{
        for (final StorefrontCountry storefront in StorefrontCountry.all)
          storefront.code: choice.canSell(storefront),
      }, {
        'SA': true,
        'AE': true,
        'KW': false,
        'QA': true,
        'BH': false,
        'OM': false,
      });
    });

    test('a newer answer replaces the older one', () async {
      final preferences = await preferencesWith({
        AppConstants.storefrontList: answerOf({'AE': true})
      });
      final choice = StorefrontChoice(preferences, enabled: true);
      expect(choice.canSell(StorefrontCountry.unitedArabEmirates), isTrue);

      await preferences.setString(
          AppConstants.storefrontList, answerOf({'AE': false}));

      expect(choice.canSell(StorefrontCountry.unitedArabEmirates), isFalse);
    });
  });

  group('while storefronts are on, with no answer yet', () {
    test('Saudi Arabia may sell and every other storefront is browse-only',
        () async {
      final choice = await choiceWith(enabled: true);

      expect(<String, bool>{
        for (final StorefrontCountry storefront in StorefrontCountry.all)
          storefront.code: choice.canSell(storefront),
      }, {
        'SA': true,
        'AE': false,
        'KW': false,
        'QA': false,
        'BH': false,
        'OM': false,
      });
    });

    test('a stored value that is not an answer counts as no answer', () async {
      for (final Object stored in <Object>[
        7,
        'garbage',
        '[]',
        '{"storefronts": 3}'
      ]) {
        final preferences =
            await preferencesWith({AppConstants.storefrontList: stored});
        final choice = StorefrontChoice(preferences, enabled: true);

        expect(choice.canSell(StorefrontCountry.saudiArabia), isTrue,
            reason: 'stored: $stored');
        expect(choice.canSell(StorefrontCountry.unitedArabEmirates), isFalse,
            reason: 'stored: $stored');
      }
    });

    test('an answer that lists nothing counts as no answer', () async {
      final choice = await choiceWith(enabled: true, answer: {});

      expect(choice.canSell(StorefrontCountry.saudiArabia), isTrue);
      expect(choice.canSell(StorefrontCountry.unitedArabEmirates), isFalse);
    });
  });

  group('the storefront the customer is on', () {
    test('may sell once the server has marked it sellable', () async {
      final preferences = await preferencesWith({
        AppConstants.storefrontCountry: 'AE',
        AppConstants.storefrontList: answerOf({'SA': true, 'AE': true}),
      });
      final choice = StorefrontChoice(preferences, enabled: true);

      expect(choice.current().code, 'AE');
      expect(choice.canSell(choice.current()), isTrue);
    });

    test('is browse-only until then, and can still be chosen', () async {
      final preferences = await preferencesWith({});
      final choice = StorefrontChoice(preferences, enabled: true);

      await choice.choose(StorefrontCountry.unitedArabEmirates);

      expect(choice.current().code, 'AE');
      expect(choice.canSell(choice.current()), isFalse);
    });
  });
}
