import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// The sheet in which the customer chooses the country whose store they shop in: every storefront the server lists, with whether it takes
/// orders yet or is open for browsing only. It looks like the language and currency sheets next to it in the settings.
///
/// Choosing does everything in [StorefrontSwitcher]. When it is done the sheet closes and [onSwitched] takes the customer to the home
/// screen, which is what everything they had open belonged to the previous storefront needs: nothing of it is left to look at.
class StorefrontChooserSheet extends StatefulWidget {
  const StorefrontChooserSheet({super.key, required this.onSwitched});

  /// What happens once the customer is on the storefront they chose. The settings pass the way to the home screen.
  final VoidCallback onSwitched;

  /// Opens the sheet over the settings, and sends the customer to the home screen once they have chosen another storefront.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (_) => StorefrontChooserSheet(
        onSwitched: () => RouterHelper.getDashboardRoute(
            action: RouteAction.pushNamedAndRemoveUntil),
      ),
    );
  }

  /// The language-file key of the name of each country the shop is known to serve. A country the app has no name for is shown by its code.
  static const Map<String, String> nameKeys = <String, String>{
    'SA': 'storefront_name_sa',
    'AE': 'storefront_name_ae',
    'KW': 'storefront_name_kw',
    'QA': 'storefront_name_qa',
    'BH': 'storefront_name_bh',
    'OM': 'storefront_name_om',
  };

  /// The name of the country with [code] in the language of the app, or the code itself when the app has no name for it.
  static String nameOf(BuildContext context, String code) {
    final String? key = nameKeys[code];

    return (key == null ? null : getTranslated(key, context)) ?? code;
  }

  @override
  State<StorefrontChooserSheet> createState() => _StorefrontChooserSheetState();
}

class _StorefrontChooserSheetState extends State<StorefrontChooserSheet> {
  late String _selectedCode;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _selectedCode =
        Provider.of<StorefrontController>(context, listen: false).current.code;
  }

  String _nameOf(StorefrontCountry storefront) =>
      StorefrontChooserSheet.nameOf(context, storefront.code);

  Future<void> _choose(List<StorefrontCountry> storefronts) async {
    final StorefrontCountry? chosen = storefronts
        .where(
            (StorefrontCountry storefront) => storefront.code == _selectedCode)
        .firstOrNull;
    if (chosen == null) {
      return;
    }

    final StorefrontSwitcher switcher =
        Provider.of<StorefrontSwitcher>(context, listen: false);
    setState(() => _switching = true);

    final StorefrontSwitch result = await switcher.switchTo(chosen);
    if (!mounted) {
      return;
    }

    switch (result) {
      case StorefrontSwitch.switched:
        Navigator.pop(context);
        widget.onSwitched();
      case StorefrontSwitch.unchanged:
        Navigator.pop(context);
      case StorefrontSwitch.failed:
        setState(() => _switching = false);
        showCustomSnackBarWidget(
          getTranslated('storefront_switch_failed', context),
          context,
          snackBarType: SnackBarType.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final StorefrontController controller =
        context.watch<StorefrontController>();
    final List<StorefrontCountry> storefronts = controller.available;
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
          children: [
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
                getTranslated('choose_your_country', context) ?? '',
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
                getTranslated('storefront_choose_hint', context) ?? '',
                textAlign: TextAlign.center,
                style: textRegular.copyWith(color: textColor),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: storefronts.length,
                itemBuilder: (BuildContext context, int index) {
                  final StorefrontCountry storefront = storefronts[index];

                  return _StorefrontOption(
                    name: _nameOf(storefront),
                    sells: controller.canSell(storefront),
                    selected: storefront.code == _selectedCode,
                    onTap: _switching
                        ? null
                        : () => setState(() => _selectedCode = storefront.code),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeSmall,
                0,
              ),
              child: CustomButton(
                buttonText: getTranslated('select', context),
                isLoading: _switching,
                onTap: _switching ? null : () => _choose(storefronts),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorefrontOption extends StatelessWidget {
  const _StorefrontOption({
    required this.name,
    required this.sells,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool sells;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color? textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final String status = getTranslated(
          sells
              ? 'storefront_orders_available'
              : 'storefront_browse_only_label',
          context,
        ) ??
        '';

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            0,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              color: selected
                  ? primaryColor.withValues(alpha: .1)
                  : Theme.of(context).cardColor,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        status,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                // The selected row is told apart by more than its tint.
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: Dimensions.iconSizeDefault,
                  color: selected ? primaryColor : Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
