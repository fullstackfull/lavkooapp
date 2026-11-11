import 'dart:io';
import 'package:syriapharmacy/features/review/domain/models/review_body.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class ReviewRepositoryInterface
    implements RepositoryInterface<ReviewBody> {
  Future<dynamic> submitReview(
      ReviewBody reviewBody, List<File> files, bool update);
  @override
  Future<dynamic> get(String id, {int offset = 1, int limit = 10});

  Future<dynamic> getOrderWiseReview(String productID, String orderId);

  Future<dynamic> deleteOrderWiseReviewImage(String id, String name);

  Future<dynamic> getDeliveryManReview(String orderId);

  Future<dynamic> submitDeliveryManReview(
      String orderId, String comment, String rating);
}
