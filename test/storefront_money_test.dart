import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_money.dart';

/// GCC-05, J-05: a storefront with its own currency writes its prices as they were priced, with the decimals of that currency (ISO 4217)
/// and no conversion. The strings below are what a customer reads; they are written by hand, not computed by the code under test.
void main() {
  group('the decimals of a currency', () {
    test('three for the Kuwaiti and Bahraini dinar and the Omani rial', () {
      expect(StorefrontMoney.decimalsOf('KWD'), 3);
      expect(StorefrontMoney.decimalsOf('BHD'), 3);
      expect(StorefrontMoney.decimalsOf('OMR'), 3);
    });

    test('two for the riyal, the dirham and the Qatari riyal', () {
      expect(StorefrontMoney.decimalsOf('SAR'), 2);
      expect(StorefrontMoney.decimalsOf('AED'), 2);
      expect(StorefrontMoney.decimalsOf('QAR'), 2);
    });

    test('a code is read whatever its case and spaces, and an unknown one has two', () {
      expect(StorefrontMoney.decimalsOf(' kwd '), 3);
      expect(StorefrontMoney.decimalsOf('xyz'), 2);
      expect(StorefrontMoney.decimalsOf(''), 2);
    });
  });

  group('an amount without a symbol', () {
    test('every storefront writes the decimals of its own currency', () {
      expect(StorefrontMoney.formatWithoutSymbol(12.5, currencyCode: 'SAR'),
          '12.50');
      expect(StorefrontMoney.formatWithoutSymbol(12.5, currencyCode: 'AED'),
          '12.50');
      expect(StorefrontMoney.formatWithoutSymbol(12.5, currencyCode: 'KWD'),
          '12.500');
      expect(StorefrontMoney.formatWithoutSymbol(12.5, currencyCode: 'QAR'),
          '12.50');
      expect(StorefrontMoney.formatWithoutSymbol(12.5, currencyCode: 'BHD'),
          '12.500');
      expect(StorefrontMoney.formatWithoutSymbol(12.5, currencyCode: 'OMR'),
          '12.500');
    });

    test('thousands are grouped with a comma, in two decimals and in three', () {
      expect(
          StorefrontMoney.formatWithoutSymbol(1234567.891, currencyCode: 'KWD'),
          '1,234,567.891');
      expect(
          StorefrontMoney.formatWithoutSymbol(1234567.891, currencyCode: 'AED'),
          '1,234,567.89');
      expect(StorefrontMoney.formatWithoutSymbol(999, currencyCode: 'OMR'),
          '999.000');
      expect(StorefrontMoney.formatWithoutSymbol(1000, currencyCode: 'QAR'),
          '1,000.00');
      expect(StorefrontMoney.formatWithoutSymbol(100000, currencyCode: 'SAR'),
          '100,000.00');
    });

    test('an amount rounds to the decimals of its currency', () {
      expect(StorefrontMoney.formatWithoutSymbol(3.5054, currencyCode: 'KWD'),
          '3.505');
      expect(StorefrontMoney.formatWithoutSymbol(3.5056, currencyCode: 'KWD'),
          '3.506');
      expect(StorefrontMoney.formatWithoutSymbol(10.126, currencyCode: 'SAR'),
          '10.13');
    });

    test('a negative amount keeps its sign, and one that rounds to zero has none', () {
      expect(StorefrontMoney.formatWithoutSymbol(-3.5, currencyCode: 'BHD'),
          '-3.500');
      expect(StorefrontMoney.formatWithoutSymbol(-1234.5, currencyCode: 'AED'),
          '-1,234.50');
      expect(StorefrontMoney.formatWithoutSymbol(-0.0004, currencyCode: 'KWD'),
          '0.000');
      expect(StorefrontMoney.formatWithoutSymbol(-0.004, currencyCode: 'SAR'),
          '0.00');
    });

    test('a missing amount, and one that is not a number, are written as zero', () {
      expect(StorefrontMoney.formatWithoutSymbol(null, currencyCode: 'KWD'),
          '0.000');
      expect(
          StorefrontMoney.formatWithoutSymbol(double.nan, currencyCode: 'SAR'),
          '0.00');
      expect(
          StorefrontMoney.formatWithoutSymbol(double.infinity,
              currencyCode: 'OMR'),
          '0.000');
      expect(StorefrontMoney.formatWithoutSymbol(0, currencyCode: 'QAR'),
          '0.00');
    });
  });

  group('an amount with its currency mark', () {
    test('the mark is on the left by default and a mark of letters is set apart', () {
      expect(
          StorefrontMoney.format(12.5, currencyCode: 'KWD', symbol: 'KD'),
          'KD 12.500');
      expect(
          StorefrontMoney.format(1234.5, currencyCode: 'AED', symbol: 'AED'),
          'AED 1,234.50');
    });

    test('the mark can be on the right', () {
      expect(
          StorefrontMoney.format(12.5,
              currencyCode: 'OMR', symbol: 'OMR', symbolOnRight: true),
          '12.500 OMR');
      expect(
          StorefrontMoney.format(40,
              currencyCode: 'QAR', symbol: 'QR', symbolOnRight: true),
          '40.00 QR');
    });

    test('an Arabic mark is set apart as well, and a sign is not', () {
      expect(
          StorefrontMoney.format(12.5, currencyCode: 'KWD', symbol: 'د.ك'),
          'د.ك 12.500');
      expect(StorefrontMoney.format(12.5, currencyCode: 'USD', symbol: r'$'),
          r'$12.50');
    });

    test('the code stands in when the server sent no symbol', () {
      expect(StorefrontMoney.format(12.5, currencyCode: 'bhd'), 'BHD 12.500');
      expect(StorefrontMoney.format(12.5, currencyCode: 'BHD', symbol: '  '),
          'BHD 12.500');
      expect(
          StorefrontMoney.format(12.5,
              currencyCode: 'SAR', symbolOnRight: true),
          '12.50 SAR');
    });

    test('a missing amount is zero with its mark', () {
      expect(StorefrontMoney.format(null, currencyCode: 'KWD', symbol: 'KD'),
          'KD 0.000');
    });
  });

  group('which storefronts this writes', () {
    test('none while storefronts are off', () {
      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(StorefrontMoney.writesPricesOf(storefront, enabled: false),
            isFalse,
            reason: storefront.code);
      }
    });

    test('every storefront but the default one while they are on', () {
      expect(
          StorefrontMoney.writesPricesOf(StorefrontCountry.saudiArabia,
              enabled: true),
          isFalse,
          reason: 'the default storefront keeps the platform money');
      for (final StorefrontCountry storefront in [
        StorefrontCountry.unitedArabEmirates,
        StorefrontCountry.kuwait,
        StorefrontCountry.qatar,
        StorefrontCountry.bahrain,
        StorefrontCountry.oman,
      ]) {
        expect(StorefrontMoney.writesPricesOf(storefront, enabled: true),
            isTrue,
            reason: storefront.code);
      }
    });

    test('a storefront reads the decimals of the currency it trades in', () {
      final Map<String, int> decimals = {
        for (final StorefrontCountry storefront in StorefrontCountry.all)
          storefront.code: StorefrontMoney.decimalsOf(storefront.currency),
      };

      expect(decimals, {'SA': 2, 'AE': 2, 'KW': 3, 'QA': 2, 'BH': 3, 'OM': 3});
    });
  });
}
