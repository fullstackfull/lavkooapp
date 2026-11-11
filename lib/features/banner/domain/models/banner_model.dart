import 'package:syriapharmacy/data/model/image_full_url.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';

class BannerModel {
  int? id;
  String? photo;
  String? bannerType;
  int? published;
  String? createdAt;
  String? updatedAt;
  String? url;
  String? resourceType;
  int? resourceId;
  Product? product;
  String? title;
  String? subTitle;
  String? buttonText;
  String? backgroundColor;
  ImageFullUrl? photoFullUrl;

  /// The phone-shaped image the merchant uploaded in Banner Setup. The server falls back to the
  /// web image when there is none, so this is the one to draw.
  ImageFullUrl? mobilePhotoFullUrl;

  /// Where tapping this banner goes, resolved by the shop.
  ///
  /// The app used to work this out from [resourceType] and [resourceId], which meant it could only
  /// open a category or brand whose list it happened to have cached already, and could not open
  /// anything else at all. The shop resolves the merchant's link once, for both clients.
  ThemeAction? action;

  BannerModel(
      {this.id,
      this.photo,
      this.bannerType,
      this.published,
      this.createdAt,
      this.updatedAt,
      this.url,
      this.resourceType,
      this.resourceId,
      this.product,
      this.title,
      this.subTitle,
      this.buttonText,
      this.backgroundColor,
      this.photoFullUrl,
      this.mobilePhotoFullUrl,
      this.action});

  /// The image to draw on a phone: the merchant's mobile image, then the web one.
  String? get imageUrl {
    final mobile = mobilePhotoFullUrl?.path;
    if (mobile != null && mobile.isNotEmpty) return mobile;

    return photoFullUrl?.path;
  }

  BannerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    photo = json['photo'];
    bannerType = json['banner_type'];
    published = json['published'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    url = json['url'];
    resourceType = json['resource_type'];
    resourceId = json['resource_id'];
    title = json['title'];
    subTitle = json['sub_title'];
    buttonText = json['button_text'];
    backgroundColor = json['background_color'];
    product =
        json['product'] != null ? Product.fromJson(json['product']) : null;
    photoFullUrl = json['photo_full_url'] != null
        ? ImageFullUrl.fromJson(json['photo_full_url'])
        : null;
    mobilePhotoFullUrl = json['mobile_photo_full_url'] != null
        ? ImageFullUrl.fromJson(json['mobile_photo_full_url'])
        : null;
    action = json['action'] is Map<String, dynamic>
        ? ThemeAction.fromJson(json['action'])
        : null;
  }
}
