import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';

abstract class DynamicThemeRepositoryInterface {
  /// The cheap sync check: what revision is live right now.
  Future<ThemeRevision> fetchRevision();

  /// The full page for this build, negotiated against its capabilities.
  ///
  /// [knownChecksum] is sent as `If-None-Match`; a 304 comes back as a success with a null
  /// payload, meaning "what you hold is current".
  Future<ApiResponseModel<ThemePayload?>> fetchPayload({
    String page = 'home',
    String? knownChecksum,
  });

  /// One section's data, from the endpoint its `source` names.
  Future<ApiResponseModel> fetchSectionData(String path);

  /// The last payload that rendered successfully, or null on a first run.
  Future<ThemePayload?> readCachedPayload({String page = 'home'});

  Future<void> dropCachedPayloads();

  Future<void> writeCachedPayload(ThemePayload payload, Map<String, dynamic> raw);
}
