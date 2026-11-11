import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_asset_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/chat/controllers/chat_controller.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/features/shop/domain/enums/vacation_duration_type.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/main.dart' show Get;
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ShopInfoWidget extends StatelessWidget {
  final String slug = '';
  final bool vacationIsOn;
  final bool temporaryClose;
  final String sellerName;
  final int? sellerId;
  final int? totalReview;
  final int? totalProduct;
  final String? rating;
  final String banner;
  final String shopImage;
  final DateTime? vacationEndDate;
  final DateTime? vacationStartDate;
  final VacationDurationType? vacationDurationType;
  final bool fromMore;
  const ShopInfoWidget(
      {super.key,
      required this.vacationIsOn,
      required this.sellerName,
      required this.sellerId,
      required this.banner,
      required this.shopImage,
      required this.temporaryClose,
      this.totalReview,
      this.totalProduct,
      this.rating,
      this.vacationEndDate,
      this.vacationStartDate,
      this.vacationDurationType,
      required this.fromMore});

  @override
  Widget build(BuildContext context) {
    var splashController =
        Provider.of<SplashController>(context, listen: false);
    return Column(
      children: [
        Stack(
          children: [
            CustomImageWidget(
                image: (sellerId == 0 || sellerId == null)
                    ? splashController
                            .configModel?.inHouseShop?.bannerFullUrl?.path ??
                        ''
                    : banner,
                placeholder: Images.placeholder_3x1,
                width: MediaQuery.of(context).size.width,
                height: ResponsiveHelper.isTab(context) ? 250 : 150),

            // A shop's cover is whatever photo the merchant uploaded. The scrim
            // is what keeps the back control and the card's edge legible over
            // a bright one without dimming the picture itself.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        BrandColors.ink.withValues(alpha: .34),
                        Colors.transparent,
                        BrandColors.ink.withValues(alpha: .22),
                      ],
                      stops: const [0, .45, 1],
                    ),
                  ),
                ),
              ),
            ),

            // if(Platform.isIOS)
            Positioned(
              top: 40,
              left: Provider.of<LocalizationController>(context, listen: false)
                      .isLtr
                  ? 15
                  : null,
              right: Provider.of<LocalizationController>(context, listen: false)
                      .isLtr
                  ? null
                  : 15,
              child: InkWell(
                onTap: () {
                  Provider.of<SellerProductController>(context, listen: false)
                      .clearSellerProducts();
                  Provider.of<CategoryController>(Get.context!, listen: false)
                      .onUpdateFilteredCategoryList(isSeller: false);
                  Provider.of<BrandController>(Get.context!, listen: false)
                      .onUpdateFiltererBrandList(isSeller: false);
                  Provider.of<ShopController>(Get.context!, listen: false)
                      .nullShopInfoModel();
                  Provider.of<CategoryController>(Get.context!, listen: false)
                      .uncheckSellerCategoryList();
                  Provider.of<BrandController>(Get.context!, listen: false)
                      .uncheckSellerBrandList();
                  if (sellerId == null) {
                    RouterHelper.getDashboardRoute(
                        action: RouteAction.pushNamedAndRemoveUntil);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  height: 40,
                  width: 40,
                  child: Icon(
                    Provider.of<LocalizationController>(context, listen: false)
                            .isLtr
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Container(
            transform: Matrix4.translationValues(0, -34, 0),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).cardColor,
                border: Border.all(color: BrandColors.hairline),
                boxShadow: Provider.of<ThemeController>(context, listen: false)
                        .darkTheme
                    ? null
                    : [
                        BoxShadow(
                            color: BrandColors.ink.withValues(alpha: .10),
                            blurRadius: 24,
                            offset: const Offset(0, 10))
                      ]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Theme.of(context).highlightColor,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow:
                            Provider.of<ThemeController>(context, listen: false)
                                    .darkTheme
                                ? null
                                : [
                                    BoxShadow(
                                        color: BrandColors.ink
                                            .withValues(alpha: .16),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6))
                                  ]),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomImageWidget(
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          image: (sellerId == 0 || sellerId == null)
                              ? splashController.configModel?.inHouseShop
                                      ?.imageFullUrl?.path ??
                                  ''
                              : shopImage,
                        ))),
                if (temporaryClose || vacationIsOn)
                  Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: BrandColors.ink.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(18),
                      )),
                temporaryClose
                    ? Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Align(
                            alignment: Alignment.center,
                            child: Center(
                                child: Text(
                                    getTranslated('temporary_closed', context)!
                                        .replaceAll(' ', '\n'),
                                    textAlign: TextAlign.center,
                                    style: textRegular.copyWith(
                                        color: Colors.white,
                                        fontSize:
                                            Dimensions.fontSizeExtraSmall)))))
                    : vacationIsOn
                        ? Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Align(
                                alignment: Alignment.center,
                                child: Center(
                                    child: Text(
                                        getTranslated(
                                            'close_for_now', context)!,
                                        textAlign: TextAlign.center,
                                        style: textRegular.copyWith(
                                            color: Colors.white,
                                            fontSize: Dimensions
                                                .fontSizeExtraSmall)))))
                        : const SizedBox()
              ]),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Consumer<ShopController>(
                    builder: (context, sellerProvider, _) {
                  String ratting = sellerProvider.sellerInfoModel != null &&
                          sellerProvider.sellerInfoModel!.avgRating != null
                      ? sellerProvider.sellerInfoModel!.avgRating.toString()
                      : "0";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sellerName,
                                style: tajawalHeavy.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    height: 1.25,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Only the marketplace's own store is vouched
                              // for by the platform. An approved seller is one
                              // who may trade, not a verified one.
                              if (sellerId == 0 || sellerId == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_rounded,
                                            size: 14, color: BrandColors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                            getTranslated('official_store',
                                                    context) ??
                                                '',
                                            style:
                                                textBold.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    color:
                                                        BrandColors.primary)),
                                      ]),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          child: InkWell(
                              onTap: () {
                                if (temporaryClose) {
                                  showCustomSnackBarWidget(
                                      "${getTranslated("this_shop_is_close_now", context)}",
                                      context,
                                      snackBarType: SnackBarType.warning);
                                } else {
                                  if (!Provider.of<AuthController>(context,
                                          listen: false)
                                      .isLoggedIn()) {
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (_) =>
                                            NotLoggedInBottomSheetWidget(
                                              fromPage:
                                                  RouterHelper.topSellerScreen,
                                              onLoginSuccess: () {
                                                RouterHelper.getTopSellerRoute(
                                                  action: RouteAction
                                                      .pushReplacement,
                                                  slug: slug,
                                                  sellerId: sellerId ?? 0,
                                                  temporaryClose:
                                                      temporaryClose,
                                                  vacationStatus: vacationIsOn,
                                                  vacationEndDate:
                                                      vacationEndDate,
                                                  vacationStartDate:
                                                      vacationStartDate,
                                                  vacationDurationType:
                                                      vacationDurationType,
                                                  name: sellerName,
                                                  banner: banner,
                                                  image: shopImage,
                                                  fromMore: fromMore,
                                                  totalReview: totalReview,
                                                  totalProduct: totalProduct,
                                                );
                                              },
                                            ));
                                  } else {
                                    Provider.of<ChatController>(context,
                                            listen: false)
                                        .setUserTypeIndex(context, 1);
                                    RouterHelper.getChatScreenRoute(
                                      action: RouteAction.push,
                                      id: sellerId ?? 0,
                                      name: sellerName,
                                      userType: 1,
                                      isShopOnVacation: vacationIsOn,
                                      image: sellerId == 0
                                          ? splashController
                                                  .configModel
                                                  ?.inHouseShop
                                                  ?.imageFullUrl
                                                  ?.path ??
                                              ''
                                          : shopImage,
                                    );
                                  }
                                }
                              },
                              child: const CustomAssetImageWidget(
                                  Images.storeChatIcon,
                                  height: 20,
                                  width: 20)),
                        )
                      ]),
                      Builder(builder: (context) {
                        final int reviews = totalReview ??
                            sellerProvider.sellerInfoModel?.totalReview ??
                            0;
                        final int products = totalProduct ??
                            sellerProvider.sellerInfoModel?.totalProduct ??
                            0;
                        final double? minimumOrder =
                            sellerProvider.sellerInfoModel?.minimumOrderAmount;
                        final double averageRating =
                            double.tryParse(rating ?? ratting) ?? 0;
                        if (sellerProvider.sellerInfoModel == null &&
                            rating == null) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                              top: Dimensions.paddingSizeSmall),
                          child: Wrap(
                            spacing: Dimensions.paddingSizeExtraSmall,
                            runSpacing: Dimensions.paddingSizeExtraSmall,
                            children: [
                              // A rating with no reviews behind it is a number
                              // nobody gave, and a 0.0 star reads as a verdict
                              // the shop never earned: both stay off the card.
                              if (reviews > 0 && averageRating > 0)
                                _ShopStatChip(
                                  icon: Icons.star_rate_rounded,
                                  iconColor: BrandColors.star,
                                  label: averageRating.toStringAsFixed(1),
                                ),
                              if (reviews > 0)
                                _ShopStatChip(
                                    label:
                                        '$reviews ${getTranslated('reviews', context)}'),
                              _ShopStatChip(
                                  label:
                                      '$products ${getTranslated('products', context)}',
                                  emphasise: true),
                              if (minimumOrder != null && minimumOrder > 0)
                                _ShopStatChip(
                                    label:
                                        '${PriceConverter.convertPrice(context, minimumOrder)} '
                                        '${getTranslated('minimum_order', context)}'),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// One fact about the shop, read at a glance: its rating, its range, what it
/// asks for an order. Same pill the vendor cards use, so the store page and the
/// card a shopper tapped to reach it agree.
class _ShopStatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool emphasise;
  const _ShopStatChip(
      {required this.label, this.icon, this.iconColor, this.emphasise = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasise
            ? BrandColors.primary.withValues(alpha: .10)
            : Theme.of(context).hintColor.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 3),
        ],
        Text(label,
            style: textBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: emphasise
                    ? BrandColors.primary
                    : Theme.of(context).textTheme.bodyLarge?.color)),
      ]),
    );
  }
}

class ShopInfoShimmerWidget extends StatelessWidget {
  const ShopInfoShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).cardColor,
      highlightColor: Theme.of(context).hintColor.withValues(alpha: .5),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 150,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Container(
              transform: Matrix4.translationValues(0, -34, 0),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          Dimensions.paddingSizeExtraSmall),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 15,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                                height: 12, width: 40, color: Colors.white),
                            const SizedBox(width: 10),
                            Container(
                                height: 12, width: 80, color: Colors.white),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                                height: 12, width: 100, color: Colors.white),
                            const SizedBox(width: 10),
                            Container(
                                height: 12, width: 60, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
