import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class BrandRepoInterface implements RepositoryInterface {
  Future<dynamic> getBrandList<T>({int offset, required DataSourceEnum source});

  Future<dynamic> getSellerWiseBrandList(String slug);
}
