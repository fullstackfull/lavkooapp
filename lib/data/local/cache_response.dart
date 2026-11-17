import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:syriapharmacy/features/storefront/storefront_cache_key.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
part 'cache_response.g.dart';

class CacheResponse extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endPoint => text().unique()();
  TextColumn get header => text()();
  TextColumn get response => text()();
  BoolColumn get isSuccess => boolean().withDefault(const Constant(true))(); // Change to BoolColumn
}


@DriftDatabase(tables: [CacheResponse])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// The same database over [executor], so a test can run its queries over a database in memory.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cache_response_new_db');
  }

  /// The key a row is filed under: [endPoint] itself while storefronts are off, and [endPoint] followed by `#<code>` of the storefront the
  /// app's requests are made for while they are on. Every read and write of a row below goes through it, so every cache that keeps rows
  /// here is kept per storefront whatever key its own code builds, and a storefront never reads another's row. It is worked out when a
  /// method is called, before anything is awaited, so an answer is filed for the storefront the caller meant.
  String _rowKey(String endPoint) => StorefrontCacheKey.scoped(
        endPoint,
        storefrontCode: StorefrontScope.current,
      );

  CacheResponseCompanion _filed(CacheResponseCompanion entry) =>
      entry.endPoint.present
          ? entry.copyWith(endPoint: Value(_rowKey(entry.endPoint.value)))
          : entry;

  Future<int> insertCacheResponse(CacheResponseCompanion entry) async {
    // final existing = await (select(cacheResponse)..where((tbl) => tbl.endPoint.equals(entry.endPoint as String))).getSingleOrNull();
    // if (existing == null) {
    //   return await into(cacheResponse).insert(entry);
    // } else {
    //   await update(cacheResponse).replace(entry);
    // }
    return await into(cacheResponse).insert(_filed(entry));
  }


  Future<List<CacheResponseData>> getAllCacheResponses() async {
    return await select(cacheResponse).get();
  }


  Future<CacheResponseData?> getCacheResponseById(String endPoint) async {
    final String rowKey = _rowKey(endPoint);
    return await (select(cacheResponse)..where((tbl) => tbl.endPoint.equals(rowKey)))
        .getSingleOrNull();
  }


  Future<int> updateCacheResponse(String endPoint, CacheResponseCompanion entry) async {
    final String rowKey = _rowKey(endPoint);
    return await (update(cacheResponse)..where((tbl) => tbl.endPoint.equals(rowKey)))
        .write(_filed(entry));
  }


  Future<int> deleteCacheResponse(int id) async {
    return await (delete(cacheResponse)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> deleteCacheResponseByEndpoint(String endPoint) async {
    final String rowKey = _rowKey(endPoint);
    return await (delete(cacheResponse)..where((tbl) => tbl.endPoint.equals(rowKey)))
        .go();
  }

  /// Deletes the rows whose key starts with [prefix]: all of them while storefronts are off, and only the storefront's own while they
  /// are on, so one storefront dropping its rows never drops another's.
  Future<int> deleteCacheResponsesByPrefix(String prefix) async {
    final String? storefrontCode = StorefrontScope.current;
    if (storefrontCode == null) {
      return await (delete(cacheResponse)..where((tbl) => tbl.endPoint.like('$prefix%')))
          .go();
    }

    final List<CacheResponseData> candidates = await (select(cacheResponse)
          ..where((tbl) => tbl.endPoint.like('$prefix%')))
        .get();

    return await _deleteRows(candidates.where((row) =>
        StorefrontCacheKey.isScopedTo(row.endPoint,
            storefrontCode: storefrontCode)));
  }

  /// Deletes every row filed for [storefrontCode], whatever its key. The rows of every other storefront, and the rows filed before
  /// storefronts were on, are left where they are.
  Future<int> deleteCacheResponsesOfStorefront(String storefrontCode) async {
    // The match in the query is a superset (LIKE ignores case); the exact one is made here.
    final List<CacheResponseData> candidates = await (select(cacheResponse)
          ..where((tbl) => tbl.endPoint.like('%#$storefrontCode')))
        .get();

    return await _deleteRows(candidates.where((row) =>
        StorefrontCacheKey.isScopedTo(row.endPoint,
            storefrontCode: storefrontCode)));
  }

  Future<int> _deleteRows(Iterable<CacheResponseData> rows) async {
    final List<int> ids = rows.map((row) => row.id).toList();
    if (ids.isEmpty) return 0;

    return await (delete(cacheResponse)..where((tbl) => tbl.id.isIn(ids))).go();
  }


  Future<int> clearCacheResponses() async {
    return await delete(cacheResponse).go();
  }



}
