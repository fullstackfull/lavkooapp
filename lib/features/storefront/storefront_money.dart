import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';

/// How the prices of a storefront with its own currency are written (GCC-05, J-05).
///
/// A storefront other than the default one trades in its own currency and the server sends its amounts as they are priced, in that
/// currency: nothing is converted from another storefront's amounts. So an amount is shown as it came, with the decimals of its
/// currency (ISO 4217: three for the Kuwaiti and Bahraini dinar and the Omani rial, two for the rest), and never multiplied by the
/// exchange rate of a currency list that belongs to another storefront.
///
/// The default storefront keeps the platform's money and the way the app has always written it, so turning storefronts on changes
/// nothing for a Saudi customer. This class is only asked for while storefronts are on and the customer is on another storefront
/// ([writesPricesOf]), or to write the amounts of an order that says it was sold on one (`OrderMarket.currencyToWrite`); with them off it
/// is never reached.
class StorefrontMoney {
  const StorefrontMoney._();

  static const int _defaultDecimals = 2;

  static const Map<String, int> _decimalsByCurrency = {
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
  };

  static final RegExp _hasLetters = RegExp(r'[A-Za-z؀-ۿ]');

  /// Whether the prices of [storefront] are written by this class: storefronts are on and it is not the default storefront.
  static bool writesPricesOf(StorefrontCountry storefront,
          {required bool enabled}) =>
      enabled && storefront.code != StorefrontCountry.defaultCountry.code;

  /// The decimals an amount of a currency is written with: the number the server [named] for the money of this request when it named one,
  /// else three for KWD, BHD and OMR and two for every other currency.
  ///
  /// The server is preferred because the decimals a market's money is written with are the shop's setting (`decimal_point_settings`, which
  /// `StorefrontCurrency` answers per market), while the table below is this app's copy of ISO 4217. Two copies of one rule drift, and the
  /// client is the copy that drifts: a currency neither table knows, or decimals an operator changes, would be written one way by the
  /// website and the server's own text and another way here. The table is the answer for every shop that sends no block, which is every
  /// shop today.
  static int decimalsOf(String currencyCode, {int? named}) =>
      named ??
      _decimalsByCurrency[currencyCode.trim().toUpperCase()] ??
      _defaultDecimals;

  /// [amount] with the decimals of [currencyCode] and a comma between thousands, without a symbol. A missing, infinite or not-a-number
  /// amount is written as zero, and an amount that rounds to zero carries no minus sign.
  static String formatWithoutSymbol(double? amount,
      {required String currencyCode, int? decimals}) {
    final int places = decimalsOf(currencyCode, named: decimals);
    final double value =
        amount == null || amount.isNaN || amount.isInfinite ? 0 : amount;

    final String fixed = value.abs().toStringAsFixed(places);
    final List<String> parts = fixed.split('.');
    final String whole = _groupThousands(parts.first);
    final String number = parts.length > 1 ? '$whole.${parts[1]}' : whole;

    return value < 0 && double.parse(fixed) != 0 ? '-$number' : number;
  }

  /// [amount] with its currency mark on the left, or on the right when [symbolOnRight] is true. The mark is [symbol], or the currency
  /// code when the server sent none; a mark made of letters is set apart from the number by a space ("KWD 12.500", "12.500 KWD"), a
  /// sign such as a dollar is not.
  static String format(double? amount,
      {required String currencyCode,
      String? symbol,
      bool symbolOnRight = false,
      int? decimals}) {
    final String number = formatWithoutSymbol(amount,
        currencyCode: currencyCode, decimals: decimals);
    final String trimmed = symbol?.trim() ?? '';
    final String mark =
        trimmed.isEmpty ? currencyCode.trim().toUpperCase() : trimmed;
    final String gap = _hasLetters.hasMatch(mark) ? ' ' : '';

    return symbolOnRight ? '$number$gap$mark' : '$mark$gap$number';
  }

  static String _groupThousands(String digits) {
    final StringBuffer grouped = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(digits[index]);
    }

    return grouped.toString();
  }
}
