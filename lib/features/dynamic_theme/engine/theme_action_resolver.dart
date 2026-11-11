import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/screens/experience_page_screen.dart';
import 'package:syriapharmacy/features/product/enums/product_type.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';

/// Turns a server-typed action into navigation inside this app.
///
/// The merchant expressed one destination in the builder — a storefront URL. The server parsed it
/// once into `{type: product, slug: …}`, and this is the other half: the same destination as a
/// native route. Without it, tapping a banner would open a browser on top of the app and lose the
/// shopper's place, which is the single most common way a server-driven home page feels wrong.
///
/// Every branch is total. An action this build has never heard of falls through to its `url`, and
/// an action with no url does nothing at all — a dead tap is better than a wrong screen.
class ThemeActionResolver {
  const ThemeActionResolver();

  /// Whether tapping this action would go anywhere. Renderers use it to decide whether to make a
  /// card tappable at all, so a shopper never presses something inert.
  bool isNavigable(ThemeAction action) {
    if (action.isNone) return false;

    return switch (action.type) {
      'product' => action.slug != null || action.id != null,
      'category' ||
      'brand' ||
      'vendor' =>
        action.slug != null || action.id != null,
      'search' => true,
      'cart' || 'wishlist' => true,
      'collection' => action.collection != null,
      'page' => action.slug != null && action.slug!.isNotEmpty,
      'campaign' => action.id != null,
      'url' => action.url != null,
      _ => action.url != null,
    };
  }

  /// Navigate, or do nothing when there is nowhere to go.
  void go(BuildContext context, ThemeAction action) {
    if (!isNavigable(action)) return;

    switch (action.type) {
      case 'product':
        RouterHelper.getProductDetailsRoute(
          action: RouteAction.push,
          slug: action.slug,
          productId: action.id,
        );

      case 'category':
        _openSubject(context,action, isBrand: false);

      case 'brand':
        _openSubject(context,action, isBrand: true);

      case 'vendor':
        RouterHelper.getTopSellerRoute(
          action: RouteAction.push,
          slug: action.slug,
          sellerId: action.id,
        );

      case 'search':
        RouterHelper.getSearchRoute(action: RouteAction.push);

      case 'cart':
        RouterHelper.getCartScreenRoute(
          action: RouteAction.push,
          showBackButton: true,
        );

      case 'wishlist':
        RouterHelper.getWishListRoute(action: RouteAction.push);

      case 'campaign':
        RouterHelper.getFlashDealScreenViewRoute(action: RouteAction.push);

      case 'collection':
        _openCollection(action);

      case 'page':
        // A page the merchant composed. Opened natively rather than in a browser: it is made of
        // the same sections as the home page and the app already knows how to draw every one.
        _openComposedPage(context, action);

      case 'url':
        _openExternally(action.url);

      default:
        // A type from a newer server than this build. It always carries the original URL, which
        // is exactly the fallback the web would have used.
        _openExternally(action.url);
    }
  }

  /// A category's or a brand's product list.
  ///
  /// The screen opens on an id and titles itself with a name; the shop resolves both, whichever
  /// half the merchant's link spelled. The slug is the fallback title only — never a substitute
  /// for the id, because the screen cannot look one up and would open an empty list. A payload old
  /// enough to carry a slug alone falls back to the storefront page, which always works.
  // void _openSubject(ThemeAction action, {required bool isBrand}) {
  //   if (action.id == null) {
  //     _openExternally(action.url);
  //     return;
  //   }
  //
  //   RouterHelper.getBrandCategoryRoute(
  //     action: RouteAction.push,
  //     isBrand: isBrand,
  //     id: action.id,
  //     name: action.label ?? action.slug,
  //   );
  // }
  /// A category's or a brand's product list.
  ///
  /// The screen opens on an id and titles itself with a name; the shop resolves both, whichever
  /// half the merchant's link spelled. When the shop couldn't name it (`label` came back empty —
  /// seen in practice for categories missing an Arabic translation server-side), a category id can
  /// still be looked up against the category list this app already loaded on the home screen,
  /// which is fetched from `/categories` and comes back properly localized. That's a much better
  /// title than the raw slug, which is an internal identifier, never a display string. The slug is
  /// only reached when neither `label` nor a local match exists — never a substitute for the id,
  /// because the screen cannot look one up and would open an empty list. A payload old enough to
  /// carry a slug alone falls back to the storefront page, which always works.
  ///
  /// //////////////////////////////////////////////////////////////////////////////////
  void _openSubject(BuildContext context, ThemeAction action, {required bool isBrand}) {
    if (action.id == null) {
      _openExternally(action.url);
      return;
    }

    String? resolvedName = action.label;

    // إذا كان الاسم فارغاً وهي تصنيف (وليست علامة تجارية)، ابحث عن الاسم محلياً
    if ((resolvedName == null || resolvedName.isEmpty) && !isBrand) {
      final categoryController = Provider.of<CategoryController>(context, listen: false);
      final match = categoryController.categoryList.where((c) => c.id == action.id);
      if (match.isNotEmpty && (match.first.name?.isNotEmpty ?? false)) {
        resolvedName = match.first.name;
      }
    }

    RouterHelper.getBrandCategoryRoute(
      action: RouteAction.push,
      isBrand: isBrand,
      id: action.id,
      name: resolvedName ?? action.slug, // استخدام الاسم المحلول أو الـ slug كحل أخير
    );
  }
/////////////////////////////////////////////////////////////////////////////////////
  /// One of the merchant's own pages, pushed onto the stack the shopper is already in.
  void _openComposedPage(BuildContext context, ThemeAction action) {
    final slug = action.slug;
    if (slug == null || slug.isEmpty) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExperiencePageScreen(slug: slug, title: action.label),
    ));
  }

  void _openCollection(ThemeAction action) {
    final productType = _productTypeFor(action.collection);

    if (productType != null) {
      RouterHelper.getViewAllProductScreenRoute(
        action: RouteAction.push,
        productType: productType,
      );
      return;
    }

    switch (action.collection) {
      case 'clearance':
        RouterHelper.getClearanceSaleAllProductScreenRoute(
            action: RouteAction.push);
      case 'featured_deal':
        RouterHelper.getFeaturedDealScreenViewRoute(action: RouteAction.push);
      case 'all_categories':
        // The category grid's "view all". Falling through to the browser here opened Chrome on
        // top of the shop for the single most-tapped heading on the home page.
        RouterHelper.getCategoryScreenRoute(action: RouteAction.push);
      case 'all_brands':
        RouterHelper.getBrandViewRoute(action: RouteAction.push);
      case 'all_vendors':
        // The link says "all vendors"; opening it under the "top sellers"
        // heading would answer a question the shopper did not ask.
        RouterHelper.getAllTopSellerRoute(
            action: RouteAction.push, title: 'our_vendors');
      default:
        _openExternally(action.url);
    }
  }

  /// The app's own list screen for a named web collection, where one exists.
  ProductType? _productTypeFor(String? collection) => switch (collection) {
        'featured' => ProductType.featuredProduct,
        'latest' => ProductType.latestProduct,
        'best_selling' => ProductType.bestSelling,
        'top_rated' => ProductType.topProduct,
        'discounted' => ProductType.discountedProduct,
        'all' => ProductType.allProduct,
        _ => null,
      };

  Future<void> _openExternally(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;

    // Failure here is silent on purpose: a launcher that refuses (no browser, a blocked scheme)
    // is not something a shopper can act on, and a thrown error would take the tap handler — and
    // with it the section — down with it.
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
