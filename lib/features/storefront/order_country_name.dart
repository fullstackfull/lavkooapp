import 'package:flutter/widgets.dart';
import 'package:syriapharmacy/features/storefront/domain/models/order_market.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_chooser_sheet.dart';

/// The country an order was sold in, written for the customer to read beside the order (GCC-05, J-13.1): its name in the language of the app,
/// or its code when the app has no name for it.
class OrderCountryName {
  const OrderCountryName._();

  /// Null while storefronts are off and when the order names no country, so a screen that has nothing to write leaves out the line.
  static String? of(BuildContext context, OrderMarket? market) {
    final String? country = market?.countryToShow();

    return country == null
        ? null
        : StorefrontChooserSheet.nameOf(context, country);
  }
}
