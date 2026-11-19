import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

/// What an order says it was sold in (GCC-05, J-13.1): the country of the storefront it was placed on, the currency its amounts are in and the
/// rate recorded with them. The server writes the three together when it saves the order, from the products the order holds, and never writes
/// them again, so an order keeps the money it was sold in whatever the customer chooses afterwards. An order saved before that, while
/// storefronts were off, or with products of more than one country carries none of them. One whose currency the server could not vouch for
/// carries the country alone: the default storefront of a platform that converts from a base currency, where the currency an order is shown in
/// is the customer's own choice, a storefront whose currency was not active, and an order saved by a request served from another storefront.
///
/// The amounts of an order are stored in its own currency and the rate recorded with them is one, so an amount is written as it is stored: the
/// app never multiplies an amount by a rate. A record whose rate is not one is not written in its currency, because that would put an amount
/// beside a currency it is not in.
class OrderMarket {
  const OrderMarket({this.country, this.currencyCode, this.currencyRate});

  /// The two-letter code of the country, in capitals (`KW`), as the storefront list writes it.
  final String? country;

  /// The code of the currency the amounts of the order are in (`KWD`).
  final String? currencyCode;

  /// What turns an amount of the order, as stored, into [currencyCode]; one for every order the server records.
  final double? currencyRate;

  static const double _rateOfStoredAmounts = 1;

  static final RegExp _countryCode = RegExp(r'^[A-Z]{2}$');
  static final RegExp _isoCurrencyCode = RegExp(r'^[A-Z]{3}$');

  /// Reads the keys the server puts on an order, `storefront_country`, `currency_code` and `currency_rate`. What is not what the server writes
  /// there, a key that is missing included, reads as nothing, so an order without them is read as every order was before.
  factory OrderMarket.fromJson(Map<String, dynamic> json) => OrderMarket(
        country: _codeOf(json['storefront_country'], pattern: _countryCode),
        currencyCode: _codeOf(json['currency_code'], pattern: _isoCurrencyCode),
        currencyRate: _rateOf(json['currency_rate']),
      );

  /// The country to write beside the order, or null while storefronts are off and when the order names none.
  String? countryToShow({bool enabled = StorefrontConfig.enabled}) =>
      enabled ? country : null;

  /// The currency to write the amounts of the order in, or null when they are written as the app always has: storefronts are off, the order is
  /// one of the default storefront, which keeps the platform's money, or it does not carry all of a country, a currency and the rate one.
  String? currencyToWrite({bool enabled = StorefrontConfig.enabled}) {
    final String? storefront = country;

    return enabled &&
            storefront != null &&
            storefront != StorefrontCountry.defaultCountry.code &&
            currencyRate == _rateOfStoredAmounts
        ? currencyCode
        : null;
  }

  static String? _codeOf(Object? value, {required RegExp pattern}) {
    final String code = value is String ? value.trim().toUpperCase() : '';

    return pattern.hasMatch(code) ? code : null;
  }

  static double? _rateOf(Object? value) {
    final double? rate = double.tryParse('$value');

    return rate != null && rate.isFinite ? rate : null;
  }
}
