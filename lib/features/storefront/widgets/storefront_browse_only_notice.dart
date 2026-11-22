import 'package:flutter/material.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// Tells the customer that the storefront they are on is open for browsing only. It is shown by the cart and the checkout while the
/// storefront may not sell, next to the buttons that are switched off for that reason.
class StorefrontBrowseOnlyNotice extends StatelessWidget {
  const StorefrontBrowseOnlyNotice({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: Dimensions.iconSizeSmall,
            color: accentColor,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              getTranslated('storefront_browse_only_notice', context) ?? '',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
