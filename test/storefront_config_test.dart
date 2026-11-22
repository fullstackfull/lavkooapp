import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Storefronts ship dark, and a stored choice the app cannot honour must never strand a customer
/// outside every storefront: anything missing or unknown lands on Saudi Arabia.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('the storefront list', () {
    test('Saudi Arabia is the default storefront', () {
      expect(StorefrontCountry.defaultCountry.code, 'SA');
      expect(StorefrontCountry.defaultCountry.currency, 'SAR');
    });

    test('holds exactly the six GCC storefronts with their currencies', () {
      final currencyByCode = {
        for (final storefront in StorefrontCountry.all)
          storefront.code: storefront.currency,
      };

      expect(StorefrontCountry.all, hasLength(6));
      expect(currencyByCode, {
        'SA': 'SAR',
        'AE': 'AED',
        'KW': 'KWD',
        'QA': 'QAR',
        'BH': 'BHD',
        'OM': 'OMR',
      });
    });

    test('every storefront has its own path', () {
      final paths = StorefrontCountry.all.map((storefront) => storefront.path);

      expect(paths.toSet(), hasLength(6));
      for (final storefront in StorefrontCountry.all) {
        expect(storefront.path, '/${storefront.code.toLowerCase()}');
      }
    });
  });

  group('the build flag', () {
    test('is off unless the build defines it', () {
      expect(StorefrontConfig.enabled, isFalse);
    });
  });

  group('resolving the stored choice', () {
    test('nothing stored resolves to Saudi Arabia', () async {
      final preferences = await preferencesWith({});

      expect(StorefrontConfig.resolve(preferences).code, 'SA');
    });

    test('a stored GCC code resolves to that storefront', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});

      final storefront = StorefrontConfig.resolve(preferences);

      expect(storefront.code, 'AE');
      expect(storefront.currency, 'AED');
    });

    test('a stored code is matched regardless of case', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'kw'});

      expect(StorefrontConfig.resolve(preferences).code, 'KW');
    });

    test('an unknown stored code falls back to Saudi Arabia', () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'US'});

      expect(StorefrontConfig.resolve(preferences).code, 'SA');
    });

    test('a stored value that is not text falls back to Saudi Arabia',
        () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 7});

      expect(StorefrontConfig.resolve(preferences).code, 'SA');
    });

    test('the language country is never read as a storefront', () async {
      final preferences = await preferencesWith({
        AppConstants.countryCode: 'AE',
      });

      expect(StorefrontConfig.resolve(preferences).code, 'SA');
    });
  });
}
