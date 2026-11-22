import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/setting/screens/settings_screen.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_chooser_sheet.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/images.dart';

/// The settings' row that opens the storefront chooser, next to the language and the currency. It is there only while the customer has a
/// country to choose: storefronts are on and the server lists more than one. Otherwise there is nothing in its place, and a build with
/// storefronts off has exactly the settings it always had.
class StorefrontSettingsEntry extends StatelessWidget {
  const StorefrontSettingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<StorefrontController>().canChoose) {
      return const SizedBox.shrink();
    }

    return TitleButton(
      image: Images.country,
      title: getTranslated('choose_your_country', context),
      onTap: () => StorefrontChooserSheet.show(context),
    );
  }
}
