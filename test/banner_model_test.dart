import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/banner/domain/models/banner_model.dart';
import 'package:syriapharmacy/features/brand/domain/models/brand_model.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';

/// What a banner knows about itself once the shop has answered.
///
/// Two things decide whether a banner behaves: which image it draws on a phone, and where its tap
/// goes. Both used to be the app's guess — the wide web image, and a resource id looked up in
/// whichever list happened to be cached. Both are now the shop's answer, and this pins the reading
/// of it, including what happens when an older shop sends neither.
void main() {
  group('the image a phone draws', () {
    test('the merchant\'s phone image wins when there is one', () {
      final banner = BannerModel.fromJson(const {
        'id': 1,
        'photo_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
        'mobile_photo_full_url': {
          'key': 'tall.webp',
          'path': 'https://shop.test/tall.webp',
          'status': 200,
        },
      });

      expect(banner.imageUrl, 'https://shop.test/tall.webp');
    });

    test('the web image is the fallback, never a blank banner', () {
      final banner = BannerModel.fromJson(const {
        'id': 1,
        'photo_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
      });

      expect(banner.imageUrl, 'https://shop.test/wide.webp');
    });

    test('a mobile image the storage could not resolve falls back too', () {
      // ImageFullUrl blanks the path when status is not 200 — an unresolved mobile image must not
      // beat a perfectly good web one.
      final banner = BannerModel.fromJson(const {
        'id': 1,
        'photo_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
        'mobile_photo_full_url': {'key': 'gone.webp', 'path': null, 'status': 404},
      });

      expect(banner.imageUrl, 'https://shop.test/wide.webp');
    });
  });

  group('where the tap goes', () {
    test('a banner pointing at a category carries that category, named', () {
      final banner = BannerModel.fromJson(const {
        'id': 1,
        'url': 'https://shop.test/products?category_id=44&data_from=category&page=1',
        'resource_type': 'category',
        'resource_id': 44,
        'action': {'type': 'category', 'id': 44, 'slug': 'vitamins', 'label': 'Vitamins'},
      });

      expect(banner.action?.type, 'category');
      expect(banner.action?.id, 44);
      expect(banner.action?.label, 'Vitamins', reason: 'the opened screen titles itself with this');
    });

    test('a shop too old to send an action leaves the resource contract intact', () {
      final banner = BannerModel.fromJson(const {
        'id': 1,
        'resource_type': 'brand',
        'resource_id': 7,
        'url': 'https://shop.test/products?brand_id=7&data_from=brand&page=1',
      });

      expect(banner.action, isNull, reason: 'the fallback path reads resource_type instead');
      expect(banner.resourceType, 'brand');
      expect(banner.resourceId, 7);
    });
  });

  group('categories and brands draw the same way', () {
    test('a category prefers its phone icon and falls back to the web one', () {
      final withMobile = CategoryModel.fromJson(const {
        'id': 1,
        'name': 'Vitamins',
        'icon_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
        'mobile_icon_full_url': {
          'key': 'tall.webp',
          'path': 'https://shop.test/tall.webp',
          'status': 200,
        },
      });
      final webOnly = CategoryModel.fromJson(const {
        'id': 2,
        'name': 'Baby Care',
        'icon_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
      });

      expect(withMobile.displayImageUrl, 'https://shop.test/tall.webp');
      expect(webOnly.displayImageUrl, 'https://shop.test/wide.webp',
          reason: 'almost every category has no mobile icon and must still show one');
    });

    test('a brand prefers its phone logo and falls back to the web one', () {
      final withMobile = BrandModel.fromJson(const {
        'id': 1,
        'name': 'Panadol',
        'image_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
        'mobile_image_full_url': {
          'key': 'tall.webp',
          'path': 'https://shop.test/tall.webp',
          'status': 200,
        },
      });
      final webOnly = BrandModel.fromJson(const {
        'id': 2,
        'name': 'Sanofi',
        'image_full_url': {'key': 'wide.webp', 'path': 'https://shop.test/wide.webp', 'status': 200},
      });

      expect(withMobile.displayImageUrl, 'https://shop.test/tall.webp');
      expect(webOnly.displayImageUrl, 'https://shop.test/wide.webp');
    });
  });

  group('a theme card knows which banner it came from', () {
    test('a card fed from Banner Setup carries its banner id', () {
      final card = ThemeCard.fromJson(const {
        'banner_id': 12,
        'image': 'https://shop.test/wide.webp',
        'action': {'type': 'category', 'id': 44},
      });

      expect(card.bannerId, 12, reason: 'the click is counted against the row the merchant edits');
    });

    test('a card typed into the builder reports no banner', () {
      final card = ThemeCard.fromJson(const {
        'image': 'https://shop.test/wide.webp',
        'action': {'type': 'url', 'url': 'https://shop.test/x'},
      });

      // Nothing rather than a wrong attribution: this card has no banner row behind it.
      expect(card.bannerId, isNull);
    });
  });
}
