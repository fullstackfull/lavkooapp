import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scalify/responsive_scale/responsive_extensions.dart';
import 'package:syriapharmacy/features/product/domain/models/home_category_product_model.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:syriapharmacy/helper/route_healper.dart';

class HomeCategoryProductItemWidget extends StatelessWidget {
  final HomeCategoryProduct homeCategoryProduct;
  final int index;
  final bool isHomePage;
  const HomeCategoryProductItemWidget(
      {super.key,
      required this.homeCategoryProduct,
      required this.index,
      required this.isHomePage});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: index.isEven
          ? Theme.of(context).cardColor
          : Theme.of(context).colorScheme.onTertiary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHomePage) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (homeCategoryProduct.bannerFullUrl?.path != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child:
                AspectRatio(
                  aspectRatio: 1200 / 600,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl :homeCategoryProduct.bannerFullUrl!.path!,
                      width: double.infinity,
                      fit: BoxFit.fill,
                    ),
                  ),
                )
              ),
            TitleRowWidget(
              title: homeCategoryProduct.name,
              onTap: () {
                RouterHelper.getBrandCategoryRoute(
                  action: RouteAction.push,
                  isBrand: false,
                  id: homeCategoryProduct.id,
                  name: homeCategoryProduct.name,
                  bannerImageUrl: homeCategoryProduct.bannerFullUrl?.path,
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
          ConstrainedBox(
            constraints: homeCategoryProduct.products!.isNotEmpty
                ? const BoxConstraints(
                    maxHeight:
                        BouncingScrollSimulation.maxSpringTransferVelocity)
                : const BoxConstraints(maxHeight: 0),
            child: RepaintBoundary(
              child: MasonryGridView.count(
                  itemCount:
                      (isHomePage && homeCategoryProduct.products!.length > 4)
                          ? 4
                          : homeCategoryProduct.products!.length,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall),
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return InkWell(
                        onTap: () {
                          RouterHelper.getProductDetailsRoute(
                              action: RouteAction.push,
                              productId: homeCategoryProduct.products![i].id!,
                              slug: homeCategoryProduct.products![i].slug!,
                              image: homeCategoryProduct
                                  .products![i].thumbnailFullUrl?.path);
                        },
                        child: ProductWidget(
                            productModel: homeCategoryProduct.products![i]));
                  }),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}

