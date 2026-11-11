import 'package:flutter/material.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class SquareButtonWidget extends StatelessWidget {
  final String image;
  final String? title;
  final Widget? navigateTo;
  final int count;
  final bool hasCount;
  final bool isWallet;
  final double? balance;
  final bool isLoyalty;
  final String? subTitle;
  final Function? onTap;

  const SquareButtonWidget(
      {super.key,
      required this.image,
      required this.title,
      this.navigateTo,
      required this.count,
      required this.hasCount,
      this.isWallet = false,
      this.balance,
      this.subTitle,
      this.isLoyalty = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context).darkTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap != null ? () => onTap!() : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 125,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Soft background decor circle
            Positioned(
              bottom: -10,
              right: -10,
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.03),
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Row(
                children: [
                  // Left Side: Circular Icon Wrapper + Count Badge Stack
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: image.endsWith('.json')
                            ? Lottie.asset(
                                image,
                                width: 16,
                                height: 16,
                                delegates: LottieDelegates(
                                  values: [
                                    ValueDelegate.color(
                                      const ['**'],
                                      value: primaryColor,
                                    ),
                                  ],
                                ),
                              )
                            : Image.asset(
                                image,
                                color: primaryColor,
                                width: 16,
                                height: 16,
                              ),
                      ),
                      if (hasCount)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 13,
                              minHeight: 13,
                            ),
                            child: Text(
                              count.toString(),
                              style: textBold.copyWith(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // Right Side: Column for Title and Optional Wallet Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isWallet) ...[
                          Text(
                            title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textMedium.copyWith(
                              fontSize: 9,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isLoyalty
                                ? (balance != null
                                    ? balance!.toStringAsFixed(0)
                                    : '0')
                                : (balance != null
                                    ? PriceConverter.convertPrice(
                                        context, balance)
                                    : '0'),
                            style: textBold.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          Text(
                            title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall - 1,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withOpacity(0.95),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
