import 'package:flutter/material.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// Says, on the home page itself, that what is on it is an unpublished draft (J-V1).
///
/// A preview looks exactly like the shop, which is the point of it and also its one danger: a
/// merchant walking around with the phone has to be able to tell, at a glance, whether they are
/// looking at their draft or at what their customers can already see. So the page says which.
///
/// Shown only while the SERVER answered a draft (`DynamicThemeController.isShowingADraft`), never
/// because this app asked for one: a token the server refused is answered with the published page,
/// and a notice over the real shop would be the worst possible moment to be wrong.
class ThemeDraftNotice extends StatelessWidget {
  const ThemeDraftNotice({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.error;

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
            Icons.visibility_outlined,
            size: Dimensions.iconSizeSmall,
            color: accentColor,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              getTranslated('theme_draft_preview_notice', context) ?? '',
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
