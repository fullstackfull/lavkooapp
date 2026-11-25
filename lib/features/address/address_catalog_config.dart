/// The central address catalogue ships dark (J-14).
///
/// Nothing calls `/api/v1/address/regions` or `/cities`, and no form offers a
/// region or a city from them, unless the build is made with
/// `--dart-define=GCC_UNIFIED_ADDRESS=true`. While it is off the address form
/// is the form this app has always had: free text, the shop-wide country and
/// zip lists, and no extra request.
///
/// It is a build-time switch rather than a setting because the server's own
/// `unified_address_mode` has three states (`off`, `soft`, `strict`) and only
/// `strict` requires every client to send a structured address. An app that
/// asked for the catalogue while the server was still `off` would be asking for
/// lists that have no rows, and an app that sent a structured address to a
/// server that cannot store it would lose the part it could not keep. So the
/// app follows the server rather than deciding: this switch says "this build
/// knows how to", and the server's mode says whether it should.
class AddressCatalogConfig {
  static const bool enabled = bool.fromEnvironment('GCC_UNIFIED_ADDRESS', defaultValue: false);
}
