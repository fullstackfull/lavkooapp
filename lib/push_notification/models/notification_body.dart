

class NotificationBody {
  int? orderId;
  String? type;
  String? status;
  String? messageKey;
  String? title;
  String? productId;
  String? slug;
  String? image;

  /// The storefront the push is about: the two-letter country code of the market whose order, wallet or product it names, as the
  /// backend sends it in the message's `storefront`.
  ///
  /// NULL FOR EVERY PUSH SENT TODAY, and that case must keep working: no sender in the backend puts this key in a message
  /// (`App\Traits\PushNotificationTrait` lists every key it sends and `storefront` is not among them), and messages already in flight
  /// when an app is updated carry none either. A push that names no storefront is read and routed exactly as it always was.
  ///
  /// The empty string is read as null on purpose. The backend stringifies every value it sends and writes a missing one as `''`
  /// (`(string)($data['order_id'] ?? '')`), so a sender that adds the key the same way would send `''` whenever it has no storefront to
  /// name, and that is not a storefront.
  String? storefront;

  NotificationBody({
    this.orderId,
    this.type,
    this.status,
    this.messageKey,
    this.title,
    this.productId,
    this.slug,
    this.image,
    this.storefront,
  });

  NotificationBody.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    type = json['type'];
    messageKey = json['message_key'];
    title = json['title'];
    productId = json['product_id'];
    slug = json['slug'];
    image = json['image'];
    status = json['status'];
    storefront = storefrontIn(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['type'] = type;
    data['message_key'] = messageKey;
    data['title'] = title;
    data['product_id'] = productId;
    data['slug'] = slug;
    data['image'] = image;
    data['status'] = status;
    data['storefront'] = storefront;
    return data;
  }

  /// The storefront a push message names, read from the message's own data: the key is `storefront`, and the answer is null when it names
  /// none. Every way of building a body reads it through here, so no branch can forget it.
  static String? storefrontIn(Map<String, dynamic> data) =>
      _code(data['storefront']);

  /// A storefront code as this app compares them: upper case, or null when the message names none. Blank text is none, and so is
  /// anything that is not a two-letter code, so a value this app cannot read never looks like a market.
  static String? _code(Object? value) {
    if (value is! String) {
      return null;
    }

    final String code = value.trim().toUpperCase();

    return RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : null;
  }
}

