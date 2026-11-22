import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/main.dart';

class DbHelper {
  /// [localDatabase] is the app's one database unless a test hands in another.
  static Future<void> insertOrUpdate(
      {required String id,
      required CacheResponseCompanion data,
      AppDatabase? localDatabase}) async {
    final AppDatabase target = localDatabase ?? database;
    final String? storefront = StorefrontScope.current;
    final response = await target.getCacheResponseById(id);

    // The row was looked up for one storefront; written after the customer moved on it would be filed for another.
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (response != null) {
      await target.updateCacheResponse(id, data);
    } else {
      await target.insertCacheResponse(data);
    }
  }
}
