import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class FlashDealRepositoryInterface implements RepositoryInterface {
  Future<dynamic> getFlashDeal();
}
