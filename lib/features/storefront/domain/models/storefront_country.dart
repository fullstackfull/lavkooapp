class StorefrontCountry {
  final String code;
  final String path;
  final String currency;

  /// Whether the storefront may take payment. A storefront the server has not approved is browse-only: it can be listed and
  /// browsed, and checkout is not offered for it. Being listed never implies permission to pay.
  final bool sellable;

  const StorefrontCountry({
    required this.code,
    required this.path,
    required this.currency,
    this.sellable = false,
  });

  static const StorefrontCountry saudiArabia = StorefrontCountry(
    code: 'SA',
    path: '/sa',
    currency: 'SAR',
    sellable: true,
  );
  static const StorefrontCountry unitedArabEmirates =
      StorefrontCountry(code: 'AE', path: '/ae', currency: 'AED');
  static const StorefrontCountry kuwait =
      StorefrontCountry(code: 'KW', path: '/kw', currency: 'KWD');
  static const StorefrontCountry qatar =
      StorefrontCountry(code: 'QA', path: '/qa', currency: 'QAR');
  static const StorefrontCountry bahrain =
      StorefrontCountry(code: 'BH', path: '/bh', currency: 'BHD');
  static const StorefrontCountry oman =
      StorefrontCountry(code: 'OM', path: '/om', currency: 'OMR');

  static const StorefrontCountry defaultCountry = saudiArabia;

  static const List<StorefrontCountry> all = [
    saudiArabia,
    unitedArabEmirates,
    kuwait,
    qatar,
    bahrain,
    oman,
  ];

  static final RegExp _countryCodePattern = RegExp(r'^[A-Z]{2}$');

  /// Reads one entry of `GET /api/v1/storefronts`: `{country, path, currency, is_default, sellable}`.
  ///
  /// The server sends `path` without a leading slash and leaves `sellable` out while storefronts are off there. A `sellable` that is
  /// missing or is not a boolean keeps the built-in answer for that country (Saudi Arabia may sell, every other storefront is
  /// browse-only), so an answer that says nothing never opens a storefront.
  ///
  /// Null when the entry cannot be used: it is not an object, it has no two-letter country code, or it names a country this app does not
  /// know and gives no currency.
  static StorefrontCountry? tryParse(Object? entry) {
    if (entry is! Map) {
      return null;
    }

    final Object? rawCode = entry['country'];
    final String code = rawCode is String ? rawCode.trim().toUpperCase() : '';
    if (!_countryCodePattern.hasMatch(code)) {
      return null;
    }

    final StorefrontCountry? builtIn = _builtInFor(code);
    final String? currency =
        _text(entry['currency'])?.toUpperCase() ?? builtIn?.currency;
    if (currency == null) {
      return null;
    }

    final Object? rawSellable = entry['sellable'];

    return StorefrontCountry(
      code: code,
      path: _path(entry['path']) ?? '/${code.toLowerCase()}',
      currency: currency,
      sellable:
          rawSellable is bool ? rawSellable : (builtIn?.sellable ?? false),
    );
  }

  /// Reads the whole answer of `GET /api/v1/storefronts`: an object whose `storefronts` is a list of entries. Entries that cannot be
  /// read are left out. Any other shape gives an empty list, so an answer that cannot be understood never looks like a list of
  /// storefronts.
  static List<StorefrontCountry> parseList(Object? body) {
    if (body is! Map) {
      return const <StorefrontCountry>[];
    }

    final Object? entries = body['storefronts'];
    if (entries is! List) {
      return const <StorefrontCountry>[];
    }

    final List<StorefrontCountry> storefronts = <StorefrontCountry>[];
    for (final Object? entry in entries) {
      final StorefrontCountry? storefront = tryParse(entry);
      if (storefront != null) {
        storefronts.add(storefront);
      }
    }

    return storefronts;
  }

  /// The shape [tryParse] reads, so a stored list is read back by the code that reads the server's answer.
  Map<String, Object> toJson() => <String, Object>{
        'country': code,
        'path': path,
        'currency': currency,
        'sellable': sellable,
      };

  static StorefrontCountry? _builtInFor(String code) {
    for (final StorefrontCountry storefront in all) {
      if (storefront.code == code) {
        return storefront;
      }
    }

    return null;
  }

  static String? _text(Object? value) {
    if (value is! String) {
      return null;
    }

    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _path(Object? value) {
    final String? text = _text(value);
    if (text == null) {
      return null;
    }

    final String withoutLeadingSlashes = text.replaceFirst(RegExp(r'^/+'), '');

    return withoutLeadingSlashes.isEmpty ? null : '/$withoutLeadingSlashes';
  }
}
