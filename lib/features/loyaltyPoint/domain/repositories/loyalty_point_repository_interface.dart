import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class LoyaltyPointRepositoryInterface implements RepositoryInterface {
  Future<dynamic> convertPointToCurrency(int point);

  @override
  Future<dynamic> getList(
      {int? offset = 1,
      String? filterBy,
      DateTime? startDate,
      DateTime? endDate,
      List<String>? transactionTypes});
}
