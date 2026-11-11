import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/domain/models/banner_model.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';

class SingleBannersWidget extends StatelessWidget {
  final BannerModel? bannerModel;
  final double? height;
  final bool noRadius;
  const SingleBannersWidget(
      {super.key, this.bannerModel, this.height, this.noRadius = false});

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(noRadius ? 0 : 12);

    return Consumer<BannerController>(
      builder: (context, bannerProvider, child) {
        return InkWell(
          onTap: () => bannerProvider.openBanner(context, bannerModel),
          child: SizedBox(
            // Was a fixed screen-width box inside callers that inset it by 15 on each side, so
            // every one of them overflowed by 30. The width comes from the parent now.
            width: double.infinity,
            height: height ?? MediaQuery.of(context).size.width / 2.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(radius),
                boxShadow: noRadius
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.all(radius),
                child: CustomImageWidget(
                  image: '${bannerModel?.imageUrl}',
                  // Cover, not fill: a banner whose ratio differs from the box was stretched out
                  // of shape rather than cropped to fit.
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
