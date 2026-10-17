/// A typed failure raised by the data layer.
///
/// Repository and service code never leaks raw exceptions to the UI; it
/// converts them to an [ApiFailure] with a human-readable message.
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  /// A connectivity failure — the request never reached the server.
  factory ApiFailure.network() =>
      const ApiFailure('Sem ligação ao servidor. Verifica a rede.');

  /// A human-readable, user-facing message (in Portuguese).
  final String message;

  /// The HTTP status code, when a response was received.
  final int? statusCode;

  /// True when the failure is a missing/invalid API key.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}
