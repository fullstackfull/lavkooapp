import 'package:syriapharmacy/features/product/domain/models/product_model.dart';

class HomeCategoryProduct {
  int? id;
  String? name;
  String? slug;
  String? icon;
  int? parentId;
  int? position;
  String? createdAt;
  String? updatedAt;
  BannerFullUrl? bannerFullUrl;
  List<Product>? products;
  List<dynamic>? translations;

  HomeCategoryProduct({
    this.id,
    this.name,
    this.slug,
    this.icon,
    this.parentId,
    this.position,
    this.createdAt,
    this.updatedAt,
    this.bannerFullUrl,
    this.products,
    this.translations,
  });

  HomeCategoryProduct.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    icon = json['icon'];
    parentId = json['parent_id'];
    position = json['position'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    bannerFullUrl = json['banner_full_url'] != null
        ? BannerFullUrl.fromJson(json['banner_full_url'])
        : null;

    if (json['products'] != null) {
      products = [];

      json['products'].forEach((v) {
        products!.add(Product.fromJson(v));
      });
    }

    if (json['translations'] != null) {
      translations = List<dynamic>.from(json['translations']);
    }
  }


  String? get bannerImageUrl => bannerFullUrl?.path;
}

class BannerFullUrl {
  String? key;
  String? path;
  int? status;

  BannerFullUrl({
    this.key,
    this.path,
    this.status,
  });

  BannerFullUrl.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    path = json['path'];
    status = json['status'];
  }
}