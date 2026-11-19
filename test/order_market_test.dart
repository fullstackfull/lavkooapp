import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/order/domain/models/order_model.dart';
import 'package:syriapharmacy/features/order_details/domain/models/order_details_model.dart';
import 'package:syriapharmacy/features/storefront/domain/models/order_market.dart';

Map<String, dynamic> _order({Map<String, dynamic> snapshot = const {}}) =>
    <String, dynamic>{
      'id': 4217,
      'order_status': 'pending',
      'created_at': '2026-11-12T10:32:00.000000Z',
      'order_amount': 12.5,
      'discount_amount': 0,
      'shipping_cost': 1,
      'extra_discount': 0,
      'order_type': 'default_type',
      ...snapshot,
    };

Map<String, dynamic> _line({Map<String, dynamic> snapshot = const {}}) =>
    <String, dynamic>{
      'id': 9001,
      'order_id': 4217,
      'qty': 2,
      'price': 6.25,
      'tax': 0,
      'discount': 0,
      'order': <String, dynamic>{
        'is_shipping_free': false,
        'order_status': 'pending',
        ...snapshot,
      },
    };

Map<String, dynamic> _snapshot(String country, String currency,
        {Object rate = '1.00000000'}) =>
    <String, dynamic>{
      'storefront_country': country,
      'currency_code': currency,
      'currency_rate': rate,
    };

const Map<String, String> _currencyOfStorefront = <String, String>{
  'SA': 'SAR',
  'AE': 'AED',
  'KW': 'KWD',
  'QA': 'QAR',
  'BH': 'BHD',
  'OM': 'OMR',
};

const List<String> _withTheirOwnCurrency = <String>[
  'AE',
  'KW',
  'QA',
  'BH',
  'OM'
];

/// J-13 criterion 1, the model half: the order list, the order and the details of an order carry the three columns of the storefront snapshot
/// the server writes on an order (`storefront_country`, `currency_code`, `currency_rate`), and the app reads them without ever failing on an
/// order that has none. The answers below are written by hand from the audit of the backend: the order list, the order by its id, the tracking
/// and the details of an order serialise every column of the order, and the snapshot is written once, when an order is saved by a path that
/// records it, by `OrderStorefrontSnapshot`, from the products the order holds. They are not recorded from a real server, and no test on
/// either side asserts that the keys are in an answer.
///
/// The server writes one of four things: the three columns for an order of a storefront with its own currency (the rate is one and a MySQL
/// decimal arrives as the text `1.00000000`), the three for the default storefront of a platform with a single currency, the country alone
/// for the default storefront of a platform that converts from a base currency or for a storefront whose currency was not active, and nothing
/// for an order saved before the columns existed, while storefronts were off, or with products of two countries. The keys are missing from an
/// order saved before the migration ran.
///
/// What this covers is the model and the two rules that read it (which country and which currency to write, with storefronts on and off).
/// It does not cover how a screen writes them: that is order_price_converter_test.dart and order_screens_currency_test.dart.
///
///   flutter test test/order_market_test.dart
void main() {
  group('an order of the list the server answers', () {
    test('carries the country, the currency and the rate of every storefront',
        () {
      final OrderModel list = OrderModel.fromJson(<String, dynamic>{
        'total_size': 6,
        'limit': '10',
        'offset': '1',
        'orders': <Map<String, dynamic>>[
          for (final MapEntry<String, String> storefront
              in _currencyOfStorefront.entries)
            _order(snapshot: _snapshot(storefront.key, storefront.value)),
        ],
      });

      expect(
        <List<Object?>>[
          for (final Orders order in list.orders!)
            <Object?>[
              order.market!.country,
              order.market!.currencyCode,
              order.market!.currencyRate,
            ],
        ],
        <List<Object?>>[
          <Object?>['SA', 'SAR', 1.0],
          <Object?>['AE', 'AED', 1.0],
          <Object?>['KW', 'KWD', 1.0],
          <Object?>['QA', 'QAR', 1.0],
          <Object?>['BH', 'BHD', 1.0],
          <Object?>['OM', 'OMR', 1.0],
        ],
      );
    });

    test('reads the rate whether the database sent it as text or as a number',
        () {
      for (final Object rate in <Object>['1.00000000', '1', 1, 1.0]) {
        final Orders order = Orders.fromJson(
            _order(snapshot: _snapshot('KW', 'KWD', rate: rate)));

        expect(order.market!.currencyRate, 1.0, reason: '$rate');
      }
    });

    test(
        'carries the country alone for the default storefront of a platform that converts',
        () {
      final Orders order = Orders.fromJson(<String, dynamic>{
        ..._order(),
        'storefront_country': 'SA',
        'currency_code': null,
        'currency_rate': null,
      });

      expect(order.market!.country, 'SA');
      expect(order.market!.currencyCode, isNull);
      expect(order.market!.currencyRate, isNull);
    });

    test(
        'is read as an order of before when the server sends the columns empty',
        () {
      final Orders order = Orders.fromJson(<String, dynamic>{
        ..._order(),
        'storefront_country': null,
        'currency_code': null,
        'currency_rate': null,
      });

      expect(order.market!.country, isNull);
      expect(order.market!.currencyCode, isNull);
      expect(order.market!.currencyRate, isNull);
    });

    test(
        'is read as an order of before when the keys are missing, and nothing else of it changes',
        () {
      final Orders order = Orders.fromJson(_order());

      expect(order.market!.country, isNull);
      expect(order.market!.currencyCode, isNull);
      expect(order.market!.currencyRate, isNull);
      expect(order.id, 4217);
      expect(order.orderStatus, 'pending');
      expect(order.orderAmount, 12.5);
      expect(order.shippingCost, 1.0);
    });

    test(
        'reads a code in any case and with spaces, as the storefront list does',
        () {
      final Orders order = Orders.fromJson(<String, dynamic>{
        ..._order(),
        'storefront_country': ' kw ',
        'currency_code': ' kwd ',
        'currency_rate': ' 1.00000000 ',
      });

      expect(order.market!.country, 'KW');
      expect(order.market!.currencyCode, 'KWD');
      expect(order.market!.currencyRate, 1.0);
    });
  });

  group('an order the server could have written wrongly', () {
    test('has no country when the value is not two letters', () {
      for (final Object? country in <Object?>[
        5,
        true,
        <String>['KW'],
        <String, String>{'code': 'KW'},
        '',
        '   ',
        'K',
        'KUW',
        'K1',
        '12',
        'Kuwait',
      ]) {
        final Orders order = Orders.fromJson(<String, dynamic>{
          ..._order(),
          'storefront_country': country,
        });

        expect(order.market!.country, isNull, reason: '$country');
      }
    });

    test('has no currency when the value is not a three-letter code', () {
      for (final Object? currency in <Object?>[
        5,
        true,
        <String>['KWD'],
        '',
        '   ',
        'KW',
        'KWDX',
        'K W D',
        '123',
        'Kuwaiti dinar',
      ]) {
        final Orders order = Orders.fromJson(<String, dynamic>{
          ..._order(),
          'currency_code': currency,
        });

        expect(order.market!.currencyCode, isNull, reason: '$currency');
      }
    });

    test('has no rate when the value is not a finite number', () {
      for (final Object? rate in <Object?>[
        'abc',
        '',
        '   ',
        true,
        <int>[1],
        <String, int>{'rate': 1},
        'NaN',
        'Infinity',
        '-Infinity',
      ]) {
        final Orders order = Orders.fromJson(<String, dynamic>{
          ..._order(),
          'currency_rate': rate,
        });

        expect(order.market!.currencyRate, isNull, reason: '$rate');
      }
    });

    test('never stops the order from being read', () {
      expect(
          () => Orders.fromJson(<String, dynamic>{
                ..._order(),
                'storefront_country': <int>[1],
                'currency_code': <String, int>{'a': 1},
                'currency_rate': true,
              }),
          returnsNormally);
    });
  });

  group('the details of an order', () {
    test('carry the snapshot of the order, in the order of each line', () {
      final OrderDetailsModel line =
          OrderDetailsModel.fromJson(_line(snapshot: _snapshot('OM', 'OMR')));

      expect(line.order!.market!.country, 'OM');
      expect(line.order!.market!.currencyCode, 'OMR');
      expect(line.order!.market!.currencyRate, 1.0);
    });

    test(
        'are read as the details of before when the keys are missing, and nothing else of them changes',
        () {
      final OrderDetailsModel line = OrderDetailsModel.fromJson(_line());

      expect(line.order!.market!.country, isNull);
      expect(line.order!.market!.currencyCode, isNull);
      expect(line.order!.market!.currencyRate, isNull);
      expect(line.price, 6.25);
      expect(line.qty, 2);
      expect(line.order!.status, 'pending');
      expect(line.order!.isShippingFree, 0);
    });

    test(
        'are read when the answer carries no order at all, so a screen writes the line as before',
        () {
      final OrderDetailsModel line =
          OrderDetailsModel.fromJson(<String, dynamic>{
        'id': 9001,
        'order_id': 4217,
        'qty': 2,
        'price': 6.25,
        'tax': 0,
        'discount': 0,
      });

      expect(line.order, isNull);
      expect(line.price, 6.25);
      expect(line.qty, 2);
    });

    test('are read when the snapshot is wrong, and say nothing of it', () {
      final OrderDetailsModel line =
          OrderDetailsModel.fromJson(_line(snapshot: <String, dynamic>{
        'storefront_country': 7,
        'currency_code': <String>[],
        'currency_rate': 'x',
      }));

      expect(line.order!.market!.country, isNull);
      expect(line.order!.market!.currencyCode, isNull);
      expect(line.order!.market!.currencyRate, isNull);
    });
  });

  group('the country to write beside an order', () {
    test('is none while storefronts are off, whatever the order says', () {
      for (final MapEntry<String, String> storefront
          in _currencyOfStorefront.entries) {
        final OrderMarket market =
            OrderMarket.fromJson(_snapshot(storefront.key, storefront.value));

        expect(market.countryToShow(enabled: false), isNull,
            reason: storefront.key);
      }
    });

    test(
        'is the country of the order while storefronts are on, the default storefront included',
        () {
      for (final String country in _currencyOfStorefront.keys) {
        final OrderMarket market = OrderMarket.fromJson(
            _snapshot(country, _currencyOfStorefront[country]!));

        expect(market.countryToShow(enabled: true), country);
      }
    });

    test('is the country alone when the order names no currency', () {
      expect(
          const OrderMarket(country: 'SA').countryToShow(enabled: true), 'SA');
    });

    test('is none for an order that names no country', () {
      expect(const OrderMarket().countryToShow(enabled: true), isNull);
      expect(
          const OrderMarket(currencyCode: 'KWD', currencyRate: 1)
              .countryToShow(enabled: true),
          isNull);
    });
  });

  group('the currency the amounts of an order are in', () {
    test('is none while storefronts are off, whatever the order says', () {
      for (final MapEntry<String, String> storefront
          in _currencyOfStorefront.entries) {
        final OrderMarket market =
            OrderMarket.fromJson(_snapshot(storefront.key, storefront.value));

        expect(market.currencyOfItsAmounts(enabled: false), isNull,
            reason: storefront.key);
      }
    });

    test(
        'is the currency the order records, for every storefront, the default one included',
        () {
      for (final MapEntry<String, String> storefront
          in _currencyOfStorefront.entries) {
        final OrderMarket market =
            OrderMarket.fromJson(_snapshot(storefront.key, storefront.value));

        expect(market.currencyOfItsAmounts(enabled: true), storefront.value,
            reason: storefront.key);
      }
    });

    test(
        'is none when the order records no currency, and none when its rate is not the one its amounts are stored at',
        () {
      expect(
          const OrderMarket(country: 'SA', currencyRate: 1)
              .currencyOfItsAmounts(enabled: true),
          isNull);
      expect(const OrderMarket().currencyOfItsAmounts(enabled: true), isNull);
      expect(
          const OrderMarket(country: 'SA', currencyCode: 'SAR')
              .currencyOfItsAmounts(enabled: true),
          isNull,
          reason: 'a currency with no rate');

      for (final double rate in <double>[0, -1, 0.307, 3.75, 1.00000001]) {
        expect(
            OrderMarket(country: 'SA', currencyCode: 'SAR', currencyRate: rate)
                .currencyOfItsAmounts(enabled: true),
            isNull,
            reason: '$rate');
      }
    });
  });

  group('whether an order records a rate that is not the one of its amounts',
      () {
    test('is no while storefronts are off, whatever the order says', () {
      expect(
          const OrderMarket(
                  country: 'KW', currencyCode: 'KWD', currencyRate: 3.75)
              .recordsAnotherRate(enabled: false),
          isFalse);
    });

    test('is no for the rate its amounts are stored at, and for no rate at all',
        () {
      expect(
          OrderMarket.fromJson(_snapshot('KW', 'KWD'))
              .recordsAnotherRate(enabled: true),
          isFalse);
      expect(
          const OrderMarket(country: 'KW', currencyCode: 'KWD')
              .recordsAnotherRate(enabled: true),
          isFalse);
      expect(const OrderMarket().recordsAnotherRate(enabled: true), isFalse);
    });

    test('is yes for every other rate, which the app cannot read', () {
      for (final double rate in <double>[0, -1, 0.307, 3.75, 1.00000001]) {
        expect(
            OrderMarket(country: 'KW', currencyCode: 'KWD', currencyRate: rate)
                .recordsAnotherRate(enabled: true),
            isTrue,
            reason: '$rate');
      }
    });
  });

  group('the currency to write the amounts of an order in', () {
    test('is none while storefronts are off, whatever the order says', () {
      for (final MapEntry<String, String> storefront
          in _currencyOfStorefront.entries) {
        final OrderMarket market =
            OrderMarket.fromJson(_snapshot(storefront.key, storefront.value));

        expect(market.currencyToWrite(enabled: false), isNull,
            reason: storefront.key);
      }
    });

    test(
        'is the currency of the order, for each storefront with its own currency',
        () {
      for (final String country in _withTheirOwnCurrency) {
        final OrderMarket market = OrderMarket.fromJson(
            _snapshot(country, _currencyOfStorefront[country]!));

        expect(market.currencyToWrite(enabled: true),
            _currencyOfStorefront[country],
            reason: country);
      }
    });

    test(
        'is none for an order of the default storefront, which keeps the money the app has always written',
        () {
      final OrderMarket market = OrderMarket.fromJson(_snapshot('SA', 'SAR'));

      expect(market.currencyToWrite(enabled: true), isNull);
    });

    test('is none for an order that names no currency', () {
      expect(
          const OrderMarket(country: 'KW', currencyRate: 1)
              .currencyToWrite(enabled: true),
          isNull);
      expect(const OrderMarket(country: 'SA').currencyToWrite(enabled: true),
          isNull);
      expect(const OrderMarket().currencyToWrite(enabled: true), isNull);
    });

    test('is none for an order that names no country, or no rate', () {
      expect(
          const OrderMarket(currencyCode: 'KWD', currencyRate: 1)
              .currencyToWrite(enabled: true),
          isNull);
      expect(
          const OrderMarket(country: 'KW', currencyCode: 'KWD')
              .currencyToWrite(enabled: true),
          isNull);
    });

    test(
        'is none when the rate is not one, because an amount is never multiplied by it',
        () {
      for (final double rate in <double>[0, -1, 0.307, 3.75, 1.00000001]) {
        final OrderMarket market =
            OrderMarket(country: 'KW', currencyCode: 'KWD', currencyRate: rate);

        expect(market.currencyToWrite(enabled: true), isNull, reason: '$rate');
      }
    });
  });
}
