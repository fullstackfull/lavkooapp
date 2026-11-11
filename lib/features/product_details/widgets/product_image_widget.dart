import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/discount_tag_widget.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/product_details/domain/models/product_details_model.dart';
import 'package:syriapharmacy/features/product_details/enums/preview_type.dart';
import 'package:syriapharmacy/features/product_details/screens/product_image_screen.dart';
import 'package:syriapharmacy/features/product_details/widgets/audio_preview.dart';
import 'package:syriapharmacy/features/product_details/widgets/download_preview_file.dart';
import 'package:syriapharmacy/features/product_details/widgets/image_preview.dart';
import 'package:syriapharmacy/features/product_details/widgets/pdf_preview_flutter.dart';
import 'package:syriapharmacy/features/product_details/widgets/video_preview.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';

class ProductImageWidget extends StatelessWidget {
  final ProductDetailsModel? productModel;
  final bool fromFlashDeals;
  final GlobalKey? productImageKey;
  final String? heroTag;
  ProductImageWidget(
      {super.key,
      required this.productModel,
      required this.fromFlashDeals,
      this.productImageKey,
      this.heroTag});

  final PageController _controller = PageController();
  @override
  Widget build(BuildContext context) {
    return productModel != null
        ? Consumer<ProductDetailsController>(
            builder: (context, productController, _) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => productModel!.productImagesNull!
                        ? null
                        : Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return ProductImageScreen(
                                  title:
                                      getTranslated('product_image', context),
                                  imageList: productModel!.imagesFullUrl,
                                );
                              },
                            ),
                          ),
                    child: (productModel != null &&
                            productModel!.imagesFullUrl != null)
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(24)),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.width,
                                  child: productModel!.imagesFullUrl != null
                                      ? PageView.builder(
                                          controller: _controller,
                                          itemCount: productModel!
                                              .imagesFullUrl!.length,
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      bottom:
                                                          Radius.circular(24)),
                                              child: index == 0
                                                  ? Container(
                                                      key: productImageKey,
                                                      child: Hero(
                                                        tag: heroTag ??
                                                            'product-image-${productModel!.id}',
                                                        child: CustomImageWidget(
                                                            height:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                            width:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                            image:
                                                                '${productModel!.imagesFullUrl![index].path}'),
                                                      ),
                                                    )
                                                  : CustomImageWidget(
                                                      height:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      image:
                                                          '${productModel!.imagesFullUrl![index].path}'),
                                            );
                                          },
                                          onPageChanged: (index) =>
                                              productController
                                                  .setImageSliderSelectedIndex(
                                                      index),
                                        )
                                      : const SizedBox(),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 15,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 40),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: _indicators(context),
                                      ),
                                      const Spacer(),
                                      Provider.of<ProductDetailsController>(
                                                      context)
                                                  .imageSliderIndex !=
                                              null
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                right: Dimensions
                                                    .paddingSizeDefault,
                                                bottom: Dimensions
                                                    .paddingSizeExtraSmall,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.4),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${productController.imageSliderIndex! + 1}/${productModel?.imagesFullUrl?.length}',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                ),
                                (productModel?.productType == 'digital' &&
                                        productModel?.previewFileFullUrl !=
                                            null &&
                                        productModel
                                                ?.previewFileFullUrl?.path !=
                                            '')
                                    ? Positioned(
                                        right: 15,
                                        bottom: 45,
                                        child: InkWell(
                                          onTap: () => _showPreview(
                                              productModel?.previewFileFullUrl
                                                      ?.path ??
                                                  '',
                                              productModel?.name ?? '',
                                              productModel?.previewFileFullUrl
                                                      ?.key ??
                                                  '',
                                              context),
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                                Dimensions
                                                    .paddingSizeExtraSmall),
                                            height: 35,
                                            width: 81,
                                            decoration: BoxDecoration(
                                                color:
                                                    Theme.of(context).cardColor,
                                                borderRadius: BorderRadius
                                                    .circular(Dimensions
                                                        .paddingSizeExtraSmall),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x0D1B7FED),
                                                    offset: Offset(0, 6),
                                                    blurRadius: 12,
                                                    spreadRadius: -3,
                                                  ),
                                                  BoxShadow(
                                                    color: Color(0x0D1B7FED),
                                                    offset: Offset(0, -6),
                                                    blurRadius: 12,
                                                    spreadRadius: -3,
                                                  ),
                                                ]),
                                            child: Row(children: [
                                              Image.asset(Images.previewEyeIcon,
                                                  width: 15),
                                              const SizedBox(
                                                  width: Dimensions
                                                      .paddingSizeExtraSmall),
                                              Text(
                                                  '${getTranslated('preview', context)}',
                                                  style:
                                                      titilliumRegular.copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeDefault)),
                                            ]),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                                if (fromFlashDeals)
                                  Positioned(
                                    top:
                                        MediaQuery.of(context).padding.top + 16,
                                    left: 16,
                                    child:
                                        Image.asset(Images.flashDeal, scale: 2),
                                  ),
                                ((productModel?.discount ?? 0) > 0 ||
                                        (productModel?.clearanceSale != null))
                                    ? DiscountTagDetailsWidget(
                                        productModel: productModel!,
                                        positionedTop:
                                            MediaQuery.of(context).padding.top +
                                                16,
                                        positionedLeft: fromFlashDeals ? 60 : 16,
                                        topLeftBorderRadius:
                                            Dimensions.radiusDefault,
                                        bottomRightBorderRadius:
                                            Dimensions.radiusDefault)
                                    : const SizedBox.shrink(),
                              ]),
                            ),
                          )
                        : const SizedBox(),
                  ),
                  // Padding(
                  //   padding: EdgeInsets.only(
                  //     left: Provider.of<LocalizationController>(context,
                  //                 listen: false)
                  //             .isLtr
                  //         ? Dimensions.homePagePadding
                  //         : 0,
                  //     right: Provider.of<LocalizationController>(context,
                  //                 listen: false)
                  //             .isLtr
                  //         ? 0
                  //         : Dimensions.homePagePadding,
                  //     bottom: Dimensions.paddingSizeLarge,
                  //   ),
                  //   child: SizedBox(
                  //       height: 60,
                  //       child: RepaintBoundary(
                  //           child: productModel!.imagesFullUrl!.length <= 5
                  //               ? Row(
                  //                   mainAxisAlignment: MainAxisAlignment.center,
                  //                   children: List.generate(
                  //                     productModel!.imagesFullUrl!.length,
                  //                     (index) => _buildThumbnailItem(
                  //                         context, index, productController),
                  //                   ),
                  //                 )
                  //               : ListView.builder(
                  //                   scrollDirection: Axis.horizontal,
                  //                   addAutomaticKeepAlives: false,
                  //                   addRepaintBoundaries: false,
                  //                   itemCount:
                  //                       productModel!.imagesFullUrl!.length,
                  //                   itemBuilder: (context, index) {
                  //                     return _buildThumbnailItem(
                  //                         context, index, productController);
                  //                   },
                  //                 ))),
                  // ),
                ]);
          })
        : const SizedBox();
  }

  Widget _buildThumbnailItem(BuildContext context, int index,
      ProductDetailsController productController) {
    return InkWell(
      onTap: () {
        productController.setImageSliderSelectedIndex(index);
        _controller.animateToPage(index,
            duration: const Duration(microseconds: 50), curve: Curves.ease);
      },
      child: Padding(
          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
          child: Center(
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: index == productController.imageSliderIndex
                              ? 2
                              : 0,
                          color: (index == productController.imageSliderIndex &&
                                  Provider.of<ThemeController>(context,
                                          listen: false)
                                      .darkTheme)
                              ? Theme.of(context).primaryColor
                              : (index == productController.imageSliderIndex &&
                                      !Provider.of<ThemeController>(context,
                                              listen: false)
                                          .darkTheme)
                                  ? Theme.of(context).primaryColor
                                  : const Color(0x00FFFFFF)),
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                          Dimensions.paddingSizeExtraSmall)),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    child: CustomImageWidget(
                        height: 50,
                        width: 50,
                        image: '${productModel!.imagesFullUrl![index].path}'),
                  )))),
    );
  }

  List<Widget> _indicators(BuildContext context) {
    List<Widget> indicators = [];
    for (int index = 0; index < productModel!.imagesFullUrl!.length; index++) {
      indicators.add(Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraExtraSmall),
        child: Container(
          width: index ==
                  Provider.of<ProductDetailsController>(context)
                      .imageSliderIndex
              ? 20
              : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: index ==
                    Provider.of<ProductDetailsController>(context)
                        .imageSliderIndex
                ? Theme.of(context).primaryColor
                : Theme.of(context).hintColor,
          ),
        ),
      ));
    }
    return indicators;
  }

  void _showPreview(
      String url, String productName, String fileName, BuildContext context) {
    PreviewType type =
        Provider.of<ProductDetailsController>(context, listen: false)
            .getFileType(url);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            insetPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: (type == PreviewType.pdf)
                ? PdfPreview(url: url, fileName: productName)
                : (type == PreviewType.image)
                    ? ImagePreview(url: url, fileName: productName)
                    : (type == PreviewType.video)
                        ? VideoPreview(url: url, fileName: productName)
                        : (type == PreviewType.audio)
                            ? AudioPreview(url: url, fileName: productName)
                            : (type == PreviewType.others)
                                ? DownloadPreview(url: url, fileName: fileName)
                                : const SizedBox(),
          );
        });
  }
}
