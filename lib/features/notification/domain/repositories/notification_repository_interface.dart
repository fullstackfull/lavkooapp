import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class NotificationRepositoryInterface implements RepositoryInterface {
  Future<dynamic> seenNotification(int id);
}
