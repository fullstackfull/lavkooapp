/// The one question the cart, the checkout and the payment entry points ask about the storefront the customer is on: may a sale start
/// here? Everything they do about the answer, showing the browse-only notice and switching off the buttons that place an order or start
/// a payment, is decided here, so no screen repeats the rule. Browsing, the cart and the orders a customer already has are not asked.
class CheckoutSaleGate {
  const CheckoutSaleGate({required this.storefrontMaySell});

  final bool storefrontMaySell;

  /// The notice is shown exactly while the storefront may not sell.
  bool get showsBrowseOnlyNotice => !storefrontMaySell;

  /// Whether a button that places an order or starts a payment may act. [otherwiseEnabled] is what the button decided on its own, for
  /// example that the terms are accepted and nothing is loading: the gate can take permission away and can never give it.
  bool permits({required bool otherwiseEnabled}) =>
      otherwiseEnabled && storefrontMaySell;
}
