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
}
