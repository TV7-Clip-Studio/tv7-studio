import 'package:forgotten_client/config/app_config.dart';

/// Placeholder for fetching remote config/feature flags from the backend.
/// Until the backend publishes a config endpoint, we rely on dart-defines.
class ConfigRepository {
  ConfigRepository(this.appConfig);

  final AppConfig appConfig;

  Future<AppConfig> fetch() async {
    // TODO(tv7): replace with backend call once config endpoint exists.
    return appConfig;
  }
}
