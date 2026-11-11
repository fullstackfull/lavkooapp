import 'package:flutter/material.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class SearchHomePageWidget extends StatelessWidget {
  const SearchHomePageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: false).darkTheme;
    final isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.homePagePadding,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Container(
        height: 50,
        padding: EdgeInsets.only(
          left: isLtr ? 16 : 8,
          right: isLtr ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).highlightColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                getTranslated('search_hint', context) ?? '',
                style: textRegular.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
