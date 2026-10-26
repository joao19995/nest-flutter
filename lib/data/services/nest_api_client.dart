import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  /// Invoked whenever the API answers with `401 Unauthorized`.
  void Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Object?> get(String path) => _send('GET', path);

  Future<Object?> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<Object?> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<Object?> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  void dispose() => _httpClient.close();

  /// Resolves [path] against [_baseUrl]. On web an empty base URL means
  /// "same origin", so the PWA can be served next to an `/api` proxy.
  Uri _resolve(String path) {
    final base = _baseUrl.isNotEmpty
        ? _baseUrl
        : kIsWeb
        ? Uri.base.origin
        : '';
    return Uri.parse('$base$path');
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _resolve(path);
    final headers = <String, String>{
      ..._baseHeaders,
      if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
    };
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final response = await _httpClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
      return _decode(response);
    } on ApiFailure {
      rethrow;
    } on TimeoutException {
      throw ApiFailure.timeout();
    } catch (_) {
      throw ApiFailure.network();
    }
  }

  Object? _decode(http.Response response) {
    Object? payload;
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
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    throw ApiFailure(
      _errorMessage(payload, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(Object? payload, int statusCode) {
    if (payload is Map<String, dynamic>) {
      final error = payload['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }
    return 'Erro $statusCode.';
  }
}
