import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/home/widgets/aster_theme/find_what_you_need_shimmer.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:provider/provider.dart';

class FindWhatYouNeedView extends StatelessWidget {
  const FindWhatYouNeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ProductController>(
        builder: (context, productController, _) {
      return productController.findWhatYouNeedModel != null
          ? (productController.findWhatYouNeedModel!.findWhatYouNeed != null &&
                  productController
                      .findWhatYouNeedModel!.findWhatYouNeed!.isNotEmpty)
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 145,
                  child: CarouselSlider.builder(
                    options: CarouselOptions(
                      padEnds: false,
                      viewportFraction: .82,
                      autoPlay: true,
                      enableInfiniteScroll: false,
                    ),
                    itemCount: productController
                        .findWhatYouNeedModel!.findWhatYouNeed!.length,
                    itemBuilder: (context, index, _) {
                      return InkWell(
                        onTap: () {
                          RouterHelper.getBrandCategoryRoute(
                            action: RouteAction.push,
                            isBrand: false,
                            id: productController.findWhatYouNeedModel!
                                .findWhatYouNeed![index].id,
                            name: productController.findWhatYouNeedModel!
                                .findWhatYouNeed![index].name,
                            bannerImageUrl: productController
                                .findWhatYouNeedModel!
                                .findWhatYouNeed![index]
                                .bannerFullUrl
                                ?.path,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isLtr ? Dimensions.paddingSizeSmall : 0,
                            right: index + 1 ==
                                    productController.findWhatYouNeedModel!
                                        .findWhatYouNeed!.length
                                ? Dimensions.paddingSizeDefault
                                : isLtr
                                    ? 0
                                    : Dimensions.paddingSizeDefault,
                          ),
                          child: Container(
                            width: 305,
                            height: 140,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Theme.of(context).highlightColor
                                  : Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.06),
                                  width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Folded Dog-Ear Bookmark
                                Positioned(
                                  top: 0,
                                  right: isLtr ? 0 : null,
                                  left: isLtr ? null : 0,
                                  child: Container(
                                    height: 23,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: isLtr
                                            ? const Radius.circular(
                                                Dimensions.radiusSmall)
                                            : Radius.zero,
                                        bottomRight: isLtr
                                            ? Radius.zero
                                            : const Radius.circular(
                                                Dimensions.radiusSmall),
                                      ),
                                      gradient: LinearGradient(
                                        stops: const [.5, .5],
                                        begin: isLtr
                                            ? Alignment.bottomLeft
                                            : Alignment.bottomRight,
                                        end: isLtr
                                            ? Alignment.topRight
                                            : Alignment.topLeft,
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeDefault),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title and Product Count
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${productController.findWhatYouNeedModel!.findWhatYouNeed![index].name}',
                                                  style: textBold.copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${productController.findWhatYouNeedModel!.findWhatYouNeed![index].productCount} ${getTranslated('products', context)}',
                                                  style: textRegular.copyWith(
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 40),
                                        ],
                                      ),
                                      const SizedBox(
                                          height: Dimensions.paddingSizeSmall),

                                      // Subcategories list
                                      Expanded(
                                        child: SizedBox(
                                          width: 240,
                                          child: ListView.builder(
                                            itemCount: productController
                                                    .findWhatYouNeedModel!
                                                    .findWhatYouNeed![index]
                                                    .childes
                                                    ?.length ??
                                                0,
                                            scrollDirection: Axis.horizontal,
                                            itemBuilder: (context, subIndex) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 12),
                                                child: InkWell(
                                                  onTap: () {
                                                    RouterHelper
                                                        .getBrandCategoryRoute(
                                                      action: RouteAction.push,
                                                      isBrand: false,
                                                      id: productController
                                                          .findWhatYouNeedModel
                                                          ?.findWhatYouNeed![
                                                              index]
                                                          .childes?[subIndex]
                                                          .id,
                                                      name: productController
                                                          .findWhatYouNeedModel
                                                          ?.findWhatYouNeed![
                                                              index]
                                                          .childes?[subIndex]
                                                          .name,
                                                    );
                                                  },
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        width: 44,
                                                        height: 44,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isDark
                                                              ? Theme.of(
                                                                      context)
                                                                  .scaffoldBackgroundColor
                                                              : const Color(
                                                                  0xFFF5F5F5),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          border: Border.all(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.08),
                                                              width: 1),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                      alpha:
                                                                          0.02),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            )
                                                          ],
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child:
                                                              CustomImageWidget(
                                                            fit: BoxFit.cover,
                                                            image:
                                                                '${productController.findWhatYouNeedModel!.findWhatYouNeed![index].childes?[subIndex].iconFullUrl?.path}',
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        width: 55,
                                                        child: Text(
                                                          '${productController.findWhatYouNeedModel!.findWhatYouNeed![index].childes?[subIndex].name}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: textMedium
                                                              .copyWith(
                                                            fontSize: 10,
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color
                                                                ?.withValues(
                                                                    alpha: 0.8),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Arrow Badge
                                Positioned(
                                  right: isLtr ? 16 : null,
                                  left: isLtr ? null : 16,
                                  top: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Theme.of(context)
                                              .scaffoldBackgroundColor
                                          : Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLtr
                                          ? Icons.arrow_forward_rounded
                                          : Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad)
              : const SizedBox()
          : const FindWhatYouNeedShimmer();
    });
  }
}
