import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:network_inspector/common/utils/json_util.dart';

class HttpInterceptor extends BaseClient {
  final Client client;

  HttpInterceptor({
    required this.client,
  });

  final _jsonUtil = JsonUtil();

  @override
  Future<Response> head(
    Uri url, {
    Map<String, String>? headers,
  }) =>
      _sendUnstreamed('HEAD', url, headers);

  @override
  Future<Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) =>
      _sendUnstreamed('GET', url, headers);

  @override
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed('POST', url, headers, body, encoding);

  @override
  Future<Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed('PUT', url, headers, body, encoding);

  @override
  Future<Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed('PATCH', url, headers, body, encoding);

  @override
  Future<Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamed('DELETE', url, headers, body, encoding);

  @override
  Future<String> read(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final response = await get(
      url,
      headers: headers,
    );
    _checkResponseSuccess(url, response);
    return response.body;
  }

  @override
  Future<Uint8List> readBytes(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final response = await get(
      url,
      headers: headers,
    );
    _checkResponseSuccess(url, response);
    return response.bodyBytes;
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<Response> _sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers, [
    body,
    Encoding? encoding,
  ]) async {
    var request = Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }
    final response = await Response.fromStream(
      await send(request),
    );

    /// Intercept area
    logRequest(request);
    logResponse(response);
    return response;
  }

  /// Sends an HTTP request and asynchronously returns the response.
  ///
  /// Implementers should call [BaseRequest.finalize] to get the body of the
  /// request as a [ByteStream]. They shouldn't make any assumptions about the
  /// state of the stream; it could have data written to it asynchronously at a
  /// later point, or it could already be closed when it's returned. Any
  /// internal HTTP errors should be wrapped as [ClientException]s.
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    return client.send(request);
  }

  Future<void> logRequest(Request request) async {
    var logTemplate = '\n[Request url] ${request.url.toString()}'
        '\n[Request header] ${request.headers.toString()}'
        '\n[Request param] ${request.url.queryParameters}'
        '\n[Request body] ${_jsonUtil.encodeRawJson(request.body)}'
        '\n[Request method] ${request.method}'
        '\n[Request content-type] ${request.headers['Content-Type']}';
    developer.log(logTemplate);
  }

  Future<void> logResponse(Response response) async {
    var logTemplate = '\n[Response header] ${response.headers.toString()}'
        '\n[Response body] ${_jsonUtil.encodeRawJson(response.body)}'
        '\n[Response code] ${response.statusCode}'
        '\n[Response message] ${response.reasonPhrase}';
    developer.log(logTemplate);
  }

  /// Throws an error if [response] is not successful.
  void _checkResponseSuccess(Uri url, Response response) {
    if (response.statusCode < 400) return;
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    throw ClientException('$message.', url);
  }

  @override
  void close() {}
}
