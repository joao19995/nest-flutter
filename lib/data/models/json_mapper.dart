import 'package:nest/domain/failures/api_failure.dart';

const ApiFailure _invalidResponse = ApiFailure(
  'Resposta inesperada do servidor.',
);

/// Requires an API payload to be a JSON object.
Map<String, dynamic> requireJsonObject(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  throw _invalidResponse;
}

/// Maps one JSON object to a domain value, converting any mapping error into
/// an [ApiFailure] so malformed payloads never leak as raw `TypeError`s.
T mapJson<T>(Object? data, T Function(Map<String, dynamic> json) mapper) =>
    _guard(() => mapper(requireJsonObject(data)));

/// Maps a JSON array to domain values, failing consistently when the payload
/// is not a list or contains a non-object entry.
List<T> mapJsonList<T>(
  Object? data,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (data is! List) {
    throw _invalidResponse;
  }
  return _guard(
    () => [
      for (final item in data)
        if (item is Map<String, dynamic>)
          mapper(item)
        else
          throw _invalidResponse,
    ],
  );
}

T _guard<T>(T Function() mapper) {
  try {
    return mapper();
  } on ApiFailure {
    rethrow;
  } catch (_) {
    throw _invalidResponse;
  }
}
