/// What the server says the money of this request is (GCC-05, J-05, B-03).
///
/// `StorefrontCurrency::apiMoney()` adds a `storefront_money` block to `GET /api/v1/config`, to the price bounds of the product list and
/// to the product details, carrying the currency the storefront trades in, that currency's mark, how many decimals the shop writes it
/// with, and which side the mark goes. The block is absent entirely while storefronts are off there and on the default storefront, which
/// keep the platform's own money — so a shop that does not send it is read exactly as it is read today, and so is every build of this app
/// older than this one.
///
/// Why the app reads it rather than deciding for itself: the decimals of a market's money are the shop's setting, and this app was
/// keeping its own copy of them in a table of three currency codes. Two copies of one business rule drift, and the one that drifts is
/// always the client: a market whose currency neither table knows — or one whose decimals an operator changes — was written one way by
/// the website and the server's own `formatted` string and another way by the app. The server's number wins where it sends one; the
/// built-in table is the answer for every shop that sends none.
class StorefrontMoneyBlock {
  const StorefrontMoneyBlock({
    required this.currency,
    this.symbol,
    this.decimals,
    this.symbolOnRight,
  });

  /// The currency the storefront serving the request trades in, upper-cased. Never empty: a block that named none is read as no block.
  final String currency;

  /// The mark the shop writes beside an amount of that currency, or null when it sent none or sent only spaces. The currency code stands
  /// in for a missing mark, which is what the writer already does.
  final String? symbol;

  /// How many decimals the shop writes that currency with, or null when it named none the app can use. Null means "use the built-in
  /// table", so a shop that sends nonsense is no worse off than a shop that sends nothing.
  final int? decimals;

  /// Whether the mark goes after the number, or null when the shop named no side. Null means the global `currency_symbol_position`
  /// stands, which is where this answer came from before.
  final bool? symbolOnRight;

  /// No currency is written with more decimals than this (ISO 4217's widest is four), so a number beyond it is a mistake and not a
  /// market this app has not met.
  static const int _mostDecimalsACurrencyHas = 4;

  /// Whether this block is the money of [currencyCode].
  ///
  /// Asked before the block is used, because the block names the currency of the REQUEST and an amount is not always in it: the amounts of
  /// an order are written in the currency the order was sold in (J-13.1), which is another market's whenever the customer has moved. A
  /// block read for the wrong currency would put this market's decimals on another market's money.
  bool isMoneyOf(String currencyCode) =>
      currency == currencyCode.trim().toUpperCase();

  /// Reads the block out of a server answer, or null for anything that is not one.
  ///
  /// Total and never throwing: the config response is the shop's and not ours, and an answer this app cannot read must leave it writing
  /// money the way it wrote it before rather than fail.
  static StorefrontMoneyBlock? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }

    final String currency = '${json['currency'] ?? ''}'.trim().toUpperCase();
    if (currency.isEmpty) {
      return null;
    }

    return StorefrontMoneyBlock(
      currency: currency,
      symbol: _text(json['symbol']),
      decimals: _decimals(json['decimals']),
      symbolOnRight: _side(json['symbol_position']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) {
      return null;
    }

    final String text = '$value'.trim();

    return text.isEmpty ? null : text;
  }

  /// A count of decimals, written as a number or as a number in text, that a currency could really have. Everything else is null.
  static int? _decimals(Object? value) {
    final int? decimals =
        value is int ? value : int.tryParse('${value ?? ''}'.trim());

    return decimals != null &&
            decimals >= 0 &&
            decimals <= _mostDecimalsACurrencyHas
        ? decimals
        : null;
  }

  /// The side of the mark, as the shop names it. A word this app does not know leaves the global setting in force rather than guessing a
  /// side, because a mark on the wrong side of a number is read by a customer and noticed.
  static bool? _side(Object? value) {
    final String side = '${value ?? ''}'.trim().toLowerCase();

    return switch (side) {
      'right' => true,
      'left' => false,
      _ => null,
    };
  }
}
