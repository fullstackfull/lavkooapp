import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// The server's list, written where the app keeps the last answer, the way the real service does.
class _Server implements StorefrontServiceInterface {
  _Server({required this.preferences, required this.listed});

  final SharedPreferences preferences;
  final List<StorefrontCountry> listed;

  @override
  Future<bool> refreshStorefronts() =>
      StoredStorefronts(preferences).save(listed);
}

/// J-01 criterion 3: the storefront a customer is on is the one they chose or, when they chose none, the default one. Nothing derives it from
/// the customer's IP address, from the language or region of their device, or from their position. The device's place is asked for in two
/// files only, to put a pin on a map for an address.
///
/// The scan finds that by absence, in the sources: who imports the location packages, and whether any file that resolves, stores or reads
/// the storefront reads the device's locale, a position or an address on the network. The behaviour is the answer under three devices
/// (Arabic in the Emirates, English in Kuwait, French in France): it is always the same storefront. A read of `PlatformDispatcher.instance`
/// or of `Platform.localeName` is not changed by the test value of the locale, so only the scan sees those. The scan looks for the spellings
/// of such a read: one made through a variable that holds the dispatcher, in a file that is not of the storefront feature, is not one of them.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };

  /// The code of a source, without its comments: the lines that are one, the end of a line that has one, and the blocks. A `//` after a colon
  /// is the one of an address inside a string, and stays.
  String codeOf(String source) => source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .split('\n')
      .map((String line) => line.replaceFirst(RegExp(r'(?<!:)//.*'), ''))
      .join('\n');

  Set<String> importersOf(String package) {
    final RegExp importOfPackage =
        RegExp('''(?:import|export)\\s+['"]package:$package/''');

    return <String>{
      for (final MapEntry<String, String> source in sources.entries)
        if (importOfPackage.hasMatch(source.value)) source.key,
    };
  }

  Set<String> filesWithCode(String text) => <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (codeOf(source.value).contains(text)) source.key,
      };

  /// The first thing [pattern] finds in the code of each file of [paths], so a failure says where and what.
  Map<String, String> foundIn(Iterable<String> paths,
      {required RegExp pattern}) {
    final Map<String, String> found = <String, String>{};
    for (final String path in paths) {
      final RegExpMatch? match = pattern.firstMatch(codeOf(sources[path]!));
      if (match != null) {
        found[path] = match.group(0)!;
      }
    }

    return found;
  }

  final RegExp storefrontClass = RegExp(
      r'Storefront(?:Controller|Country|Config|Choice|Switcher|Scope|ChangeNotifier|ChangeAware)\b|storefront_chooser');

  /// The files that resolve, store or read the storefront: everything of the storefront feature, and every file that names one of its classes.
  final List<String> storefrontCode = <String>[
    for (final MapEntry<String, String> source in sources.entries)
      if (source.key.startsWith('lib/features/storefront/') ||
          storefrontClass.hasMatch(source.value))
        source.key,
  ];

  final List<String> storefrontFeature = <String>[
    for (final String path in sources.keys)
      if (path.startsWith('lib/features/storefront/')) path,
  ];

  group('the sources', () {
    test(
        'give the code that decides the storefront, and the code that reads it',
        () {
      expect(
          storefrontCode,
          containsAll(<String>[
            'lib/features/storefront/storefront_config.dart',
            'lib/features/storefront/storefront_choice.dart',
            'lib/data/datasource/remote/dio/dio_client.dart',
            'lib/features/cart/controllers/cart_controller.dart',
          ]));
      expect(storefrontFeature.length, greaterThan(15));
    });

    test(
        'reach the stored choice through StorefrontConfig, which reads it, and StorefrontChoice, which writes it',
        () {
      expect(filesWithCode('AppConstants.storefrontCountry'), <String>{
        'lib/features/storefront/storefront_config.dart',
        'lib/features/storefront/storefront_choice.dart',
      });
      expect(filesWithCode('StorefrontConfig.resolve('), <String>{
        'lib/features/storefront/storefront_choice.dart',
        'lib/data/datasource/remote/dio/dio_client.dart',
      });
    });
  });

  group('the place of the device', () {
    test('is asked for by two files, which put a pin on a map for an address',
        () {
      expect(importersOf('geolocator'), <String>{
        'lib/features/location/controllers/location_controller.dart',
        'lib/features/address/screens/add_new_address_screen.dart',
      });
      expect(importersOf('geocoding'), <String>{
        'lib/features/location/controllers/location_controller.dart',
      });
    });

    test(
        'is not read by any file that decides or reads the storefront, nor the locale of the device, nor an address on the network',
        () {
      final RegExp derivesFromTheDevice = RegExp(
          r'Platform\.localeName|\blocaleName\b|\bsystemLocales?\b|didChangeLocales'
          r'|(?:PlatformDispatcher\.instance|platformDispatcher|\bwindow)\s*\.\s*locales?\b'
          r'|Intl\.(?:systemLocale|getCurrentLocale|defaultLocale)|findSystemLocale'
          r'|package:geolocator/|package:geocoding/'
          r'|ipify|ip-api|ipapi|ipinfo|ipwho|ipgeolocation|geoip|geo-ip|ifconfig|checkip|whatismyip|ipstack|ipdata|freegeoip'
          r'|NetworkInterface|InternetAddress');

      expect(foundIn(storefrontCode, pattern: derivesFromTheDevice), isEmpty);
    });

    test(
        'is not read by the storefront feature itself in any way: no locale, no position, no address on the network',
        () {
      final RegExp anyUse = RegExp(
          r'Localizations\.localeOf|PlatformDispatcher|platformDispatcher|\bwindow\b'
          r'|geolocator|geocoding|Geolocator|placemarkFromCoordinates|LocationController|LocationService|LocationPermission'
          r'|\blatitude\b|\blongitude\b|\bLatLng\b|\bPosition\b|google_maps_flutter'
          r'|https?://|dart:io|package:http/|HttpClient');

      expect(foundIn(storefrontFeature, pattern: anyUse), isEmpty);
    });
  });

  group('the storefront the app resolves', () {
    const List<Locale> devices = <Locale>[
      Locale('ar', 'AE'),
      Locale('en', 'KW'),
      Locale('fr', 'FR'),
    ];

    Future<SharedPreferences> preferencesWith(
        Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);

      return SharedPreferences.getInstance();
    }

    StorefrontSwitcher switcherOver(SharedPreferences preferences,
            {required List<StorefrontCountry> listed}) =>
        StorefrontSwitcher(
          storefrontController: StorefrontController(
            storefrontServiceInterface:
                _Server(preferences: preferences, listed: listed),
            storefrontChoice: StorefrontChoice(preferences, enabled: true),
          ),
          applyHeaders: () {},
          changeNotifier: StorefrontChangeNotifier(
            clearHttpCache: (String code) {},
            clearLocalCache: (String code) async {},
            isSignedIn: () => false,
            enabled: true,
          ),
        );

    for (final Locale device in devices) {
      group('on a device set to ${device.toLanguageTag()}', () {
        void setDevice(WidgetTester tester) {
          tester.platformDispatcher.localeTestValue = device;
          tester.platformDispatcher.localesTestValue = <Locale>[device];
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(WidgetsBinding.instance.platformDispatcher.locale, device);
        }

        testWidgets(
            'is the default storefront while the customer has chosen none',
            (WidgetTester tester) async {
          setDevice(tester);
          final SharedPreferences preferences =
              await preferencesWith(<String, Object>{});

          expect(StorefrontConfig.resolve(preferences),
              StorefrontCountry.defaultCountry);
          expect(StorefrontChoice(preferences, enabled: true).current(),
              StorefrontCountry.defaultCountry);
        });

        testWidgets(
            'is the one the customer chose, whatever the device is set to',
            (WidgetTester tester) async {
          setDevice(tester);
          final SharedPreferences preferences = await preferencesWith(
              <String, Object>{AppConstants.storefrontCountry: 'QA'});

          expect(
              StorefrontConfig.resolve(preferences), StorefrontCountry.qatar);
          expect(StorefrontChoice(preferences, enabled: true).current(),
              StorefrontCountry.qatar);
        });

        testWidgets(
            'is kept while the server\'s list has it, and is the default one when the list does not',
            (WidgetTester tester) async {
          setDevice(tester);
          final List<StorefrontCountry> listed = <StorefrontCountry>[
            StorefrontCountry.saudiArabia,
            StorefrontCountry.unitedArabEmirates,
            StorefrontCountry.kuwait,
          ];

          final SharedPreferences unchosen =
              await preferencesWith(<String, Object>{});
          expect(
              await switcherOver(unchosen, listed: listed)
                  .followTheServersList(),
              StorefrontSwitch.unchanged);
          expect(StorefrontChoice(unchosen, enabled: true).current(),
              StorefrontCountry.defaultCountry);

          final SharedPreferences onKuwait = await preferencesWith(
              <String, Object>{AppConstants.storefrontCountry: 'KW'});
          expect(
              await switcherOver(onKuwait, listed: listed)
                  .followTheServersList(),
              StorefrontSwitch.unchanged);
          expect(StorefrontChoice(onKuwait, enabled: true).current(),
              StorefrontCountry.kuwait);

          final SharedPreferences onOman = await preferencesWith(
              <String, Object>{AppConstants.storefrontCountry: 'OM'});
          expect(
              await switcherOver(onOman, listed: listed).followTheServersList(),
              StorefrontSwitch.switched);
          expect(StorefrontChoice(onOman, enabled: true).current(),
              StorefrontCountry.defaultCountry);
        });

        testWidgets(
            'is the one the requests ask for, and only while storefronts are on',
            (WidgetTester tester) async {
          setDevice(tester);

          Future<DioClient> clientWith(Map<String, Object> values) async =>
              DioClient(
                'https://shop.test',
                Dio(),
                loggingInterceptor: LoggingInterceptor(),
                sharedPreferences: await preferencesWith(<String, Object>{
                  AppConstants.userLoginToken: 'token',
                  AppConstants.analyticsClientId: 'test-client-id',
                  ...values,
                }),
              );

          final DioClient unchosen = await clientWith(<String, Object>{});
          final DioClient chosen = await clientWith(
              <String, Object>{AppConstants.storefrontCountry: 'QA'});

          expect(unchosen.dio!.options.headers[AppConstants.storefrontHeader],
              StorefrontConfig.enabled ? 'SA' : isNull);
          expect(chosen.dio!.options.headers[AppConstants.storefrontHeader],
              StorefrontConfig.enabled ? 'QA' : isNull);
        });
      });
    }
  });
}
