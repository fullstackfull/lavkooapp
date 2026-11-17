abstract class StorefrontServiceInterface {
  /// Asks the server which storefronts may sell yet and keeps its answer. True when a usable answer replaced the stored one; false when
  /// nothing was asked (storefronts are off), the request failed, or the answer could not be used, and the stored answer stays in force.
  Future<bool> refreshStorefronts();
}
