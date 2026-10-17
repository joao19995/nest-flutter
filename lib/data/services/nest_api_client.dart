import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nest/config/env.dart';
import 'package:nest/domain/failures/api_failure.dart';

/// Thin HTTP wrapper around the Nest API.
///
/// Adds the JSON headers, the `Authorization: Bearer` key, a timeout, and
/// normalises every non-2xx response into an [ApiFailure].
class NestApiClient {
  NestApiClient({http.Client? httpClient, String? baseUrl, String? apiKey})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? Env.apiBaseUrl,
      _apiKey = apiKey ?? Env.apiKey;

  final http.Client _httpClient;
  final String _baseUrl;
  final String _apiKey;

  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  void dispose() => _httpClient.close();

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      ..._baseHeaders,
      if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
    };
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _httpClient.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw ApiFailure.network();
    }
  }

  dynamic _decode(http.Response response) {
    dynamic payload;
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } on FormatException {
        payload = null;
      }
    }
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) {
      return payload;
    }
    throw ApiFailure(
      _errorMessage(payload, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(dynamic payload, int statusCode) {
    if (payload is Map<String, dynamic>) {
      final error = payload['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }
    return 'Erro $statusCode.';
  }
}
