import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailsShimmer extends StatelessWidget {
  final String? heroTag;
  final String? image; // The product thumbnail to show during load
  const ProductDetailsShimmer({
    super.key,
    this.heroTag,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeController>(context).darkTheme;
    final Color shimmerBase =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFECECEC);
    final Color shimmerHighlight =
        isDark ? const Color(0xFF3A3A3A) : Colors.white;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero image (real image if available, else shimmer box) ──
          Hero(
            tag: heroTag ?? 'product-details-image-shimmer',
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: image != null && image!.isNotEmpty
                  ? CustomImageWidget(
                      image: image!,
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      color: shimmerBase,
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Shimmer skeleton below the image ──
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Shimmer.fromColors(
              baseColor: shimmerBase,
              highlightColor: shimmerHighlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title card skeleton
                  Container(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Container(
                          height: 22,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: shimmerBase,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 22,
                          width: MediaQuery.of(context).size.width * 0.6,
                          decoration: BoxDecoration(
                            color: shimmerBase,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Price
                        Container(
                          height: 30,
                          width: 130,
                          decoration: BoxDecoration(
                            color: shimmerBase,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: shimmerBase, height: 1),
                        const SizedBox(height: 16),
                        // Rating row
                        Row(children: [
                          Container(
                            height: 28,
                            width: 70,
                            decoration: BoxDecoration(
                              color: shimmerBase,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 18,
                            width: 90,
                            decoration: BoxDecoration(
                              color: shimmerBase,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tabs skeleton (Reviews / Specification)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Description lines skeleton
                  Container(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(children: [
                      for (int i = 0; i < 5; i++) ...[
                        Container(
                          height: 14,
                          width: i == 4
                              ? MediaQuery.of(context).size.width * 0.5
                              : double.infinity,
                          decoration: BoxDecoration(
                            color: shimmerBase,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        if (i < 4) const SizedBox(height: 10),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100), // padding for bottom bar
        ],
      ),
    );
  }
}
