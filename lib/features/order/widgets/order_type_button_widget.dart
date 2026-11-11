import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/order/controllers/order_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

import 'package:syriapharmacy/core/animations/app_animations.dart';

class OrderTypeButton extends StatelessWidget {
  final String? text;
  final int index;

  const OrderTypeButton({super.key, required this.text, required this.index});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<OrderController>(builder: (context, orderController, _) {
        bool isActive = orderController.orderTypeIndex == index;
        return TextButton(
          onPressed: () => orderController.setIndex(index),
          style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                border: Border.all(
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor.withValues(alpha: .2)),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : null,
                borderRadius: BorderRadius.circular(50)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text!,
                    style: titilliumBold.copyWith(
                      color: isActive
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: Dimensions.fontSizeSmall,
                    )),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ).animateHorizontalListEntrance(index);
      }),
    );
  }
}
