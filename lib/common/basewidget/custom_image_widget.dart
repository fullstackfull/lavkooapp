import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/utill/images.dart';

class CustomImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String? placeholder;
  const CustomImageWidget(
      {super.key,
        required this.image,
        this.height,
        this.width,
        this.fit = BoxFit.cover,
        this.placeholder = Images.placeholder});

  @override
  Widget build(BuildContext context) {
    // Guard: empty or whitespace-only URL causes CachedNetworkImage to crash
    // with "No host specified in URI file:///" — fall back to placeholder.
    final String url = image.trim();
    if (url.isEmpty) {
      return Image.asset(
        placeholder ?? Images.placeholder,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      placeholder: (context, url) => Image.asset(
          placeholder ?? Images.placeholder,
          height: height,
          width: width,
          fit: BoxFit.cover),
      imageUrl: url,
      fit: fit ?? BoxFit.cover,
      height: height,
      width: width,
      errorWidget: (c, o, s) => Image.asset(placeholder ?? Images.placeholder,
          height: height, width: width, fit: BoxFit.cover),
    );
  }
}
