import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/push_notification/models/notification_body.dart';
import 'package:syriapharmacy/push_notification/notification_helper.dart';
import 'package:syriapharmacy/push_notification/push_storefront_target.dart';

/// J-11 criterion 3, the reading half: a push carries the storefront it is about, and the storefront a tap on it should open in is
/// decided in one place.
///
/// [PushStorefrontTarget.of] takes the build flag as a parameter, so both answers are measured in one run. What the tap then DOES with
/// the answer, on the real routing of the real notification helper, is push_storefront_notification_test.dart.
///
/// The case to look at first is the one with no storefront in the message. That is every push the backend sends today — no sender writes
/// the key — and every push already in flight when an app is updated. It must answer null, which is "change nothing".
void main() {
  const List<StorefrontCountry> listed = <StorefrontCountry>[
    StorefrontCountry.saudiArabia,
    StorefrontCountry.kuwait,
    StorefrontCountry.unitedArabEmirates,
  ];

  StorefrontCountry? targetOf(
    Map<String, dynamic> message, {
    StorefrontCountry current = StorefrontCountry.saudiArabia,
    List<StorefrontCountry> available = listed,
    bool enabled = true,
  }) =>
      PushStorefrontTarget.of(
        NotificationBody.fromJson(message),
        current: current,
        available: available,
        enabled: enabled,
      );

  group('a push that names no storefront changes nothing', () {
    test('a message without the key, which is every push the backend sends today', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'order_id': 4217}),
        isNull,
      );
    });

    test('a message whose storefront is the empty string, which is how the backend writes a value it does not have', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': ''}),
        isNull,
      );
    });

    test('a message whose storefront is blank', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': '   '}),
        isNull,
      );
    });

    test('a message whose storefront is not a country code', () {
      for (final Object? value in <Object?>['Saudi Arabia', 'S', 'SAU', 12, true]) {
        expect(
          targetOf(<String, dynamic>{'type': 'order', 'storefront': value}),
          isNull,
          reason: '$value',
        );
      }
    });

    test('and the body reads such a message exactly as it always did', () {
      final NotificationBody body = NotificationBody.fromJson(
          <String, dynamic>{'type': 'order', 'order_id': 4217});

      expect(body.type, 'order');
      expect(body.orderId, 4217);
      expect(body.storefront, isNull);
    });
  });

  group('with storefronts off, a push that names a storefront still changes nothing', () {
    test('even one the server lists', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'KW'},
            enabled: false),
        isNull,
      );
    });
  });

  group('with storefronts on', () {
    test('a push about another market the server lists opens in that market', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'KW'})?.code,
        'KW',
      );
    });

    test('the code is read however it was spelled', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'kw'})?.code,
        'KW',
      );
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': ' Kw '})?.code,
        'KW',
      );
    });

    test('a push about the market the customer is already on changes nothing', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'SA'})?.code,
        isNull,
      );
    });

    test('a push about a market the server does not list changes nothing', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'QA'}),
        isNull,
        reason: 'Qatar is a storefront this app knows but the server has not listed',
      );
    });

    test('a push about a market this app has never heard of changes nothing', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'ZZ'}),
        isNull,
      );
    });

    test('the storefront answered is the server\'s own entry, with its currency and whether it may sell', () {
      final StorefrontCountry? target = PushStorefrontTarget.of(
        NotificationBody.fromJson(
            <String, dynamic>{'type': 'order', 'storefront': 'AE'}),
        current: StorefrontCountry.saudiArabia,
        available: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          const StorefrontCountry(
              code: 'AE', path: '/ae', currency: 'AED', sellable: true),
        ],
        enabled: true,
      );

      expect(target?.code, 'AE');
      expect(target?.currency, 'AED');
      expect(target?.sellable, isTrue);
    });

    test('nothing is answered while the server has listed nothing at all', () {
      expect(
        targetOf(<String, dynamic>{'type': 'order', 'storefront': 'KW'},
            available: const <StorefrontCountry>[]),
        isNull,
      );
    });
  });

  group('every kind of message carries its storefront through the helper\'s own reader', () {
    // The helper builds a body per kind of message, in seven branches. The storefront is read once for all of them; a branch that read it
    // for itself and was forgotten would route a push about another market on whatever storefront the customer happens to be on. This was
    // a real defect in the first draft of this branch, found by the test below.
    for (final Map<String, dynamic> message in <Map<String, dynamic>>[
      <String, dynamic>{'type': 'order', 'order_id': '4217'},
      <String, dynamic>{'type': 'wallet'},
      <String, dynamic>{'type': 'notification'},
      <String, dynamic>{'type': 'block'},
      <String, dynamic>{'type': 'chatting', 'message_key': 'a message'},
      <String, dynamic>{
        'type': 'product_restock_update',
        'product_id': 9,
        'slug': 'a-product',
      },
      <String, dynamic>{
        'type': 'referral_code_used',
        'product_id': 9,
        'slug': 'a-product',
      },
    ]) {
      test('a ${message['type']} push names its market', () {
        expect(
          NotificationHelper.convertNotification(<String, dynamic>{
            ...message,
            'storefront': 'KW',
          }).storefront,
          'KW',
        );
      });

      test('and a ${message['type']} push that names none reads as none', () {
        expect(
          NotificationHelper.convertNotification(message).storefront,
          isNull,
        );
      });
    }
  });

  group('the local notification payload carries the storefront through', () {
    test('a body written to the payload and read back keeps the market it was about', () {
      final String payload = jsonEncode(
          NotificationBody(type: 'order', orderId: 7, storefront: 'KW')
              .toJson());

      expect(NotificationBody.fromJson(jsonDecode(payload)).storefront, 'KW');
    });

    test('and a body about no market reads back as no market', () {
      final String payload =
          jsonEncode(NotificationBody(type: 'order', orderId: 7).toJson());

      expect(NotificationBody.fromJson(jsonDecode(payload)).storefront, isNull);
    });
  });
}
