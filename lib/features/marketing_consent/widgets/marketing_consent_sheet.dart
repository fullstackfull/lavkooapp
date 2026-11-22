import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/di_container.dart' as di;
import 'package:syriapharmacy/features/marketing_consent/marketing_consent.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_decision.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_store.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_chooser_sheet.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/push_notification/storefront_topic_subscriber.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// WHERE THE PERSON SAYS YES OR NO TO MARKETING, for the market they are shopping in and for one channel at a time.
///
/// It looks like the language, currency and country sheets it sits next to in the settings. Each answer is a decision in its own right:
/// saying yes writes one, changing one's mind writes another, and nothing is ever edited — the same shape the backend's
/// `customer_marketing_consents` table keeps, so what is captured here is already what the backend records.
///
/// THE PUSH ANSWER IS ACTED ON AT ONCE. Agreeing puts the device on this market's marketing topic and withdrawing takes it off, through
/// the one subscriber that answers that question, so the person's choice is not a note in a store that nothing reads. The e-mail, SMS and
/// WhatsApp answers are recorded and no more: those senders live on the server, which publishes no route for a customer to record a
/// decision through, so there is nowhere to send them yet. That is one named endpoint missing, not a second scheme.
class MarketingConsentSheet extends StatefulWidget {
  const MarketingConsentSheet({
    super.key,
    required this.preferences,
    required this.topics,
  });

  final SharedPreferences preferences;

  /// The one subscriber that answers which marketing topics this device is on. It is the container's own, not a second one built here:
  /// the push answer has to be acted on by the same object a storefront switch and a sign-out act through, and a sheet that built its
  /// own would be a second copy of that wiring, which is a copy no test can watch.
  final StorefrontTopicSubscriber topics;

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (_) => MarketingConsentSheet(
          preferences: di.sl(),
          topics: di.sl<StorefrontTopicSubscriber>(),
        ),
      );

  /// The language-file key of each channel's name, in the order they are shown.
  static const Map<String, String> channelNameKeys = <String, String>{
    MarketingConsent.channelEmail: 'marketing_channel_email',
    MarketingConsent.channelSms: 'marketing_channel_sms',
    MarketingConsent.channelWhatsapp: 'marketing_channel_whatsapp',
    MarketingConsent.channelPush: 'marketing_channel_push',
  };

  @override
  State<MarketingConsentSheet> createState() => _MarketingConsentSheetState();
}

class _MarketingConsentSheetState extends State<MarketingConsentSheet> {
  late final MarketingConsentStore _store =
      MarketingConsentStore(widget.preferences);

  String get _market =>
      Provider.of<StorefrontController>(context, listen: false).current.code;

  bool _allows(String channel) => _store.allows(
        market: _market,
        channel: channel,
        purpose: MarketingConsent.purposeBroadcast,
      );

  Future<void> _answer(String channel, bool granted) async {
    await _store.record(MarketingConsentDecision(
      market: _market,
      channel: channel,
      purpose: MarketingConsent.purposeBroadcast,
      decision: granted
          ? MarketingConsent.decisionGranted
          : MarketingConsent.decisionWithdrawn,
      answeredAt: DateTime.now().toUtc(),
    ));

    // The switch moves as soon as the answer is recorded. The topics follow after: a build with storefronts on asks Firebase to leave half
    // a dozen topics and join one, and a switch that waited for all of that would sit under the finger showing the old answer for as long
    // as the network took.
    if (mounted) {
      setState(() {});
    }

    if (channel == MarketingConsent.channelPush) {
      await widget.topics.apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color? textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.only(
        top: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeLarge,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.paddingSizeDefault),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
              ),
              child: Text(
                getTranslated('marketing_consent', context) ?? '',
                textAlign: TextAlign.center,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: textColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
              ),
              child: Text(
                '${getTranslated('marketing_consent_hint', context) ?? ''} '
                '${StorefrontChooserSheet.nameOf(context, _market)}',
                textAlign: TextAlign.center,
                style: textRegular.copyWith(color: textColor),
              ),
            ),
            // The rows are a ListTile each, and a ListTile paints its ink on the nearest Material. The sheet's own background is a
            // decorated box, which would hide it, so the rows get a transparent Material of their own: the splash is then visible over
            // the sheet's colour instead of under it.
            Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final MapEntry<String, String> channel
                      in MarketingConsentSheet.channelNameKeys.entries)
                    SwitchListTile(
                      key: ValueKey<String>(
                          'marketing_consent_${channel.key}'),
                      value: _allows(channel.key),
                      title: Text(
                        getTranslated(channel.value, context) ?? channel.key,
                        style: textRegular.copyWith(color: textColor),
                      ),
                      onChanged: (bool granted) =>
                          _answer(channel.key, granted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
