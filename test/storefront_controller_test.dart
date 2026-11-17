import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/checkout_sale_gate.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// A service double that, like the real one, keeps what the server answered where the choice reads it from.
class _FakeStorefrontService implements StorefrontServiceInterface {
  _FakeStorefrontService(this._preferences);

  final SharedPreferences _preferences;

  List<StorefrontCountry>? answer;
  bool throwOnRefresh = false;
  int refreshes = 0;

  @override
  Future<bool> refreshStorefronts() async {
    refreshes++;

    if (throwOnRefresh) {
      throw StateError('the device refused the write');
    }

    final List<StorefrontCountry>? newAnswer = answer;
    if (newAnswer == null) {
      return false;
    }

    return StoredStorefronts(_preferences).save(newAnswer);
  }
}

const StorefrontCountry _sellableEmirates = StorefrontCountry(
  code: 'AE',
  path: '/ae',
  currency: 'AED',
  sellable: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferencesWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  StorefrontController controllerOver(
    SharedPreferences preferences,
    _FakeStorefrontService service, {
    required bool enabled,
  }) =>
      StorefrontController(
        storefrontServiceInterface: service,
        storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
      );

  group('while storefronts are off', () {
    test('the gate lets every sale start, whatever is stored', () async {
      final preferences = await preferencesWith({
        AppConstants.storefrontCountry: 'AE',
      });
      final controller = controllerOver(
        preferences,
        _FakeStorefrontService(preferences),
        enabled: false,
      );

      expect(controller.saleGate.storefrontMaySell, isTrue);
      expect(controller.saleGate.showsBrowseOnlyNotice, isFalse);
      expect(controller.saleGate.permits(otherwiseEnabled: true), isTrue);
    });

    test('refreshing asks nothing and tells nobody', () async {
      final preferences = await preferencesWith({});
      final service = _FakeStorefrontService(preferences)
        ..answer = <StorefrontCountry>[_sellableEmirates];
      final controller = controllerOver(preferences, service, enabled: false);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.refresh();

      expect(service.refreshes, 0);
      expect(notifications, 0);
    });

    test('choosing a storefront saves nothing, asks nothing and tells nobody',
        () async {
      final preferences = await preferencesWith({});
      final service = _FakeStorefrontService(preferences);
      final controller = controllerOver(preferences, service, enabled: false);
      var notifications = 0;
      controller.addListener(() => notifications++);

      final saved =
          await controller.choose(StorefrontCountry.unitedArabEmirates);

      expect(saved, isFalse);
      expect(service.refreshes, 0);
      expect(notifications, 0);
      expect(preferences.containsKey(AppConstants.storefrontCountry), isFalse);
    });
  });

  group('the lookup the controllers that place an order use', () {
    Future<BuildContext> contextWithoutProviders(WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (BuildContext builderContext) {
        context = builderContext;
        return const SizedBox();
      }));

      return context;
    }

    test(
        'leaves the refusal to the server when there is no context to look up from',
        () {
      expect(StorefrontController.maySellIn(null), isTrue);
    });

    testWidgets(
        'lets a sale start without looking any provider up while storefronts are off',
        (tester) async {
      final BuildContext context = await contextWithoutProviders(tester);

      expect(StorefrontController.maySellIn(context), isTrue);
    }, skip: StorefrontConfig.enabled);

    // Runs only in a build made with --dart-define=GCC_STOREFRONTS_ENABLED=true, because the flag is a compile-time constant.
    testWidgets('asks the controller while storefronts are on', (tester) async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});
      final controller = controllerOver(
        preferences,
        _FakeStorefrontService(preferences),
        enabled: true,
      );
      late BuildContext context;
      await tester.pumpWidget(
        ChangeNotifierProvider<StorefrontController>.value(
          value: controller,
          child: Builder(builder: (BuildContext builderContext) {
            context = builderContext;
            return const SizedBox();
          }),
        ),
      );

      expect(StorefrontController.maySellIn(context), isFalse);
    }, skip: !StorefrontConfig.enabled);
  });

  group('a screen that listens', () {
    testWidgets('is rebuilt when the answer arrives', (tester) async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});
      final service = _FakeStorefrontService(preferences)
        ..answer = <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          _sellableEmirates,
        ];
      final controller = controllerOver(preferences, service, enabled: true);
      await tester.pumpWidget(
        ChangeNotifierProvider<StorefrontController>.value(
          value: controller,
          child: MaterialApp(
            home: Builder(builder: (BuildContext context) {
              final CheckoutSaleGate saleGate =
                  Provider.of<StorefrontController>(context).saleGate;

              return Scaffold(
                body: Column(children: [
                  if (saleGate.showsBrowseOnlyNotice) const Text('browse-only'),
                  TextButton(
                    onPressed:
                        saleGate.permits(otherwiseEnabled: true) ? () {} : null,
                    child: const Text('checkout'),
                  ),
                ]),
              );
            }),
          ),
        ),
      );
      expect(find.text('browse-only'), findsOneWidget);
      expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);

      await controller.refresh();
      await tester.pump();

      expect(find.text('browse-only'), findsNothing);
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNotNull);
    });
  });

  group('while storefronts are on', () {
    test('Saudi Arabia may sell with no answer yet', () async {
      final preferences = await preferencesWith({});
      final controller = controllerOver(
        preferences,
        _FakeStorefrontService(preferences),
        enabled: true,
      );

      expect(controller.saleGate.storefrontMaySell, isTrue);
    });

    test('a browse-only storefront closes the gate and shows the notice',
        () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});
      final controller = controllerOver(
        preferences,
        _FakeStorefrontService(preferences),
        enabled: true,
      );

      expect(controller.saleGate.storefrontMaySell, isFalse);
      expect(controller.saleGate.showsBrowseOnlyNotice, isTrue);
      expect(controller.saleGate.permits(otherwiseEnabled: true), isFalse);
    });

    test(
        'a refresh that brings a newer answer opens the gate and tells the screens',
        () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});
      final service = _FakeStorefrontService(preferences)
        ..answer = <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          _sellableEmirates,
        ];
      final controller = controllerOver(preferences, service, enabled: true);
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(controller.saleGate.storefrontMaySell, isFalse);

      await controller.refresh();

      expect(service.refreshes, 1);
      expect(notifications, 1);
      expect(controller.saleGate.storefrontMaySell, isTrue);
    });

    test('a refresh that brings nothing new tells nobody', () async {
      final preferences = await preferencesWith({});
      final service = _FakeStorefrontService(preferences);
      final controller = controllerOver(preferences, service, enabled: true);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.refresh();

      expect(service.refreshes, 1);
      expect(notifications, 0);
    });

    test('a refresh that fails does not throw and leaves the gate as it was',
        () async {
      final preferences =
          await preferencesWith({AppConstants.storefrontCountry: 'AE'});
      final service = _FakeStorefrontService(preferences)
        ..throwOnRefresh = true;
      final controller = controllerOver(preferences, service, enabled: true);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.refresh();

      expect(service.refreshes, 1);
      expect(notifications, 0);
      expect(controller.saleGate.storefrontMaySell, isFalse);
    });

    test(
        'choosing another storefront saves it, tells the screens and asks again',
        () async {
      final preferences = await preferencesWith({});
      final service = _FakeStorefrontService(preferences)
        ..answer = <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          _sellableEmirates,
        ];
      final controller = controllerOver(preferences, service, enabled: true);
      var notifications = 0;
      controller.addListener(() => notifications++);

      final saved =
          await controller.choose(StorefrontCountry.unitedArabEmirates);

      expect(saved, isTrue);
      expect(preferences.getString(AppConstants.storefrontCountry), 'AE');
      expect(service.refreshes, 1);
      expect(notifications, 2,
          reason: 'once for the choice, once for the answer about it');
      expect(controller.saleGate.storefrontMaySell, isTrue);
    });

    test(
        'choosing a storefront the server has not opened leaves the gate closed',
        () async {
      final preferences = await preferencesWith({});
      final service = _FakeStorefrontService(preferences)
        ..answer = <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.unitedArabEmirates,
        ];
      final controller = controllerOver(preferences, service, enabled: true);

      await controller.choose(StorefrontCountry.unitedArabEmirates);

      expect(controller.saleGate.storefrontMaySell, isFalse);
    });

    test(
        'choosing a storefront is still saved when the answer about it cannot be fetched',
        () async {
      final preferences = await preferencesWith({});
      final service = _FakeStorefrontService(preferences)
        ..throwOnRefresh = true;
      final controller = controllerOver(preferences, service, enabled: true);

      final saved = await controller.choose(StorefrontCountry.kuwait);

      expect(saved, isTrue);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
    });
  });
}
