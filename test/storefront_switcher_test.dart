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

/// What the server is asked for after a choice, written into the log of the test so the order of everything the switch does is one list.
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

class _RecordingNotifier extends StorefrontChangeNotifier {
  _RecordingNotifier(this._log)
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;
  late SharedPreferences preferences;

  Future<StorefrontSwitcher> switcher({
    bool enabled = true,
    Map<String, Object> stored = const <String, Object>{},
    List<StorefrontCountry>? listed,
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    preferences = await SharedPreferences.getInstance();
    if (listed != null) {
      await StoredStorefronts(preferences).save(listed);
    }

    return StorefrontSwitcher(
      storefrontController: StorefrontController(
        storefrontServiceInterface: _RecordingService(log, preferences),
        storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
      ),
      applyHeaders: () => log.add(
          'headers rebuilt, choice then ${preferences.getString(AppConstants.storefrontCountry)}'),
      changeNotifier: _RecordingNotifier(log),
    );
  }

  setUp(() => log = <String>[]);

  test(
      'saves the choice, asks the server, rebuilds the headers, then tells the listeners, in that order',
      () async {
    final StorefrontSwitcher subject = await switcher();

    final StorefrontSwitch result =
        await subject.switchTo(StorefrontCountry.unitedArabEmirates);

    expect(result, StorefrontSwitch.switched);
    expect(log, <String>[
      'server asked, choice then AE',
      'headers rebuilt, choice then AE',
      'listeners told SA -> AE',
    ]);
    expect(preferences.getString(AppConstants.storefrontCountry), 'AE');
  });

  test('tells the listeners which storefront the customer came from', () async {
    final StorefrontSwitcher subject = await switcher(stored: <String, Object>{
      AppConstants.storefrontCountry: 'KW',
    });

    await subject.switchTo(StorefrontCountry.qatar);

    expect(log.last, 'listeners told KW -> QA');
  });

  test('does nothing when the customer chose the storefront they were on',
      () async {
    final StorefrontSwitcher subject = await switcher(stored: <String, Object>{
      AppConstants.storefrontCountry: 'AE',
    });

    final StorefrontSwitch result =
        await subject.switchTo(StorefrontCountry.unitedArabEmirates);

    expect(result, StorefrontSwitch.unchanged);
    expect(log, isEmpty);
  });

  test(
      'nothing chosen yet is the Saudi storefront, so choosing it does nothing',
      () async {
    final StorefrontSwitcher subject = await switcher();

    expect(await subject.switchTo(StorefrontCountry.saudiArabia),
        StorefrontSwitch.unchanged);
    expect(log, isEmpty);
  });

  test(
      'does nothing, and says so, when the choice cannot be saved, which is every choice while storefronts are off',
      () async {
    final StorefrontSwitcher subject = await switcher(enabled: false);

    final StorefrontSwitch result =
        await subject.switchTo(StorefrontCountry.unitedArabEmirates);

    expect(result, StorefrontSwitch.failed);
    expect(log, isEmpty);
    expect(preferences.containsKey(AppConstants.storefrontCountry), isFalse);
  });

  group('following the list the server answers with (J-01)', () {
    test(
        'moves a customer whose storefront the server no longer lists to the default one, the way a choice moves them',
        () async {
      final StorefrontSwitcher subject = await switcher(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        listed: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.unitedArabEmirates,
        ],
      );

      final StorefrontSwitch result = await subject.followTheServersList();

      expect(result, StorefrontSwitch.switched);
      expect(log, <String>[
        'server asked, choice then KW',
        'server asked, choice then SA',
        'headers rebuilt, choice then SA',
        'listeners told KW -> SA',
      ]);
      expect(preferences.getString(AppConstants.storefrontCountry), 'SA');
    });

    test('leaves a customer on a storefront the server still lists', () async {
      final StorefrontSwitcher subject = await switcher(
        stored: <String, Object>{AppConstants.storefrontCountry: 'AE'},
        listed: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.unitedArabEmirates,
        ],
      );

      final StorefrontSwitch result = await subject.followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(log, <String>['server asked, choice then AE']);
      expect(preferences.getString(AppConstants.storefrontCountry), 'AE');
    });

    test('a storefront the server lists as browse-only is still a storefront the customer may stay on',
        () async {
      final StorefrontSwitcher subject = await switcher(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        listed: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          StorefrontCountry.kuwait,
        ],
      );

      expect(await subject.followTheServersList(), StorefrontSwitch.unchanged);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
    });

    test('does nothing before the server has answered once, because there is then nothing to judge by',
        () async {
      final StorefrontSwitcher subject = await switcher(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
      );

      final StorefrontSwitch result = await subject.followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(log, <String>['server asked, choice then KW']);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
    });

    test('a customer on the default storefront stays on it even when the list leaves it out',
        () async {
      final StorefrontSwitcher subject = await switcher(
        listed: <StorefrontCountry>[
          StorefrontCountry.unitedArabEmirates,
          StorefrontCountry.kuwait,
        ],
      );

      final StorefrontSwitch result = await subject.followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(log, <String>['server asked, choice then null']);
      expect(preferences.containsKey(AppConstants.storefrontCountry), isFalse);
    });

    test('does nothing, and asks nothing, while storefronts are off', () async {
      final StorefrontSwitcher subject = await switcher(
        enabled: false,
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        listed: <StorefrontCountry>[StorefrontCountry.saudiArabia],
      );

      final StorefrontSwitch result = await subject.followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(log, isEmpty);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
    });
  });
}
