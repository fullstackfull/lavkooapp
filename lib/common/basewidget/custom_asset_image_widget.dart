import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAssetImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? color;
  const CustomAssetImageWidget(this.image, {super.key, this.height = 20, this.width = 20, this.fit = BoxFit.contain, this.color});

  @override
  Widget build(BuildContext context) {
    final isSvg = image.contains('.svg');
    final isExcluded = image.contains('no_') ||
                       image.contains('placeholder') ||
                       image.contains('success') ||
                       image.contains('verified') ||
                       image.contains('timeline') ||
                       image.contains('bg') ||
                       image.contains('white') ||
                       image.contains('otp');

    final Color? targetColor = color ?? (isSvg && !isExcluded ? Theme.of(context).primaryColor : null);

    return isSvg ? SvgPicture.asset(
      image, width: width, height: height,
      colorFilter: targetColor != null ? ColorFilter.mode(targetColor, BlendMode.srcIn) : null,
      fit: fit,
    ) : Image.asset(image, fit: fit, width: width, height: height, color: color);
  }
}

