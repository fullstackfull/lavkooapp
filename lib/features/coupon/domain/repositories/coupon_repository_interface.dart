import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class CouponRepositoryInterface<T> extends RepositoryInterface {
  Future<dynamic> getAvailableCouponList();

  Future<dynamic> getSellerCouponList(String slug, int offset);
}
