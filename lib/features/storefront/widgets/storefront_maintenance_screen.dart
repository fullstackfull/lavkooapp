import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_chooser_sheet.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';

/// What the customer sees instead of a storefront the server has put in maintenance (J-08): the server's message for them, when it expects the stop to end, a way to
/// ask again and, when the shop serves more than one storefront, a way to leave for another. The screen is built from the server's own entry for the storefront, so
/// it is there only while that answer says maintenance, and it is gone as soon as a newer answer says otherwise: the controller notifies, and the screen that shows
/// it (the dashboard) builds what it always showed.
class StorefrontMaintenanceScreen extends StatefulWidget {
  const StorefrontMaintenanceScreen({super.key});

  @override
  State<StorefrontMaintenanceScreen> createState() =>
      _StorefrontMaintenanceScreenState();
}

class _StorefrontMaintenanceScreenState
    extends State<StorefrontMaintenanceScreen> {
  bool _asking = false;

  Future<void> _askAgain() async {
    setState(() => _asking = true);
    await Provider.of<StorefrontController>(context, listen: false).refresh();
    if (mounted) {
      setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final StorefrontController controller =
        context.watch<StorefrontController>();
    final StorefrontCountry? entry = controller.currentEntry;
    final String message = entry?.stopMessage?.trim() ?? '';
    final String? until = entry?.stopUntil;
    final TextStyle? bodyColor = Theme.of(context).textTheme.bodyLarge;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(Images.maintenance, width: 200, height: 200),
                  Text(
                    getTranslated('storefront_maintenance_title', context) ??
                        '',
                    textAlign: TextAlign.center,
                    style: titilliumBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: bodyColor?.color,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    message.isNotEmpty
                        ? message
                        : getTranslated('storefront_maintenance_body', context) ??
                            '',
                    textAlign: TextAlign.center,
                    style: titilliumRegular.copyWith(color: bodyColor?.color),
                  ),
                  if (until != null) ...[
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      '${getTranslated('storefront_maintenance_expected_back', context) ?? ''}: $until UTC',
                      textAlign: TextAlign.center,
                      style: titilliumRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: bodyColor?.color,
                      ),
                    ),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  FilledButton(
                    onPressed: _asking ? null : _askAgain,
                    child: Text(getTranslated('try_again', context) ?? ''),
                  ),
                  if (controller.canChoose)
                    TextButton(
                      onPressed: () => StorefrontChooserSheet.show(context),
                      child: Text(
                          getTranslated('choose_your_country', context) ?? ''),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
