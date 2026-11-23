import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/marketing_consent/widgets/marketing_consent_sheet.dart';
import 'package:syriapharmacy/features/setting/screens/settings_screen.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/images.dart';

/// The settings' row that opens the marketing consent sheet, next to the language, the currency and the country.
///
/// It is there only in a build with storefronts on. A build with them off has exactly the settings it always had: there is one market, no
/// consent was ever asked for in it, and the device's subscription is the one global topic it has always been on.
class MarketingConsentSettingsEntry extends StatelessWidget {
  const MarketingConsentSettingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (!StorefrontConfig.enabled) {
      return const SizedBox.shrink();
    }

    return TitleButton(
      image: Images.notification,
      title: getTranslated('marketing_consent', context),
      onTap: () => MarketingConsentSheet.show(context),
    );
  }
}
