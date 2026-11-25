/// What the shop quoted for customs duty on this basket (H1-09).
///
/// Four states, and the one that matters most is `not_quoted`: nobody has written a duty rule for that route, so the shop cannot say what
/// is owed. A zero in that place would read as "these goods cross free", which is a claim the shop has no authority to make, so the app
/// shows the sentence the server sends rather than a figure of nought.
///
/// `notice` arrives already in the customer's language, because the server writes it for the `lang` header every request carries. Nothing
/// here is translated and no key is kept in step.
class CustomsDuty {
  /// Nobody has written a rule for this route: no amount may be claimed, not even zero.
  static const String notQuoted = 'not_quoted';

  /// Quotable and nothing is payable: a domestic basket, or one under the destination's threshold.
  static const String none = 'none';

  /// An amount is payable, by the named payer.
  static const String payable = 'payable';

  final String kind;
  final double amount;
  final String? payer;
  final double basis;
  final String? notice;

  const CustomsDuty({required this.kind, this.amount = 0, this.payer, this.basis = 0, this.notice});

  bool get isPayable => kind == payable;

  /// The quote in the server's answer, or null when there is nothing to say -- which is what a basket that crosses no border answers, and
  /// what a shop with duty switched off answers. A caller that reads null draws no line at all. It never throws, whatever the body is.
  static CustomsDuty? fromBody(Object? body) {
    final Object? quote = body is Map ? body['customs_duty'] : null;

    if (quote is! Map) {
      return null;
    }

    final String kind = '${quote['kind'] ?? ''}'.trim();

    if (kind.isEmpty) {
      return null;
    }

    return CustomsDuty(
      kind: kind,
      amount: _number(quote['amount']),
      payer: _text(quote['payer']),
      basis: _number(quote['basis']),
      notice: _text(quote['notice']),
    );
  }

  /// PHP writes a whole float without its decimal point, so 5.0 arrives as `5`: read as a number, never cast to double.
  static double _number(Object? value) => value == null ? 0 : (double.tryParse('$value') ?? 0);

  static String? _text(Object? value) {
    final String text = value == null ? '' : '$value'.trim();

    return text.isEmpty ? null : text;
  }
}
