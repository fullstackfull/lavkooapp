import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/enums/product_type.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ProductPopupFilterWidget extends StatelessWidget {
  const ProductPopupFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ProductController, ProductType>(
      selector: (_, productController) => productController.productType,
      builder: (ctx, selectedType, _) {
        final primaryColor = Theme.of(context).primaryColor;

        final filterList = [
          _FilterItem(
            type: ProductType.discountedProduct,
            title: getTranslated('discounted_product', context) ?? 'Discounted',
          ),
          _FilterItem(
            type: ProductType.newArrival,
            title: getTranslated('new_arrival', context) ?? 'New Arrival',
          ),
          _FilterItem(
            type: ProductType.topProduct,
            title: getTranslated('top_product', context) ?? 'Top Product',
          ),
          _FilterItem(
            type: ProductType.bestSelling,
            title: getTranslated('best_selling', context) ?? 'Best Selling',
          ),
        ];

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall),
            itemCount: filterList.length,
            itemBuilder: (context, index) {
              final item = filterList[index];
              final isSelected = selectedType == item.type;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Material(
                  color: isSelected
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Provider.of<ProductController>(context, listen: false)
                          .onChangeSelectedProductType(item.type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : primaryColor.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.title,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterItem {
  final ProductType type;
  final String title;

  _FilterItem({required this.type, required this.title});
}
