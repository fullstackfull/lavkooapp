import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/no_internet_screen_widget.dart';
import 'package:syriapharmacy/common/basewidget/paginated_list_view_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_shimmer_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class OfferProductListScreen extends StatefulWidget {
  final bool showBackButton;
  const OfferProductListScreen({super.key, this.showBackButton = true});

  @override
  State<OfferProductListScreen> createState() => _OfferProductListScreenState();
}

class _OfferProductListScreenState extends State<OfferProductListScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Provider.of<ProductController>(context, listen: false)
        .getDiscountedProductList(1, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${getTranslated('offers', context)}',
        isBackButtonExist: widget.showBackButton,
      ),
      body: Consumer<ProductController>(
        builder: (context, productController, child) {
          if (productController.discountedProductModel == null) {
            return const ProductShimmer(isEnabled: true, isHomePage: false);
          }

          return (productController
                      .discountedProductModel?.products?.isNotEmpty ??
                  false)
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault)
                      .copyWith(bottom: Dimensions.paddingSizeSmall),
                  child: PaginatedListView(
                    scrollController: scrollController,
                    totalSize:
                        productController.discountedProductModel?.totalSize,
                    offset: productController.discountedProductModel?.offset,
                    onPaginate: (int? offset) async => await productController
                        .getDiscountedProductList(offset ?? 1, false),
                    itemView: Expanded(
                      child: RepaintBoundary(
                        child: MasonryGridView.count(
                          itemCount: productController
                              .discountedProductModel?.products?.length,
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(0),
                          controller: scrollController,
                          itemBuilder: (BuildContext context, int index) {
                            return ProductWidget(
                                productModel: productController
                                    .discountedProductModel!.products![index]);
                          },
                        ),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: NoInternetOrDataScreenWidget(
                  isNoInternet: false,
                  message: 'currently_no_offers_available',
                  icon: Images.noOffer,
                ));
        },
      ),
    );
  }
}
