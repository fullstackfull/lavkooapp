import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/paginated_list_view_widget.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/shop/widgets/seller_card.dart';
import 'package:syriapharmacy/features/shop/widgets/seller_shimmer.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:provider/provider.dart';

class AllTopSellerScreen extends StatefulWidget {
  final String title;
  const AllTopSellerScreen({super.key, required this.title});

  @override
  State<AllTopSellerScreen> createState() => _AllTopSellerScreenState();
}

class _AllTopSellerScreenState extends State<AllTopSellerScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Provider.of<ShopController>(context, listen: false)
        .setSellerType('all', notify: false);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ShopController, String?>(
      selector: (ctx, shopController) => shopController.sellerType,
      builder: (context, sellerType, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).highlightColor,
          appBar: CustomAppBar(
              title: getTranslated(
                      widget.title.isNotEmpty ? widget.title : 'our_vendors',
                      context) ??
                  getTranslated('our_vendors', context)),
          body: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(children: [
              _SellerSegmentRow(selected: sellerType),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Expanded(child: Consumer<ShopController>(
                  builder: (context, topSellerProvider, child) {
                return (topSellerProvider
                            .filteredSellerModel?.sellers?.isNotEmpty ??
                        false)
                    ? PaginatedListView(
                        scrollController: scrollController,
                        onPaginate: (int? offset) async {
                          await topSellerProvider.getFilteredSellerList(
                            offset: offset ?? 1,
                            type: topSellerProvider.sellerType,
                            // false, offset?? 1, type : topSellerProvider.sellerType,
                          );
                        },
                        totalSize:
                            topSellerProvider.filteredSellerModel?.totalSize,
                        offset: topSellerProvider.filteredSellerModel?.offset,
                        itemView: Expanded(
                          child: ListView.builder(
                            itemCount: topSellerProvider
                                .filteredSellerModel?.sellers?.length,
                            padding: EdgeInsets.zero,
                            controller: scrollController,
                            itemBuilder: (BuildContext context, int index) {
                              // No fixed height: a shop with a rating carries
                              // one more pill than a shop without, and clamping
                              // every card to the shorter of the two clipped it.
                              return SellerCard(
                                sellerModel: topSellerProvider
                                    .filteredSellerModel?.sellers?[index],
                                isHomePage: false,
                                index: index,
                                length: topSellerProvider
                                        .filteredSellerModel?.sellers?.length ??
                                    0,
                              );
                            },
                          ),
                        ),
                      )
                    : (topSellerProvider
                                .filteredSellerModel?.sellers?.isEmpty ??
                            false)
                        ? const SizedBox()
                        : const SellerShimmer();
              })),
            ]),
          ),
        );
      },
    );
  }
}

/// Which slice of the marketplace is on screen — all shops, the highest rated,
/// or the ones that just opened.
class _SellerSegmentRow extends StatelessWidget {
  final String? selected;
  const _SellerSegmentRow({this.selected});

  static const Map<String, String> _segments = {
    'all': 'all_vendors',
    'top': 'top_rated_vendors',
    'new': 'new_vendors',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _segments.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        itemBuilder: (context, index) {
          final MapEntry<String, String> segment =
              _segments.entries.elementAt(index);
          final bool active = selected == segment.key;
          return InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => Provider.of<ShopController>(context, listen: false)
                .setSellerType(segment.key, notify: true),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                gradient: active ? BrandGradients.primary : null,
                color: active ? null : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                    color: active ? Colors.transparent : BrandColors.hairline),
              ),
              child: Text(
                getTranslated(segment.value, context) ?? '',
                style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: active
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          );
        },
      ),
    );
  }
}
