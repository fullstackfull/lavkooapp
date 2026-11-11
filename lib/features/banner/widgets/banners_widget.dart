import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/widgets/banner_shimmer.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';

class BannersWidget extends StatelessWidget {
  const BannersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BannerController>(
        builder: (context, bannerProvider, child) {
          double width = MediaQuery.of(context).size.width;

          return bannerProvider.mainBannerList != null
              ? bannerProvider.mainBannerList!.isNotEmpty
              ? SizedBox(
            width: width,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CarouselSlider.builder(
                  options: CarouselOptions(
                    aspectRatio: 1.1 / 1,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    pauseAutoPlayOnTouch: true,
                    pauseAutoPlayOnManualNavigate: true,
                    pauseAutoPlayInFiniteScroll: true,
                    enlargeFactor: 0.0,
                    enlargeCenterPage: false,
                    disableCenter: true,
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    scrollPhysics: const BouncingScrollPhysics(),
                    onPageChanged: (index, reason) {
                      Provider.of<BannerController>(context, listen: false)
                          .setCurrentIndex(index);
                    },
                  ),
                  itemCount: bannerProvider.mainBannerList!.length,
                  itemBuilder: (context, index, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),   // <-- سطر جديد (فتح)
                      child: Container(
                        decoration:  BoxDecoration(
                          borderRadius: BorderRadius.circular(12),   // غيّرتها لتصير مدورة (اختياري)

                          // borderRadius: BorderRadius.zero,
                          boxShadow: [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),   // نفس الشي هون (اختياري)

                          // borderRadius: BorderRadius.zero,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Banner Image
                              InkWell(
                                onTap: () => bannerProvider.openBanner(
                                    context, bannerProvider.mainBannerList?[index]),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Provider.of<ThemeController>(context, listen: false).darkTheme
                                        ? Theme.of(context).primaryColor.withValues(alpha: .1)
                                        : Theme.of(context).primaryColor.withValues(alpha: .05),
                                  ),
                                  child: CustomImageWidget(
                                    image: '${bannerProvider.mainBannerList?[index].imageUrl}',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Subtle Gradient Overlay at the bottom
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 60,
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Floating Pagination Dots (عددها يتطابق مع البنرات، والنشط عريض وملون)
// Floating Pagination Dots (بدون كونتينر خارجي)
                Positioned(
                  bottom: 90,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bannerProvider.mainBannerList!.map((banner) {
                      int idx = bannerProvider.mainBannerList!.indexOf(banner);
                      bool isActive = bannerProvider.currentIndex == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22.0 : 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.grey.shade800   // Active: رمادي غامق
                              : Colors.grey.shade300,  // Inactive: رمادي فاتح
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ),
                ),              ],
            ),
          )
              : const SizedBox()
              : const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: BannerShimmer(),
          );
        });
  }
}