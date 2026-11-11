import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/order_details/controllers/order_details_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

class PaymentInfoWidget extends StatelessWidget {
  final OrderDetailsController? order;
  const PaymentInfoWidget({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(color: Theme.of(context).highlightColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeSmall),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(getTranslated('PAYMENT_STATUS', context)!,
                      style: titilliumRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                  Text(
                      (order!.orders!.paymentStatus != null &&
                              order!.orders!.paymentStatus!.isNotEmpty)
                          ? order!.orders!.paymentStatus!
                          : 'Digital Payment',
                      style: titilliumRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color))
                ])),
        order?.orders?.paymentMethod != null
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(getTranslated('PAYMENT_PLATFORM', context)!,
                    style: titilliumRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                Text(
                    order!.orders!.paymentMethod!
                        .replaceAll('_', ' ')
                        .capitalize(),
                    style: titilliumBold.copyWith(
                        color: Theme.of(context).primaryColor)),
              ])
            : const SizedBox(),
      ]),
    );
  }
}
