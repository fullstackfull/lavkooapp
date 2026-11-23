import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/main.dart' show navigatorKey;
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/theme/light_theme.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// What the app's own screens need above them to be built in a test: the real translations, the shop's config, the storefront the
/// customer is on and the app's global navigator key, which is the context the screens and the controllers reach each other by.
///
/// Nothing here stands in for a screen or a widget. The screens built on top of it are the app's own, and what they draw is read from
/// the tree they build.

Map<String, dynamic> languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

/// A word of the app, as the language files hold it.
String words(String code, String key) => languageFile(code)[key] as String;

class _FileLocalization extends AppLocalization {
  _FileLocalization(super.locale)
      : _values = languageFile(locale.languageCode);

  final Map<String, dynamic> _values;

  @override
  String? translate(String? key) => _values[key] as String?;
}

class FileLocalizationsDelegate extends LocalizationsDelegate<AppLocalization> {
  const FileLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalization> load(Locale locale) =>
      SynchronousFuture<AppLocalization>(_FileLocalization(locale));

  @override
  bool shouldReload(FileLocalizationsDelegate old) => false;
}

const List<LocalizationsDelegate<dynamic>> appLocalizations =
    <LocalizationsDelegate<dynamic>>[
  FileLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class NoStorefrontServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

/// A server answer, as the repository layer hands one to a controller.
ApiResponseModel<Response<dynamic>> answered(Object? data) =>
    ApiResponseModel<Response<dynamic>>.withSuccess(Response<dynamic>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
        data: data));

/// What a service that is not asked for anything in particular answers, so a controller a screen starts does not have to be stubbed
/// method by method. A member a screen really needs is overridden in the test that needs it.
Future<dynamic> answeredWithNothing() =>
    Future<dynamic>.value(answered(const <dynamic>[]));

/// The shop's config as a device has it once the config has arrived: the currency list, the mark's side and the shipping method.
ConfigModel shopConfig({
  String shippingMethod = 'inhouse_shipping',
  int billingInputByCustomer = 0,
  int systemTaxIncludeStatus = 0,
}) =>
    ConfigModel(
      currencySymbolPosition: 'left',
      shippingMethod: shippingMethod,
      billingInputByCustomer: billingInputByCustomer,
      systemTaxIncludeStatus: systemTaxIncludeStatus,
      currencyList: <CurrencyList>[
        CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75),
        CurrencyList(id: 2, code: 'KWD', symbol: 'KD', exchangeRate: 0.307),
        CurrencyList(id: 3, code: 'AED', symbol: 'AED', exchangeRate: 3.67),
      ],
    );

/// The currency the customer chose in the settings and the one the platform converts through. The platform writes an amount at the rate
/// of the first over the rate of the second, with no decimals: 10.00 is "SR38" and 20.00 is "SR75".
final CurrencyList saudiRiyal =
    CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75);

final CurrencyList usDollar =
    CurrencyList(id: 9, code: 'USD', symbol: '\$', exchangeRate: 1);

class SplashWithConfig extends SplashController {
  SplashWithConfig(this._config) : super(splashServiceInterface: null);

  final ConfigModel _config;

  @override
  ConfigModel? get configModel => _config;

  @override
  CurrencyList? get myCurrency => saudiRiyal;

  @override
  CurrencyList? get usdCurrency => usDollar;

  @override
  Future<void> refreshPaymentMethods() async {}
}

/// A screen of a phone, wide enough that the lines of the cart's cards are not clipped by the test's own window.
const Size phoneScreen = Size(600, 1600);

/// Everything a screen is built on: the storefront the customer is on, the list the server last answered with, and the providers the
/// screen reads. [storefrontsEnabled] is what the storefront choice is told, so the gate of a screen can be read in a build with
/// storefronts off as well as on; leave it out to use the build's own flag, which is what proves the screens are dormant.
class ScreenHarness {
  ScreenHarness._(this.preferences, this.storefronts, this.splash);

  final SharedPreferences preferences;
  final StorefrontController storefronts;
  final SplashWithConfig splash;

  static Future<ScreenHarness> open(
    WidgetTester tester, {
    required Widget screen,
    String? customerOn,
    List<StorefrontCountry>? listed,
    bool? storefrontsEnabled,
    ConfigModel? config,
    Locale locale = const Locale('en'),
    Size screenSize = phoneScreen,
    List<SingleChildWidget> providers = const <SingleChildWidget>[],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (customerOn != null) AppConstants.storefrontCountry: customerOn,
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (listed != null) {
      await StoredStorefronts(preferences).save(listed);
    }

    final StorefrontController storefronts = StorefrontController(
      storefrontServiceInterface: NoStorefrontServer(),
      storefrontChoice: StorefrontChoice(preferences,
          enabled: storefrontsEnabled ?? StorefrontConfig.enabled),
    );
    final SplashWithConfig splash = SplashWithConfig(config ?? shopConfig());

    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = screenSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<StorefrontController>.value(value: storefronts),
        ChangeNotifierProvider<SplashController>.value(value: splash),
        ChangeNotifierProvider<ThemeController>.value(
            value: ThemeController(sharedPreferences: preferences)),
        ...providers,
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: light(),
        locale: locale,
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        localizationsDelegates: appLocalizations,
        home: screen,
      ),
    ));

    // Fixed pumps, never pumpAndSettle: the cards of these screens fade and slide in forever by design, and a settle would hang.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    return ScreenHarness._(preferences, storefronts, splash);
  }

  /// The words the screen was built with, for a key of the language files.
  String word(String key) => words('en', key);
}
