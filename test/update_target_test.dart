import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/update/screen/update_screen.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/update_target.dart';

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

/// The shop's config as a device has it once it has arrived, or the nothing a device has while it has not.
class _SplashWithConfig extends SplashController {
  _SplashWithConfig(this._config) : super(splashServiceInterface: null);

  final ConfigModel? _config;

  @override
  ConfigModel? get configModel => _config;
}

/// The device's launcher, answering through the channel the plugin really uses: which addresses it was asked about, which it says it can
/// open, and which it was told to open.
class _Launcher {
  _Launcher({required this.canOpen});

  static const MethodChannel channel =
      MethodChannel('plugins.flutter.io/url_launcher');

  final bool Function(String address) canOpen;
  final List<String> asked = <String>[];
  final List<String> opened = <String>[];

  Future<Object?> answer(MethodCall call) async {
    final String address =
        (call.arguments as Map<Object?, Object?>)['url'] as String;

    switch (call.method) {
      case 'canLaunch':
        asked.add(address);
        return canOpen(address);
      case 'launch':
        opened.add(address);
        return true;
      default:
        return null;
    }
  }
}

ForAndroid _row(String? link) =>
    ForAndroid(status: 1, version: '14.1', link: link);

/// What /api/v1/config publishes for the live shop: the floor of 14.1 with the switch on and an empty link, for both platforms.
UserAppVersionControl _liveControl() => UserAppVersionControl(
      forAndroid: _row(''),
      forIos: _row(''),
    );

List<String> _candidatesFor(String? link, {bool isIos = false}) =>
    UpdateTarget.candidates(
      control: UserAppVersionControl(
        forAndroid: isIos ? null : _row(link),
        forIos: isIos ? _row(link) : null,
      ),
      isIos: isIos,
    );

bool _anythingOpens(String address) => true;

const String _playStorePage =
    'https://play.google.com/store/apps/details?id=com.lavkoo.app';
const String _appStoreSearch = 'https://apps.apple.com/search?term=LAVKOO';

/// The one line of a Gradle, Kotlin or plist file that carries the id, as the file writes it.
String _fileValue(String path, RegExp pattern) {
  final RegExpMatch? found =
      pattern.firstMatch(File(path).readAsStringSync());

  return found == null ? 'no match in $path' : found.group(1)!;
}

/// J-17 criterion 4: the update screen offers a target that works even when the shop configures no link — which is the live state, not a
/// hypothetical: the shop publishes a floor of 14.1 with `link: ""` for both platforms, and the screen used to hand that empty string to the
/// launcher, which refuses it, and to dereference a missing one.
///
/// The decision is pinned on the helper it was extracted into, for both platforms and for every shape of link the shop can publish, the way
/// test/update_gate_test.dart pins the rule that puts the customer on this screen in the first place. The screen itself is then run, with the
/// device's launcher answering through the plugin's own channel, so what is pinned is what the button does and not only what the helper
/// returns.
///
/// What this does not cover: the screen was run on the test host, where `Platform.isIOS` is false, so the button is only ever seen taking the
/// Android road; the iOS road is pinned on the helper alone. Whether the two addresses answer is Google's and Apple's business and is not
/// asked here. That the Android id in the Dart sources is the id the Android build really carries is read from build.gradle.kts and the
/// manifest; `PRODUCT_BUNDLE_IDENTIFIER` in ios/Runner.xcodeproj/project.pbxproj says `com.ksacosmetics.app`, which is neither read nor
/// changed here.
///
///   flutter test test/update_target_test.dart
void main() {
  group('the target the update screen offers', () {
    test('is the link the shop configured, exactly as it was given', () {
      for (final String link in <String>[
        'https://play.google.com/store/apps/details?id=com.example.other',
        'https://lavkoo.com/app',
        'market://details?id=com.lavkoo.app',
        '  https://lavkoo.com/app  ',
      ]) {
        expect(_candidatesFor(link).first, link, reason: 'link "$link"');
      }
    });

    test('is the store page when the shop configures an empty link', () {
      expect(_candidatesFor(''), <String>[_playStorePage]);
      expect(_candidatesFor('', isIos: true), <String>[_appStoreSearch]);
    });

    test('is the store page when the shop configures only blank space', () {
      for (final String link in <String>[' ', '   ', '\n', '\t ']) {
        expect(_candidatesFor(link), <String>[_playStorePage],
            reason: 'link "$link"');
        expect(_candidatesFor(link, isIos: true), <String>[_appStoreSearch],
            reason: 'link "$link" on iOS');
      }
    });

    test('is the store page when the shop configures no link at all', () {
      expect(_candidatesFor(null), <String>[_playStorePage]);
      expect(_candidatesFor(null, isIos: true), <String>[_appStoreSearch]);
    });

    test('is the store page when the shop sends no row for the platform', () {
      expect(
        UpdateTarget.candidates(
            control: UserAppVersionControl(forIos: _row('https://lavkoo.com')),
            isIos: false),
        <String>[_playStorePage],
      );
      expect(
        UpdateTarget.candidates(
            control:
                UserAppVersionControl(forAndroid: _row('https://lavkoo.com')),
            isIos: true),
        <String>[_appStoreSearch],
      );
    });

    test('is the store page when the shop sends no setting at all', () {
      expect(UpdateTarget.candidates(control: null, isIos: false),
          <String>[_playStorePage]);
      expect(UpdateTarget.candidates(control: null, isIos: true),
          <String>[_appStoreSearch]);
    });

    test('names this build on the store of the platform it runs on', () {
      expect(UpdateTarget.storePage(isIos: false), _playStorePage);
      expect(UpdateTarget.storePage(isIos: true), _appStoreSearch);
      expect(UpdateTarget.applicationId, 'com.lavkoo.app');
    });

    test('each platform reads its own link', () {
      final UserAppVersionControl control = UserAppVersionControl(
        forAndroid: _row('https://lavkoo.com/android'),
        forIos: _row(''),
      );

      expect(UpdateTarget.candidates(control: control, isIos: false).first,
          'https://lavkoo.com/android');
      expect(UpdateTarget.candidates(control: control, isIos: true),
          <String>[_appStoreSearch]);
    });

    test('ends at the store page even when the shop configures a link', () {
      expect(
        _candidatesFor('https://lavkoo.com/app'),
        <String>['https://lavkoo.com/app', _playStorePage],
      );
    });

    test('is never empty and never blank, whatever the shop publishes', () {
      for (final String? link in <String?>[null, '', ' ', '\n', 'x']) {
        for (final bool isIos in <bool>[false, true]) {
          final List<String> candidates = _candidatesFor(link, isIos: isIos);

          expect(candidates, isNotEmpty, reason: 'link "$link"');
          for (final String candidate in candidates) {
            expect(candidate.trim(), isNotEmpty,
                reason: 'link "$link" on ${isIos ? 'iOS' : 'Android'}');
          }
        }
      }
    });
  });

  group('the id the store page is built from', () {
    test('is the id the build itself carries, in every place it is written',
        () {
      expect(
        _fileValue('android/app/build.gradle.kts',
            RegExp(r'applicationId\s*=\s*"([^"]+)"')),
        UpdateTarget.applicationId,
        reason: 'the Android build',
      );
      expect(
        _fileValue('android/app/src/main/AndroidManifest.xml',
            RegExp(r'package="([^"]+)"')),
        UpdateTarget.applicationId,
        reason: 'the Android manifest',
      );
      expect(
        _fileValue('ios/Runner/GoogleService-Info.plist',
            RegExp(r'<key>BUNDLE_ID</key>\s*<string>([^<]+)</string>')),
        UpdateTarget.applicationId,
        reason: 'the iOS Firebase settings',
      );
    });
  });

  group('the update screen', () {
    Future<_Launcher> tapUpdate(
      WidgetTester tester, {
      required ConfigModel? config,
      bool Function(String address) canOpen = _anythingOpens,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final _Launcher launcher = _Launcher(canOpen: canOpen);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_Launcher.channel, launcher.answer);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_Launcher.channel, null));

      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize =
          const Size(390, 844) * tester.view.devicePixelRatio;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<SplashController>.value(
              value: _SplashWithConfig(config)),
          ChangeNotifierProvider<ThemeController>.value(
              value: ThemeController(sharedPreferences: preferences)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            _FileLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const UpdateScreen(),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text(_words('en', 'update_now')));
      await tester.pumpAndSettle();

      return launcher;
    }

    testWidgets('opens the store page when the shop configures an empty link',
        (WidgetTester tester) async {
      final _Launcher launcher = await tapUpdate(tester,
          config: ConfigModel(userAppVersionControl: _liveControl()));

      expect(launcher.opened, <String>[_playStorePage]);
      expect(launcher.asked, isNot(contains('')));
    });

    testWidgets('opens the link the shop configured',
        (WidgetTester tester) async {
      final _Launcher launcher = await tapUpdate(tester,
          config: ConfigModel(
              userAppVersionControl: UserAppVersionControl(
                  forAndroid: _row('https://lavkoo.com/app'))));

      expect(launcher.opened, <String>['https://lavkoo.com/app']);
    });

    testWidgets('opens the store page when the shop sent no config at all',
        (WidgetTester tester) async {
      final _Launcher launcher = await tapUpdate(tester, config: null);

      expect(launcher.opened, <String>[_playStorePage]);
    });

    testWidgets('opens the store page when the configured link cannot be opened',
        (WidgetTester tester) async {
      final _Launcher launcher = await tapUpdate(
        tester,
        config: ConfigModel(
            userAppVersionControl:
                UserAppVersionControl(forAndroid: _row('lavkoo://update'))),
        canOpen: (String address) => address != 'lavkoo://update',
      );

      expect(launcher.asked, <String>['lavkoo://update', _playStorePage]);
      expect(launcher.opened, <String>[_playStorePage]);
    });

    testWidgets('says what it could not open when the device opens nothing',
        (WidgetTester tester) async {
      final _Launcher launcher = await tapUpdate(
        tester,
        config: ConfigModel(userAppVersionControl: _liveControl()),
        canOpen: (String address) => false,
      );

      expect(launcher.opened, isEmpty);
      expect(
        find.text('${_words('en', 'can_not_launch')}  $_playStorePage'),
        findsOneWidget,
      );
    });
  });
}
