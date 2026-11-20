import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// What the server is asked for after a choice, written into the log of the test so the order of everything a move does is one list. The
/// stored list is left as the test saved it: a refresh that reports nothing new leaves the last answer in force.
class _RecordingService implements StorefrontServiceInterface {
  _RecordingService(this._log, this._preferences);

  final List<String> _log;
  final SharedPreferences _preferences;

  @override
  Future<bool> refreshStorefronts() async {
    _log.add(
        'server asked, choice then ${_preferences.getString(AppConstants.storefrontCountry)}');

    return false;
  }
}

const Map<String, Object> _saudiEntry = <String, Object>{
  'country': 'SA',
  'path': 'sa',
  'currency': 'SAR',
  'sellable': true,
};

const Map<String, Object> _emiratesEntry = <String, Object>{
  'country': 'AE',
  'path': 'ae',
  'currency': 'AED',
  'sellable': true,
};

const Map<String, Object> _kuwaitEntry = <String, Object>{
  'country': 'KW',
  'path': 'kw',
  'currency': 'KWD',
  'sellable': false,
};

const List<Map<String, Object>> _threeStorefronts = <Map<String, Object>>[
  _saudiEntry,
  _emiratesEntry,
  _kuwaitEntry,
];

/// J-01 criterion 4: when the server changes `default_country` the storefront the app falls back to follows it. The fallback is the
/// storefront a customer is on while they have chosen none the app can honour, and the one a customer is moved to when the server stops
/// listing theirs.
///
/// Saudi Arabia stays the floor: an answer that names no default, names one it does not list, or names one that cannot be read leaves the
/// app on the storefront it serves today, so a customer is never left without one. Nothing of this is read or written while storefronts are
/// off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;

  /// The answer of `GET /api/v1/storefronts`, naming [defaultCountry] the default storefront of the list.
  Map<String, Object?> answerNaming(Object? defaultCountry,
          {List<Map<String, Object>> entries = _threeStorefronts}) =>
      <String, Object?>{
        'enabled': true,
        'default_country': defaultCountry,
        'storefronts': entries,
      };

  /// The same answer with no `default_country` in it at all.
  Map<String, Object?> answerNamingNothing(
          {List<Map<String, Object>> entries = _threeStorefronts}) =>
      <String, Object?>{'enabled': true, 'storefronts': entries};

  /// The device of a customer, with [answer] stored the way the service stores it: read into storefronts, then kept as the last answer.
  Future<SharedPreferences> deviceWith({
    Map<String, Object> stored = const <String, Object>{},
    Object? answer,
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (answer != null) {
      await StoredStorefronts(preferences)
          .save(StorefrontCountry.parseList(answer));
    }

    return preferences;
  }

  String fallbackOf(SharedPreferences preferences) =>
      StorefrontChoice(preferences, enabled: true).current().code;

  StorefrontSwitcher switcherOver(SharedPreferences preferences,
          {bool enabled = true}) =>
      StorefrontSwitcher(
        storefrontController: StorefrontController(
          storefrontServiceInterface: _RecordingService(log, preferences),
          storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
        ),
        applyHeaders: () => log.add(
            'headers rebuilt, choice then ${preferences.getString(AppConstants.storefrontCountry)}'),
        changeNotifier: StorefrontChangeNotifier(
          clearHttpCache: (String code) => log.add('http cache cleared of $code'),
          clearLocalCache: (String code) async =>
              log.add('local cache cleared of $code'),
          isSignedIn: () => false,
          enabled: true,
        ),
      );

  setUp(() => log = <String>[]);

  group('the default the answer names', () {
    test('is read from default_country, and is the only default of the list',
        () {
      final List<StorefrontCountry> listed =
          StorefrontCountry.parseList(answerNaming('AE'));

      expect(
        listed.map((StorefrontCountry storefront) =>
            '${storefront.code} ${storefront.isDefault}'),
        <String>['SA false', 'AE true', 'KW false'],
      );
      expect(StorefrontCountry.fallbackAmong(listed).code, 'AE');
    });

    test('is read regardless of case and surrounding spaces', () {
      expect(
        StorefrontCountry.fallbackAmong(
                StorefrontCountry.parseList(answerNaming(' ae ')))
            .code,
        'AE',
      );
    });

    test('is the entry\'s own is_default when the answer carries no default_country',
        () {
      final List<StorefrontCountry> listed = StorefrontCountry.parseList(
        answerNamingNothing(entries: <Map<String, Object>>[
          _saudiEntry,
          <String, Object>{..._kuwaitEntry, 'is_default': true},
        ]),
      );

      expect(StorefrontCountry.fallbackAmong(listed).code, 'KW');
    });

    test('is the one default_country names, when an entry\'s is_default says otherwise',
        () {
      final List<StorefrontCountry> listed = StorefrontCountry.parseList(
        answerNaming('KW', entries: <Map<String, Object>>[
          <String, Object>{..._saudiEntry, 'is_default': true},
          _kuwaitEntry,
        ]),
      );

      expect(
        listed.map((StorefrontCountry storefront) =>
            '${storefront.code} ${storefront.isDefault}'),
        <String>['SA false', 'KW true'],
      );
    });

    test('is nothing at all when the answer names one that cannot be read, or one it does not list',
        () {
      for (final Object? unusable in <Object?>[
        '',
        '   ',
        'E',
        'EGY',
        'A1',
        7,
        true,
        null,
        <Object?>[],
        'EG',
      ]) {
        final List<StorefrontCountry> listed =
            StorefrontCountry.parseList(answerNaming(unusable));

        expect(
            listed.where((StorefrontCountry storefront) => storefront.isDefault),
            isEmpty,
            reason: 'default_country: $unusable');
        expect(StorefrontCountry.fallbackAmong(listed).code, 'SA',
            reason: 'default_country: $unusable');
      }
    });

    test('is kept with the stored list, under the key the server writes it with',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));

      expect(jsonDecode(preferences.getString(AppConstants.storefrontList)!), {
        'storefronts': [
          {'country': 'SA', 'path': '/sa', 'currency': 'SAR', 'sellable': true},
          {
            'country': 'AE',
            'path': '/ae',
            'currency': 'AED',
            'is_default': true,
            'sellable': true,
          },
          {
            'country': 'KW',
            'path': '/kw',
            'currency': 'KWD',
            'sellable': false,
          },
        ],
      });
      expect(
        StorefrontCountry.fallbackAmong(StoredStorefronts(preferences).read())
            .code,
        'AE',
      );
    });
  });

  group('the storefront a customer with no choice of their own is on', () {
    test('is the one the server names its default', () async {
      expect(fallbackOf(await deviceWith(answer: answerNaming('AE'))), 'AE');
    });

    test('follows the server when it moves its default', () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));
      final StoredStorefronts stored = StoredStorefronts(preferences);
      expect(fallbackOf(preferences), 'AE');

      await stored.save(StorefrontCountry.parseList(answerNaming('KW')));
      expect(fallbackOf(preferences), 'KW');

      await stored.save(StorefrontCountry.parseList(answerNamingNothing()));
      expect(fallbackOf(preferences), 'SA');
    });

    test('is the server\'s default for a stored choice the app cannot honour',
        () async {
      for (final Object storedChoice in <Object>['US', 7]) {
        expect(
          fallbackOf(await deviceWith(
            stored: <String, Object>{
              AppConstants.storefrontCountry: storedChoice
            },
            answer: answerNaming('AE'),
          )),
          'AE',
          reason: 'stored choice: $storedChoice',
        );
      }
    });

    test('is Saudi Arabia before the server has answered once', () async {
      expect(fallbackOf(await deviceWith()), 'SA');
    });

    test('is Saudi Arabia when the answer names no default, even when it does not list Saudi Arabia',
        () async {
      expect(
        fallbackOf(await deviceWith(
            answer: answerNamingNothing(entries: <Map<String, Object>>[
          _emiratesEntry,
          _kuwaitEntry,
        ]))),
        'SA',
      );
    });

    test('is Saudi Arabia when the answer names a default it does not list',
        () async {
      expect(
        fallbackOf(await deviceWith(
            answer: answerNaming('OM', entries: <Map<String, Object>>[
          _emiratesEntry,
          _kuwaitEntry,
        ]))),
        'SA',
      );
    });

    test('is not the server\'s default for a customer who chose a storefront the answer lists',
        () async {
      expect(
        fallbackOf(await deviceWith(
          stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
          answer: answerNaming('AE'),
        )),
        'KW',
      );
    });
  });

  group('while storefronts are off', () {
    test('the server\'s default is not read: the storefront is Saudi Arabia, and nothing is written',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        answer: answerNaming('AE'),
      );
      final StorefrontChoice choice =
          StorefrontChoice(preferences, enabled: false);

      expect(choice.current().code, 'SA');
      expect(choice.available(), isEmpty);
      expect(await choice.choose(StorefrontCountry.unitedArabEmirates), isFalse);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
    });

    test('a storefront the answer no longer lists is left alone, and nothing is asked',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNaming('AE'),
      );

      expect(
          await switcherOver(preferences, enabled: false)
              .followTheServersList(),
          StorefrontSwitch.unchanged);
      expect(log, isEmpty);
      expect(preferences.getString(AppConstants.storefrontCountry), 'OM');
    });
  });

  group('following the list the server answers with', () {
    test('moves a customer whose storefront it no longer lists to the default it names, the way a choice moves them',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNaming('AE', entries: <Map<String, Object>>[
          _saudiEntry,
          _emiratesEntry,
        ]),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();
      await Future<void>.delayed(Duration.zero);

      expect(result, StorefrontSwitch.switched);
      expect(preferences.getString(AppConstants.storefrontCountry), 'AE');
      expect(log, <String>[
        'server asked, choice then OM',
        'server asked, choice then AE',
        'headers rebuilt, choice then AE',
        'http cache cleared of OM',
        'local cache cleared of OM',
      ]);
    });

    test('moves them to Saudi Arabia when it names no default, even when it does not list Saudi Arabia',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNamingNothing(entries: <Map<String, Object>>[
          _emiratesEntry,
          _kuwaitEntry,
        ]),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();

      expect(result, StorefrontSwitch.switched);
      expect(preferences.getString(AppConstants.storefrontCountry), 'SA');
    });

    test('moves them to Saudi Arabia when the default it names is one it does not list',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNaming('OM', entries: <Map<String, Object>>[
          _saudiEntry,
          _emiratesEntry,
        ]),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();

      expect(result, StorefrontSwitch.switched);
      expect(preferences.getString(AppConstants.storefrontCountry), 'SA');
    });

    test('leaves a customer the answer still lists where they are, whichever storefront is its default',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        answer: answerNaming('AE'),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
      expect(log, <String>['server asked, choice then KW']);
    });
  });
}
