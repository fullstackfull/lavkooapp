import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/shop/domain/models/shop_navigation_model.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/favourite_button_widget.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/product_details/widgets/cart_bottom_sheet_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// The compositions one product card can take.
///
/// Not one layout with different corners: `standard` is the vertical commerce card, `large`
/// gives a featured product more type and a two-line name, and `horizontal` reads as a row —
/// image beside text — for list-style sections where scanning beats browsing.
enum ProductCardStyle { standard, large, horizontal, compact }

class ProductWidget extends StatefulWidget {
  final Product productModel;
  final int productNameLine;
  final double? margin;
  final SellerNavigationModel? sellerNavigationModel;
  final String? heroTag;

  /// The theme builder's per-section add_to_cart toggle; everywhere else the button stays.
  final bool showCartButton;

  /// Trending position (1-based). When set, the approved ink «#N» pill rides the
  /// image corner instead of the «جديد» badge.
  final int? rank;

  final ProductCardStyle style;
  const ProductWidget(
      {super.key,
      required this.productModel,
      this.productNameLine = 1,
      this.margin,
      this.sellerNavigationModel,
      this.heroTag,
      this.showCartButton = true,
      this.rank,
      this.style = ProductCardStyle.standard});

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  final GlobalKey productImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;
    double ratting = (widget.productModel.rating?.isNotEmpty ?? false)
        ? double.parse('${widget.productModel.rating?[0].average}')
        : 0;
    final String finalHeroTag =
        widget.heroTag ?? 'product-image-${widget.productModel.id}-$hashCode';
    final bool outOfStock = (widget.productModel.currentStock ?? 0) == 0 &&
        widget.productModel.productType == 'physical';

    if (widget.style == ProductCardStyle.horizontal) {
      return _horizontal(context, ratting, finalHeroTag, outOfStock);
    }

    final bool large = widget.style == ProductCardStyle.large;
    final bool compact = widget.style == ProductCardStyle.compact;
    // The standard card is the COMPLETE commerce card: a product name gets two
    // readable lines. Only the compact variant, for genuinely dense rails,
    // trades a line away — and it says so in its name.
    final int nameLines = compact
        ? widget.productNameLine
        : (widget.productNameLine < 2 ? 2 : widget.productNameLine);
    final Widget? imageBadge = _imageBadge(context);

    // The details column's height is deterministic — meta, name, price row and
    // their padding — so where the card is given a fixed height (a themed
    // carousel, a rail) the image takes what is left instead of overflowing.
    final double margin = widget.margin ?? Dimensions.paddingSizeExtraSmall;
    // Reserved areas, in order: meta, name, price, the discount line, the
    // action, and the padding around them. Every card in a grid reserves the
    // same, so images, titles, prices and buttons line up across a row whatever
    // each product happens to carry.
    final double detailsHeight = 15 +
        (18.0 * nameLines) +
        21 +
        (compact ? 0 : 15) +
        (compact ? 0 : 36) +
        16;

    return LayoutBuilder(builder: (context, cardConstraints) {
    final double? imageCap = cardConstraints.maxHeight.isFinite
        ? (cardConstraints.maxHeight - (margin * 2) - 2 - detailsHeight)
            .clamp(56.0, double.infinity)
            .toDouble()
        : null;

    return InkWell(
      onTap: () {
        RouterHelper.getProductDetailsRoute(
          action: RouteAction.push,
          productId: widget.productModel.id,
          slug: widget.productModel.slug,
          heroTag: finalHeroTag,
          image: widget.productModel.thumbnailFullUrl?.path,
        );
      },
      child: Container(
        margin:
            EdgeInsets.all(widget.margin ?? Dimensions.paddingSizeExtraSmall),
        // Direction B card: hairline ink border, flat white field — no drop shadow.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.hairline, width: 1),
          color: Theme.of(context).highlightColor,
        ),
        child: Stack(children: [
          SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LayoutBuilder(
                  builder: (context, boxConstraint) => ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Stack(children: [
                          Hero(
                            tag: finalHeroTag,
                            child: ColoredBox(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: .04)
                                  : BrandColors.surface,
                              // Packaged products sit contained on the lilac
                              // field, per the approved photography treatment.
                              child: SizedBox(
                                height: imageCap == null
                                    ? boxConstraint.maxWidth
                                    : (boxConstraint.maxWidth < imageCap
                                        ? boxConstraint.maxWidth
                                        : imageCap),
                                width: boxConstraint.maxWidth,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: CustomImageWidget(
                                    key: productImageKey,
                                    image:
                                        '${widget.productModel.thumbnailFullUrl?.path}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (imageBadge != null)
                            // One pill rides the image's top-start corner, by the
                            // approved priority: ink «#N» rank, magenta «−40%»
                            // saving, or blue «جديد».
                            PositionedDirectional(
                              top: 7,
                              start: 8,
                              child: imageBadge,
                            ),
                          if (outOfStock) ...[
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.18),
                                ),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: BackdropFilter(
                                      filter:
                                          ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.15),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF3B30),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              getTranslated(
                                                      'out_of_stock', context) ??
                                                  '',
                                              style: textBold.copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ]),
                      )),
            
              // Product Details — the areas the card always reserves, so a
              // longer name can never push the price or the button out of view.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeSmall, 6,
                    Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand and rating: «★ 4.8 (214) · CERAVE». Unreviewed
                      // products keep the brand alone rather than «(0) 0.0»,
                      // and the row keeps its height either way.
                      SizedBox(
                        height: 15,
                        child: Row(children: [
                          if ((widget.productModel.reviewCount ?? 0) > 0) ...[
                            const Icon(Icons.star_rate_rounded,
                                color: BrandColors.star, size: 13),
                            const SizedBox(width: 2),
                          ],
                          Flexible(
                            child: Text(
                              _metaLine(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textRegular.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(context).hintColor),
                            ),
                          ),
                        ]),
                      ),

                      // The name gets its two lines on a standard card.
                      SizedBox(
                        height: 18.0 * nameLines,
                        child: Text(widget.productModel.name ?? '',
                            textAlign: TextAlign.start,
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              height: 1.25,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: nameLines,
                            overflow: TextOverflow.ellipsis),
                      ),

                      // The selling price, always present and always the
                      // loudest thing under the name.
                      SizedBox(
                        height: 21,
                        child: Builder(
                          builder: (context) {
                            // ignore: unused_local_variable
                            final splash = context.watch<SplashController>();
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                PriceConverter.convertPrice(
                                  context,
                                  widget.productModel.unitPrice,
                                  discountType: (widget.productModel
                                                  .clearanceSale?.discountAmount ??
                                              0) >
                                          0
                                      ? widget.productModel.clearanceSale
                                          ?.discountType
                                      : widget.productModel.discountType,
                                  discount: (widget.productModel.clearanceSale
                                                  ?.discountAmount ??
                                              0) >
                                          0
                                      ? widget.productModel.clearanceSale
                                          ?.discountAmount
                                      : widget.productModel.discount,
                                ),
                                maxLines: 1,
                                style: robotoBold.copyWith(
                                    color: hasDiscount()
                                        ? BrandColors.magenta
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                    fontSize: large ? 18 : 16),
                              ),
                            );
                          },
                        ),
                      ),

                      // What it used to cost, and how much is off.
                      if (!compact)
                        SizedBox(
                          height: 15,
                          child: hasDiscount()
                              ? Row(children: [
                                  Flexible(
                                    child: Text(
                                      PriceConverter.convertPrice(context,
                                          widget.productModel.unitPrice),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: titleRegular.copyWith(
                                        color: Theme.of(context).hintColor,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor:
                                            Theme.of(context).hintColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (_discountPercent() != null)
                                    Container(
                                      margin: const EdgeInsetsDirectional.only(
                                          start: 5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: BrandColors.magenta
                                            .withValues(alpha: .12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '−${_discountPercent()}%',
                                        style: textBold.copyWith(
                                            fontSize: 9,
                                            color: BrandColors.magenta),
                                      ),
                                    ),
                                ])
                              : const SizedBox.shrink(),
                        ),

                      // The purchase action: its own full-width row, so it is
                      // never squeezed by a long price or a long name.
                      if (!compact) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 30,
                          child: outOfStock
                              ? _soldOutButton(context)
                              : (widget.showCartButton
                                  ? _addStates(context)
                                  : const SizedBox.shrink()),
                        ),
                      ],
                    ]),
              ),
            ]),
          ),
          Positioned(
            top: Dimensions.paddingSizeSmall,
            right: isLtr ? Dimensions.paddingSizeSmall : null,
            left: !isLtr ? Dimensions.paddingSizeSmall : null,
            child: FavouriteButtonWidget(
              sellerNavigationModel: widget.sellerNavigationModel,
              backgroundColor: Theme.of(context).cardColor,
              productId: widget.productModel.id,
            ),
          ),
        ]),
      ),
    ).animateCardEntrance();
    });
  }

  /// The row-shaped card: image beside text, for sections a shopper scans down a list.
  ///
  /// Same data, different geometry — the vertical card's hierarchy (name, price, saving, add)
  /// kept, but laid out for reading. Used by the builder's "list" style; nothing else changes.
  Widget _horizontal(BuildContext context, double ratting, String heroTag,
      bool outOfStock) {
    final theme = Theme.of(context);
    final int? percentOff = _discountPercent();

    return InkWell(
      onTap: () {
        RouterHelper.getProductDetailsRoute(
          action: RouteAction.push,
          productId: widget.productModel.id,
          slug: widget.productModel.slug,
          heroTag: heroTag,
          image: widget.productModel.thumbnailFullUrl?.path,
        );
      },
      child: Container(
        margin:
            EdgeInsets.all(widget.margin ?? Dimensions.paddingSizeExtraSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: BrandColors.hairline, width: 1),
          color: theme.highlightColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Stack(fit: StackFit.expand, children: [
                  ColoredBox(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: .04)
                        : BrandColors.surface,
                    child: Hero(
                      tag: heroTag,
                      child: CustomImageWidget(
                        key: productImageKey,
                        image:
                            '${widget.productModel.thumbnailFullUrl?.path}',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (outOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: .35),
                      alignment: Alignment.center,
                      child: Text(
                        getTranslated('out_of_stock', context) ?? '',
                        textAlign: TextAlign.center,
                        style: textBold.copyWith(
                            color: Colors.white, fontSize: 9),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productModel.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault, height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 15,
                    child: Row(children: [
                      if ((widget.productModel.reviewCount ?? 0) > 0) ...[
                        const Icon(Icons.star_rate_rounded,
                            color: BrandColors.star, size: 14),
                        const SizedBox(width: 2),
                      ],
                      Flexible(
                        child: Text(
                          _metaLine(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textRegular.copyWith(
                              fontSize: 10, color: theme.hintColor),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  if (hasDiscount())
                    Text(
                        PriceConverter.convertPrice(
                            context, widget.productModel.unitPrice),
                        style: titleRegular.copyWith(
                          color: theme.hintColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: theme.hintColor,
                          fontSize: Dimensions.fontSizeSmall,
                        )),
                  Row(children: [
                    Flexible(
                      child: Text(
                        PriceConverter.convertPrice(
                          context,
                          widget.productModel.unitPrice,
                          discountType: (widget.productModel.clearanceSale
                                          ?.discountAmount ??
                                      0) >
                                  0
                              ? widget
                                  .productModel.clearanceSale?.discountType
                              : widget.productModel.discountType,
                          discount: (widget.productModel.clearanceSale
                                          ?.discountAmount ??
                                      0) >
                                  0
                              ? widget
                                  .productModel.clearanceSale?.discountAmount
                              : widget.productModel.discount,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                            color: hasDiscount()
                                ? BrandColors.magenta
                                : theme.textTheme.bodyLarge?.color,
                            fontSize: Dimensions.fontSizeDefault),
                      ),
                    ),
                    if (percentOff != null)
                      Container(
                        margin: const EdgeInsetsDirectional.only(start: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BrandColors.magenta,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '−$percentOff%',
                          style: textBold.copyWith(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FavouriteButtonWidget(
                  sellerNavigationModel: widget.sellerNavigationModel,
                  backgroundColor: theme.cardColor,
                  productId: widget.productModel.id,
                ),
                const SizedBox(height: 24),
                if (!outOfStock && widget.showCartButton)
                  Material(
                    color: theme.cardColor,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: .3),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _openCartSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(Icons.add_shopping_cart_outlined,
                            size: 16,
                            color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animateCardEntrance();
  }

  /// An out-of-stock product keeps the action row so the grid stays level, and
  /// spends it saying the one thing that matters.
  Widget _soldOutButton(BuildContext context) => Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          getTranslated('out_of_stock', context) ?? '',
          maxLines: 1,
          style: robotoBold.copyWith(
              fontSize: 11, color: Theme.of(context).hintColor),
        ),
      );

  /// «★ 4.8 (214) · BRAND», «BRAND» alone when unreviewed, or nothing.
  String _metaLine() {
    final int reviews = widget.productModel.reviewCount ?? 0;
    final String? brandName = widget.productModel.brand?.name;
    final bool hasBrand = brandName?.isNotEmpty ?? false;
    final double average = (widget.productModel.rating?.isNotEmpty ?? false)
        ? double.tryParse('${widget.productModel.rating?[0].average}') ?? 0
        : 0;
    if (reviews > 0) {
      final String rating =
          '${average.toStringAsFixed(1)} (${PriceConverter.longToShortPrice(reviews.toDouble(), withDecimalPoint: false)})';
      return hasBrand ? '$rating · $brandName' : rating;
    }
    return hasBrand ? brandName! : '';
  }

  /// The one pill an image carries, by the approved priority: ink «#N» rank,
  /// magenta «−40%» saving, blue «جديد» for a recent arrival — or none.
  Widget? _imageBadge(BuildContext context) {
    if (widget.rank != null) {
      return _badgePill('#${widget.rank}', BrandColors.inkSoft);
    }
    final int? percentOff = _discountPercent();
    if (percentOff != null) {
      return _badgePill('−$percentOff%', BrandColors.magenta);
    }
    if (_isNewArrival()) {
      return _badgePill(getTranslated('new_badge', context) ?? '', BrandColors.blue);
    }
    return null;
  }

  Widget _badgePill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: textBold.copyWith(fontSize: 10, color: Colors.white)),
      );

  bool _isNewArrival() {
    final created = DateTime.tryParse(widget.productModel.createdAt ?? '');
    if (created == null) return false;
    return DateTime.now().difference(created).inDays <= 30;
  }

  /// The approved add states: gradient «أضف» when the product is not in the
  /// cart, the quantity stepper for a simple product already there, and an
  /// outlined «✔ في السلة» chip for a variation product whose line is edited
  /// through the cart sheet. Same guards as the cart screen's own buttons.
  Widget _addStates(BuildContext context) {
    return Consumer<CartController>(builder: (context, cart, _) {
      final int index = cart.cartList
          .indexWhere((item) => item.productId == widget.productModel.id);
      if (index == -1) {
        return InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => _openCartSheet(context),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: BrandGradients.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              getTranslated('add', context) ?? '',
              style: robotoBold.copyWith(fontSize: 12, color: Colors.white),
            ),
          ),
        );
      }

      final CartModel item = cart.cartList[index];
      // digitalVariation is never populated by Product.fromJson, so a digital
      // product with variants is recognised by its type instead.
      final bool hasVariations =
          (widget.productModel.colors?.isNotEmpty ?? false) ||
              (widget.productModel.choiceOptions?.isNotEmpty ?? false) ||
              (widget.productModel.variation?.isNotEmpty ?? false) ||
              widget.productModel.productType == 'digital';

      if (hasVariations) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openCartSheet(context),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: BrandColors.blue),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '✔ ${getTranslated('in_cart', context) ?? ''}',
              style: robotoBold.copyWith(fontSize: 11, color: BrandColors.blue),
            ),
          ),
        );
      }

      final int quantity = item.quantity ?? 1;
      // minimum_order_quantity never reaches CartModel from JSON — the cart
      // screen's own source is productInfo, so the stepper reads the same.
      final int minQty = item.productInfo?.minimumOrderQty ?? 1;
      final int? maxQty =
          item.maxQuantity ?? item.productInfo?.totalCurrentStock;
      final bool digital = item.productType != 'physical';
      // A tap during an in-flight update would race the stale index.
      final bool busy =
          (item.increment ?? false) || (item.decrement ?? false);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .06)
              : BrandColors.surface,
          border: Border.all(color: BrandColors.hairline),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          // Same order as the cart screen's own stepper — decrement at the
          // reading edge — so one gesture never means two different things.
          // At the minimum it turns into the cart screen's delete affordance
          // instead of silently dropping the line.
          InkWell(
            onTap: () {
              if (busy) return;
              // The list re-indexes on every cart refresh: resolve this row's
              // position now, not at build time.
              final int live =
                  cart.cartList.indexWhere((row) => row.id == item.id);
              if (live == -1) return;
              if (quantity > minQty) {
                cart.updateCartProductQuantity(
                    item.id, quantity - 1, context, false, live);
              } else {
                cart.removeFromCartAPI(item.id, live);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: quantity > minQty
                  ? Text('−',
                      style: robotoBold.copyWith(
                          fontSize: 15, color: Theme.of(context).hintColor))
                  : Icon(Icons.delete_outline_rounded,
                      size: 15, color: Theme.of(context).colorScheme.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text('$quantity',
                style: robotoBold.copyWith(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          InkWell(
            onTap: () {
              if (busy) return;
              final int live =
                  cart.cartList.indexWhere((row) => row.id == item.id);
              if (live == -1) return;
              if (digital || maxQty == null || quantity < maxQty) {
                cart.updateCartProductQuantity(
                    item.id, quantity + 1, context, true, live);
              } else {
                showCustomSnackBarWidget(
                    getTranslated('out_of_stock', context), context,
                    snackBarType: SnackBarType.warning);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Text('＋',
                  style: robotoBold.copyWith(
                      fontSize: 15, color: BrandColors.primary)),
            ),
          ),
        ]),
      );
    });
  }

  /// The saving as the reference apps speak it: "-42%" beside the price. A flat discount is
  /// expressed against the unit price; a nonsensical result (0% or 100%+) shows nothing.
  int? _discountPercent() {
    final double price = (widget.productModel.unitPrice ?? 0).toDouble();
    final clearance = widget.productModel.clearanceSale;
    final bool clearanceWins = (clearance?.discountAmount ?? 0) > 0;
    final double amount =
        ((clearanceWins ? clearance?.discountAmount : widget.productModel.discount) ?? 0)
            .toDouble();
    final String? type = clearanceWins
        ? clearance?.discountType
        : widget.productModel.discountType;
    if (amount <= 0 || price <= 0) return null;
    final double percent = (type == 'percent' || type == 'percentage')
        ? amount
        : (amount / price) * 100;
    final int rounded = percent.round();
    return (rounded > 0 && rounded <= 99) ? rounded : null;
  }

  Future<void> _openCartSheet(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        // Back during the fetch must dismiss the loader, not the listing.
        builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator())));
    final detailsController =
        Provider.of<ProductDetailsController>(context, listen: false);
    await detailsController.getProductDetails(context,
        widget.productModel.id.toString(), widget.productModel.slug.toString());
    if (!context.mounted) return;
    Navigator.pop(context);

    // A failed fetch leaves the PREVIOUS product in the controller; opening the
    // sheet on it would add the wrong product to the cart.
    if (detailsController.productDetailsModel?.id != widget.productModel.id) {
      showCustomSnackBarWidget(
          getTranslated('product_not_found', context) ?? '', context,
          snackBarType: SnackBarType.error);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (con) => CartBottomSheetWidget(
        product: Provider.of<ProductDetailsController>(context, listen: false)
            .productDetailsModel,
        callback: () {
          if (Navigator.of(con).canPop()) {
            Navigator.of(con).pop();
          }
          showCustomSnackBarWidget(
              getTranslated('added_to_cart', context)!, context,
              snackBarType: SnackBarType.success);
          AppConstants.runAddToCartAnimation?.call(productImageKey);
        },
      ),
    );
  }

  bool hasDiscount() =>
      (widget.productModel.discount != null &&
          widget.productModel.discount! > 0) ||
      (widget.productModel.clearanceSale?.discountAmount ?? 0) > 0;
}
