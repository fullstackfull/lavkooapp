import 'package:flutter/material.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/deal/controllers/featured_deal_controller.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/features/deal/widgets/featured_deal_list_widget.dart';
import 'package:provider/provider.dart';

class FeaturedDealScreenView extends StatelessWidget {
  const FeaturedDealScreenView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      CustomAppBar(title: getTranslated('featured_deals', context)),
      Expanded(
          child: RefreshIndicator(
              backgroundColor: Theme.of(context).primaryColor,
              onRefresh: () async => await Provider.of<FeaturedDealController>(
                      context,
                      listen: false)
                  .getFeaturedDealList(),
              child: const Padding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  child: FeaturedDealsListWidget(isHomePage: false))))
    ]));
  }
}
