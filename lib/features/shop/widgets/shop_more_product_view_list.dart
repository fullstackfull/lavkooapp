import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/no_internet_screen_widget.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/common/basewidget/paginated_list_view_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_shimmer_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class ShopMoreProductViewList extends StatefulWidget {
  final ScrollController scrollController;
  final int sellerId;
  final String? heroTagSuffix;
  const ShopMoreProductViewList(
      {super.key, required this.scrollController, required this.sellerId, this.heroTagSuffix});

  @override
  State<ShopMoreProductViewList> createState() =>
      _ShopMoreProductViewListState();
}

class _ShopMoreProductViewListState extends State<ShopMoreProductViewList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SellerProductController>(
        builder: (context, productController, _) {
      return productController.sellerMoreProduct != null
          ? (productController.sellerMoreProduct!.products != null &&
                  productController.sellerMoreProduct!.products!.isNotEmpty)
              ? PaginatedListView(
                  scrollController: widget.scrollController,
                  onPaginate: (offset) async =>
                      await productController.getSellerProductList(
                          widget.sellerId.toString(), offset!, "",
                          reload: false),
                  totalSize: productController.sellerMoreProduct?.totalSize,
                  offset: productController.sellerMoreProduct?.offset,
                  itemView: MasonryGridView.count(
                    itemCount:
                        productController.sellerMoreProduct?.products?.length,
                    crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
                    padding: const EdgeInsets.all(0),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      final product =
                          productController.sellerMoreProduct!.products![index];
                      return ProductWidget(
                        productModel: product,
                        heroTag: 'product-image-${product.id}-shop-more-${widget.heroTagSuffix ?? ''}',
                      );
                    },
                  ))
              : const NoInternetOrDataScreenWidget(isNoInternet: false)
          : const ProductShimmer(isEnabled: true, isHomePage: false);
    });
  }
}
