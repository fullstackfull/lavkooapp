import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class SubCategoriesScreen extends StatefulWidget {
  final CategoryModel category;

  const SubCategoriesScreen({super.key, required this.category});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ جلب البانر والـ sub categories إذا لم تكن موجودة
    final categoryController = Provider.of<CategoryController>(context, listen: false);
    if (widget.category.bannerFullUrl?.path == null ||
        widget.category.subCategories?.isEmpty == true) {
      categoryController.getCategoryPageHeaderData(widget.category.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(title: widget.category.name),
      body: Consumer<CategoryController>(
        builder: (context, categoryController, child) {
          // ✅ نستخدم البيانات المحدثة من الـ Controller إن وجدت
          final updatedCategory = categoryController.categoryList
              .firstWhere(
                (c) => c.id == widget.category.id,
            orElse: () => widget.category,
          );

          final bannerUrl = updatedCategory.bannerFullUrl?.path;
          final hasBanner = bannerUrl != null &&
              bannerUrl.trim().isNotEmpty &&
              bannerUrl.toLowerCase() != 'null';

          final subCategories = updatedCategory.subCategories ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ البانر في الأعلى
              if (hasBanner)
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: CustomImageWidget(
                      image: bannerUrl,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // عنوان
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeDefault,
                  0,
                ),
                child: Text(
                  getTranslated('sub_categories', context) ?? 'Sub Categories',
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              // ✅ Sub Categories بشكل أفقي مربعات
              SizedBox(
                height: 130,
                child: subCategories.isNotEmpty
                    ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault),
                  itemCount: subCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final sub = subCategories[index];
                    return InkWell(
                      onTap: () {
                        RouterHelper.getBrandCategoryRoute(
                          action: RouteAction.push,
                          isBrand: false,
                          id: sub.id,
                          name: sub.name,
                          subCategory: sub,
                          bannerImageUrl: updatedCategory.bannerFullUrl?.path,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E2C)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CustomImageWidget(
                                  image: sub.displayImageUrl ?? '',
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                sub.name ?? '',
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.8),
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
                    : Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}