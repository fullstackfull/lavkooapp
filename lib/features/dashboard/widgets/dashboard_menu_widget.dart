import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CustomMenuWidget extends StatelessWidget {
  final bool isSelected;
  final String name;
  final String icon;
  final bool showCartCount;
  final VoidCallback onTap;

  const CustomMenuWidget({
    super.key,
    required this.isSelected,
    required this.name,
    required this.icon,
    required this.onTap,
    this.showCartCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).primaryColor;
    final Color inactiveColor = Theme.of(context).hintColor;

    return InkWell(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with cart badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Image.asset(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    width: Dimensions.menuIconSize,
                    height: Dimensions.menuIconSize,
                  ),
                ),
                if (showCartCount)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Consumer<CartController>(
                      builder: (context, cart, child) {
                        return cart.cartList.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  cart.cartList.length.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveHelper.isTab(context) ? 9 : 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Dot indicator - matches Figma exactly
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
