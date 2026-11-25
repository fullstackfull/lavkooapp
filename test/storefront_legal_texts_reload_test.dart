import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/services/splash_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';

const StorefrontChange _toEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: false,
);

String get _who => StorefrontScope.current ?? 'none';

/// The pages an answer carries say which storefront they were asked for, so a stale list is visible as the wrong market's terms.
class _FakeSplashService implements SplashServiceInterface {
  int pagesAsked = 0;
  final List<String> types = <String>[];

  @override
  Future<dynamic> getBusinessPages(String type) async {
    pagesAsked++;
    types.add(type);

    return ApiResponseModel.withSuccess(Response<dynamic>(
      requestOptions: RequestOptions(path: '/business-pages'),
      statusCode: 200,
      data: <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'page_name': 'terms', 'title': 'Terms of $_who', 'content': 'the terms of $_who'},
      ],
    ));
  }

  @override
  Future<dynamic> getConfig() async => throw UnimplementedError('the config needs a screen, and these tests have none');

  @override
  String getCurrency() => 'SAR';

  @override
  void setCurrency(String currencyCode) {}

  @override
  void initSharedData() {}

  @override
  void disableIntro() {}

  @override
  bool? showIntro() => false;
}

/// J-15: the legal texts a customer reads are the ones of the market they are on.
///
/// The server has served each storefront its own published pages for a while -- the terms, the privacy policy, the refund and the shipping
/// policy go through `StorefrontLegalPages::listShownInStorefront` before `/api/v1/business-pages` answers. The app loaded them ONCE, from
/// the dashboard, and a change of market re-asked only the shop's config, so a customer who moved from Riyadh to Dubai went on reading the
/// Saudi terms. A legal text is the one thing in the app that must never be the wrong market's.
void main() {
  // The controller's constructor reads a preference (`loadPricingMode`) and `onStorefrontChanged` asks `Get.context`, which is a
  // GlobalKey's context: both reach a Flutter binding, so the binding has to exist before either runs. Without this the whole file fails
  // with "Binding has not yet been initialized", which is what the first CI run of it said.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSplashService service;
  late SplashController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    StorefrontScope.publish('SA');
    service = _FakeSplashService();
    controller = SplashController(splashServiceInterface: service);
    // The constructor starts a preference read; let it finish before the test, so it cannot land after the controller is disposed.
    await pumpEventQueue();
  });

  tearDown(() {
    controller.dispose();
    StorefrontScope.publish(null);
  });

  test('are the market\'s own when they are asked for', () async {
    await controller.getBusinessPagesList('default');

    expect(controller.defaultBusinessPages?.single.title, 'Terms of SA');
  });

  test('are dropped at once on a change of market, before anything answers', () async {
    await controller.getBusinessPagesList('default');
    await controller.getBusinessPagesList('pages');
    StorefrontScope.publish('AE');

    final Future<void> told = controller.onStorefrontChanged(_toEmirates);

    expect(controller.defaultBusinessPages, isNull, reason: 'a policy of the market the customer left must not be on screen');
    expect(controller.businessPages, isNull);

    await told;
  });

  test('are asked for again and are the new market\'s once they have loaded', () async {
    await controller.getBusinessPagesList('default');
    await controller.getBusinessPagesList('pages');
    service.pagesAsked = 0;
    service.types.clear();
    StorefrontScope.publish('AE');

    await controller.onStorefrontChanged(_toEmirates);

    expect(service.pagesAsked, 2);
    expect(service.types, containsAll(<String>['default', 'pages']), reason: 'both lists, as the dashboard asks for them');
    expect(controller.defaultBusinessPages?.single.title, 'Terms of AE');
    expect(controller.businessPages?.single.title, 'Terms of AE');
  });

  test('that were never asked for are not asked for by a change of market', () async {
    StorefrontScope.publish('AE');

    await controller.onStorefrontChanged(_toEmirates);

    expect(service.pagesAsked, 0, reason: 'a change of market reloads what was read, and nothing else');
    expect(controller.defaultBusinessPages, isNull);
  });

  /// The config is NOT dropped and is not asked for without a screen: the app cannot run without one, so it is replaced and never emptied.
  test('the shop config is left alone when the app has no screen to read it with', () async {
    await controller.getBusinessPagesList('default');

    await controller.onStorefrontChanged(_toEmirates);

    expect(controller.configModel, isNull, reason: 'getConfig would have thrown, and nothing asked for it');
  });
}
