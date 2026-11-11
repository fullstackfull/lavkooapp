/// What the server says happened to a MyFatoorah payment.
///
/// This type exists so the app stops reading the outcome of a payment out of a URL. The old flow
/// decided a payment had succeeded because the redirect it landed on contained the substring
/// `success`, which is wrong whenever the customer loses connectivity on the way back from the bank —
/// and is forgeable by anyone who can put a URL in front of the WebView. The result now comes from
/// `GET /api/v1/payment/myfatoorah/status`, which checks with MyFatoorah server-to-server.
class MyFatoorahPaymentStatus {
  /// Our reference for the payment attempt. Unguessable, and the key the status endpoint takes.
  final String reference;

  /// `paid`, `failed`, `cancelled`, `expired`, `confirming` or `pending`.
  final String status;

  /// True once the answer cannot change any more. While this is false the app keeps asking.
  final bool isFinal;

  /// The only flag that may show an order as placed.
  final bool paid;

  final String amount;
  final String currency;

  /// Orders the server created for this payment, so the app can open them directly.
  final List<int> orderIds;

  /// A translation key, not a sentence: the app owns its own Arabic and English wording.
  final String messageKey;

  const MyFatoorahPaymentStatus({
    required this.reference,
    required this.status,
    required this.isFinal,
    required this.paid,
    required this.amount,
    required this.currency,
    required this.orderIds,
    required this.messageKey,
  });

  factory MyFatoorahPaymentStatus.fromJson(Map<String, dynamic> json) {
    return MyFatoorahPaymentStatus(
      reference: '${json['reference'] ?? ''}',
      status: '${json['status'] ?? 'pending'}',
      isFinal: json['is_final'] == true,
      paid: json['paid'] == true,
      amount: '${json['amount'] ?? ''}',
      currency: '${json['currency'] ?? ''}',
      orderIds: (json['order_ids'] is List)
          ? (json['order_ids'] as List)
              .map((dynamic id) => int.tryParse('$id') ?? 0)
              .where((int id) => id > 0)
              .toList()
          : <int>[],
      messageKey: '${json['message_key'] ?? 'payment_is_being_processed'}',
    );
  }

  /// The payment definitely did not go through, so it is safe to tell the customer so.
  bool get isDefiniteFailure =>
      isFinal && !paid && (status == 'failed' || status == 'cancelled' || status == 'expired');

  /// We do not know yet. The customer must NOT be told it failed: their money may already have gone.
  bool get isUnresolved => !isFinal;

  /// Could not be read at all — treated exactly like "not resolved", never like a failure.
  static MyFatoorahPaymentStatus unresolved(String reference) => MyFatoorahPaymentStatus(
        reference: reference,
        status: 'pending',
        isFinal: false,
        paid: false,
        amount: '',
        currency: '',
        orderIds: const <int>[],
        messageKey: 'payment_is_being_processed',
      );
}
