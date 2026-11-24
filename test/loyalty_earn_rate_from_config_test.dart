import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';

/// What the app is told about earning points (E-02, J-V2).
///
/// The shop sent the app whether loyalty runs, what a point converts at and how few may be converted, but never the EARN rate, so the app
/// could not say what an order is about to earn -- the one loyalty number a customer sees before they buy rather than after. The shop now
/// sends it per market, so a Kuwaiti customer is told Kuwait's rate.
///
/// The reading that matters most is the last one: a shop too old to send it leaves the field null, and null means the screen says nothing.
/// A zero would read as "this order earns nothing", which is a claim an older shop has not made.
///
/// These are the first tests in this app to build a ConfigModel from JSON rather than with its named constructor, and the first run of them
/// found a real defect: the constructor read `json['unit']` without a guard, so a shop whose config omitted that one key crashed the app at
/// the splash screen. The last group here is that, kept.
void main() {
  ConfigModel configFrom(Map<String, dynamic> loyalty) => ConfigModel.fromJson(<String, dynamic>{
        'loyalty_point_status': 1,
        'loyalty_point_exchange_rate': 100,
        'loyalty_point_minimum_point': 50,
        ...loyalty,
      });

  group('the earn rate the shop sends', () {
    test('is read as the percentage of an order that becomes points', () {
      expect(configFrom(<String, dynamic>{'loyalty_point_item_purchase_point': 4}).loyaltyPointEarnRate, 4);
    });

    test('is read when the shop sends it as text, as the settings table holds it', () {
      expect(configFrom(<String, dynamic>{'loyalty_point_item_purchase_point': '2.5'}).loyaltyPointEarnRate, 2.5);
    });

    test('is null for a shop that does not send it, so the screen says nothing rather than zero', () {
      expect(configFrom(<String, dynamic>{}).loyaltyPointEarnRate, isNull);
    });

    test('is null rather than zero when the shop sends something that is not a number', () {
      expect(configFrom(<String, dynamic>{'loyalty_point_item_purchase_point': 'four'}).loyaltyPointEarnRate, isNull);
    });

    test('leaves the three numbers the app was already told alone', () {
      final ConfigModel config = configFrom(<String, dynamic>{'loyalty_point_item_purchase_point': 4});

      expect(config.loyaltyPointStatus, 1);
      expect(config.loyaltyPointExchangeRate, 100);
      expect(config.loyaltyPointMinimumPoint, 50);
    });
  });

  /// The config response is the shop's and not ours, so a response that leaves things out has to leave the app usable rather than
  /// unopenable. Every list in the constructor is read behind a guard except one, which this holds in place.
  group('a config response that leaves things out', () {
    test('does not crash on a shop that sends no list of units', () {
      expect(ConfigModel.fromJson(<String, dynamic>{}).unit, isNull);
    });

    test('still reads the units a shop does send', () {
      expect(
        ConfigModel.fromJson(<String, dynamic>{'unit': <dynamic>['kg', 'pc']}).unit,
        <String>['kg', 'pc'],
      );
    });

    test('does not crash on a response with nothing in it at all', () {
      expect(() => ConfigModel.fromJson(<String, dynamic>{}), returnsNormally);
    });
  });
}
