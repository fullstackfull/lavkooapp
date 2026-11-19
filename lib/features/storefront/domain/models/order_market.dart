import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

/// What an order says it was sold in (GCC-05, J-13.1): the country of the storefront it was placed on, the currency its amounts are in and the
/// rate recorded with them. The server writes the three together on the paths that record them, which are the checkout of the site and of both
/// APIs and the POS of the seller app, from the products the order holds, and never writes them again, so an order keeps the money it was sold
/// in whatever the customer chooses afterwards. An order saved before the columns existed, while storefronts were off, with products of more
/// than one country, or by a path that does not record them (the two POS screens of the panel, and an order a sales channel writes straight
/// into the table) carries none of them. One whose currency the server could not vouch for carries the country alone: the default storefront
/// of a platform that converts from a base currency, where the currency an order is shown in is the customer's own choice, a storefront whose
/// currency was not active, and an order saved by a request served from another storefront.
///
/// The amounts of an order are stored in the currency it records and the rate recorded with them is one, so an amount written in that currency
/// is written as it is stored, never multiplied by a rate. A record whose rate is not one is not written in its currency, because that would
/// put an amount beside a currency it is not in; such an order, and one that records no currency at all, is written the way the platform
/// writes an amount, which does multiply by the rate of the currency the customer chose (`PriceConverter.convertOrderPrice`).
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

  /// The currency the amounts of the order are in, whatever storefront it names, or null while storefronts are off, when the order records no
  /// currency and when it records a rate that is not the one its amounts are stored at. Whether this is the currency a screen writes them in
  /// is [currencyToWrite], which the storefront the customer is on has a say in.
  String? currencyOfItsAmounts({bool enabled = StorefrontConfig.enabled}) =>
      enabled && currencyRate == _rateOfStoredAmounts ? currencyCode : null;

  /// The currency to write the amounts of the order in, or null when they are written as the app always has: storefronts are off, the order is
  /// one of the default storefront, which keeps the platform's money, or it does not carry all of a country, a currency and the rate one.
  String? currencyToWrite({bool enabled = StorefrontConfig.enabled}) {
    final String? storefront = country;

    return storefront != null &&
            storefront != StorefrontCountry.defaultCountry.code
        ? currencyOfItsAmounts(enabled: enabled)
        : null;
  }

  /// Whether the order records a rate that is not the one its amounts are stored at, so the app cannot read them as the money of the currency
  /// the order names, nor as the money of any storefront: a row of a platform that wrote the two columns of its own before the storefronts
  /// did.
  bool recordsAnotherRate({bool enabled = StorefrontConfig.enabled}) =>
      enabled && currencyRate != null && currencyRate != _rateOfStoredAmounts;

  static String? _codeOf(Object? value, {required RegExp pattern}) {
    final String code = value is String ? value.trim().toUpperCase() : '';

    return pattern.hasMatch(code) ? code : null;
  }

  static double? _rateOf(Object? value) {
    final double? rate = double.tryParse('$value');

    return rate != null && rate.isFinite ? rate : null;
  }
}
