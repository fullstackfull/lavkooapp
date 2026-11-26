import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';

/// Which payment methods a screen offers (J-09).
///
/// `payment_methods` is the shop's GLOBAL list and always has been. It cannot answer the per-market question and the server deliberately does
/// not make it try: without an order there is no amount to judge a routing rule against, so hiding a method on a maybe would hide one the
/// customer is entitled to. What the server added is a second key, `storefront_payment_methods`, which it can narrow because the app says
/// which storefront it is asking for -- a hide rule bound to that country is judged, and a gateway that cannot take that market's money is
/// left out HERE instead of refusing the customer after they have picked it.
///
/// So the app reads two lists and the screens read one accessor. The three readings that matter:
///
///  - a shop that sends the narrower list has it offered;
///  - a shop that sends an EMPTY narrower list offers nothing, and does not fall back to the global list. "This storefront offers no online
///    method" is an answer, and serving the global list there would offer exactly the methods the shop has just refused;
///  - a shop that sends no such key at all is served the global list, so every older shop behaves exactly as it did.
void main() {
  ConfigModel configFrom(Map<String, dynamic> payment) =>
      ConfigModel.fromJson(<String, dynamic>{
        'payment_methods': <dynamic>[
          <String, dynamic>{'key_name': 'ssl_commerz'},
          <String, dynamic>{'key_name': 'myfatoorah'},
        ],
        ...payment,
      });

  List<String> keysOf(List<PaymentMethods>? methods) =>
      (methods ?? <PaymentMethods>[])
          .map((PaymentMethods method) => method.keyName ?? '')
          .toList();

  group('the methods a storefront may offer', () {
    test('are what the screens offer when the shop sends them', () {
      final ConfigModel config = configFrom(<String, dynamic>{
        'storefront_payment_methods': <dynamic>[
          <String, dynamic>{'key_name': 'myfatoorah'},
        ],
      });

      expect(keysOf(config.paymentMethodsOnOffer), <String>['myfatoorah']);
    });

    test(
        'leave the global list exactly as it was, so a client that reads only it is unchanged',
        () {
      final ConfigModel config = configFrom(<String, dynamic>{
        'storefront_payment_methods': <dynamic>[
          <String, dynamic>{'key_name': 'myfatoorah'},
        ],
      });

      expect(
          keysOf(config.paymentMethods), <String>['ssl_commerz', 'myfatoorah']);
    });

    test(
        'offer nothing when the shop says the storefront has nothing, rather than falling back to the global list',
        () {
      final ConfigModel config = configFrom(
          <String, dynamic>{'storefront_payment_methods': <dynamic>[]});

      expect(config.storefrontPaymentMethods, isEmpty);
      expect(keysOf(config.paymentMethodsOnOffer), isEmpty,
          reason:
              'the shop refused these methods for this market; offering them anyway is the defect');
    });

    test(
        'are the global list for a shop that does not answer per storefront, which is every shop with storefronts off',
        () {
      final ConfigModel config = configFrom(<String, dynamic>{});

      expect(config.storefrontPaymentMethods, isNull);
      expect(keysOf(config.paymentMethodsOnOffer),
          <String>['ssl_commerz', 'myfatoorah']);
    });

    test(
        'are null when the shop sends neither list, so a screen that reads them shows nothing rather than throwing',
        () {
      final ConfigModel config = ConfigModel.fromJson(<String, dynamic>{});

      expect(config.paymentMethods, isNull);
      expect(config.storefrontPaymentMethods, isNull);
      expect(config.paymentMethodsOnOffer, isNull);
    });
  });

  /// The checkout re-reads the config when the payment sheet opens, because a gateway switched off in the admin panel could otherwise still
  /// be on a cached list. That re-read has to replace BOTH lists: replacing the global one and leaving the storefront's stale would leave the
  /// screens -- which read the storefront's -- showing exactly the list the re-read existed to refresh.
  group('the re-read of the payment part of the config', () {
    test('replaces the storefront list beside the global one', () {
      final String source =
          File('lib/features/splash/controllers/splash_controller.dart')
              .readAsStringSync();
      final int opens = source.indexOf('Future<void> refreshPaymentMethods()');
      expect(opens, greaterThan(-1),
          reason: 'the method this test is about has been renamed or removed');

      final String body = source.substring(opens);
      expect(body,
          contains('_configModel!.paymentMethods = fresh.paymentMethods;'));
      expect(
        body,
        contains(
            '_configModel!.storefrontPaymentMethods = fresh.storefrontPaymentMethods;'),
        reason: 'the re-read must replace the list the screens actually read',
      );
    });
  });

  /// Every screen that offers a gateway reads the accessor and not the global field. A screen left on the global field would offer a market
  /// methods its shop has excluded, which is the whole of what J-09 asks for, and the mistake is invisible in a diff of one file.
  group('the screens that offer a gateway', () {
    const List<String> screens = <String>[
      'lib/features/checkout/widgets/choose_payment_widget.dart',
      'lib/features/checkout/widgets/payment_method_bottom_sheet_widget.dart',
      'lib/features/wallet/widgets/add_fund_dialogue_widget.dart',
      'lib/features/wallet/widgets/wallet_card_widget.dart',
      'lib/features/order_details/widgets/order_payment_bottomsheet_widget.dart',
    ];

    test('read the accessor and never the global list', () {
      for (final String screen in screens) {
        final String source = File(screen).readAsStringSync();

        expect(source, contains('paymentMethodsOnOffer'),
            reason:
                '$screen offers a gateway and must read the storefront\'s list');
        expect(
          RegExp(r'paymentMethods(?!OnOffer)').hasMatch(source
              .replaceAll('paymentMethodImagePath', '')
              .replaceAll('paymentMethodIndex', '')),
          isFalse,
          reason:
              '$screen still reads the global payment_methods list somewhere',
        );
      }
    });
  });
}
