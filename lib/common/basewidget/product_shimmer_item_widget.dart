import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ProductShimmerItemWidget extends StatelessWidget {
  const ProductShimmerItemWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).highlightColor),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).cardColor,
        highlightColor: Colors.grey[300]!,
        enabled: true,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Provider.of<ThemeController>(context).darkTheme
                    ? Theme.of(context).primaryColor.withValues(alpha: .05)
                    : Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
              ),
            ),
          ),

          // The approved card anatomy: meta line above the name, then the
          // price beside the add chip.
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 8,
                      width: 70,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Container(
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(children: [
                    Expanded(
                      child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4))),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Container(
                        height: 24,
                        width: 44,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8))),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
