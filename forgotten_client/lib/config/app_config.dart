import 'dart:convert';

class AppConfigDefaults {
  const AppConfigDefaults({
    required this.flavor,
    required this.apiBaseUrl,
    required this.openAiMode,
    required this.featureFlagsJson,
    required this.appLogLevel,
  });

  final String flavor;
  final String apiBaseUrl;
  final String openAiMode;
  final String featureFlagsJson;
  final String appLogLevel;
}

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.openAiMode,
    required this.featureFlags,
    required this.appLogLevel,
  });

  factory AppConfig.fromEnvironment({required AppConfigDefaults defaults}) {
    const flavorOverride = String.fromEnvironment('FLAVOR');
    const apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
    const openAiModeOverride = String.fromEnvironment('OPENAI_MODE');
    const appLogLevelOverride = String.fromEnvironment('APP_LOG_LEVEL');
    const featureFlagsOverride = String.fromEnvironment('FEATURE_FLAGS_JSON');

    return AppConfig(
      flavor: flavorOverride.isEmpty ? defaults.flavor : flavorOverride,
      apiBaseUrl: Uri.parse(
        apiBaseUrlOverride.isEmpty ? defaults.apiBaseUrl : apiBaseUrlOverride,
      ),
      openAiMode: openAiModeOverride.isEmpty
          ? defaults.openAiMode
          : openAiModeOverride,
      featureFlags: _decodeFeatureFlags(
        featureFlagsOverride.isEmpty
            ? defaults.featureFlagsJson
            : featureFlagsOverride,
      ),
      appLogLevel: appLogLevelOverride.isEmpty
          ? defaults.appLogLevel
          : appLogLevelOverride,
    );
  }

  final String flavor;
  final Uri apiBaseUrl;
  final String openAiMode;
  final Map<String, dynamic> featureFlags;
  final String appLogLevel;

  static Map<String, dynamic> _decodeFeatureFlags(String source) {
    if (source.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'raw': decoded};
    } catch (_) {
      // Preserve the raw value to surface in diagnostics if JSON parsing fails.
      return {'raw': source, 'parseError': true};
    }
  }
}
