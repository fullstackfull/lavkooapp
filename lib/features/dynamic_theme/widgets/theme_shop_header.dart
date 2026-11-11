import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// The shop a showcase is about, above the products it is selling.
///
/// The shop travels inside the section's settings as the same customer-safe
/// summary every other vendor payload carries — the app is never asked to
/// resolve a shop id it has no endpoint for, and nothing private crosses over.
class ThemeShopHeader extends StatelessWidget {
  final ThemeSectionSchema section;
  const ThemeShopHeader({super.key, required this.section});

  Map<String, dynamic>? get _shop {
    final dynamic shop = section.settings.raw['shop'];
    return shop is Map<String, dynamic> ? shop : null;
  }

  void _openShop(BuildContext context, Map<String, dynamic> shop) {
    RouterHelper.getTopSellerRoute(
      action: RouteAction.push,
      slug: shop['slug']?.toString(),
      sellerId: shop['seller_id'] is int ? shop['seller_id'] as int : null,
      temporaryClose: shop['temporary_close'] == true,
      vacationStatus: shop['vacation_status'] == true,
      vacationEndDate: DateTime.tryParse('${shop['vacation_end_date']}'),
      vacationStartDate: DateTime.tryParse('${shop['vacation_start_date']}'),
      vacationDurationType: null,
      name: shop['name']?.toString(),
      banner: shop['banner_full_url']?.toString(),
      image: shop['image_full_url']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? shop = _shop;
    if (shop == null) {
      return const SizedBox.shrink();
    }

    final bool showCover = section.settings.flag('cover', true);
    final bool showStats = section.settings.flag('stats', true);
    final bool showVisit = section.settings.flag('view_all', true);
    final num rating = shop['average_rating'] is num
        ? shop['average_rating'] as num
        : num.tryParse('${shop['average_rating']}') ?? 0;
    final int reviews = shop['review_count'] is int
        ? shop['review_count'] as int
        : int.tryParse('${shop['review_count']}') ?? 0;
    final int products = shop['products_count'] is int
        ? shop['products_count'] as int
        : int.tryParse('${shop['products_count']}') ?? 0;
    final bool official = shop['author_type'] == 'admin';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, 0,
          Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openShop(context, shop),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BrandColors.hairline),
          ),
          child: Column(children: [
            if (showCover)
              SizedBox(
                height: 96,
                width: double.infinity,
                child: CustomImageWidget(
                  image: shop['banner_full_url']?.toString() ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).highlightColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                        image: shop['image_full_url']?.toString() ?? ''),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            section.settings.string('title') ??
                                shop['name']?.toString() ??
                                '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tajawalHeavy.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                          ),
                        ),
                        // The platform vouches for its own store and no other.
                        if (official) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 15, color: BrandColors.blue),
                        ],
                      ]),
                      if (showStats)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(children: [
                            // A rating needs reviews behind it and a value of
                            // its own; 0.0 is a verdict no shop earned.
                            if (reviews > 0 && rating > 0) ...[
                              const Icon(Icons.star_rate_rounded,
                                  size: 15, color: BrandColors.star),
                              Text(
                                rating.toStringAsFixed(1),
                                style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '$products ${getTranslated('products', context)}',
                              style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: BrandColors.mutedText),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ),
                if (showVisit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: BrandGradients.primary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      getTranslated('visit_store', context) ?? '',
                      style: textBold.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Colors.white),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
