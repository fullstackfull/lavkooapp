import 'package:flutter/material.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/common/basewidget/slider_product_shimmer_widget.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/product/enums/product_type.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class FeaturedProductWidget extends StatelessWidget {
  const FeaturedProductWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTab(context);

    final viewportFraction = isTablet ? 0.4 : 0.6;

    return Selector<ProductController, ProductModel?>(
        selector: (ctx, productController) =>
            productController.featuredProductModel,
        builder: (context, featuredProductModel, _) {
          return (featuredProductModel?.products?.isNotEmpty ?? false)
              ? Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    child: TitleRowWidget(
                      title: getTranslated('featured_products', context),
                      onTap: () => RouterHelper.getViewAllProductScreenRoute(
                          productType: ProductType.featuredProduct,
                          action: RouteAction.push),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.isTab(context) ? 360 : 310,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.homePagePadding),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: featuredProductModel?.products?.length ?? 0,
                      itemBuilder: (context, index) {
                        return Container(
                          width: ResponsiveHelper.isTab(context) ? 220 : 160,
                          margin: const EdgeInsets.only(
                              right: Dimensions.paddingSizeSmall),
                          child: ProductWidget(
                              productModel:
                                  featuredProductModel!.products![index],
                              productNameLine: 1,
                              margin: 0,
                              heroTag:
                              'product-image-${featuredProductModel.products![index].id}-featured'),
                        ).animateHorizontalListEntrance(index);
                      },
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingSizeExtraSmall)
                ])
              : featuredProductModel == null
                  ? const SliderProductShimmerWidget()
                  : const SizedBox();
        });
  }
}
