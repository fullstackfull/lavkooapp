import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

const StorefrontCountry _sellableEmirates = StorefrontCountry(
  code: 'AE',
  path: '/ae',
  currency: 'AED',
  sellable: true,
);

/// What the chooser asks the controller: which storefronts there are to choose from, whether there is a choice at all, and what each of
/// them may do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorefrontController> controllerWith({
    required bool enabled,
    List<StorefrontCountry>? answered,
    Map<String, Object> stored = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (answered != null) {
      await StoredStorefronts(preferences).save(answered);
    }

    return StorefrontController(
      storefrontServiceInterface: _NoServer(),
      storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
    );
  }

  group('while storefronts are off', () {
    test('there is nothing to choose from, whatever was stored', () async {
      final StorefrontController controller = await controllerWith(
        enabled: false,
        answered: StorefrontCountry.all,
      );

      expect(controller.available, isEmpty);
      expect(controller.canChoose, isFalse);
    });

    test('the customer is on the Saudi storefront, whatever was chosen',
        () async {
      final StorefrontController controller = await controllerWith(
        enabled: false,
        stored: <String, Object>{AppConstants.storefrontCountry: 'AE'},
      );

      expect(controller.current.code, 'SA');
    });
  });

  group('while storefronts are on', () {
    test('there is nothing to choose from before the server has answered',
        () async {
      final StorefrontController controller =
          await controllerWith(enabled: true);

      expect(controller.available, isEmpty);
      expect(controller.canChoose, isFalse);
    });

    test('there is nothing to choose from when the server lists one storefront',
        () async {
      final StorefrontController controller = await controllerWith(
        enabled: true,
        answered: <StorefrontCountry>[StorefrontCountry.saudiArabia],
      );

      expect(controller.available, hasLength(1));
      expect(controller.canChoose, isFalse);
    });

    test('there is a choice when the server lists more than one, in its order',
        () async {
      final StorefrontController controller = await controllerWith(
        enabled: true,
        answered: <StorefrontCountry>[
          StorefrontCountry.unitedArabEmirates,
          StorefrontCountry.saudiArabia,
        ],
      );

      expect(controller.canChoose, isTrue);
      expect(controller.available.map((StorefrontCountry s) => s.code),
          <String>['AE', 'SA']);
    });

    test('the customer is on the storefront they chose', () async {
      final StorefrontController controller = await controllerWith(
        enabled: true,
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
      );

      expect(controller.current.code, 'KW');
    });

    test(
        'a storefront the server marks sellable may sell and the others are browse-only',
        () async {
      final StorefrontController controller = await controllerWith(
        enabled: true,
        answered: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          _sellableEmirates,
          StorefrontCountry.kuwait,
        ],
      );

      expect(controller.canSell(StorefrontCountry.saudiArabia), isTrue);
      expect(controller.canSell(StorefrontCountry.unitedArabEmirates), isTrue);
      expect(controller.canSell(StorefrontCountry.kuwait), isFalse);
    });

    test('a storefront the server did not list keeps the built-in answer',
        () async {
      final StorefrontController controller = await controllerWith(
        enabled: true,
        answered: <StorefrontCountry>[StorefrontCountry.saudiArabia],
      );

      expect(controller.canSell(StorefrontCountry.qatar), isFalse);
    });
  });
}
