

import 'package:flutter/material.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/widgets/category_widget.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/helper/route_healper.dart';

import 'category_shimmer_widget.dart';

class CategoryListWidget extends StatelessWidget {
  final bool isHomePage;
  const CategoryListWidget({super.key, required this.isHomePage});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(
      builder: (context, categoryProvider, child) {
        final int count = categoryProvider.categoryList.length;

        return Column(children: [
          categoryProvider.categoryList.isNotEmpty
              ? SizedBox(
            height: 175,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.homePagePadding),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: count,
              itemBuilder: (context, index) {
                final category = categoryProvider.categoryList[index];

                return InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    // ✅ نمرر Banner URL من الـ controller Map أو من الـ model
                    final bannerUrl = categoryProvider.getBannerForCategory(category.id)
                        ?? category.bannerFullUrl?.path;

                    RouterHelper.getBrandCategoryRoute(
                      action: RouteAction.push,
                      isBrand: false,
                      id: category.id,
                      name: category.name,
                      categoryModel: category,
                      isAllProduct: true,
                      bannerImageUrl: bannerUrl,
                    );
                  },
                  child: SizedBox(
                    width: 76,
                    child: CategoryWidget(
                      category: category,
                      index: index,
                      length: count,
                    ),
                  ),
                ).animateHorizontalListEntrance(index);
              },
            ),
          )
              : const CategoryShimmerWidget(),
        ]);
      },
    );
  }
}