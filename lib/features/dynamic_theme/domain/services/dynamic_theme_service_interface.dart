import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';

abstract class DynamicThemeServiceInterface {
  Future<ThemeRevision> getRevision();

  Future<ApiResponseModel<ThemePayload?>> getPayload({
    String page = 'home',
    String? knownChecksum,
  });

  Future<ApiResponseModel> getSectionData(SectionSource source);

  Future<ThemePayload?> getCachedPayload({String page = 'home'});

  Future<void> dropCachedPayloads();
}
