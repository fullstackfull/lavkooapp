import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_money_block.dart';
import 'package:syriapharmacy/features/storefront/storefront_money.dart';

/// GCC-05, J-05, B-03: the app reads the money the server names for the market it is on, instead of keeping a second copy of the shop's
/// decimals in a table of its own.
///
/// `StorefrontCurrency::apiMoney()` adds `storefront_money` to `GET /api/v1/config`, to the price bounds of the product list and to the
/// product details. The block is absent for every shop with storefronts off and for the default storefront of every shop, so the cases
/// below pin both halves: what a block changes, and that no block changes nothing.
///
/// Nothing here reads the build flag — a server answer is parsed the same way in both builds — so the file runs once per build and says
/// the same thing.
void main() {
  group('the block the server sends', () {
    test('is read with its currency, mark, decimals and side', () {
      final StorefrontMoneyBlock? block = StorefrontMoneyBlock.fromJson({
        'currency': 'KWD',
        'symbol': 'KD',
        'decimals': 3,
        'symbol_position': 'right',
      });

      expect(block, isNotNull);
      expect(block!.currency, 'KWD');
      expect(block.symbol, 'KD');
      expect(block.decimals, 3);
      expect(block.symbolOnRight, isTrue);
    });

    test('names its currency in upper case, however the shop spelled it', () {
      expect(
          StorefrontMoneyBlock.fromJson({'currency': ' bhd '})!.currency, 'BHD');
      expect(StorefrontMoneyBlock.fromJson({'currency': 'bhd'})!.isMoneyOf('BHD'),
          isTrue);
      expect(
          StorefrontMoneyBlock.fromJson({'currency': 'BHD'})!.isMoneyOf(' bhd '),
          isTrue);
    });

    test('is the money of its own currency and of no other', () {
      final StorefrontMoneyBlock block =
          StorefrontMoneyBlock.fromJson({'currency': 'KWD', 'decimals': 3})!;

      expect(block.isMoneyOf('KWD'), isTrue);
      expect(block.isMoneyOf('SAR'), isFalse);
      expect(block.isMoneyOf(''), isFalse);
    });

    test('reads decimals written as text, and as a number', () {
      expect(StorefrontMoneyBlock.fromJson({'currency': 'KWD', 'decimals': '3'})!
          .decimals, 3);
      expect(StorefrontMoneyBlock.fromJson({'currency': 'JPY', 'decimals': 0})!
          .decimals, 0);
    });

    test('and puts the mark on the left when the shop says left', () {
      expect(
          StorefrontMoneyBlock.fromJson(
              {'currency': 'AED', 'symbol_position': 'LEFT'})!.symbolOnRight,
          isFalse);
    });
  });

  group('an answer the app cannot use leaves the money written as before', () {
    test('a block that is not an object, or names no currency, is no block', () {
      expect(StorefrontMoneyBlock.fromJson(null), isNull);
      expect(StorefrontMoneyBlock.fromJson('KWD'), isNull);
      expect(StorefrontMoneyBlock.fromJson(<Object>[]), isNull);
      expect(StorefrontMoneyBlock.fromJson(<String, Object?>{}), isNull);
      expect(StorefrontMoneyBlock.fromJson({'currency': ''}), isNull);
      expect(StorefrontMoneyBlock.fromJson({'currency': '   '}), isNull);
      expect(StorefrontMoneyBlock.fromJson({'decimals': 3}), isNull);
    });

    test('decimals that no currency could have are read as none named', () {
      for (final Object? sent in <Object?>[null, '', 'three', -1, 5, 99, 2.5]) {
        expect(
            StorefrontMoneyBlock.fromJson({
              'currency': 'KWD',
              'decimals': sent,
            })!.decimals,
            isNull,
            reason: 'decimals sent as $sent');
      }
    });

    test('a mark of nothing but spaces, and a side the app does not know, are read as none named',
        () {
      final StorefrontMoneyBlock block = StorefrontMoneyBlock.fromJson({
        'currency': 'OMR',
        'symbol': '   ',
        'symbol_position': 'middle',
      })!;

      expect(block.symbol, isNull);
      expect(block.symbolOnRight, isNull);
    });
  });

  group('the writer takes the number the server named', () {
    test('and falls back to the decimals of the currency when none was named', () {
      expect(StorefrontMoney.decimalsOf('KWD'), 3);
      expect(StorefrontMoney.decimalsOf('KWD', named: null), 3);
      expect(StorefrontMoney.decimalsOf('SAR'), 2);
      expect(StorefrontMoney.decimalsOf('xyz'), 2);
    });

    test('so a currency this app has never met is written the way the shop writes it',
        () {
      expect(StorefrontMoney.decimalsOf('JOD', named: 3), 3);
      expect(StorefrontMoney.decimalsOf('JPY', named: 0), 0);
      expect(
          StorefrontMoney.formatWithoutSymbol(1234.5,
              currencyCode: 'JOD', decimals: 3),
          '1,234.500');
      expect(
          StorefrontMoney.formatWithoutSymbol(1234.5,
              currencyCode: 'JPY', decimals: 0),
          '1,235');
      expect(
          StorefrontMoney.format(1234.5,
              currencyCode: 'JOD', symbol: 'JD', decimals: 3),
          'JD 1,234.500');
    });

    test('and the app table still answers for every shop that names nothing', () {
      expect(StorefrontMoney.formatWithoutSymbol(1234.5, currencyCode: 'KWD'),
          '1,234.500');
      expect(StorefrontMoney.formatWithoutSymbol(1234.5, currencyCode: 'AED'),
          '1,234.50');
      expect(
          StorefrontMoney.format(1234.5, currencyCode: 'AED', symbol: 'AED'),
          'AED 1,234.50');
    });
  });

  group('the config of a shop', () {
    test('carries the block when the shop sends one', () {
      final ConfigModel config = ConfigModel.fromJson(<String, dynamic>{
        'currency_symbol_position': 'left',
        'storefront_money': {
          'currency': 'KWD',
          'symbol': 'KD',
          'decimals': 3,
          'symbol_position': 'right',
        },
      });

      expect(config.storefrontMoney, isNotNull);
      expect(config.storefrontMoney!.currency, 'KWD');
      expect(config.storefrontMoney!.decimals, 3);
      expect(config.storefrontMoney!.symbolOnRight, isTrue);
      expect(config.currencySymbolPosition, 'left');
    });

    test('and carries none when it does not, which is every shop today', () {
      expect(
          ConfigModel.fromJson(<String, dynamic>{
            'currency_symbol_position': 'right',
          }).storefrontMoney,
          isNull);
      expect(
          ConfigModel.fromJson(<String, dynamic>{
            'storefront_money': <String, dynamic>{},
          }).storefrontMoney,
          isNull);
    });
  });
}
