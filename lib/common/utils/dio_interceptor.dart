import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../common/extensions/curl_extension.dart';
import '../../domain/entities/http_request.dart';
import '../../domain/entities/http_response.dart';
import '../../network_inspector.dart';
import 'byte_util.dart';
import 'json_util.dart';

class DioInterceptor extends Interceptor {
  /// Enable/Disable overall logging
  final bool logIsAllowed;

  /// Enable/Disable only console logging
  final bool isConsoleLogAllowed;
  final NetworkInspector? networkInspector;
  final Function(
      int requestHashCode,
      String title,
      String message,
      )? onHttpFinish;

  DioInterceptor({
    this.logIsAllowed = true,
    this.isConsoleLogAllowed = true,
    this.networkInspector,
    this.onHttpFinish,
  });

  final _jsonUtil = JsonUtil();
  final _byteUtil = ByteUtil();

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    if (logIsAllowed) {
      await saveRequest(options);
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    if (!NetworkInspector.isEnabled) return;
    if (logIsAllowed) {
      await saveResponse(response);
      await finishActivity(
        response,
        response.requestOptions.uri.toString(),
        response.data.toString(),
      );
    }
    handler.next(response);
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (!NetworkInspector.isEnabled) return;
    var logError = '\n[Error Message]: ${err.message}';
    if (logIsAllowed) {
      if (isConsoleLogAllowed) {
        developer.log(logError);
      }
// Handling errors with response (HTTP errors: 4xx, 5xx)
      if (err.response != null) {
        await saveResponse(err.response!);
        await finishActivity(
          err.response!,
          err.response!.requestOptions.uri.toString(),
          err.response!.data?.toString() ?? 'No response data',
        );
      }
// Handling errors without a response (timeouts, network errors)
      else {
        await _saveErrorResponse(err);
        await _finishErrorActivity(err);
      }
    }

    var errorResponse = '\n[Error Response]'
        '\nError Type: ${err.type}'
        '\nRequest URL: ${err.requestOptions.uri}'
        '\nRequest Method: ${err.requestOptions.method}'
        '\nHeaders: ${err.response?.headers.toString() ?? err.requestOptions.headers.toString()}'
        '\nParams: ${err.response?.requestOptions.queryParameters.toString() ?? err.requestOptions.queryParameters.toString()}'
        '\nData: ${_jsonUtil.encodeRawJson(err.response?.data ?? err.requestOptions.data)}'
        '\nStacktrace: ${err.stackTrace.toString()}';

    if (logIsAllowed && isConsoleLogAllowed) {
      developer.log(errorResponse);
    }
    handler.next(err);
  }

  /// Saves error information (for cases without response)
  Future<void> _saveErrorResponse(DioException err) async {
    var request = err.requestOptions;
    var payload = HttpResponse(
      createdAt: DateTime.now().millisecondsSinceEpoch,
      responseHeader: _jsonUtil.encodeRawJson(request.headers),
      responseBody: _jsonUtil.encodeRawJson({
        'error_type': err.type.name,
        'error_message': err.message,
        'error_stacktrace': err.stackTrace?.toString() ?? '',
      }),
      responseStatusCode: _getStatusCodeFromError(err),
      responseStatusMessage: err.message ?? 'Unknown error',
      responseSize: 0,
      requestHashCode: request.hashCode,
      cUrl: request.toCurlCmd(),
    );
    await networkInspector!.writeHttpResponseLog(payload);
  }

  /// Terminates activity for errors
  Future<void> _finishErrorActivity(DioException err) async {
    var request = err.requestOptions;
    var title = request.uri.toString();
    var message = 'Error: ${err.type.name} - ${err.message}';

    if (onHttpFinish != null) {
      await onHttpFinish!(request.hashCode, title, message);
    }

    if (isConsoleLogAllowed) {
      await _logErrorRequest(request, err);
    }
  }

  Future<void> _logErrorRequest(RequestOptions request, DioException err) async {
    var logTemplate = '\n[Request url] ${request.uri.toString()}'
        '\n[Request header] ${request.headers.toString()}'
        '\n[Request param] ${request.queryParameters}'
        '\n[Request body] ${_jsonUtil.encodeRawJson(request.data)}'
        '\n[Request method] ${request.method}'
        '\n[Error type] ${err.type.name}'
        '\n[Error message] ${err.message}'
        '\n[cUrl] ${request.toCurlCmd()}';
    developer.log(logTemplate);
  }

  /// Determines the status code based on the error type
  int _getStatusCodeFromError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 408; // Request Timeout
      case DioExceptionType.badCertificate:
        return 495; // SSL Certificate Error
      case DioExceptionType.badResponse:
        return err.response?.statusCode ?? 400;
      case DioExceptionType.cancel:
        return 499; // Client Closed Request
      case DioExceptionType.connectionError:
        return 503; // Service Unavailable
      case DioExceptionType.unknown:
        return 500; // Internal Server Error
    }
  }

  Future<void> logRequest(RequestOptions request) async {
    var logTemplate = '\n[Request url] ${request.uri.toString()}'
        '\n[Request header] ${request.headers.toString()}'
        '\n[Request param] ${request.queryParameters}'
        '\n[Request body] ${_jsonUtil.encodeRawJson(request.data)}'
        '\n[Request method] ${request.method}'
        '\n[Request content-type] ${request.contentType}'
        '\n[cUrl] ${request.toCurlCmd()}';
    developer.log(logTemplate);
  }

  Future<void> logResponse(Response response) async {
    var logTemplate = '\n[Response header] ${response.headers.toString()}'
        '\n[Response body] ${_jsonUtil.encodeRawJson(response.data)}'
        '\n[Response code] ${response.statusCode}'
        '\n[Response message] ${response.statusMessage}'
        '\n[Response extra] ${response.extra}';
    developer.log(logTemplate);
  }

  Future<void> saveRequest(RequestOptions options) async {
    var payload = HttpRequest(
        baseUrl: options.baseUrl,
        path: options.uri.path,
        params: _jsonUtil.encodeRawJson(options.queryParameters),
        method: options.method,
        requestHeader: _jsonUtil.encodeRawJson(options.headers),
        requestBody: _jsonUtil.encodeRawJson(options.data),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        requestSize: _byteUtil.stringToBytes(options.data.toString()),
        requestHashCode: options.hashCode,
        cUrl: options.toCurlCmd());
    await networkInspector!.writeHttpRequestLog(payload);
  }

  Future<void> saveResponse(Response response) async {
    var request = response.requestOptions;
    var payload = HttpResponse(
        createdAt: DateTime.now().millisecondsSinceEpoch,
        responseHeader: _jsonUtil.encodeRawJson(response.headers.map),
        responseBody: _jsonUtil.encodeRawJson(response.data),
        responseStatusCode: response.statusCode,
        responseStatusMessage: response.statusMessage,
        responseSize: _byteUtil.stringToBytes(response.data.toString()),
        requestHashCode: request.hashCode,
        cUrl: request.toCurlCmd());
    await networkInspector!.writeHttpResponseLog(payload);
  }

  Future<void> finishActivity(
      Response response,
      String title,
      String message,
      ) async {
    var request = response.requestOptions;
    if (onHttpFinish != null) {
      await onHttpFinish!(response.requestOptions.hashCode, title, message);
    }
    if (isConsoleLogAllowed) {
      await logRequest(request);
      await logResponse(response);
    }
  }
}