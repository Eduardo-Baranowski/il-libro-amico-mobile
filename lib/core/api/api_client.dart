import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/api_config.dart';
import 'api_exception.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient({required this.getToken, this.onUnauthorized});

  final Future<String?> Function() getToken;
  final UnauthorizedHandler? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.instance.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response res) async {
    if (res.statusCode == 401 && onUnauthorized != null) {
      await onUnauthorized!();
    }

    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = res.body;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    String message = res.reasonPhrase ?? 'Erro';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['msg'] != null) {
      message = body['msg'].toString();
    }

    throw ApiException(statusCode: res.statusCode, message: message);
  }

  Future<T> _send<T>(Future<http.Response> Function() request, T Function(dynamic) parse) async {
    try {
      final res = await request();
      final data = await _handleResponse(res);
      return parse(data);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message:
            'Sem conexão com ${ApiConfig.instance.baseUrl}. Verifique se a API está rodando (npm run dev) e a URL em Conta. (${e.message})',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Falha de rede em ${ApiConfig.instance.baseUrl}. (${e.message})',
      );
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, String>? query,
    T Function(dynamic)? parser,
  }) async {
    final headers = await _headers();
    return _send(
      () => http.get(_uri(path, query), headers: headers),
      parser ?? (d) => d as T,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    T Function(dynamic)? parser,
  }) async {
    final headers = await _headers(jsonBody: body != null);
    return _send(
      () => http.post(
        _uri(path),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      parser ?? (d) => d as T,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? body,
    T Function(dynamic)? parser,
  }) async {
    final headers = await _headers(jsonBody: body != null);
    return _send(
      () => http.put(
        _uri(path),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      parser ?? (d) => d as T,
    );
  }

  Future<T> delete<T>(
    String path, {
    T Function(dynamic)? parser,
  }) async {
    final headers = await _headers();
    return _send(
      () => http.delete(_uri(path), headers: headers),
      parser ?? (d) => d as T,
    );
  }

  /// Sends a multipart request. Pass [file] to attach a binary file.
  Future<T> sendMultipart<T>(
    String path, {
    required String method,
    Map<String, String>? fields,
    ({String fieldName, String filePath, String mimeType})? file,
    T Function(dynamic)? parser,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(method, _uri(path));
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    if (fields != null) request.fields.addAll(fields);
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        file.fieldName,
        file.filePath,
        contentType: MediaType.parse(file.mimeType),
      ));
    }

    return _send(
      () async {
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      parser ?? (d) => d as T,
    );
  }

  Future<T> postMultipart<T>(
    String path, {
    Map<String, String>? fields,
    ({String fieldName, String filePath, String mimeType})? file,
    T Function(dynamic)? parser,
  }) =>
      sendMultipart(path, method: 'POST', fields: fields, file: file, parser: parser);

  Future<T> putMultipart<T>(
    String path, {
    Map<String, String>? fields,
    ({String fieldName, String filePath, String mimeType})? file,
    T Function(dynamic)? parser,
  }) =>
      sendMultipart(path, method: 'PUT', fields: fields, file: file, parser: parser);
}
