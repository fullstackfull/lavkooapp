import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/utill/update_gate.dart';

/// A build is held at the update screen when the shop asks for a higher version than the one installed. The shop stores, for each platform,
/// a minimum version and a switch next to it. With the switch off, with no row for the platform, with a blank minimum or with a minimum
/// that is not a version, nothing holds a build back.
void main() {
  const installed = '16.2.1';

  ForAndroid row({required int? status, required String? version}) =>
      ForAndroid(status: status, version: version, link: '');

  bool requiredOn({
    required ForAndroid? android,
    ForAndroid? ios,
    bool isIos = false,
  }) =>
      UpdateGate.isRequired(
        control: UserAppVersionControl(forAndroid: android, forIos: ios),
        isIos: isIos,
        installedVersion: installed,
      );

  group('an update is required', () {
    for (final String minimum in [
      '16.2.2',
      '16.3',
      '16.3.0',
      '17',
      '17.0.0',
      '16.2.1.1',
      '100.0',
    ]) {
      test('when the shop asks for $minimum and the build is $installed', () {
        expect(requiredOn(android: row(status: 1, version: minimum)), isTrue);
      });
    }
  });

  group('an update is not required', () {
    for (final String minimum in [
      '16.2.1',
      '16.2.1.0',
      '16.2',
      '16.1.9',
      '15.99',
      '14.1',
      '3.0.6',
      '1',
    ]) {
      test('when the shop asks for $minimum and the build is $installed', () {
        expect(requiredOn(android: row(status: 1, version: minimum)), isFalse);
      });
    }

    test('when the switch is not on, however high the minimum', () {
      for (final int? status in [0, 2, -1, null]) {
        expect(
          requiredOn(android: row(status: status, version: '99.0')),
          isFalse,
          reason: 'status $status',
        );
      }
    });

    test('when the shop sends no setting at all', () {
      for (final bool isIos in [false, true]) {
        expect(
          UpdateGate.isRequired(
            control: null,
            isIos: isIos,
            installedVersion: installed,
          ),
          isFalse,
          reason: isIos ? 'iOS' : 'Android',
        );
      }
    });

    test('when the shop sends no row for the platform', () {
      expect(
        requiredOn(android: row(status: 1, version: '99.0'), isIos: true),
        isFalse,
        reason: 'iOS has no row',
      );
      expect(
        requiredOn(android: null, ios: row(status: 1, version: '99.0')),
        isFalse,
        reason: 'Android has no row',
      );
      expect(requiredOn(android: null), isFalse);
    });

    test('when the minimum is missing or blank', () {
      for (final String? minimum in [null, '', '   ']) {
        expect(
          requiredOn(android: row(status: 1, version: minimum)),
          isFalse,
          reason: 'minimum "$minimum"',
        );
      }
    });

    test('when the minimum is not a version', () {
      for (final String minimum in ['latest', 'n/a', '.']) {
        expect(
          requiredOn(android: row(status: 1, version: minimum)),
          isFalse,
          reason: 'minimum "$minimum"',
        );
      }
    });
  });

  group('each platform reads its own row', () {
    test('Android is held back by its floor and iOS is not by its own', () {
      final android = row(status: 1, version: '99.0');
      final ios = row(status: 1, version: '1.0');

      expect(requiredOn(android: android, ios: ios), isTrue);
      expect(requiredOn(android: android, ios: ios, isIos: true), isFalse);
    });

    test('iOS is held back by its floor and Android is not by its own', () {
      final android = row(status: 1, version: '1.0');
      final ios = row(status: 1, version: '99.0');

      expect(requiredOn(android: android, ios: ios), isFalse);
      expect(requiredOn(android: android, ios: ios, isIos: true), isTrue);
    });

    test('a platform whose switch is off is not held back by the other', () {
      final android = row(status: 1, version: '99.0');
      final ios = row(status: 0, version: '99.0');

      expect(requiredOn(android: android, ios: ios), isTrue);
      expect(requiredOn(android: android, ios: ios, isIos: true), isFalse);
    });
  });

  group('comparing two versions', () {
    const cases = <(String, String, int)>[
      ('16.2.1', '16.2.1', 0),
      ('16.2.2', '16.2.1', 1),
      ('16.3.0', '16.2.9', 1),
      ('17.0.0', '16.99.99', 1),
      ('16.2.0', '16.2.1', -1),
      ('15.9.9', '16.0.0', -1),
      ('1.0', '1.0.0', 0),
      ('1.0.0', '1', 0),
      ('16.2.1', '16.2.1.1', -1),
      ('16.2.1.1', '16.2.1', 1),
      ('1.10', '1.9', 1),
      ('1.9', '1.10', -1),
      ('2', '10', -1),
      ('1.02', '1.2', 0),
      ('1.x', '1.0', 0),
      ('1.x.1', '1.0.0', 1),
      ('beta', '0', 0),
      ('', '', 0),
      ('', '0.0.1', -1),
    ];

    for (final (first, second, expected) in cases) {
      test('"$first" against "$second" is $expected', () {
        expect(UpdateGate.compare(first, second), expected);
      });
    }

    test('swapping the two versions reverses the answer', () {
      for (final (first, second, expected) in cases) {
        expect(
          UpdateGate.compare(second, first),
          -expected,
          reason: '"$second" against "$first"',
        );
      }
    });
  });
}
