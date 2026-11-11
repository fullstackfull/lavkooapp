import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/features/brand/domain/repositories/brand_repo_interface.dart';
import 'package:syriapharmacy/features/brand/domain/services/brand_service_interface.dart';

class BrandService implements BrandServiceInterface {
  BrandRepoInterface brandRepoInterface;
  BrandService({required this.brandRepoInterface});

  @override
  Future getList() {
    return brandRepoInterface.getList();
  }

  @override
  Future getBrandList<T>({int offset = 1, required DataSourceEnum source}) {
    return brandRepoInterface.getBrandList(offset: offset, source: source);
  }

  @override
  Future getSellerWiseBrandList(String slug) {
    return brandRepoInterface.getSellerWiseBrandList(slug);
  }
}
