/// Build-time environment configuration.
///
/// Values are injected with `--dart-define`, e.g.:
/// `flutter run --dart-define=NEST_API_BASE_URL=https://... --dart-define=NEST_API_KEY=...`
abstract final class Env {
  /// Base origin of the Nest API (no trailing slash, no `/api` suffix).
  static const String apiBaseUrl = String.fromEnvironment(
    'NEST_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Shared API key sent as `Authorization: Bearer <key>`.
  /// Required for external clients; empty when the API is unauthenticated.
  static const String apiKey = String.fromEnvironment('NEST_API_KEY');
}
