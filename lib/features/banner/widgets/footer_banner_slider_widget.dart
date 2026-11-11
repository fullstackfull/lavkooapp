import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/domain/models/banner_model.dart';
import 'package:syriapharmacy/features/banner/widgets/single_banner_widget.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class FooterBannerSliderWidget extends StatelessWidget {
  const FooterBannerSliderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Column(children: [
      Consumer<BannerController>(
        builder: (context, bannerProvider, child) {
          List<BannerModel> bannerList = [];

          if ((bannerProvider.footerBannerList?.length ?? 0) > 1) {
            bannerList = bannerProvider.footerBannerList?.sublist(1) ?? [];
          }

          return bannerList.length == 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault),
                  child: SingleBannersWidget(bannerModel: bannerList[0]),
                )
              : bannerList.length > 1
                  ? Column(
                      children: [
                        SizedBox(
                          height: width * 0.35,
                          width: width,
                          child: CarouselSlider.builder(
                            options: CarouselOptions(
                              aspectRatio: 3 / 1,
                              viewportFraction: 0.85,
                              autoPlay: true,
                              pauseAutoPlayOnTouch: true,
                              pauseAutoPlayOnManualNavigate: true,
                              pauseAutoPlayInFiniteScroll: true,
                              enlargeFactor: 0.16,
                              enlargeCenterPage: true,
                              disableCenter: true,
                              autoPlayAnimationDuration:
                                  const Duration(milliseconds: 800),
                              autoPlayCurve: Curves.fastOutSlowIn,
                              scrollPhysics: const BouncingScrollPhysics(),
                              onPageChanged: (index, reason) {
                                Provider.of<BannerController>(context,
                                        listen: false)
                                    .onChangeFooterBannerIndex(index);
                              },
                            ),
                            itemCount: bannerList.length,
                            itemBuilder: (context, index, _) {
                              bool isActive =
                                  bannerProvider.footerBannerIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 2.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.15),
                                            blurRadius: 16,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 8),
                                          )
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: () => bannerProvider.openBanner(
                                        context, bannerList[index]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Provider.of<ThemeController>(
                                                    context,
                                                    listen: false)
                                                .darkTheme
                                            ? Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: .1)
                                            : Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: .05),
                                      ),
                                      child: CustomImageWidget(
                                        image: '${bannerList[index].imageUrl}',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: bannerList.map((banner) {
                            int idx = bannerList.indexOf(banner);
                            bool isActive =
                                bannerProvider.footerBannerIndex == idx;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 18.0 : 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : const SizedBox();
        },
      ),
      const SizedBox(height: 5),
    ]);
  }
}
