// import 'package:flutter/cupertino.dart';
// import 'package:syriapharmacy/data/model/image_full_url.dart';
//
// class CategoryModel {
//   int? _id;
//   String? _name;
//   String? _slug;
//   String? _icon;
//   int? _parentId;
//   int? _position;
//   String? _createdAt;
//   String? _updatedAt;
//   List<SubCategory>? _subCategories;
//   bool? isSelected;
//   ImageFullUrl? _imageFullUrl;
//   ImageFullUrl? _bannerFullUrl;
//   int? _totalProductCount;
//
//   CategoryModel(
//       {int? id,
//       String? name,
//       String? slug,
//       String? icon,
//       int? parentId,
//       int? position,
//       String? createdAt,
//       String? updatedAt,
//       List<SubCategory>? subCategories,
//       bool? isSelected,
//       ImageFullUrl? imageFullUrl,
//       ImageFullUrl? bannerFullUrl,
//       int? totalProductCount}) {
//     _id = id;
//     _name = name;
//     _slug = slug;
//     _icon = icon;
//     _parentId = parentId;
//     _position = position;
//     _createdAt = createdAt;
//     _updatedAt = updatedAt;
//     _subCategories = subCategories;
//     isSelected = isSelected;
//     _imageFullUrl = imageFullUrl;
//     _bannerFullUrl = bannerFullUrl;
//     _totalProductCount = totalProductCount;
//   }
//
//   int? get id => _id;
//   String? get name => _name;
//   String? get slug => _slug;
//   String? get icon => _icon;
//   int? get parentId => _parentId;
//   int? get position => _position;
//   String? get createdAt => _createdAt;
//   String? get updatedAt => _updatedAt;
//   List<SubCategory>? get subCategories => _subCategories;
//   ImageFullUrl? get imageFullUrl => _imageFullUrl;
//   ImageFullUrl? get bannerFullUrl => _bannerFullUrl;
//   int? get totalProductCount => _totalProductCount;
//
//   CategoryModel.fromJson(Map<String, dynamic> json) {
//     _id = json['id'];
//     _name = json['name'];
//     _slug = json['slug'];
//     _icon = json['icon'];
//     _parentId = json['parent_id'];
//     _position = json['position'];
//     _createdAt = json['created_at'];
//     _updatedAt = json['updated_at'];
//     if (json['childes'] != null) {
//       _subCategories = [];
//       json['childes'].forEach((v) {
//         _subCategories!.add(SubCategory.fromJson(v));
//       });
//     }
//     _imageFullUrl = json['icon_full_url'] != null
//         ? ImageFullUrl.fromJson(json['icon_full_url'])
//         : null;
//     _bannerFullUrl = json['banner_full_url'] != null
//         ? ImageFullUrl.fromJson(json['banner_full_url'])
//         : null;
//     isSelected = false;
//
//     try {
//       _totalProductCount = int.tryParse(json['product_count'].toString());
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['id'] = _id;
//     data['name'] = _name;
//     data['slug'] = _slug;
//     data['icon'] = _icon;
//     data['parent_id'] = _parentId;
//     data['position'] = _position;
//     data['created_at'] = _createdAt;
//     data['updated_at'] = _updatedAt;
//     if (_subCategories != null) {
//       data['childes'] = _subCategories!.map((v) => v.toJson()).toList();
//     }
//     if (_imageFullUrl != null) {
//       data['icon_full_url'] = _imageFullUrl!.toJson();
//     }
//     if (_bannerFullUrl != null) {
//       data['banner_full_url'] = _bannerFullUrl!.toJson();
//     }
//     data['is_selected'] = isSelected;
//     data['product_count'] = _totalProductCount;
//     return data;
//   }
// }
//
// class SubCategory {
//   int? _id;
//   String? _name;
//   String? _slug;
//   String? _icon;
//   int? _parentId;
//   int? _position;
//   String? _createdAt;
//   String? _updatedAt;
//   List<SubSubCategory>? _subSubCategories;
//   bool? isSelected;
//   ImageFullUrl? _imageFullUrl;
//   int? _totalProductCount;
//
//   SubCategory(
//       {int? id,
//       String? name,
//       String? slug,
//       String? icon,
//       int? parentId,
//       int? position,
//       String? createdAt,
//       String? updatedAt,
//       List<SubSubCategory>? subSubCategories,
//       bool? isSelected,
//       ImageFullUrl? imageFullUrl,
//       int? totalProductCount}) {
//     _id = id;
//     _name = name;
//     _slug = slug;
//     _icon = icon;
//     _parentId = parentId;
//     _position = position;
//     _createdAt = createdAt;
//     _updatedAt = updatedAt;
//     _subSubCategories = subSubCategories;
//     isSelected = isSelected;
//     _imageFullUrl = imageFullUrl;
//     _totalProductCount = totalProductCount;
//   }
//
//   int? get id => _id;
//   String? get name => _name;
//   String? get slug => _slug;
//   String? get icon => _icon;
//   int? get parentId => _parentId;
//   int? get position => _position;
//   String? get createdAt => _createdAt;
//   String? get updatedAt => _updatedAt;
//   List<SubSubCategory>? get subSubCategories => _subSubCategories;
//   ImageFullUrl? get imageFullUrl => _imageFullUrl;
//   int? get totalProductCount => _totalProductCount;
//
//   SubCategory.fromJson(Map<String, dynamic> json) {
//     _id = json['id'];
//     _name = json['name'];
//     _slug = json['slug'];
//     _icon = json['icon'];
//     _parentId = json['parent_id'];
//     _position = json['position'];
//     _createdAt = json['created_at'];
//     _updatedAt = json['updated_at'];
//     if (json['childes'] != null) {
//       _subSubCategories = [];
//       json['childes'].forEach((v) {
//         _subSubCategories!.add(SubSubCategory.fromJson(v));
//       });
//     }
//     _imageFullUrl = json['icon_full_url'] != null
//         ? ImageFullUrl.fromJson(json['icon_full_url'])
//         : null;
//     isSelected = false;
//
//     try {
//       _totalProductCount =
//           int.tryParse(json['sub_category_product_count'].toString()) ??
//               int.tryParse(json['products_count'].toString());
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['id'] = _id;
//     data['name'] = _name;
//     data['slug'] = _slug;
//     data['icon'] = _icon;
//     data['parent_id'] = _parentId;
//     data['position'] = _position;
//     data['created_at'] = _createdAt;
//     data['updated_at'] = _updatedAt;
//     if (_subSubCategories != null) {
//       data['childes'] = _subSubCategories!.map((v) => v.toJson()).toList();
//     }
//     if (_imageFullUrl != null) {
//       data['icon_full_url'] = _imageFullUrl!.toJson();
//     }
//     data['is_selected'] = isSelected;
//     data['sub_category_product_count'] = _totalProductCount;
//     return data;
//   }
// }
//
// class SubSubCategory {
//   int? _id;
//   String? _name;
//   String? _slug;
//   String? _icon;
//   int? _parentId;
//   int? _position;
//   String? _createdAt;
//   String? _updatedAt;
//   ImageFullUrl? _imageFullUrl;
//   int? _totalProductCount;
//
//   SubSubCategory(
//       {int? id,
//       String? name,
//       String? slug,
//       String? icon,
//       int? parentId,
//       int? position,
//       String? createdAt,
//       String? updatedAt,
//       ImageFullUrl? imageFullUrl,
//       int? totalProductCount}) {
//     _id = id;
//     _name = name;
//     _slug = slug;
//     _icon = icon;
//     _parentId = parentId;
//     _position = position;
//     _createdAt = createdAt;
//     _updatedAt = updatedAt;
//     _imageFullUrl = imageFullUrl;
//     _totalProductCount = totalProductCount;
//   }
//
//   int? get id => _id;
//   String? get name => _name;
//   String? get slug => _slug;
//   String? get icon => _icon;
//   int? get parentId => _parentId;
//   int? get position => _position;
//   String? get createdAt => _createdAt;
//   String? get updatedAt => _updatedAt;
//   ImageFullUrl? get imageFullUrl => _imageFullUrl;
//   int? get totalProductCount => _totalProductCount;
//
//   SubSubCategory.fromJson(Map<String, dynamic> json) {
//     _id = json['id'];
//     _name = json['name'];
//     _slug = json['slug'];
//     _icon = json['icon'];
//     _parentId = json['parent_id'];
//     _position = json['position'];
//     _createdAt = json['created_at'];
//     _updatedAt = json['updated_at'];
//     _imageFullUrl = json['icon_full_url'] != null
//         ? ImageFullUrl.fromJson(json['icon_full_url'])
//         : null;
//
//     _totalProductCount =
//         int.tryParse(json['sub_sub_category_product_count'].toString()) ??
//             int.tryParse(json['products_count'].toString());
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['id'] = _id;
//     data['name'] = _name;
//     data['slug'] = _slug;
//     data['icon'] = _icon;
//     data['parent_id'] = _parentId;
//     data['position'] = _position;
//     data['created_at'] = _createdAt;
//     data['updated_at'] = _updatedAt;
//     if (_imageFullUrl != null) {
//       data['icon_full_url'] = _imageFullUrl!.toJson();
//     }
//     data['sub_sub_category_product_count'] = _totalProductCount;
//     return data;
//   }
// }


import 'package:flutter/cupertino.dart';
import 'package:syriapharmacy/data/model/image_full_url.dart';

class CategoryModel {
  int? _id;
  String? _name;
  String? _slug;
  String? _icon;
  int? _parentId;
  int? _position;
  String? _createdAt;
  String? _updatedAt;
  List<SubCategory>? _subCategories;
  bool? isSelected;
  ImageFullUrl? _imageFullUrl;
  ImageFullUrl? _mobileImageFullUrl;
  ImageFullUrl? _bannerFullUrl;
  int? _totalProductCount;

  CategoryModel(
      {int? id,
        String? name,
        String? slug,
        String? icon,
        int? parentId,
        int? position,
        String? createdAt,
        String? updatedAt,
        List<SubCategory>? subCategories,
        bool? isSelected,
        ImageFullUrl? imageFullUrl,
        ImageFullUrl? bannerFullUrl,
        int? totalProductCount}) {
    _id = id;
    _name = name;
    _slug = slug;
    _icon = icon;
    _parentId = parentId;
    _position = position;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _subCategories = subCategories;
    isSelected = isSelected;
    _imageFullUrl = imageFullUrl;
    _bannerFullUrl = bannerFullUrl;
    _totalProductCount = totalProductCount;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get icon => _icon;
  int? get parentId => _parentId;
  int? get position => _position;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  List<SubCategory>? get subCategories => _subCategories;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;
  ImageFullUrl? get mobileImageFullUrl => _mobileImageFullUrl;
  ImageFullUrl? get bannerFullUrl => _bannerFullUrl;
  int? get totalProductCount => _totalProductCount;

  /// The picture to draw on a phone: the merchant's mobile icon where they uploaded one, the web
  /// icon otherwise. What reads on a wide storefront is often unreadable in a 62px circle.
  String? get displayImageUrl {
    final mobile = _mobileImageFullUrl?.path;
    if (mobile != null && mobile.isNotEmpty) return mobile;

    return _imageFullUrl?.path;
  }

  // ✅ SETTERS — هذه هي الإضافة المهمة
  set subCategories(List<SubCategory>? value) => _subCategories = value;
  set bannerFullUrl(ImageFullUrl? value) => _bannerFullUrl = value;

  CategoryModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _icon = json['icon'];
    _parentId = json['parent_id'];
    _position = json['position'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    if (json['childes'] != null) {
      _subCategories = [];
      json['childes'].forEach((v) {
        _subCategories!.add(SubCategory.fromJson(v));
      });
    }
    _imageFullUrl = json['icon_full_url'] != null
        ? ImageFullUrl.fromJson(json['icon_full_url'])
        : null;
    _mobileImageFullUrl = json['mobile_icon_full_url'] != null
        ? ImageFullUrl.fromJson(json['mobile_icon_full_url'])
        : null;
    _bannerFullUrl = json['banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['banner_full_url'])
        : null;
    isSelected = false;

    try {
      _totalProductCount = int.tryParse(json['product_count'].toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = _id;
    data['name'] = _name;
    data['slug'] = _slug;
    data['icon'] = _icon;
    data['parent_id'] = _parentId;
    data['position'] = _position;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    if (_subCategories != null) {
      data['childes'] = _subCategories!.map((v) => v.toJson()).toList();
    }
    if (_imageFullUrl != null) {
      data['icon_full_url'] = _imageFullUrl!.toJson();
    }
    if (_bannerFullUrl != null) {
      data['banner_full_url'] = _bannerFullUrl!.toJson();
    }
    data['is_selected'] = isSelected;
    data['product_count'] = _totalProductCount;
    return data;
  }
}

class SubCategory {
  int? _id;
  String? _name;
  String? _slug;
  String? _icon;
  int? _parentId;
  int? _position;
  String? _createdAt;
  String? _updatedAt;
  List<SubSubCategory>? _subSubCategories;
  bool? isSelected;
  ImageFullUrl? _imageFullUrl;
  ImageFullUrl? _mobileImageFullUrl;
  int? _totalProductCount;

  SubCategory(
      {int? id,
        String? name,
        String? slug,
        String? icon,
        int? parentId,
        int? position,
        String? createdAt,
        String? updatedAt,
        List<SubSubCategory>? subSubCategories,
        bool? isSelected,
        ImageFullUrl? imageFullUrl,
        int? totalProductCount}) {
    _id = id;
    _name = name;
    _slug = slug;
    _icon = icon;
    _parentId = parentId;
    _position = position;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _subSubCategories = subSubCategories;
    isSelected = isSelected;
    _imageFullUrl = imageFullUrl;
    _totalProductCount = totalProductCount;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get icon => _icon;
  int? get parentId => _parentId;
  int? get position => _position;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  List<SubSubCategory>? get subSubCategories => _subSubCategories;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;
  ImageFullUrl? get mobileImageFullUrl => _mobileImageFullUrl;
  int? get totalProductCount => _totalProductCount;

  /// The phone icon where the merchant uploaded one, the web icon otherwise.
  String? get displayImageUrl {
    final mobile = _mobileImageFullUrl?.path;
    if (mobile != null && mobile.isNotEmpty) return mobile;

    return _imageFullUrl?.path;
  }

  // ✅ SETTER للـ subSubCategories إذا احتجت تعديلها لاحقاً
  set subSubCategories(List<SubSubCategory>? value) => _subSubCategories = value;

  SubCategory.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _icon = json['icon'];
    _parentId = json['parent_id'];
    _position = json['position'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    if (json['childes'] != null) {
      _subSubCategories = [];
      json['childes'].forEach((v) {
        _subSubCategories!.add(SubSubCategory.fromJson(v));
      });
    }
    _imageFullUrl = json['icon_full_url'] != null
        ? ImageFullUrl.fromJson(json['icon_full_url'])
        : null;
    _mobileImageFullUrl = json['mobile_icon_full_url'] != null
        ? ImageFullUrl.fromJson(json['mobile_icon_full_url'])
        : null;
    isSelected = false;

    try {
      _totalProductCount =
          int.tryParse(json['sub_category_product_count'].toString()) ??
              int.tryParse(json['products_count'].toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = _id;
    data['name'] = _name;
    data['slug'] = _slug;
    data['icon'] = _icon;
    data['parent_id'] = _parentId;
    data['position'] = _position;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    if (_subSubCategories != null) {
      data['childes'] = _subSubCategories!.map((v) => v.toJson()).toList();
    }
    if (_imageFullUrl != null) {
      data['icon_full_url'] = _imageFullUrl!.toJson();
    }
    data['is_selected'] = isSelected;
    data['sub_category_product_count'] = _totalProductCount;
    return data;
  }
}

class SubSubCategory {
  int? _id;
  String? _name;
  String? _slug;
  String? _icon;
  int? _parentId;
  int? _position;
  String? _createdAt;
  String? _updatedAt;
  ImageFullUrl? _imageFullUrl;
  int? _totalProductCount;

  SubSubCategory(
      {int? id,
        String? name,
        String? slug,
        String? icon,
        int? parentId,
        int? position,
        String? createdAt,
        String? updatedAt,
        ImageFullUrl? imageFullUrl,
        int? totalProductCount}) {
    _id = id;
    _name = name;
    _slug = slug;
    _icon = icon;
    _parentId = parentId;
    _position = position;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _imageFullUrl = imageFullUrl;
    _totalProductCount = totalProductCount;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get icon => _icon;
  int? get parentId => _parentId;
  int? get position => _position;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;
  int? get totalProductCount => _totalProductCount;

  SubSubCategory.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _icon = json['icon'];
    _parentId = json['parent_id'];
    _position = json['position'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _imageFullUrl = json['icon_full_url'] != null
        ? ImageFullUrl.fromJson(json['icon_full_url'])
        : null;

    _totalProductCount =
        int.tryParse(json['sub_sub_category_product_count'].toString()) ??
            int.tryParse(json['products_count'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = _id;
    data['name'] = _name;
    data['slug'] = _slug;
    data['icon'] = _icon;
    data['parent_id'] = _parentId;
    data['position'] = _position;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    if (_imageFullUrl != null) {
      data['icon_full_url'] = _imageFullUrl!.toJson();
    }
    data['sub_sub_category_product_count'] = _totalProductCount;
    return data;
  }
}
