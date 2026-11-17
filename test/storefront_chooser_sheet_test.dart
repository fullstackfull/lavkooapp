import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_chooser_sheet.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_settings_entry.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/theme/dark_theme.dart';
import 'package:syriapharmacy/theme/light_theme.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

Map<String, dynamic> _languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

String _words(String code, String key) => _languageFile(code)[key] as String;

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

/// What the server answers when it is asked for the storefronts, as the controller's service keeps it. The answer is written by hand from
/// the audit of the backend, whose storefront pull requests (#47 to #64) were not available when this was written, not recorded from a
/// real server.
class _Server implements StorefrontServiceInterface {
  _Server(this._preferences);

  final SharedPreferences _preferences;
  List<StorefrontCountry>? answer;
  int asked = 0;

  @override
  Future<bool> refreshStorefronts() async {
    asked++;
    final List<StorefrontCountry>? answered = answer;

    return answered == null
        ? false
        : StoredStorefronts(_preferences).save(answered);
  }
}

/// A switcher that says what it was asked and answers as scripted.
class _ScriptedSwitcher extends StorefrontSwitcher {
  _ScriptedSwitcher(this.log, StorefrontController controller)
      : super(
          storefrontController: controller,
          applyHeaders: () {},
          changeNotifier: StorefrontChangeNotifier(
            clearHttpCache: (String code) {},
            clearLocalCache: (String code) async {},
            isSignedIn: () => false,
            enabled: true,
          ),
        );

  final List<String> log;
  Future<StorefrontSwitch> Function() answer =
      () async => StorefrontSwitch.switched;

  @override
  Future<StorefrontSwitch> switchTo(StorefrontCountry storefront) {
    log.add('switch to ${storefront.code}');
    return answer();
  }
}

/// Says, in the log of the test, when a route is closed: here, the sheet.
class _ClosingObserver extends NavigatorObserver {
  _ClosingObserver(this.log);

  final List<String> log;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      log.add('sheet closed');
}

const StorefrontCountry _sellableKuwait = StorefrontCountry(
  code: 'KW',
  path: '/kw',
  currency: 'KWD',
  sellable: true,
);

const StorefrontCountry _unknownCountry = StorefrontCountry(
  code: 'XX',
  path: '/xx',
  currency: 'XXX',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late List<String> log;

  Future<StorefrontController> controllerWith({
    bool enabled = true,
    List<StorefrontCountry>? answered,
    String? chosen,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (chosen != null) AppConstants.storefrontCountry: chosen,
    });
    preferences = await SharedPreferences.getInstance();
    if (answered != null) {
      await StoredStorefronts(preferences).save(answered);
    }

    return StorefrontController(
      storefrontServiceInterface: _Server(preferences),
      storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
    );
  }

  setUp(() => log = <String>[]);

  /// Builds the app around [home], at the size and the text scale of the test, in the language of the test.
  Future<void> pumpApp(
    WidgetTester tester, {
    required StorefrontController controller,
    required Widget home,
    StorefrontSwitcher? switcher,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    bool dark = false,
    List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
  }) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorefrontController>.value(value: controller),
          ChangeNotifierProvider<ThemeController>.value(
              value: ThemeController(sharedPreferences: preferences)),
          Provider<StorefrontSwitcher>.value(
              value: switcher ?? _ScriptedSwitcher(log, controller)),
        ],
        child: MaterialApp(
          theme: dark ? _dark() : light(),
          locale: locale,
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          navigatorObservers: navigatorObservers,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            _FileLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Widget opener() => Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                context: context,
                builder: (_) =>
                    StorefrontChooserSheet(onSwitched: () => log.add('home')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required StorefrontController controller,
    StorefrontSwitcher? switcher,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    bool dark = false,
    List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
  }) async {
    await pumpApp(
      tester,
      controller: controller,
      home: opener(),
      switcher: switcher,
      locale: locale,
      textScale: textScale,
      dark: dark,
      navigatorObservers: navigatorObservers,
    );
    await openSheet(tester);
  }

  group('the language files', () {
    test('carry every word the chooser says, in all five languages', () {
      const List<String> keys = <String>[
        'choose_your_country',
        'select',
        'storefront_choose_hint',
        'storefront_orders_available',
        'storefront_browse_only_label',
        'storefront_switch_failed',
        'storefront_name_sa',
        'storefront_name_ae',
        'storefront_name_kw',
        'storefront_name_qa',
        'storefront_name_bh',
        'storefront_name_om',
      ];

      for (final String language in <String>['en', 'ar', 'bn', 'es', 'hi']) {
        for (final String key in keys) {
          final Object? value = _languageFile(language)[key];

          expect(value, isA<String>(), reason: '$language $key');
          expect((value! as String).trim(), isNotEmpty,
              reason: '$language $key');
        }
      }
    });

    test('name every country the app knows, under the key the sheet looks for',
        () {
      for (final StorefrontCountry country in StorefrontCountry.all) {
        final String? key = StorefrontChooserSheet.nameKeys[country.code];

        expect(key, isNotNull, reason: country.code);
        expect(_languageFile('en')[key], isNotEmpty, reason: country.code);
      }
    });
  });

  group('the settings entry', () {
    Future<void> pumpEntry(
      WidgetTester tester,
      StorefrontController controller,
    ) =>
        pumpApp(
          tester,
          controller: controller,
          home: const Scaffold(
            body: Column(children: [StorefrontSettingsEntry()]),
          ),
        );

    final Finder entry = find.text('Choose your country');

    testWidgets(
        'is not there while storefronts are off, whatever the server listed',
        (tester) async {
      final StorefrontController controller = await controllerWith(
        enabled: false,
        answered: StorefrontCountry.all,
      );

      await pumpEntry(tester, controller);

      expect(entry, findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('is not there before the server has answered', (tester) async {
      await pumpEntry(tester, await controllerWith());

      expect(entry, findsNothing);
    });

    testWidgets('is not there when the server lists one storefront',
        (tester) async {
      await pumpEntry(
        tester,
        await controllerWith(
            answered: <StorefrontCountry>[StorefrontCountry.saudiArabia]),
      );

      expect(entry, findsNothing);
    });

    testWidgets('is there when the server lists two', (tester) async {
      await pumpEntry(
        tester,
        await controllerWith(answered: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.unitedArabEmirates,
        ]),
      );

      expect(entry, findsOneWidget);
    });

    testWidgets(
        'appears when the server\'s answer arrives after the settings were opened',
        (tester) async {
      final StorefrontController controller = await controllerWith();
      await pumpEntry(tester, controller);
      expect(entry, findsNothing);

      (controller.storefrontServiceInterface as _Server).answer =
          StorefrontCountry.all;
      await controller.refresh();
      await tester.pump();

      expect(entry, findsOneWidget);
    });

    testWidgets('opens the chooser', (tester) async {
      await pumpEntry(
        tester,
        await controllerWith(answered: StorefrontCountry.all),
      );

      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.byType(StorefrontChooserSheet), findsOneWidget);
    });

    testWidgets('says it in Arabic', (tester) async {
      final StorefrontController controller =
          await controllerWith(answered: StorefrontCountry.all);
      await pumpApp(
        tester,
        controller: controller,
        locale: const Locale('ar'),
        home: const Scaffold(
          body: Column(children: [StorefrontSettingsEntry()]),
        ),
      );

      expect(find.text(_words('ar', 'choose_your_country')), findsOneWidget);
    });
  });

  group('the sheet', () {
    final List<StorefrontCountry> served = <StorefrontCountry>[
      StorefrontCountry.saudiArabia,
      StorefrontCountry.unitedArabEmirates,
      _sellableKuwait,
    ];

    testWidgets('lists every storefront the server listed, by name',
        (tester) async {
      await pumpSheet(tester,
          controller: await controllerWith(answered: served));

      expect(find.text('Saudi Arabia'), findsOneWidget);
      expect(find.text('United Arab Emirates'), findsOneWidget);
      expect(find.text('Kuwait'), findsOneWidget);
      expect(find.text('Qatar'), findsNothing);
    });

    testWidgets(
        'says plainly which ones take orders and which are for browsing only',
        (tester) async {
      await pumpSheet(tester,
          controller: await controllerWith(answered: served));

      expect(find.text(_words('en', 'storefront_orders_available')),
          findsNWidgets(2));
      expect(find.text(_words('en', 'storefront_browse_only_label')),
          findsOneWidget);
      expect(
        tester.getTopLeft(find.text('United Arab Emirates')).dy,
        lessThan(tester
            .getTopLeft(find.text(_words('en', 'storefront_browse_only_label')))
            .dy),
        reason: 'the wording sits under the storefront it is about',
      );
    });

    testWidgets('says it in Arabic, in words, not as keys', (tester) async {
      await pumpSheet(
        tester,
        controller: await controllerWith(answered: served),
        locale: const Locale('ar'),
      );

      expect(find.text(_words('ar', 'storefront_name_sa')), findsOneWidget);
      expect(find.text(_words('ar', 'storefront_name_ae')), findsOneWidget);
      expect(find.text(_words('ar', 'storefront_browse_only_label')),
          findsOneWidget);
      expect(find.text(_words('ar', 'storefront_orders_available')),
          findsNWidgets(2));
      expect(find.text(_words('ar', 'storefront_choose_hint')), findsOneWidget);
      expect(find.textContaining('storefront_'), findsNothing);
    });

    testWidgets('shows a country the app has no name for by its code',
        (tester) async {
      await pumpSheet(
        tester,
        controller: await controllerWith(answered: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          _unknownCountry,
        ]),
      );

      expect(find.text('XX'), findsOneWidget);
      expect(find.text(_words('en', 'storefront_browse_only_label')),
          findsOneWidget);
    });

    testWidgets(
        'marks the storefront the customer is on, with more than a tint',
        (tester) async {
      await pumpSheet(
        tester,
        controller: await controllerWith(answered: served, chosen: 'AE'),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
      final double checkY =
          tester.getCenter(find.byIcon(Icons.check_circle)).dy;
      expect(
        (checkY - tester.getCenter(find.text('United Arab Emirates')).dy).abs(),
        lessThan(40),
        reason: 'the mark is on the row of the storefront the customer is on',
      );
    });

    testWidgets('marks the Saudi storefront before anything was chosen',
        (tester) async {
      await pumpSheet(tester,
          controller: await controllerWith(answered: served));

      final double checkY =
          tester.getCenter(find.byIcon(Icons.check_circle)).dy;
      expect((checkY - tester.getCenter(find.text('Saudi Arabia')).dy).abs(),
          lessThan(40));
    });

    testWidgets('does nothing until the customer presses the button',
        (tester) async {
      await pumpSheet(tester,
          controller: await controllerWith(answered: served));

      await tester.tap(find.text('Kuwait'));
      await tester.pump();

      expect(log, isEmpty);
      expect(find.byType(StorefrontChooserSheet), findsOneWidget);
    });

    testWidgets('moves the mark to the row that is tapped', (tester) async {
      await pumpSheet(tester,
          controller: await controllerWith(answered: served));

      await tester.tap(find.text('Kuwait'));
      await tester.pump();

      final double checkY =
          tester.getCenter(find.byIcon(Icons.check_circle)).dy;
      expect((checkY - tester.getCenter(find.text('Kuwait')).dy).abs(),
          lessThan(40));
    });

    testWidgets(
        'switches to the storefront that was chosen, closes, and then goes home',
        (tester) async {
      await pumpSheet(
        tester,
        controller: await controllerWith(answered: served),
        navigatorObservers: <NavigatorObserver>[_ClosingObserver(log)],
      );

      await tester.tap(find.text('Kuwait'));
      await tester.pump();
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(log, <String>['switch to KW', 'sheet closed', 'home']);
      expect(find.byType(StorefrontChooserSheet), findsNothing);
    });

    testWidgets(
        'closes without going anywhere when the storefront chosen is the one the customer is on',
        (tester) async {
      final StorefrontController controller =
          await controllerWith(answered: served);
      await pumpSheet(
        tester,
        controller: controller,
        switcher: _ScriptedSwitcher(log, controller)
          ..answer = () async => StorefrontSwitch.unchanged,
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(log, <String>['switch to SA']);
      expect(find.byType(StorefrontChooserSheet), findsNothing);
    });

    testWidgets(
        'stays open, says so, and can be tried again when the choice could not be made',
        (tester) async {
      final StorefrontController controller =
          await controllerWith(answered: served);
      await pumpSheet(
        tester,
        controller: controller,
        switcher: _ScriptedSwitcher(log, controller)
          ..answer = () async => StorefrontSwitch.failed,
      );

      await tester.tap(find.text('Kuwait'));
      await tester.pump();
      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
          find.text(_words('en', 'storefront_switch_failed')), findsOneWidget);
      expect(find.byType(StorefrontChooserSheet), findsOneWidget);
      expect(log, <String>['switch to KW']);

      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(log, <String>['switch to KW', 'switch to KW']);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets(
        'shows that it is working, and ignores taps, while the switch runs',
        (tester) async {
      final StorefrontController controller =
          await controllerWith(answered: served);
      final Completer<StorefrontSwitch> working = Completer<StorefrontSwitch>();
      await pumpSheet(
        tester,
        controller: controller,
        switcher: _ScriptedSwitcher(log, controller)
          ..answer = () => working.future,
      );
      addTearDown(() {
        if (!working.isCompleted) working.complete(StorefrontSwitch.unchanged);
      });

      await tester.tap(find.text('Kuwait'));
      await tester.pump();
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(find.text(_words('en', 'loading')), findsOneWidget);

      await tester.tap(find.text('United Arab Emirates'));
      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(log, <String>['switch to KW']);
      final double checkY =
          tester.getCenter(find.byIcon(Icons.check_circle)).dy;
      expect((checkY - tester.getCenter(find.text('Kuwait')).dy).abs(),
          lessThan(40),
          reason: 'the mark stays on the storefront being switched to');

      working.complete(StorefrontSwitch.switched);
      await tester.pumpAndSettle();
      expect(log, <String>['switch to KW', 'home']);
    });
  });

  group('the switch the sheet makes', () {
    testWidgets(
        'saves the choice and asks the server, rebuilds the headers, tells the listeners, and only then goes home',
        (tester) async {
      final StorefrontController controller = await controllerWith(
        answered: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.unitedArabEmirates,
        ],
      );
      final StorefrontSwitcher switcher = StorefrontSwitcher(
        storefrontController: controller,
        applyHeaders: () => log.add(
            'headers rebuilt, choice then ${preferences.getString(AppConstants.storefrontCountry)}'),
        changeNotifier: _OrderedNotifier(log),
      );
      controller.addListener(() => log.add('screens told of the choice'));

      await pumpSheet(tester, controller: controller, switcher: switcher);
      await tester.tap(find.text('United Arab Emirates'));
      await tester.pump();
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(log, <String>[
        'screens told of the choice',
        'headers rebuilt, choice then AE',
        'listeners told SA -> AE',
        'home',
      ]);
      expect(controller.current.code, 'AE');
    });
  });

  group('the layout', () {
    final List<StorefrontCountry> all = <StorefrontCountry>[
      ...StorefrontCountry.all,
      _unknownCountry,
    ];

    for (final Locale locale in const <Locale>[Locale('en'), Locale('ar')]) {
      for (final bool dark in <bool>[false, true]) {
        testWidgets(
            'holds at 320 by 640 at twice the text size in ${locale.languageCode}${dark ? ', dark' : ''}',
            (tester) async {
          await pumpSheet(
            tester,
            controller: await controllerWith(answered: all),
            locale: locale,
            textScale: 2.0,
            dark: dark,
          );

          expect(tester.takeException(), isNull);
          final Rect sheet =
              tester.getRect(find.byType(StorefrontChooserSheet));
          expect(sheet.width, 320.0);
          expect(sheet.bottom, lessThanOrEqualTo(640.0));
          expect(tester.getRect(find.byType(CustomButton)).bottom,
              lessThanOrEqualTo(640.0));
          expect(tester.getRect(find.byType(CustomButton)).left,
              greaterThanOrEqualTo(0.0));
        });
      }
    }

    testWidgets('scrolls to the storefronts that do not fit', (tester) async {
      await pumpSheet(
        tester,
        controller: await controllerWith(answered: all),
        textScale: 2.0,
      );
      expect(find.text('XX'), findsNothing,
          reason: 'there is no room for the last one on the screen');

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('XX'), findsOneWidget);
      expect(tester.getRect(find.text('XX')).bottom, lessThanOrEqualTo(640.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('puts the mark at the end of the row, in either direction',
        (tester) async {
      final StorefrontController controller =
          await controllerWith(answered: all);

      await pumpSheet(tester, controller: controller);
      final double markInEnglish =
          tester.getCenter(find.byIcon(Icons.check_circle)).dx;
      final double nameInEnglish =
          tester.getCenter(find.text('Saudi Arabia')).dx;
      expect(markInEnglish, greaterThan(nameInEnglish));

      await tester.pumpWidget(const SizedBox());
      await pumpSheet(tester,
          controller: controller, locale: const Locale('ar'));
      final double markInArabic =
          tester.getCenter(find.byIcon(Icons.check_circle)).dx;
      final double nameInArabic =
          tester.getCenter(find.text(_words('ar', 'storefront_name_sa'))).dx;
      expect(markInArabic, lessThan(nameInArabic));
    });

    testWidgets('keeps the same width in both directions', (tester) async {
      final StorefrontController controller =
          await controllerWith(answered: all);

      await pumpSheet(tester, controller: controller);
      final double english =
          tester.getSize(find.byType(StorefrontChooserSheet)).width;
      await tester.pumpWidget(const SizedBox());
      await pumpSheet(tester,
          controller: controller, locale: const Locale('ar'));

      expect(
          tester.getSize(find.byType(StorefrontChooserSheet)).width, english);
    });
  });
}

ThemeData _dark() => dark();

/// A notifier that only writes into the log of the test when it is told, as the real one would tell the controllers.
class _OrderedNotifier extends StorefrontChangeNotifier {
  _OrderedNotifier(this._log)
      : super(
          clearHttpCache: (String code) {},
          clearLocalCache: (String code) async {},
          isSignedIn: () => false,
          enabled: true,
        );

  final List<String> _log;

  @override
  Future<void> storefrontChanged({
    required StorefrontCountry previous,
    required StorefrontCountry current,
  }) async {
    _log.add('listeners told ${previous.code} -> ${current.code}');
  }
}
