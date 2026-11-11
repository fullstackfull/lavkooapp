import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/repositories/dynamic_theme_repository_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';

class DynamicThemeService implements DynamicThemeServiceInterface {
  DynamicThemeService({required this.dynamicThemeRepositoryInterface});

  final DynamicThemeRepositoryInterface dynamicThemeRepositoryInterface;

  @override
  Future<ThemeRevision> getRevision() =>
      dynamicThemeRepositoryInterface.fetchRevision();

  @override
  Future<ApiResponseModel<ThemePayload?>> getPayload({
    String page = 'home',
    String? knownChecksum,
  }) =>
      dynamicThemeRepositoryInterface.fetchPayload(
        page: page,
        knownChecksum: knownChecksum,
      );

  @override
  Future<ThemePayload?> getCachedPayload({String page = 'home'}) =>
      dynamicThemeRepositoryInterface.readCachedPayload(page: page);

  @override
  Future<void> dropCachedPayloads() =>
      dynamicThemeRepositoryInterface.dropCachedPayloads();

  /// A section's own data, when its source names an endpoint.
  ///
  /// Sources that are `inline` or `none` never reach the network: the first already carries its
  /// data in the payload, and the second has no endpoint to call. Returning an error for those is
  /// what a caller expects — it means "do not wait for anything".
  @override
  Future<ApiResponseModel> getSectionData(SectionSource source) async {
    final path = source.requestPath;

    if (!source.isApi || path == null) {
      return ApiResponseModel.withError('section_has_no_remote_source');
    }

    return dynamicThemeRepositoryInterface.fetchSectionData(path);
  }
}
