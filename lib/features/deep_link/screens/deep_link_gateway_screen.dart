import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syriapharmacy/data/services/deep_link_resolver.dart';
import 'package:syriapharmacy/di_container.dart' as di;
import 'package:syriapharmacy/features/deep_link/deep_link_storefront_rule.dart';
import 'package:syriapharmacy/features/product/enums/product_type.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_chooser_sheet.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:url_launcher/url_launcher.dart';

/// The screen a shop link lands on before it knows which screen it is.
///
/// Every published path — /brand/…, /products, /track-order/…, /go/… — routes here rather than to
/// a guess. It asks the shop what the link means (which is also what counts a campaign tap), then
/// replaces itself with the answer. A link opened from outside always leaves the home screen
/// underneath it, so the first back press lands in the app rather than closing it.
class DeepLinkGatewayScreen extends StatefulWidget {
  /// The link as it arrived. A bare path is fine — the shop's own host is assumed.
  final String link;

  const DeepLinkGatewayScreen({super.key, required this.link});

  @override
  State<DeepLinkGatewayScreen> createState() => _DeepLinkGatewayScreenState();
}

class _DeepLinkGatewayScreenState extends State<DeepLinkGatewayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final resolved =
        await di.sl<DeepLinkResolver>().resolve(Uri.parse(widget.link));

    if (!mounted) return;

    // The market the link named, and what this build does about it: stay where the customer is, ask
    // them, or follow the link's market (J-10). The move is made BEFORE the screen opens, so the
    // screen is built under the market the link was for and not under the one it replaced.
    await _enterTheLinksMarket(resolved);

    if (!mounted) return;

    // Opened from outside, this is the only page on the stack: home goes underneath so back does
    // not close the app. Opened from inside, the gateway simply steps aside for the answer.
    final replacesGateway = GoRouter.of(context).canPop();

    if (!replacesGateway) {
      RouterHelper.getDashboardRoute(
          action: RouteAction.pushNamedAndRemoveUntil);
    }

    // From here the gateway may already be gone; navigation goes through RouterHelper, which
    // routes from the navigator key rather than from this State's context.
    final action =
        replacesGateway ? RouteAction.pushReplacement : RouteAction.push;

    switch (resolved.target) {
      case 'home':
        if (replacesGateway) {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        }
      case 'product':
        RouterHelper.getProductDetailsRoute(
            slug: resolved.parameter, isNotification: true, action: action);
      case 'brand':
        _openBrand(resolved, action);
      case 'product_list':
        RouterHelper.getViewAllProductScreenRoute(
            productType: ProductType.allProduct, action: action);
      case 'order_tracking':
        _openOrderTracking(resolved, action);
      default:
        if (replacesGateway) {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        }
        await _openInBrowser(resolved.webUrl ?? widget.link);
    }
  }

  /// Applies the owner's rule for a link that names another market.
  ///
  /// Nothing happens for a link that names no market, for one that names the market the customer is
  /// on, for one that names a market the server does not list, while storefronts are off, or when the
  /// providers that would make the move are not in this tree — all of which is the app as it was.
  Future<void> _enterTheLinksMarket(ResolvedDeepLink resolved) async {
    final decision = DeepLinkStorefrontTarget.decide(
        named: resolved.storefront, context: context);
    final StorefrontCountry? target = decision.target;

    if (target == null || decision.step == DeepLinkStorefrontStep.openHere) {
      return;
    }

    if (decision.step == DeepLinkStorefrontStep.askFirst &&
        !await _askWhetherToFollow(target)) {
      return;
    }

    if (!mounted) return;

    final StorefrontSwitcher? switcher =
        DeepLinkStorefrontTarget.read<StorefrontSwitcher>(context);
    if (switcher != null) {
      await DeepLinkStorefrontTarget.move(switcher, target);
    }
  }

  /// Names both markets and lets the customer decide. A dialog dismissed any other way is "stay",
  /// because moving a customer between markets is never the default answer to a question they did
  /// not answer.
  Future<bool> _askWhetherToFollow(StorefrontCountry target) async {
    final String there = StorefrontChooserSheet.nameOf(context, target.code);

    final bool? follow = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(getTranslated('deep_link_other_market_title', dialogContext) ?? ''),
        content: Text((getTranslated('deep_link_other_market_body', dialogContext) ?? '')
            .replaceAll('{store}', there)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(getTranslated('deep_link_stay_here', dialogContext) ?? ''),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(getTranslated('deep_link_open_there', dialogContext) ?? ''),
          ),
        ],
      ),
    );

    return follow ?? false;
  }

  /// The brand screen opens on an id and a link carries a slug. The shop resolves one to the other;
  /// when it could not — an old link, an unpublished brand, no network — the brand list is a closer
  /// answer than the home screen.
  void _openBrand(ResolvedDeepLink resolved, RouteAction action) {
    if (resolved.subjectId == null) {
      RouterHelper.getBrandViewRoute(action: action);
      return;
    }

    RouterHelper.getBrandCategoryRoute(
      action: action,
      isBrand: true,
      id: resolved.subjectId,
      name: resolved.subjectName ?? '',
    );
  }

  void _openOrderTracking(ResolvedDeepLink resolved, RouteAction action) {
    final orderId = resolved.parameter;

    if (orderId == null || orderId.isEmpty) {
      RouterHelper.getGuestTrackOrderRoute(action: action);
      return;
    }

    RouterHelper.getTrackingResultRoute(orderID: orderId, action: action);
  }

  /// Not an app screen: the shop's own page opens in the browser and the app stays on home.
  Future<void> _openInBrowser(String webUrl) async {
    final uri = Uri.tryParse(webUrl);
    if (uri == null || !uri.hasScheme) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A link that will not open leaves the customer on the home screen, not on a dead end.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
