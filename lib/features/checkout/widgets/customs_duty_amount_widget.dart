import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/shipping/customs_duty.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// What the shop quotes for customs duty, shown before the customer pays (H1-09).
///
/// Nothing at all when the shop says nothing, which is every basket that crosses no border and every shop with duty switched off: a row
/// about duty on an order that never approaches a border is noise.
///
/// Three things can be said, and they are not the same thing:
///
///   - an amount is payable, and who pays it -- the figure and the sentence;
///   - nothing is payable, which needs no row: the basket is under the destination's threshold or crosses nothing;
///   - nobody has written a rule for that route, which is NOT nothing payable. The customer is told so in the shop's own words rather
///     than shown a nought, because a nought would say the goods cross free and the shop has not said that.
///
/// The sentence arrives already in the customer's language; the app translates nothing here.
class CustomsDutyAmountWidget extends StatelessWidget {
  const CustomsDutyAmountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomsDuty? duty = context.select<CheckoutController, CustomsDuty?>(
      (CheckoutController checkout) => checkout.customsDuty,
    );

    if (duty == null || duty.kind == CustomsDuty.none) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(getTranslated('customs_duty', context) ?? '', style: textRegular),
              Text(
                duty.isPayable ? PriceConverter.convertPrice(context, duty.amount) : '—',
                style: textRegular,
              ),
            ],
          ),
          if (duty.notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                duty.notice!,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
