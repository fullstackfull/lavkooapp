import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/deal/domain/models/flash_deal_model.dart';
import 'package:syriapharmacy/features/deal/domain/services/flash_deal_service_interface.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:intl/intl.dart';

class FlashDealController extends ChangeNotifier {
  final FlashDealServiceInterface flashDealServiceInterface;
  FlashDealController({required this.flashDealServiceInterface});

  FlashDealModel? _flashDeal;
  final List<Product> _flashDealList = [];
  Duration? _duration;
  Timer? _timer;
  FlashDealModel? get flashDeal => _flashDeal;
  List<Product> get flashDealList => _flashDealList;
  Duration? get duration => _duration;
  int? _currentIndex;
  int? get currentIndex => _currentIndex;

  Future<void> getFlashDealList(bool reload, bool notify) async {
    var localData =
        await database.getCacheResponseById(AppConstants.flashDealUri);
    CacheResponseData? localData2;

    if (localData != null) {
      // With no live deal the endpoint answers a bare `null` — cached or fresh,
      // that is "no deal", not a parseable model.
      final dynamic cached = jsonDecode(localData.response);
      _flashDeal =
          cached is Map<String, dynamic> ? FlashDealModel.fromJson(cached) : null;

      if (_flashDeal?.id != null) {
        // The deal runs through the end of its end_date day — the countdown
        // is the true remainder, and it stops at zero instead of inventing time.
        final DateTime endTime = DateFormat("yyyy-MM-dd")
            .parse(_flashDeal!.endDate!)
            .add(const Duration(days: 1));

        _duration = endTime.difference(DateTime.now());
        if (_duration!.isNegative) _duration = Duration.zero;

        _timer?.cancel();

        _timer = null;

        if (_duration! > Duration.zero) {
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _duration = _duration! - const Duration(seconds: 1);

            if (_duration! <= Duration.zero) {
              _duration = Duration.zero;
              timer.cancel();
            }

            notifyListeners();
          });
        }

        localData2 = await database
            .getCacheResponseById(AppConstants.flashDealProductUri);

        // if (localData2 != null) {
        //   _flashDealList.clear();
        //   var products = jsonDecode(localData2.response);
        //
        //   products.forEach(
        //       (flashDeal) => _flashDealList.add(Product.fromJson(flashDeal)));
        //   _currentIndex = 0;
        // }
        if (localData2 != null) {
          _flashDealList.clear();
          final dynamic decoded = jsonDecode(localData2.response);

          final List productsList = decoded is Map
              ? (decoded['products'] as List? ?? const [])
              : (decoded as List? ?? const []);

          for (final flashDeal in productsList) {
            _flashDealList.add(Product.fromJson(flashDeal));
          }
          _currentIndex = 0;
        }
      }
      notifyListeners();
    }

    if (_flashDealList.isEmpty || reload) {
      ApiResponseModel apiResponse =
          await flashDealServiceInterface.getFlashDeal();
      if (apiResponse.response != null &&
          apiResponse.response!.statusCode == 200) {
        final dynamic fresh = apiResponse.response!.data;
        _flashDeal =
            fresh is Map<String, dynamic> ? FlashDealModel.fromJson(fresh) : null;

        if (localData != null) {
          await database.updateCacheResponse(
              AppConstants.flashDealUri,
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.flashDealUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.flashDealUri),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }

        if (_flashDeal?.id != null) {
          // The deal runs through the end of its end_date day — the countdown
          // is the true remainder, and it stops at zero instead of inventing time.
          final DateTime endTime = DateFormat("yyyy-MM-dd")
              .parse(_flashDeal!.endDate!)
              .add(const Duration(days: 1));

          _duration = endTime.difference(DateTime.now());
          if (_duration!.isNegative) _duration = Duration.zero;

          _timer?.cancel();

          _timer = null;

          if (_duration! > Duration.zero) {
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              _duration = _duration! - const Duration(seconds: 1);

              if (_duration! <= Duration.zero) {
                _duration = Duration.zero;
                timer.cancel();
              }

              notifyListeners();
            });
          }

          ApiResponseModel megaDealResponse =
              await flashDealServiceInterface.get(_flashDeal!.id.toString());

          if (megaDealResponse.response != null &&
              megaDealResponse.response!.statusCode == 200) {
            _flashDealList.clear();
            // The endpoint answers {total_size, products: [...]}; older builds of the API sent a
            // bare list. A Map's forEach takes (key, value) — feeding it the single-argument
            // closure below was an unhandled type error that killed the whole screen.
            final dealData = megaDealResponse.response!.data;
            final dealRows = dealData is Map
                ? (dealData['products'] as List? ?? const [])
                : (dealData as List? ?? const []);
            for (final flashDeal in dealRows) {
              _flashDealList.add(Product.fromJson(flashDeal));
            }
            _currentIndex = 0;

            if (localData2 != null) {
              await database.updateCacheResponse(
                  AppConstants.flashDealProductUri,
                  CacheResponseCompanion(
                    endPoint: const Value(AppConstants.flashDealProductUri),
                    header: Value(
                        jsonEncode(megaDealResponse.response!.headers.map)),
                    response:
                        Value(jsonEncode(megaDealResponse.response!.data)),
                  ));
            } else {
              await database.insertCacheResponse(
                CacheResponseCompanion(
                  endPoint: const Value(AppConstants.flashDealProductUri),
                  header:
                      Value(jsonEncode(megaDealResponse.response!.headers.map)),
                  response: Value(jsonEncode(megaDealResponse.response!.data)),
                ),
              );
            }
            notifyListeners();
          } else {
            ApiChecker.checkApi(megaDealResponse);
          }
        } else {
          notifyListeners();
        }
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    }
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
