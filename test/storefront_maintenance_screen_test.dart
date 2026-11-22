import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_maintenance_screen.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

Map<String, dynamic> _languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

String _words(String code, String key) => _languageFile(code)[key] as String;

/// The app's translations, read straight from the language files and handed over at once, so the screen is built with the real words.
class _FileLocalization extends AppLocalization {
  _FileLocalization(super.locale)
      : _values = _languageFile(locale.languageCode);

  final Map<String, dynamic> _values;

  @override
  String? translate(String? key) => _values[key] as String?;
}

class _FileLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _FileLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalization> load(Locale locale) =>
      SynchronousFuture<AppLocalization>(_FileLocalization(locale));

  @override
  bool shouldReload(_FileLocalizationsDelegate old) => false;
}

/// A server that answers each question with the list it was given, the way the real one replaces the stored list, and counts the questions.
class _Server implements StorefrontServiceInterface {
  _Server(this._preferences);

  final SharedPreferences _preferences;
  List<Map<String, Object>>? answer;
  int asked = 0;

  @override
  Future<bool> refreshStorefronts() async {
    asked++;
    final List<Map<String, Object>>? next = answer;
    if (next == null) {
      return false;
    }

    return _preferences.setString(
        AppConstants.storefrontList, jsonEncode(<String, Object>{'storefronts': next}));
  }
}

Map<String, Object> _entry(String code,
        {String? mode, String? message, String? until}) =>
    <String, Object>{
      'country': code,
      'path': code.toLowerCase(),
      'currency': code == 'KW' ? 'KWD' : 'SAR',
      'sellable': mode == null,
      if (mode != null) 'stop_mode': mode,
      if (message != null) 'stop_message': message,
      if (until != null) 'stop_until': until,
    };

Future<({StorefrontController controller, _Server server})> _controllerOn(
  String code, {
  required List<Map<String, Object>>? stored,
  bool enabled = true,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    AppConstants.storefrontCountry: code,
    if (stored != null)
      AppConstants.storefrontList:
          jsonEncode(<String, Object>{'storefronts': stored}),
  });
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final _Server server = _Server(preferences);

  return (
    controller: StorefrontController(
      storefrontServiceInterface: server,
      storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
    ),
    server: server,
  );
}

/// J-08: a storefront the server has put in maintenance. The controller says so from the server's own entry for the storefront the customer is on and from no other,
/// and the screen the dashboard shows instead of its content says what the server told the customers, when it expects the stop to end, lets the customer ask again,
/// and offers another storefront only when the shop has one.
void main() {
  group('the controller', () {
    test('says a storefront is in maintenance when the server says so', () async {
      final r = await _controllerOn('KW', stored: [
        _entry('SA'),
        _entry('KW', mode: 'maintenance', message: 'Back on Sunday.', until: '2026-12-01 08:00'),
      ]);

      expect(r.controller.inMaintenance, isTrue);
      expect(r.controller.currentEntry?.stopMessage, 'Back on Sunday.');
      expect(r.controller.currentEntry?.stopUntil, '2026-12-01 08:00');
    });

    test('says no for every other stop, and for a storefront that is not stopped',
        () async {
      for (final String? mode in <String?>[null, 'browse_only', 'redirect']) {
        final r = await _controllerOn('KW', stored: [_entry('SA'), _entry('KW', mode: mode)]);

        expect(r.controller.inMaintenance, isFalse, reason: '$mode');
      }
    });

    test('is not moved by the maintenance of another storefront', () async {
      final r = await _controllerOn('SA', stored: [
        _entry('SA'),
        _entry('KW', mode: 'maintenance'),
      ]);

      expect(r.controller.inMaintenance, isFalse);
    });

    test('says no when the server does not list the storefront or has not answered', () async {
      final unlisted = await _controllerOn('KW', stored: [_entry('SA')]);
      final unanswered = await _controllerOn('KW', stored: null);

      expect(unlisted.controller.inMaintenance, isFalse);
      expect(unlisted.controller.currentEntry, isNull);
      expect(unanswered.controller.inMaintenance, isFalse);
    });

    test('says no while storefronts are off, whatever an old stored answer says', () async {
      final r = await _controllerOn('KW',
          stored: [_entry('SA'), _entry('KW', mode: 'maintenance')], enabled: false);

      expect(r.controller.inMaintenance, isFalse);
      expect(r.controller.currentEntry, isNull);
    });
  });

  group('the screen', () {
    Future<void> pump(
      WidgetTester tester,
      StorefrontController controller, {
      Locale locale = const Locale('en'),
      double width = 390,
      double textScale = 1.0,
    }) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<StorefrontController>.value(
          value: controller,
          child: MaterialApp(
            locale: locale,
            supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              _FileLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const StorefrontMaintenanceScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('says what the server told the customers and when it expects the stop to end', (tester) async {
      final r = await _controllerOn('KW', stored: [
        _entry('SA'),
        _entry('KW', mode: 'maintenance', message: 'We are back on Sunday, with our thanks.', until: '2026-12-01 08:00'),
      ]);

      await pump(tester, r.controller);

      expect(find.text(_words('en', 'storefront_maintenance_title')), findsOneWidget);
      expect(find.text('We are back on Sunday, with our thanks.'), findsOneWidget);
      expect(find.text('${_words('en', 'storefront_maintenance_expected_back')}: 2026-12-01 08:00 UTC'), findsOneWidget);
      expect(find.text(_words('en', 'try_again')), findsOneWidget);
    });

    testWidgets('says its own words when the server sent no message, and no end when it gave none', (tester) async {
      final r = await _controllerOn('KW', stored: [_entry('SA'), _entry('KW', mode: 'maintenance')]);

      await pump(tester, r.controller);

      expect(find.text(_words('en', 'storefront_maintenance_body')), findsOneWidget);
      expect(find.textContaining(_words('en', 'storefront_maintenance_expected_back')), findsNothing);
    });

    testWidgets('offers another country only when the shop lists more than one', (tester) async {
      final two = await _controllerOn('KW', stored: [_entry('SA'), _entry('KW', mode: 'maintenance')]);
      await pump(tester, two.controller);
      expect(find.text(_words('en', 'choose_your_country')), findsOneWidget);

      final one = await _controllerOn('KW', stored: [_entry('KW', mode: 'maintenance')]);
      await pump(tester, one.controller);
      expect(find.text(_words('en', 'choose_your_country')), findsNothing);
    });

    testWidgets('asks the server again, and what the answer says is what the controller says', (tester) async {
      final r = await _controllerOn('KW', stored: [_entry('SA'), _entry('KW', mode: 'maintenance')]);
      r.server.answer = [_entry('SA'), _entry('KW')];
      await pump(tester, r.controller);

      await tester.tap(find.text(_words('en', 'try_again')));
      await tester.pump();
      await tester.pump();

      expect(r.server.asked, 1);
      expect(r.controller.inMaintenance, isFalse, reason: 'the newer answer says the storefront is open: the dashboard shows what it always showed');
    });

    testWidgets('reads in Arabic, right to left, on a narrow screen at a large text size', (tester) async {
      final r = await _controllerOn('KW', stored: [
        _entry('SA'),
        _entry('KW', mode: 'maintenance', until: '2026-12-01 08:00'),
      ]);

      await pump(tester, r.controller, locale: const Locale('ar'), width: 320, textScale: 2.0);

      expect(find.text(_words('ar', 'storefront_maintenance_title')), findsOneWidget);
      expect(find.text(_words('ar', 'storefront_maintenance_body')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(Directionality.of(tester.element(find.byType(StorefrontMaintenanceScreen))), TextDirection.rtl);
    });
  });

  group('the language files', () {
    test('all five carry the three strings, in words', () {
      for (final String code in <String>['en', 'ar', 'bn', 'es', 'hi']) {
        for (final String key in <String>[
          'storefront_maintenance_title',
          'storefront_maintenance_body',
          'storefront_maintenance_expected_back',
        ]) {
          final Object? text = _languageFile(code)[key];

          expect(text, isA<String>(), reason: '$code $key');
          expect((text! as String).trim(), isNot(key), reason: '$code $key');
          expect((text as String).length, greaterThan(5), reason: '$code $key');
        }
      }
    });
  });
}
