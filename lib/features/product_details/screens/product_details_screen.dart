import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:syriapharmacy/common/basewidget/no_internet_screen_widget.dart'
    show NoInternetOrDataScreenWidget;
import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/product_details/widgets/bottom_cart_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/product_image_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/product_specification_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/product_title_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/promise_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/related_product_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/review_and_specification_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/shop_info_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/youtube_video_widget.dart';
import 'package:syriapharmacy/features/review/controllers/review_controller.dart';
import 'package:syriapharmacy/features/home/shimmers/product_details_shimmer.dart';
import 'package:syriapharmacy/features/review/widgets/review_section.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/shop/widgets/shop_more_product_view_list.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/helper/product_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/product_details/widgets/favourite_button_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';

class ProductDetails extends StatefulWidget {
  final int? productId;
  final String? slug;
  final bool isFromWishList;
  final bool isNotification;
  final bool fromFlashDeals;
  final String? heroTag;
  final String? image; // thumbnail URL for instant Hero display during shimmer
  const ProductDetails(
      {super.key,
      required this.productId,
      required this.slug,
      this.isFromWishList = false,
      this.isNotification = false,
      this.fromFlashDeals = false,
      this.heroTag,
      this.image});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final GlobalKey productImageKey = GlobalKey();
  final GlobalKey<CartIconKey> cartDetailsKey = GlobalKey<CartIconKey>();
  Function(GlobalKey)? runAddToCartAnimation;

  List<TextSpan> _publishingHouse = [];
  List<TextSpan> _authors = [];

  Size widgetSize = const Size(100, 400);

  Future<void> _loadData(BuildContext context) async {
    if (!mounted) return;
    Provider.of<ProductDetailsController>(context, listen: false)
        .getProductDetails(
            context, widget.slug.toString(), widget.slug.toString());
    Provider.of<ReviewController>(context, listen: false).removePrevReview();
    Provider.of<ProductDetailsController>(context, listen: false)
        .removePrevLink();
    Provider.of<ReviewController>(context, listen: false)
        .getReviewList(1, productSlug: widget.slug);
    Provider.of<ProductController>(context, listen: false)
        .removePrevRelatedProduct();
    Provider.of<ProductController>(context, listen: false)
        .initRelatedProductList(widget.slug.toString(), context);
    Provider.of<ProductDetailsController>(context, listen: false)
        .getCount(widget.slug.toString(), context);
    Provider.of<ProductDetailsController>(context, listen: false)
        .getSharableLink(widget.slug.toString(), context);
    Provider.of<ProductDetailsController>(context, listen: false)
        .setImageSliderSelectedIndex(0, isUpdate: false);
    Provider.of<ShopController>(context, listen: false)
        .emptyProductDetailsSeller();
  }

  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    Provider.of<ProductDetailsController>(context, listen: false)
        .selectReviewSection(false, isUpdate: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData(context);
      }
    });

    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      double newOpacity = (offset / 150).clamp(0.0, 1.0);
      if (newOpacity != _appBarOpacity) {
        setState(() {
          _appBarOpacity = newOpacity;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.isNotification) {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        } else {
          return;
        }
      },
      child: AddToCartAnimation(
        cartKey: cartDetailsKey,
        height: 30,
        width: 30,
        opacity: 0.85,
        dragAnimation: const DragToCartAnimationOptions(
          rotation: true,
        ),
        jumpAnimation: const JumpAnimationOptions(),
        createAddToCartAnimation: (addToCartAnimationMethod) {
          runAddToCartAnimation = addToCartAnimationMethod;
        },
        child: Scaffold(
          // backgroundColor: Colors.white,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async => _loadData(context),
              child: Consumer<ProductDetailsController>(
                builder: (context, details, child) {
                  if (details.productDetailsModel?.publishingHouse != null &&
                      details
                          .productDetailsModel!.publishingHouse!.isNotEmpty) {
                    _publishingHouse = [];
                    for (String? houseName
                        in details.productDetailsModel!.publishingHouse!) {
                      _publishingHouse.add(TextSpan(
                          text: '${houseName!} ',
                          style: titilliumSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault)));
                    }
                  }

                  if (details.productDetailsModel?.authors != null &&
                      details.productDetailsModel!.authors!.isNotEmpty) {
                    _authors = [];
                    for (String? authorName
                        in details.productDetailsModel!.authors!) {
                      _authors.add(TextSpan(
                          text: '${authorName!} ',
                          style: titilliumSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault)));
                    }
                  }

                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: !details.isDetails
                        ? (!details.isDetails &&
                                details.productDetailsModel?.userId == null)
                            ? SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: NoInternetOrDataScreenWidget(
                                    isNoInternet: false,
                                    icon: Images.noProduct,
                                    message: 'no_product_found'))
                            : Column(children: [
                                ProductImageWidget(
                                        productImageKey: productImageKey,
                                        productModel:
                                            details.productDetailsModel,
                                        fromFlashDeals: widget.fromFlashDeals,
                                        heroTag: widget.heroTag),
                                if (widget.fromFlashDeals)
                                  Consumer<FlashDealController>(
                                          builder:
                                              (context, flashDealController,
                                                  child) {
                                    Duration? eventDuration =
                                        flashDealController.duration;

                                    int? days, hours, minutes, seconds;
                                    if (eventDuration != null) {
                                      days = eventDuration.inDays;
                                      hours = eventDuration.inHours - days * 24;
                                      minutes = eventDuration.inMinutes -
                                          (24 * days * 60) -
                                          (hours * 60);
                                      seconds = eventDuration.inSeconds -
                                          (24 * days * 60 * 60) -
                                          (hours * 60 * 60) -
                                          (minutes * 60);
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(
                                          left: Dimensions.paddingSizeDefault,
                                          right: Dimensions.paddingSizeDefault,
                                          top: Dimensions.paddingSizeSmall),
                                      child: Container(
                                        padding: EdgeInsets.all(
                                            Dimensions.paddingSizeSmall),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                                .withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.radiusSmall)),
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .radiusSmall),
                                                  color: Theme.of(context)
                                                      .cardColor,
                                                ),
                                                padding: EdgeInsets.all(
                                                    Dimensions
                                                        .paddingSizeSmall),
                                                child: Text(
                                                  getTranslated(
                                                          'this_product_is_now_on_a_flash_deal',
                                                          context) ??
                                                      '',
                                                  style: textRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color),
                                                ),
                                              ),
                                            ),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  eventDuration == null
                                                      ? const Expanded(
                                                          child:
                                                              SizedBox.shrink())
                                                      : Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 0),
                                                          child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const SizedBox(
                                                                    width: 5),
                                                                TimerBox(
                                                                    time: days,
                                                                    day: getTranslated(
                                                                        'day',
                                                                        context),
                                                                    isDetailsPage:
                                                                        true),
                                                                TimerBox(
                                                                    time: hours,
                                                                    day: getTranslated(
                                                                        'hour',
                                                                        context),
                                                                    isDetailsPage:
                                                                        true),
                                                                TimerBox(
                                                                    time:
                                                                        minutes,
                                                                    day: getTranslated(
                                                                        'min',
                                                                        context),
                                                                    isDetailsPage:
                                                                        true),
                                                                TimerBox(
                                                                    time:
                                                                        seconds,
                                                                    day: getTranslated(
                                                                        'sec',
                                                                        context),
                                                                    isDetailsPage:
                                                                        true),
                                                              ]),
                                                        ),
                                                ])
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                                      .animate()
                                      .fadeIn(delay: 200.ms, duration: 500.ms)
                                      .slideY(
                                          begin: 0.1, end: 0, duration: 500.ms),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ProductTitleWidget(
                                        productModel:
                                            details.productDetailsModel,
                                        averageRatting: details
                                                .productDetailsModel
                                                ?.averageReview ??
                                            "0",
                                      )
                                          .animate()
                                          .fadeIn(
                                              delay: 400.ms, duration: 500.ms)
                                          .slideY(
                                              begin: 0.1,
                                              end: 0,
                                              duration: 500.ms),
                                      (details.productDetailsModel
                                                      ?.productType ==
                                                  'digital' &&
                                              (_publishingHouse.isNotEmpty ||
                                                  _authors.isNotEmpty))
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: Dimensions
                                                          .homePagePadding),
                                              child: RichText(
                                                  text: TextSpan(
                                                text: '',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: Dimensions
                                                          .fontSizeDefault,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                    ),
                                                children: [
                                                  if (details.productDetailsModel
                                                              ?.publishingHouse !=
                                                          null &&
                                                      details
                                                          .productDetailsModel!
                                                          .publishingHouse!
                                                          .isNotEmpty)
                                                    TextSpan(
                                                        text:
                                                            "${getTranslated('publishing_housec', context)}",
                                                        style: titilliumRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeDefault,
                                                          color:
                                                              Theme.of(context)
                                                                  .hintColor,
                                                        )),
                                                  ..._publishingHouse,
                                                  if (details.productDetailsModel
                                                              ?.publishingHouse !=
                                                          null &&
                                                      details
                                                          .productDetailsModel!
                                                          .publishingHouse!
                                                          .isNotEmpty)
                                                    WidgetSpan(
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8.0),
                                                        height: 15.0,
                                                        width: 1.0,
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.50),
                                                      ),
                                                    ),
                                                  if (details.productDetailsModel
                                                              ?.authors !=
                                                          null &&
                                                      details
                                                          .productDetailsModel!
                                                          .authors!
                                                          .isNotEmpty)
                                                    TextSpan(
                                                        text:
                                                            "${getTranslated('author', context)}",
                                                        style: titilliumRegular.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                            color: Theme.of(
                                                                    context)
                                                                .hintColor)),
                                                  ..._authors,
                                                ],
                                              )),
                                            )
                                          : const SizedBox(),
                                      (details.productDetailsModel != null)
                                          ? Consumer<ShopController>(
                                        builder: (context, shopController, child) {
                                          final addedBy = details.productDetailsModel?.addedBy;
                                          String? phone;
                                          if (addedBy == 'seller') {
                                            phone = shopController.sellerInfoModelProductDetails?.seller?.phone ??
                                                shopController.sellerInfoModelProductDetails?.seller?.shop?.contact;
                                          } else {
                                            phone = Provider.of<SplashController>(context, listen: false)
                                                .configModel?.companyPhone;
                                          }

                                          if (phone == null || phone.isEmpty) return const SizedBox.shrink();

                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(12),
                                                onTap: () async {
                                                  final cleanPhone = phone!.replaceAll(RegExp(r'[^\d+]'), '');
                                                  final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone");
                                                  final errorMsg = getTranslated('could_not_launch_whatsapp', context) ?? 'Could not launch WhatsApp';
                                                  if (await canLaunchUrl(whatsappUrl)) {
                                                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                                                  } else {
                                                    if (context.mounted) {
                                                      showCustomSnackBar(
                                                        errorMsg,
                                                        context,
                                                      );
                                                    }
                                                  }
                                                },
                                                ////للواتساب==============================
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Lottie.asset(
                                                        'assets/lottie/Whatsapp.json',
                                                        width: 32,
                                                        height: 32,
                                                        repeat: true,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        getTranslated('contact_via_whatsapp', context) ?? 'Contact via WhatsApp',
                                                        style: textMedium.copyWith(color: Colors.green, fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                          : const SizedBox.shrink(),
                                      ReviewAndSpecificationSectionWidget(
                                        averageReview: double.tryParse(details
                                                .productDetailsModel
                                                ?.averageReview ??
                                            '0'),
                                      ),
                                      details.isReviewSelected
                                          ? Column(children: [
                                              ReviewSection(details: details),
                                              _ProductDetailsProductListWidget(
                                                  scrollController:
                                                      _scrollController),
                                            ])
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [

                                                  (details.productDetailsModel
                                                                  ?.details !=
                                                              null &&
                                                          details
                                                              .productDetailsModel!
                                                              .details!
                                                              .isNotEmpty)
                                                      ? Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .cardColor,
                                                          ),
                                                          margin: const EdgeInsets
                                                              .only(
                                                              top: Dimensions
                                                                  .paddingSizeSmall),
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              vertical: Dimensions
                                                                  .paddingSizeSmall,
                                                              horizontal: Dimensions
                                                                  .paddingSizeDefault),
                                                          child:
                                                              ProductSpecificationWidget(
                                                            productSpecification:
                                                                ProductHelper
                                                                    .removeIframe(
                                                                        details.productDetailsModel!.details ??
                                                                            ''),
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                  (details.productDetailsModel
                                                                  ?.videoUrl !=
                                                              null &&
                                                          details.isValidYouTubeUrl(
                                                              details
                                                                  .productDetailsModel!
                                                                  .videoUrl!))
                                                      ? Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      Dimensions
                                                                          .paddingSizeDefault),
                                                          child: YoutubeVideoWidget(
                                                              url: details
                                                                  .productDetailsModel!
                                                                  .videoUrl))
                                                      : const SizedBox(),
                                                  // (details.productDetailsModel != null)
                                                  //     ? Consumer<ShopController>(
                                                  //         builder: (context, shopController, child) {
                                                  //           final addedBy = details.productDetailsModel?.addedBy;
                                                  //           String? phone;
                                                  //           if (addedBy == 'seller') {
                                                  //             phone = shopController.sellerInfoModelProductDetails?.seller?.phone ??
                                                  //                     shopController.sellerInfoModelProductDetails?.seller?.shop?.contact;
                                                  //           } else {
                                                  //             phone = Provider.of<SplashController>(context, listen: false)
                                                  //                 .configModel?.companyPhone;
                                                  //           }
                                                  //
                                                  //           if (phone == null || phone.isEmpty) return const SizedBox.shrink();
                                                  //
                                                  //           return Center(
                                                  //             child: Padding(
                                                  //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  //               child: InkWell(
                                                  //                 borderRadius: BorderRadius.circular(12),
                                                  //                  onTap: () async {
                                                  //                     final cleanPhone = phone!.replaceAll(RegExp(r'[^\d+]'), '');
                                                  //                     final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone");
                                                  //                     final errorMsg = getTranslated('could_not_launch_whatsapp', context) ?? 'Could not launch WhatsApp';
                                                  //                     if (await canLaunchUrl(whatsappUrl)) {
                                                  //                       await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                                                  //                     } else {
                                                  //                       if (context.mounted) {
                                                  //                         showCustomSnackBar(
                                                  //                           errorMsg,
                                                  //                           context,
                                                  //                         );
                                                  //                       }
                                                  //                     }
                                                  //                   },
                                                  //                 ////للواتساب==============================
                                                  //                  child: Container(
                                                  //                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  //                    decoration: BoxDecoration(
                                                  //                      color: Colors.green.withValues(alpha: 0.1),
                                                  //                      borderRadius: BorderRadius.circular(12),
                                                  //                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                                  //                    ),
                                                  //                   child: Row(
                                                  //                     mainAxisSize: MainAxisSize.min,
                                                  //                     children: [
                                                  //                       Lottie.asset(
                                                  //                         'assets/lottie/Whatsapp.json',
                                                  //                         width: 32,
                                                  //                         height: 32,
                                                  //                         repeat: true,
                                                  //                       ),
                                                  //                       const SizedBox(width: 8),
                                                  //                       Text(
                                                  //                         getTranslated('contact_via_whatsapp', context) ?? 'Contact via WhatsApp',
                                                  //                         style: textMedium.copyWith(color: Colors.green, fontSize: 14),
                                                  //                       ),
                                                  //                     ],
                                                  //                   ),
                                                  //                 ),
                                                  //               ),
                                                  //             ),
                                                  //           );
                                                  //         },
                                                  //       )
                                                  //     : const SizedBox.shrink(),
                                                  (details
                                                              .productDetailsModel !=
                                                          null)
                                                      ? ShopInfoWidget(
                                                          sellerId: details
                                                                      .productDetailsModel!
                                                                      .addedBy ==
                                                                  'seller'
                                                              ? details
                                                                  .productDetailsModel!
                                                                  .seller!
                                                                  .shop!
                                                                  .slug!
                                                                  .toString()
                                                              : Provider.of<
                                                                          SplashController>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .configModel!
                                                                  .inHouseShop!
                                                                  .slug!)
                                                      : const SizedBox.shrink(),
                                                  const SizedBox(
                                                      height: Dimensions
                                                          .paddingSizeSmall),
                                                  Consumer<SplashController>(
                                                    builder: (context,
                                                        splashController, _) {
                                                      final config =
                                                          splashController
                                                              .configModel;
                                                      final showPromiseWidget = config
                                                                  ?.activeTheme ==
                                                              'default' &&
                                                          config?.companyReliability
                                                                  ?.any((item) =>
                                                                      item.status ==
                                                                      1) ==
                                                              true;

                                                      if (showPromiseWidget) {
                                                        return Container(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              top: Dimensions
                                                                  .paddingSizeLarge,
                                                              bottom: Dimensions
                                                                  .paddingSizeDefault),
                                                          decoration: BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .cardColor),
                                                          child:
                                                              const PromiseWidget(),
                                                        );
                                                      }
                                                      return const SizedBox();
                                                    },
                                                  ),
                                                  _ProductDetailsProductListWidget(
                                                      scrollController:
                                                          _scrollController),
                                                ]),
                                    ]),
                              ])
                        : ProductDetailsShimmer(
                            heroTag: widget.heroTag,
                            image: widget.image,
                          ),
                  );
                },
              ),
            ),

            // Premium Floating dynamic App Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Consumer<ProductDetailsController>(
                builder: (context, details, child) {
                  final theme = Theme.of(context);
                  final topPadding = MediaQuery.of(context).padding.top;

                  return ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX:
                            _appBarOpacity > 0.1 ? 15.0 * _appBarOpacity : 0.0,
                        sigmaY:
                            _appBarOpacity > 0.1 ? 15.0 * _appBarOpacity : 0.0,
                      ),
                      child: Container(
                        height: topPadding + 56,
                        padding: EdgeInsets.only(
                            top: topPadding, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor
                              .withValues(alpha: _appBarOpacity * 0.8),
                          boxShadow: _appBarOpacity > 0.1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            InkWell(
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  RouterHelper.getDashboardRoute(
                                      action:
                                          RouteAction.pushNamedAndRemoveUntil);
                                }
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _appBarOpacity > 0.5
                                      ? Colors.transparent
                                      : Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: _appBarOpacity > 0.5
                                      ? theme.textTheme.bodyLarge?.color
                                      : Colors.white,
                                ),
                              ),
                            ),

                            // Title
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: _appBarOpacity > 0.5 &&
                                          details.productDetailsModel != null
                                      ? Text(
                                          details.productDetailsModel?.name ??
                                              '',
                                          style: textBold.copyWith(
                                            fontSize: Dimensions.fontSizeLarge,
                                            color: theme
                                                .textTheme.bodyLarge?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),

                            // Trailing Buttons
                            details.productDetailsModel != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Share Button
                                      InkWell(
                                        onTap: () {
                                          if (details.sharableLink != null) {
                                            SharePlus.instance.share(
                                              ShareParams(
                                                text: details.sharableLink!,
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: _appBarOpacity > 0.5
                                                ? Colors.transparent
                                                : Colors.black
                                                    .withValues(alpha: 0.4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.share_outlined,
                                            size: 18,
                                            color: _appBarOpacity > 0.5
                                                ? theme.primaryColor
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Wishlist/Favorite Button
                                      FavouriteButtonWidget(
                                        backgroundColor: _appBarOpacity > 0.5
                                            ? Colors.transparent
                                            : Colors.black
                                                .withValues(alpha: 0.4),
                                        iconColor: _appBarOpacity > 0.5
                                            ? theme.primaryColor
                                            : Colors.white,
                                        productId:
                                            details.productDetailsModel?.id,
                                        fromProductDetails: true,
                                      ),
                                    ],
                                  )
                                : const SizedBox(
                                    width: 84), // Spacer to balance back button
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Consumer<ProductDetailsController>(
            builder: (context, details, child) {
          return !details.isDetails &&
                  details.productDetailsModel?.userId != null
              ? BottomCartWidget(
                  product: details.productDetailsModel,
                  cartDetailsKey: cartDetailsKey,
                  onAddToCart: () {
                    if (runAddToCartAnimation != null) {
                      runAddToCartAnimation!(productImageKey);
                    }
                  },
                )
              : const SizedBox();
        }),
      ),
      ),
    );
  }
}

class _ProductDetailsProductListWidget extends StatelessWidget {
  const _ProductDetailsProductListWidget({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailsController>(
        builder: (context, productDetailsController, _) {
      return Column(children: [
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Consumer<ProductController>(builder: (context, productController, _) {
          return (productController.relatedProductList != null &&
                  productController.relatedProductList!.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeExtraSmall),
                  child: TitleRowWidget(
                      title: getTranslated('related_products', context),
                      isDetailsPage: true))
              : const SizedBox();
        }),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeExtraSmall),
          child: RelatedProductWidget(),
        ),
        Consumer<SellerProductController>(
            builder: (context, sellerProductController, _) {
          return (sellerProductController.sellerMoreProduct != null &&
                  sellerProductController.sellerMoreProduct!.products != null &&
                  sellerProductController
                      .sellerMoreProduct!.products!.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeDefault),
                  child: TitleRowWidget(
                    title: getTranslated('more_from_the_shop', context),
                    onTap: () {
                      if (productDetailsController
                              .productDetailsModel?.addedBy ==
                          'seller') {
                        RouterHelper.getTopSellerRoute(
                          action: RouteAction.push,
                          slug: productDetailsController
                              .productDetailsModel?.seller?.shop?.slug,
                          sellerId: productDetailsController
                              .productDetailsModel?.seller?.id,
                          temporaryClose: productDetailsController
                              .productDetailsModel
                              ?.seller
                              ?.shop
                              ?.temporaryClose,
                          vacationStatus: productDetailsController
                                  .productDetailsModel
                                  ?.seller
                                  ?.shop
                                  ?.vacationStatus ??
                              false,
                          vacationEndDate: productDetailsController
                              .productDetailsModel
                              ?.seller
                              ?.shop
                              ?.vacationEndDate,
                          vacationStartDate: productDetailsController
                              .productDetailsModel
                              ?.seller
                              ?.shop
                              ?.vacationStartDate,
                          vacationDurationType: productDetailsController
                              .productDetailsModel
                              ?.seller
                              ?.shop!
                              .vacationDurationType,
                          name: productDetailsController
                              .productDetailsModel?.seller?.shop?.name,
                          banner: productDetailsController.productDetailsModel
                              ?.seller?.shop?.bannerFullUrl?.path,
                          image: productDetailsController.productDetailsModel
                              ?.seller?.shop?.imageFullUrl?.path,
                          fromMore: true,
                        );
                      } else {
                        RouterHelper.getTopSellerRoute(
                            sellerId: 0,
                            fromMore: true,
                            slug: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inHouseShop
                                ?.slug,
                            temporaryClose: Provider.of<SplashController>(context, listen: false)
                                    .configModel
                                    ?.inhouseTemporaryClose
                                    ?.status ??
                                false,
                            vacationStatus: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inhouseVacationAdd
                                ?.status,
                            vacationEndDate: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inhouseVacationAdd
                                ?.vacationEndDate,
                            vacationStartDate: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inhouseVacationAdd
                                ?.vacationStartDate,
                            vacationDurationType: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inhouseVacationAdd
                                ?.vacationDurationType,
                            name: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inHouseShop
                                ?.name,
                            banner: Provider.of<SplashController>(context, listen: false)
                                .configModel
                                ?.inHouseShop
                                ?.bannerFullUrl
                                ?.path,
                            image: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.imageFullUrl?.path);
                      }
                    },
                  ),
                )
              : const SizedBox();
        }),
        Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall),
            child: ShopMoreProductViewList(
                scrollController: scrollController,
                sellerId:
                    productDetailsController.productDetailsModel!.userId!,
                heroTagSuffix: hashCode.toString())),
      ]);
    }).animateScreenEntrance();
  }
}
