import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/business_pages_model.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CheckoutConditionCheckBox extends StatelessWidget {
  const CheckoutConditionCheckBox({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController splashController =
        Provider.of<SplashController>(context, listen: false);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child:
          Consumer<CheckoutController>(builder: (ctx, checkoutController, _) {
        return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          InkWell(
            onTap: () => checkoutController.toggleTermsCheck(),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checkoutController.isAcceptTerms
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: checkoutController.isAcceptTerms
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  width: 1.8,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: checkoutController.isAcceptTerms ? 1.0 : 0.0,
                child: const Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(
                    color: Theme.of(context).textTheme.headlineLarge?.color),
                children: <InlineSpan>[
                  TextSpan(
                      text: getTranslated(
                              'i_have_read_and_agree_to_the_website',
                              context) ??
                          '',
                      style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: IntrinsicWidth(
                      child: InkWell(
                        onTap: () => RouterHelper.getHtmlViewRoute(
                          page: getPageBySlug('terms-and-conditions',
                              splashController.defaultBusinessPages)!,
                        ),
                        child: Text(getTranslated('terms_condition', context)!,
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.8),
                              decoration: TextDecoration.underline,
                              decorationColor: Theme.of(context).primaryColor,
                            )),
                      ),
                    ),
                  ),
                  const TextSpan(text: ', '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: IntrinsicWidth(
                      child: InkWell(
                        onTap: () => RouterHelper.getHtmlViewRoute(
                          page: getPageBySlug('privacy-policy',
                              splashController.defaultBusinessPages)!,
                        ),
                        child: Text(getTranslated('privacy_policy', context)!,
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.8),
                              decoration: TextDecoration.underline,
                              decorationColor: Theme.of(context).primaryColor,
                            )),
                      ),
                    ),
                  ),
                  const TextSpan(text: ', '),
                  if (getPageBySlug('refund-policy',
                          splashController.defaultBusinessPages) !=
                      null)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: IntrinsicWidth(
                        child: InkWell(
                          onTap: () => RouterHelper.getHtmlViewRoute(
                            page: getPageBySlug('refund-policy',
                                splashController.defaultBusinessPages)!,
                          ),
                          child: Text(getTranslated('refund_policy', context)!,
                              style: textMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.8),
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(context).primaryColor,
                              )),
                        ),
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ]);
      }),
    );
  }

  BusinessPageModel? getPageBySlug(
      String slug, List<BusinessPageModel>? pagesList) {
    BusinessPageModel? pageModel;
    if (pagesList != null && pagesList.isNotEmpty) {
      for (var page in pagesList) {
        if (page.slug == slug) {
          pageModel = page;
        }
      }
    }

    return pageModel;
  }
}
