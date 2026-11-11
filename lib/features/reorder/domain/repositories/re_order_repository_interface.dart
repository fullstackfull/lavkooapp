import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class ReOrderRepositoryInterface<T> extends RepositoryInterface {
  Future<dynamic> reorder(String orderId);
}
