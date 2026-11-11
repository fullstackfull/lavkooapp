import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/enums/local_caches_type_enum.dart';
import 'package:syriapharmacy/localization/models/language_model.dart';
import 'package:syriapharmacy/utill/images.dart';

class AppConstants {
  static const String appName = 'LAVKOO';
  static const String slogan = 'Pharmacy Marketplace';
  /// What the app reports as its version — and, deliberately, NOT the version in pubspec.yaml.
  ///
  /// pubspec says `3.0.6+48`. This says `16.2.1`, which is the marketplace template's own numbering
  /// and a version no build of this app has ever had. That is wrong in three places at once: the
  /// shop's Monitoring groups crashes and traffic by it, `X-App-Version` carries it on every
  /// request, and the "Version" line in More shows it to the customer.
  ///
  /// It cannot simply be corrected, and the reason is worth reading before touching it. The live
  /// shop publishes `user_app_version_control` = **14.1 with status 1** for both platforms (read
  /// from /api/v1/config on 2026-11-11), and `_updateIsRequired` in splash_screen.dart demands an
  /// update whenever that floor is higher than this constant. Set this to the true `3.0.6` and
  /// 14.1 > 3.0.6, so EVERY build is held at the update screen — and the config ships `link: ""`,
  /// so there is nowhere for the customer to go. The wrong number is what currently keeps the app
  /// past its own update gate.
  ///
  /// So the two must move together, and which way is the owner's call:
  ///   * lower the shop's floor to at most the app's real version, then set this to `3.0.6`; or
  ///   * renumber the app at or above 14.1 in pubspec.yaml and set this to match.
  /// Either closes it. Changing this line alone bricks every build, which is why
  /// test/release_version_test.dart refuses a value below the live floor.
  static const String appVersion = '16.2.1';

  ///Flutter SDK 3.41.9
  static const bool demo = false;

  static Function(GlobalKey)? runAddToCartAnimation;

  static const int imageQuality = 100;
  static const LocalCachesTypeEnum cachesType = LocalCachesTypeEnum.all;

  static const String baseUrl = 'https://lavkoo.com';

  static const String googleServerClientId =
      '225848042220-6bpr48i5cvs6sbtff1dunn3s3v07odl3.apps.googleusercontent.com';
  static const String userId = 'userId';

  static const String name = 'name';
  static const String categoriesUri = '/api/v1/categories';
  static const String categoryPageHeaderUri = '/api/v1/categories/page-header/';
  static const String brandUri = '/api/v1/brands?guest_id=1';

  static const String brandProductUri = '/api/v1/brands/products/';
  static const String categoryProductUri = '/api/v1/categories/products/';
  static const String registrationUri = '/api/v1/auth/register';
  static const String loginUri = '/api/v1/auth/login';

  /// The server-driven home page. `themeVersionUri` is the cheap "has anything changed" check
  /// asked on every cold start and resume; `themeHomeUri` is the page itself, fetched only when
  /// the revision moved. `themeSectionsUri` is the older unversioned endpoint, kept for reference.
  static const String themeHomeUri = '/api/v1/theme/home';
  static const String themeVersionUri = '/api/v1/theme/version';
  static const String themeSectionsUri = '/api/v1/theme/sections';

  /// Self-reported app health: sessions/crashes counters only — no ids, no stack traces. The
  /// server's Monitoring panel cannot see a crash (a crash produces no request), so the app says
  /// "I ran" once per launch and owns up to any crash the previous run recorded.
  static const String appHealthUri = '/api/v1/app-health';

  /// Deep links resolved server-side: campaign short links (/go/x) become native targets and the
  /// click is counted against its campaign — the app's side of the Analytics attribution.
  static const String deepLinkResolveUri = '/api/v1/deep-link/resolve';

  /// What only the app can see. The web reports the same events from its own beacon; in the app a
  /// banner tap is not a navigation the server could ever observe.
  static const String analyticsEventsUri = '/api/v1/analytics/events';

  static const String pendingCrashCount = 'pending_crash_count';

  static const String logOut = '/api/v1/auth/logout';
  static const String latestProductUri =
      '/api/v1/products/latest?guest_id=1&limit=10&&offset=';
  static const String newArrivalProductUri =
      '/api/v1/products/new-arrival?guest_id=1&limit=10&&offset=';
  static const String topProductUri =
      '/api/v1/products/top-rated?guest_id=1&limit=10&&offset=';
  static const String bestSellingProductUri =
      '/api/v1/products/best-sellings?guest_id=1&limit=10&offset=';
  static const String discountedProductUri =
      '/api/v1/products/discounted-product?guest_id=1&limit=10&&offset=';
  static const String featuredProductUri =
      '/api/v1/products/featured?guest_id=1&limit=10&&offset=';
  static const String homeCategoryProductUri =
      '/api/v1/products/home-categories?guest_id=1';
  static const String productDetailsUri = '/api/v1/products/details/';
  static const String productReviewUri = '/api/v1/products/reviews/';
  static const String searchUri = '/api/v1/products/filter';
  static const String getSuggestionProductName =
      '/api/v1/products/suggestion-product?guest_id=1&name=';
  static const String configUri = '/api/v1/config';
  static const String addWishListUri =
      '/api/v1/customer/wish-list/add?product_id=';
  static const String removeWishListUri =
      '/api/v1/customer/wish-list/remove?product_id=';
  static const String updateProfileUri = '/api/v1/customer/update-profile';
  static const String customerUri = '/api/v1/customer/info';
  static const String addressListUri = '/api/v1/customer/address/list';
  static const String removeAddressUri = '/api/v1/customer/address';
  static const String addAddressUri = '/api/v1/customer/address/add';
  static const String getWishListUri = '/api/v1/customer/wish-list';
  static const String supportTicketUri =
      '/api/v1/customer/support-ticket/create';
  static const String getBannerList = '/api/v1/banners';
  static const String relatedProductUri = '/api/v1/products/related-products/';
  static const String orderUri = '/api/v1/customer/order/list?limit=10&offset=';
  static const String orderDetailsUri =
      '/api/v1/customer/order/details?order_id=';
  static const String orderPlaceUri = '/api/v1/customer/order/place';
  static const String sellerUri = '/api/v1/seller?slug=';
  static const String sellerProductUri = '/api/v1/seller/';
  static const String sellerList = '/api/v1/seller/list/';
  static const String trackingUri = '/api/v1/order/track?order_id=';
  static const String forgetPasswordUri = '/api/v1/auth/forgot-password';
  static const String getSupportTicketUri =
      '/api/v1/customer/support-ticket/get';
  static const String supportTicketConversationUri =
      '/api/v1/customer/support-ticket/conv/';
  static const String supportTicketReplyUri =
      '/api/v1/customer/support-ticket/reply/';
  static const String closeSupportTicketUri =
      '/api/v1/customer/support-ticket/close/';
  static const String submitReviewUri = '/api/v1/products/reviews/submit';
  static const String getOrderWiseReview = '/api/v1/products/review/';
  static const String updateOrderWiseReview = '/api/v1/products/review/update';
  static const String deleteOrderWiseReviewImage =
      '/api/v1/products/review/delete-image';
  static const String flashDealUri = '/api/v1/flash-deals';
  static const String featuredDealUri = '/api/v1/deals/featured';
  static const String flashDealProductUri = '/api/v1/flash-deals/products/';
  static const String counterUri = '/api/v1/products/counter/';
  static const String socialLinkUri = '/api/v1/products/social-share-link/';
  static const String shippingUri = '/api/v1/products/shipping-methods';
  static const String couponUri = '/api/v1/coupon/apply?code=';
  static const String messageUri = '/api/v1/customer/chat/get-messages/';
  static const String chatInfoUri = '/api/v1/customer/chat/list/';
  static const String searchChat = '/api/v1/customer/chat/search/';
  static const String sendMessageUri = '/api/v1/customer/chat/send-message/';
  static const String seenMessageUri = '/api/v1/customer/chat/seen-message/';
  static const String tokenUri = '/api/v1/customer/cm-firebase-token';
  static const String notificationUri = '/api/v1/notifications';
  static const String seenNotificationUri = '/api/v1/notifications/seen';
  static const String getCartDataUri = '/api/v1/cart';
  static const String addToCartUri = '/api/v1/cart/add';
  static const String updateCartQuantityUri = '/api/v1/cart/update';
  static const String removeFromCartUri = '/api/v1/cart/remove';
  static const String getShippingMethod = '/api/v1/shipping-method/by-seller';
  static const String chooseShippingMethod =
      '/api/v1/shipping-method/choose-for-order';
  static const String chosenShippingMethod = '/api/v1/shipping-method/chosen';
  static const String sendOtpToPhone = '/api/v1/auth/check-phone';
  static const String resendPhoneOtpUri = '/api/v1/auth/resend-otp-check-phone';
  static const String verifyPhoneUri = '/api/v1/auth/verify-phone';
  static const String socialLoginUri = '/api/v1/auth/social-customer-login';
  static const String sendOtpToEmail = '/api/v1/auth/check-email';
  static const String resendEmailOtpUri = '/api/v1/auth/resend-otp-check-email';
  static const String verifyEmailUri = '/api/v1/auth/verify-email';
  static const String resetPasswordUri = '/api/v1/auth/reset-password';
  static const String verifyOtpUri = '/api/v1/auth/verify-otp';
  static const String refundRequestUri = '/api/v1/customer/order/refund-store';
  static const String refundRequestPreReqUri = '/api/v1/customer/order/refund';
  static const String refundResultUri = '/api/v1/customer/order/refund-details';
  static const String cancelOrderUri = '/api/v1/order/cancel-order';
  static const String getSelectedShippingTypeUri =
      '/api/v1/shipping-method/check-shipping-type';
  static const String dealOfTheDay = '/api/v1/dealsoftheday/deal-of-the-day';
  static const String walletTransactionUri = '/api/v1/customer/wallet/list';
  static const String loyaltyPointUri = '/api/v1/customer/loyalty/list';
  static const String loyaltyPointConvert =
      '/api/v1/customer/loyalty/loyalty-exchange-currency';
  static const String deleteCustomerAccount = '/api/v1/customer/account-delete';
  static const String deliveryRestrictedCountryList =
      '/api/v1/customer/get-restricted-country-list';
  static const String deliveryRestrictedZipList =
      '/api/v1/customer/get-restricted-zip-list';
  static const String getOrderFromOrderId =
      '/api/v1/customer/order/get-order-by-id?order_id=';
  static const String offlinePayment =
      '/api/v1/customer/order/place-by-offline-payment';
  static const String walletPayment = '/api/v1/customer/order/place-by-wallet';
  static const String couponListApi = '/api/v1/coupon/list?limit=100&offset=';
  static const String sellerWiseCouponListApi = '/api/v1/coupons/';
  static const String sellerWiseBestSellingProduct = '/api/v1/seller/';
  static const String digitalPayment = '/api/v1/digital-payment';

  /// What the app asks after a MyFatoorah payment, instead of reading the result out of the redirect
  /// URL. The server checks with MyFatoorah server-to-server; the app never decides this itself.
  static const String myFatoorahStatusUri = '/api/v1/payment/myfatoorah/status';
  static const String offlinePaymentList =
      '/api/v1/customer/order/offline-payment-method-list';
  static const String sellerWiseCategoryList = '/api/v1/categories?shop_slug=';
  static const String sellerWiseBrandList = '/api/v1/brands?shop_slug=';
  static const String getDigitalAuthorList =
      '/api/v1/products/digital-author-list?guest_id=1';
  static const String getDigitalPublishingHouse =
      '/api/v1/products/digital-publishing-house-list?guest_id=1';
  static const String verifyProfileInfo = '/api/v1/auth/verify-profile-info';
  static const String firebaseAuthTokenStore =
      '/api/v1/auth/firebase-auth-token-store';
  static const String productRestockRequest =
      '/api/v1/cart/product-restock-request';
  static const String productRestockList =
      '/api/v1/customer/restock-requests/list?';
  static const String productRestockDelete =
      '/api/v1/customer/restock-requests/delete';
  static const String clearanceAllProductUri =
      '/api/v1/products/clearance-sale';
  static const String clearanceShopProductUri = '/api/v1/seller/';
  static const String clearanceShopSearchProductUri = '/api/v1/seller/';
  static const String businessPagesUri = '/api/v1/business-pages?type=';
  static const String getDeliveryManReview =
      '/api/v1/customer/order/deliveryman-review?order_id=';
  static const String submitDeliveryManReview =
      '/api/v1/customer/order/deliveryman-review/update?order_id=';
  static const String mergeGuestCart = '/api/v1/cart/get-merge-guest-cart';
  static const String orderDetailsTrack =
      '/api/v1/order/track-order-details?order_id=';

  //address
  static const String updateAddressUri = '/api/v1/customer/address/update';
  static const String geocodeUri = '/api/v1/mapapi/geocode-api';
  static const String searchLocationUri =
      '/api/v1/mapapi/place-api-autocomplete';
  static const String placeDetailsUri = '/api/v1/mapapi/place-api-details';
  static const String distanceMatrixUri = '/api/v1/mapapi/distance-api';
  static const String chatWithDeliveryMan = '/api/v1/mapapi/distance-api';

  static const String getGuestIdUri = '/api/v1/get-guest-id';
  static const String mostDemandedProduct =
      '/api/v1/products/most-demanded-product?guest_id=1';
  static const String shopAgainFromRecentStore =
      '/api/v1/products/shop-again-product';
  static const String findWhatYouNeed =
      '/api/v1/categories/find-what-you-need?guest_id=1';
  static const String orderTrack = '/api/v1/order/track-order';
  static const String addFundToWallet = '/api/v1/add-to-fund';
  static const String reorder = '/api/v1/customer/order/again';
  static const String walletBonusList = '/api/v1/customer/wallet/bonus-list';
  static const String moreStore = '/api/v1/seller/more';
  static const String justForYou = '/api/v1/products/just-for-you?guest_id=1';
  static const String mostSearching = '/api/v1/products/most-searching';
  static const String contactUsUri = '/api/v1/contact-us';
  static const String attributeUri = '/api/v1/attributes';
  static const String availableCoupon = '/api/v1/coupon/applicable-list';
  static const String downloadDigitalProduct =
      '/api/v1/customer/order/digital-product-download/';
  static const String otpVResendForDigitalProduct =
      '/api/v1/customer/order/digital-product-download-otp-resend';
  static const String otpVerificationForDigitalProduct =
      '/api/v1/customer/order/digital-product-download-otp-verify';
  static const String selectCartItemsUri = '/api/v1/cart/select-cart-items';
  static const String generateInvoice =
      '/api/v1/customer/order/generate-invoice?order_id=';

  static const String checkEmailUri = '/api/v1/auth/check-email';
  static const String checkPhoneUri = '/api/v1/auth/check-phone?phone=';
  static const String firebaseAuthVerify = '/api/v1/auth/firebase-auth-verify';
  static const String registerWithOtp = '/api/v1/auth/registration-with-otp';
  static const String verifyTokenUri = '/api/v1/auth/verify-token';
  static const String existingAccountCheck =
      '/api/v1/auth/existing-account-check';
  static const String referralAmountUri =
      '/api/v1/cart/get-referral-discount-redeem';

  static const String duePaymentByCodUri =
      '/api/v1/edit-order/due-payment-by-cod';
  static const String duePaymentByDigitalPayment =
      '/api/v1/edit-order/due-payment-by-digital-payment';
  static const String duePaymentByWallet =
      '/api/v1/edit-order/due-payment-by-wallet';
  static const String duePaymentByOfflinePayment =
      '/api/v1/edit-order/due-payment-by-offline-payment';

  static const String getCompareList = '/api/v1/customer/compare/list';
  static const String addToCompareList =
      '/api/v1/customer/compare/product-store';
  static const String removeAllFromCompareList =
      '/api/v1/customer/compare/clear-all';
  static const String replaceFromCompareList =
      '/api/v1/customer/compare/product-replace';
  static const String setCurrentLanguage = '/api/v1/customer/language-change';
  static const String registerWithSocialMedia =
      '/api/v1/auth/registration-with-social-media';

  // sharePreference
  static const String analyticsClientId = 'analytics_client_id';
  static const String userLoginToken = 'user_login_token';
  static const String guestId = 'guestId';
  static const String user = 'user';
  static const String userEmail = 'user_email';
  static const String userPassword = 'user_password';
  static const String homeAddress = 'home_address';
  static const String searchProductName = 'search_product';
  static const String officeAddress = 'office_address';
  static const String config = 'config';
  static const String guestMode = 'guest_mode';
  static const String currency = 'currency';
  static const String langKey = 'lang';
  static const String intro = 'intro';
  static const String userLogData = 'user_log_data';
  static const pi = 3.14;
  static const defaultSpread = 0.0872665;
  static const double minFilter = 0;
  static const double maxFilter = 1000000;
  static const String appleLoginEmail = 'apple_login_email';
  static const String guestCartId = 'guest_cart_id';

  // order status
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String processing = 'processing';
  static const String processed = 'processed';
  static const String delivered = 'delivered';
  static const String failed = 'failed';
  static const String returned = 'returned';
  static const String cancelled = 'canceled';
  static const String outForDelivery = 'out_for_delivery';
  static const String maintenanceModeTopic = 'maintenance_mode_start_user_app';

  /// The publish beacon: a silent data ping the backend sends when a merchant publishes a theme,
  /// so an open app re-syncs in seconds instead of on its next resume. Subscribed at startup,
  /// before login, so guests hear it too.
  static const String themeUpdatesTopic = 'theme_updates_user_app';
  static const String themeVersionChangedType = 'theme_version_changed';
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String theme = 'theme';
  static const String topic = 'sixvalley';
  static const String demoTopic = 'sixvalley';
  static const String userAddress = 'user_address';

  static List<LanguageModel> languages = [
    LanguageModel(
        imageUrl: Images.ar,
        languageName: 'Arabic',
        countryCode: 'SA',
        languageCode: 'ar'),
    LanguageModel(
        imageUrl: Images.en,
        languageName: 'English',
        countryCode: 'US',
        languageCode: 'en'),
  ];

  static const reviewList = ['very_bad', 'bad', 'good', 'very_good', 'best'];

  static const double maxSizeOfASingleFile = 10;
  static const double maxLimitOfTotalFileSent = 5;
  static const double maxLimitOfFileSentINConversation = 25;
  static const int fileImageMaxLimit = 2;

  static const List<String> filterTypeList = ['all', 'debit', 'credit'];

  static const List<String> loyaltyEarnTypeList = [
    'order_place',
    'point_to_wallet',
    'refund_order'
  ];

  static const List<String> walletEarnTypeList = [
    'add_fund_by_admin',
    'loyalty_point',
    'order_place',
    'order_refund',
    'added_via_payment_method',
    'earned_by_referral',
    'due_payment_for_order',
    'return_order_amount_by_admin'
  ];

  static const List<String> videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'mpeg',
    'mpg',
    'm4v',
    '3gp',
    'ogv'
  ];

  static const List<String> imageExtensions = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp'
  ];

  static const List<String> documentExtensions = [
    'doc',
    'docx',
    'txt',
    'csv',
    'xls',
    'xlsx',
    'rar',
    'tar',
    'targz',
    'zip',
    'pdf'
  ];
}