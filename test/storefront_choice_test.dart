import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// A choice is only read or written while storefronts are on, so a build with them off behaves exactly as before.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('while storefronts are off', () {
    test('a stored choice is ignored and Saudi Arabia is current', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});

      final choice = StorefrontChoice(preferences, enabled: false);

      expect(choice.current().code, 'SA');
    });

    test('choosing a storefront writes nothing', () async {
      final preferences = await preferencesWith({});
      final choice = StorefrontChoice(preferences, enabled: false);

      final saved = await choice.choose(StorefrontCountry.oman);

      expect(saved, isFalse);
      expect(preferences.containsKey(AppConstants.storefrontCountry), isFalse);
      expect(choice.current().code, 'SA');
    });
  });

  group('while storefronts are on', () {
    test('choosing a storefront saves it and it becomes current', () async {
      final preferences = await preferencesWith({});
      final choice = StorefrontChoice(preferences, enabled: true);

      final saved = await choice.choose(StorefrontCountry.unitedArabEmirates);

      expect(saved, isTrue);
      expect(preferences.getString(AppConstants.storefrontCountry), 'AE');
      expect(choice.current().currency, 'AED');
    });

    test('the choice survives a new instance over the same preferences',
        () async {
      final preferences = await preferencesWith({});
      await StorefrontChoice(preferences, enabled: true)
          .choose(StorefrontCountry.qatar);

      final reopened = StorefrontChoice(preferences, enabled: true);

      expect(reopened.current().code, 'QA');
    });

    test('nothing chosen yet resolves to Saudi Arabia', () async {
      final preferences = await preferencesWith({});

      expect(StorefrontChoice(preferences, enabled: true).current().code, 'SA');
    });

    test('an unknown stored code still falls back to Saudi Arabia', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'US'});

      expect(StorefrontChoice(preferences, enabled: true).current().code, 'SA');
    });
  });
}
