import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';

/// The list the server answers with is read defensively. Whatever it says, an answer that cannot be understood must never open a
/// storefront: a missing or unreadable `sellable` keeps the built-in answer, where only Saudi Arabia may sell.
void main() {
  String describe(StorefrontCountry storefront) =>
      '${storefront.code} ${storefront.path} ${storefront.currency} '
      '${storefront.sellable ? 'sellable' : 'browse-only'}';

  List<String> described(Object? body) =>
      StorefrontCountry.parseList(body).map(describe).toList();

  Map<String, Object> answerOf(List<Object?> entries) =>
      <String, Object>{'enabled': true, 'storefronts': entries};

  group('a complete answer', () {
    final Map<String, Object> completeAnswer = answerOf(<Object?>[
      <String, Object>{
        'country': 'SA',
        'path': 'sa',
        'currency': 'SAR',
        'is_default': true,
        'sellable': true,
      },
      <String, Object>{
        'country': 'AE',
        'path': 'ae',
        'currency': 'AED',
        'is_default': false,
        'sellable': true,
      },
      <String, Object>{
        'country': 'OM',
        'path': 'om',
        'currency': 'OMR',
        'is_default': false,
        'sellable': false,
      },
    ]);

    test('is read entry by entry, in the order the server sent it', () {
      expect(described(completeAnswer), <String>[
        'SA /sa SAR sellable',
        'AE /ae AED sellable',
        'OM /om OMR browse-only',
      ]);
    });

    test(
        'keeps the server\'s word even for the storefront that sells by default',
        () {
      final List<StorefrontCountry> storefronts = StorefrontCountry.parseList(
        answerOf(<Object?>[
          <String, Object>{
            'country': 'SA',
            'path': 'sa',
            'currency': 'SAR',
            'sellable': false,
          },
        ]),
      );

      expect(storefronts.single.sellable, isFalse);
    });

    test('gives the path a leading slash, like the built-in storefronts', () {
      final List<StorefrontCountry> storefronts =
          StorefrontCountry.parseList(completeAnswer);

      for (final StorefrontCountry storefront in storefronts) {
        expect(storefront.path, '/${storefront.code.toLowerCase()}');
      }
    });
  });

  group('a missing sellable', () {
    test(
        'keeps Saudi Arabia sellable, as the server leaves the key out while storefronts are off',
        () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{
            'country': 'SA',
            'path': 'sa',
            'currency': 'SAR',
            'is_default': true,
          },
        ])),
        <String>['SA /sa SAR sellable'],
      );
    });

    test('leaves every other storefront browse-only', () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'country': 'AE', 'path': 'ae', 'currency': 'AED'},
          <String, Object>{'country': 'KW', 'path': 'kw', 'currency': 'KWD'},
        ])),
        <String>['AE /ae AED browse-only', 'KW /kw KWD browse-only'],
      );
    });

    test('is the same as a sellable that is not a boolean', () {
      for (final Object? unreadable in <Object?>[
        'true',
        'yes',
        1,
        0,
        null,
        <Object?>[],
      ]) {
        final List<StorefrontCountry> storefronts = StorefrontCountry.parseList(
          answerOf(<Object?>[
            <String, Object?>{
              'country': 'AE',
              'path': 'ae',
              'currency': 'AED',
              'sellable': unreadable,
            },
            <String, Object?>{
              'country': 'SA',
              'path': 'sa',
              'currency': 'SAR',
              'sellable': unreadable,
            },
          ]),
        );

        expect(storefronts.map((storefront) => storefront.sellable),
            <bool>[false, true],
            reason: 'sellable: $unreadable');
      }
    });

    test('never opens a storefront that an unknown country names', () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'country': 'EG', 'currency': 'EGP'},
        ])),
        <String>['EG /eg EGP browse-only'],
      );
    });
  });

  group('an entry that is not complete', () {
    test(
        'takes the path and the currency of a built-in storefront when it leaves them out',
        () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'country': 'QA', 'sellable': true},
        ])),
        <String>['QA /qa QAR sellable'],
      );
    });

    test('reads the code regardless of case and surrounding spaces', () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{
            'country': ' bh ',
            'path': ' bh ',
            'currency': 'bhd'
          },
        ])),
        <String>['BH /bh BHD browse-only'],
      );
    });

    test('takes only one leading slash of the path', () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'country': 'AE', 'path': '//ae', 'currency': 'AED'},
          <String, Object>{'country': 'KW', 'path': '/kw', 'currency': 'KWD'},
        ])),
        <String>['AE /ae AED browse-only', 'KW /kw KWD browse-only'],
      );
    });

    test('falls back to the code for a path that is blank or not text', () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'country': 'AE', 'path': '  ', 'currency': 'AED'},
          <String, Object>{'country': 'KW', 'path': '/', 'currency': 'KWD'},
          <String, Object>{'country': 'QA', 'path': 7, 'currency': 'QAR'},
        ])),
        <String>[
          'AE /ae AED browse-only',
          'KW /kw KWD browse-only',
          'QA /qa QAR browse-only',
        ],
      );
    });

    test('is left out when it names an unknown country and gives no currency',
        () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'country': 'EG', 'path': 'eg'},
          <String, Object>{'country': 'AE', 'path': 'ae', 'currency': 'AED'},
        ])),
        <String>['AE /ae AED browse-only'],
      );
    });

    test('is left out when it has no usable country code', () {
      expect(
        described(answerOf(<Object?>[
          <String, Object>{'path': 'ae', 'currency': 'AED'},
          <String, Object>{'country': '', 'currency': 'AED'},
          <String, Object>{'country': '   ', 'currency': 'AED'},
          <String, Object>{'country': 'UAE', 'currency': 'AED'},
          <String, Object>{'country': 'A', 'currency': 'AED'},
          <String, Object>{'country': 'A1', 'currency': 'AED'},
          <String, Object>{'country': 784, 'currency': 'AED'},
        ])),
        isEmpty,
      );
    });

    test('is left out when it is not an object, and the others are still read',
        () {
      expect(
        described(answerOf(<Object?>[
          'AE',
          7,
          null,
          <Object?>['AE'],
          <String, Object>{'country': 'KW', 'path': 'kw', 'currency': 'KWD'},
        ])),
        <String>['KW /kw KWD browse-only'],
      );
    });
  });

  group('an answer of an unknown shape', () {
    test('is no list at all, whatever it is', () {
      for (final Object? body in <Object?>[
        null,
        'storefronts',
        42,
        true,
        <Object?>[],
        <Object?>[
          <String, Object>{'country': 'AE', 'currency': 'AED'},
        ],
        <String, Object>{},
        <String, Object>{'enabled': true},
        <String, Object?>{'storefronts': null},
        <String, Object>{'storefronts': 'AE'},
        <String, Object>{
          'storefronts': <String, Object>{'country': 'AE'}
        },
        <String, Object>{'data': <Object?>[]},
      ]) {
        expect(StorefrontCountry.parseList(body), isEmpty, reason: '$body');
      }
    });
  });

  group('an empty list', () {
    test('is an empty list, not a list of the built-in storefronts', () {
      expect(StorefrontCountry.parseList(answerOf(<Object?>[])), isEmpty);
    });
  });

  group('the stored shape', () {
    test('is read back by the code that reads the server\'s answer', () {
      final List<StorefrontCountry> original = <StorefrontCountry>[
        StorefrontCountry.saudiArabia,
        StorefrontCountry.unitedArabEmirates,
        const StorefrontCountry(
          code: 'KW',
          path: '/kw',
          currency: 'KWD',
          sellable: true,
        ),
      ];

      final List<StorefrontCountry> readBack = StorefrontCountry.parseList(
        <String, Object>{
          'storefronts':
              original.map((storefront) => storefront.toJson()).toList(),
        },
      );

      expect(readBack.map(describe), original.map(describe));
    });

    test('names the keys the server uses', () {
      expect(StorefrontCountry.saudiArabia.toJson(), <String, Object>{
        'country': 'SA',
        'path': '/sa',
        'currency': 'SAR',
        'sellable': true,
      });
    });
  });

  group('the built-in storefronts', () {
    test('are unchanged: only Saudi Arabia sells by default', () {
      expect(
        StorefrontCountry.all
            .where((storefront) => storefront.sellable)
            .map((storefront) => storefront.code),
        <String>['SA'],
      );
    });
  });
}
