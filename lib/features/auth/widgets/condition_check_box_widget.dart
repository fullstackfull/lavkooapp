import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/business_pages_model.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ConditionCheckBox extends StatelessWidget {
  const ConditionCheckBox({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController splashController =
        Provider.of<SplashController>(context, listen: false);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Consumer<AuthController>(builder: (ctx, authController, _) {
        return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          InkWell(
            onTap: () => authController.toggleTermsCheck(),
            child: Row(children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: authController.isAcceptTerms
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: authController.isAcceptTerms
                                ? Theme.of(context).primaryColor
                                : Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: .4),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.done_rounded,
                          size: 14,
                          color: authController.isAcceptTerms
                              ? Colors.white
                              : Colors.transparent))),
            ]),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(getTranslated('i_agree_with_the', context)!,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
          InkWell(
            onTap: () => RouterHelper.getHtmlViewRoute(
              page: getPageBySlug('terms-and-conditions',
                  splashController.defaultBusinessPages)!,
            ),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: Text(getTranslated('terms_condition', context)!,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    decoration: TextDecoration.underline,
                    decorationColor: Theme.of(context).primaryColor,
                  )),
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

class ConditionCheckBoxTwoLine extends StatelessWidget {
  const ConditionCheckBoxTwoLine({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController splashController =
        Provider.of<SplashController>(context, listen: false);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Consumer<AuthController>(
        builder: (ctx, authController, _) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () => authController.toggleTermsCheck(),
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: authController.isAcceptTerms
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: authController.isAcceptTerms
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withValues(alpha: .4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.done_rounded,
                    size: 14,
                    color: authController.isAcceptTerms
                        ? Colors.white
                        : Colors.transparent),
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(getTranslated('i_agree_with_the', context)!,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  )),
              InkWell(
                onTap: () => RouterHelper.getHtmlViewRoute(
                  page: getPageBySlug('terms-and-conditions',
                      splashController.defaultBusinessPages)!,
                ),
                child: Text(getTranslated('terms_condition', context)!,
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).primaryColor,
                    )),
              ),
            ]),
          ]);
        },
      ),
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
