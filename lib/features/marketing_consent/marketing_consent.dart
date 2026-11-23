/// The names a marketing consent decision is filed under, in one place, so the app and the backend can never disagree by a typo.
///
/// Every name here is the one the backend's own `App\Services\Marketing\MarketingConsent` stores and the
/// `customer_marketing_consents` table holds, so a decision this app captures is already in the shape the backend records and needs no
/// translation when there is somewhere to send it. A CHANNEL is how a message travels; a PURPOSE is what it is for; agreeing to a
/// newsletter is not agreeing to a push broadcast.
class MarketingConsent {
  const MarketingConsent._();

  static const String channelEmail = 'email';
  static const String channelSms = 'sms';
  static const String channelWhatsapp = 'whatsapp';
  static const String channelPush = 'push';

  static const List<String> channels = <String>[
    channelEmail,
    channelSms,
    channelWhatsapp,
    channelPush,
  ];

  static const String purposeNewsletter = 'newsletter';
  static const String purposeAbandonedCart = 'abandoned_cart';
  static const String purposeCartMarketing = 'cart_marketing';
  static const String purposeBroadcast = 'broadcast';

  static const List<String> purposes = <String>[
    purposeNewsletter,
    purposeAbandonedCart,
    purposeCartMarketing,
    purposeBroadcast,
  ];

  /// A decision is one of these two and nothing else: granting writes one row, withdrawing writes another, and the answer in force is the
  /// newest row for that market, channel and purpose. Nothing is ever edited, here or in the table.
  static const String decisionGranted = 'granted';
  static const String decisionWithdrawn = 'withdrawn';

  /// Where an answer came from. The backend lists `registration`, `account_page`, `newsletter_form` and `unsubscribe_link`; the app's own
  /// consent screen is an account page, and there is deliberately no fifth name invented for it.
  static const String sourceAccountPage = 'account_page';

  /// Whether a customer who has recorded no answer at all may be sent marketing on a channel.
  ///
  /// The app's floor is [optIn]: a device subscribes to no marketing topic until a person has said yes. The backend's rule is a
  /// deployment setting per market and channel, and the owner's legal answer is still open (tracker A2-13), so this is the strictest of
  /// the two shipped policies and never the looser one.
  static const bool optIn = false;

  /// A market spelled the one way it is stored and compared: an upper-case ISO code, as the backend's `market` column holds it.
  static String market(String code) => code.trim().toUpperCase();

  static bool isChannel(String channel) => channels.contains(channel);

  static bool isPurpose(String purpose) => purposes.contains(purpose);
}
