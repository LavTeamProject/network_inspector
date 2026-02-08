import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_inspector/domain/entities/http_request.dart';
import 'package:network_inspector/domain/entities/http_response.dart';
import 'package:network_inspector/network_inspector.dart';

/// Logging level for PrettyChopperLogger
///
/// Defines the verbosity of logging output for Chopper HTTP requests.
///
/// **Levels:**
/// - `none`: No logging output
/// - `basic`: Logs only request/response lines (method, URL, status code)
/// - `headers`: Includes headers in addition to basic information
/// - `body`: Full logging including request/response bodies (default)
///
/// Example:
/// ```dart
/// PrettyChopperLogger(level: Level.headers) // Logs headers but not bodies
/// ```
enum Level {
  none,
  basic,
  headers,
  body,
}

/// A comprehensive Chopper interceptor for HTTP request/response logging
/// with NetworkInspector integration and enhanced console output.
///
/// This interceptor provides:
/// - **Pretty console logging** with formatted JSON and borders
/// - **NetworkInspector integration** for saving logs to database
/// - **Request/Response tracking** with unique IDs for correlation
/// - **Error handling** with detailed error information
/// - **Configurable logging levels** from none to full body logging
///
/// ## Basic Usage
///
/// ```dart
/// final chopper = ChopperClient(
///   baseUrl: 'https://api.example.com',
///   interceptors: [
///     PrettyChopperLogger(
///       level: Level.body,
///       networkInspector: NetworkInspector.instance,
///       onHttpFinish: (hashCode, title, message) {
///         print('Request completed: $title');
///       },
///     ),
///   ],
///   services: [
///     MyApiService.create(),
///   ],
/// );
/// ```
///
/// ## Features
///
/// ### Console Logging
/// Produces beautifully formatted console output with:
/// - Clear visual separation using border lines
/// - Proper JSON indentation and formatting
/// - Color-coded output (when supported by IDE)
/// - Truncated body previews for large responses
///
/// ### NetworkInspector Integration
/// Automatically saves all HTTP traffic to NetworkInspector when enabled:
/// - Requests are saved immediately when sent
/// - Responses are saved when received
/// - Errors are properly captured and logged
/// - Request/response pairs are correlated using unique IDs
///
/// ### Request Tracking
/// Each request gets a unique ID that's used to:
/// - Correlate requests with their responses
/// - Track request lifecycle from start to finish
/// - Clean up tracking information after completion
/// - Provide debugging information about pending requests
///
/// ## Configuration Options
///
/// | Option | Default | Description |
/// |--------|---------|-------------|
/// | `level` | `Level.body` | Verbosity of logging output |
/// | `maxWidth` | 120 | Maximum width for border lines |
/// | `indentSize` | 2 | Indentation for JSON formatting |
/// | `logIsAllowed` | true | Enable/disable NetworkInspector logging |
/// | `isConsoleLogAllowed` | true | Enable/disable console output |
/// | `networkInspector` | null | NetworkInspector instance for saving logs |
/// | `onHttpFinish` | null | Callback when HTTP request completes |
///
/// ## Example Output
///
/// ```
/// ╔╣ Request ║ GET
/// ║  https://api.example.com/users/123
/// ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
/// ╔╣ Headers
/// ║   {
/// ║     "content-type": "application/json",
/// ║     "authorization": "Bearer abc123"
/// ║   }
/// ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
/// ```
///
/// ## Integration with NetworkInspector
///
/// When used with NetworkInspector, this interceptor:
///
/// 1. **Saves requests** immediately when `onRequest` is called
/// 2. **Saves responses** when they arrive (successful or error)
/// 3. **Triggers callbacks** via `onHttpFinish` for UI updates
/// 4. **Cleans up tracking** information after completion
///
/// ## Error Handling
///
/// The interceptor properly handles:
/// - HTTP errors (4xx, 5xx status codes)
/// - Network timeouts and connection errors
/// - JSON parsing errors
/// - Malformed responses
///
/// All errors are logged to both console and NetworkInspector (if configured).
///
/// ## Performance Considerations
///
/// - JSON formatting is only done when `Level.body` is enabled
/// - Large response bodies are handled efficiently
/// - Tracking overhead is minimal (uses simple map for correlation)
/// - NetworkInspector operations are async and non-blocking
///
/// @see [NetworkInspector]
/// @see [ChopperClient]
/// @see [Interceptor]
/// @since 1.0.0
class PrettyChopperLogger implements Interceptor {
  /// Creates a PrettyChopperLogger with the specified configuration.
  ///
  /// @param level Controls the amount of detail logged (defaults to [Level.body])
  /// @param maxWidth Sets the maximum width for border lines (defaults to 120)
  /// @param indentSize Sets the indentation size for JSON formatting (defaults to 2)
  /// @param logIsAllowed Enables/disables logging to NetworkInspector
  /// @param isConsoleLogAllowed Enables/disables console logging
  /// @param networkInspector Instance of NetworkInspector for saving logs
  /// @param onHttpFinish Callback when HTTP request finishes
  ///
  /// @throws AssertionError if maxWidth <= 0 or indentSize < 0
  ///
  /// Example:
  /// ```dart
  /// PrettyChopperLogger(
  ///   level: Level.headers,
  ///   maxWidth: 100,
  ///   networkInspector: NetworkInspector.instance,
  ///   onHttpFinish: (id, title, message) {
  ///     print('Request $id finished: $title');
  ///   },
  /// )
  /// ```
  PrettyChopperLogger({
    this.level = Level.body,
    this.maxWidth = 120,
    this.indentSize = 2,
    this.logIsAllowed = true,
    this.isConsoleLogAllowed = true,
    this.networkInspector,
    this.onHttpFinish,
  })  : assert(maxWidth > 0, 'maxWidth must be positive'),
        assert(indentSize >= 0, 'indentSize must be non-negative'),
        _logBody = level == Level.body,
        _logHeaders = level == Level.body || level == Level.headers,
        _logBasic = level != Level.none,
        _borderLine = '═' * maxWidth,
        _encoder = JsonEncoder.withIndent(' ' * indentSize);

  /// [Level.none]
  /// No logs
  /// [Level.basic]
  /// Logs request and response lines.
  /// [Level.headers]
  /// Logs request and response lines and their respective headers.
  /// [Level.body]
  /// Logs request and response lines and their respective headers and bodies (if present).
  final Level level;

  /// Maximum width for the border line in console output
  ///
  /// The border line helps visually separate different log sections.
  /// Defaults to 120 characters.
  final int maxWidth;

  /// Indent size for JSON formatting in console output
  ///
  /// Controls how many spaces are used for indentation when pretty-printing
  /// JSON in console logs. Defaults to 2 spaces.
  final int indentSize;

  /// Enable/Disable overall logging to NetworkInspector
  ///
  /// When `true`, requests and responses are saved to NetworkInspector's database.
  /// When `false`, no data is persisted (console logging may still occur).
  final bool logIsAllowed;

  /// Enable/Disable only console logging
  ///
  /// When `true`, formatted logs are printed to the console.
  /// When `false`, console output is suppressed (NetworkInspector logging may still occur).
  final bool isConsoleLogAllowed;

  /// NetworkInspector instance for saving logs
  ///
  /// Required if you want to save logs to NetworkInspector's database.
  /// If `null`, only console logging will occur (if enabled).
  final NetworkInspector? networkInspector;

  /// Callback when HTTP request finishes
  ///
  /// Called when a request completes (successfully or with error).
  /// Useful for triggering UI updates or other side effects.
  ///
  /// @param requestHashCode Unique identifier for the request
  /// @param title Request URL or descriptive title
  /// @param message Response summary or error message
  ///
  /// Example:
  /// ```dart
  /// onHttpFinish: (id, title, message) {
  ///   debugPrint('Request $id completed: $title - $message');
  ///   NetworkInspector.showFloatingCircle(context);
  /// }
  /// ```
  final Function(
      int requestHashCode,
      String title,
      String message,
      )? onHttpFinish;

  // Internal computed properties based on logging level
  final bool _logBody;
  final bool _logHeaders;
  final bool _logBasic;
  final String _borderLine;
  final JsonEncoder _encoder;
  static const JsonDecoder _decoder = JsonDecoder();

  // Helper utilities for JSON and byte operations
  final _jsonUtil = _JsonUtil();
  final _byteUtil = _ByteUtil();

  // For tracking correlation between request and response
  final Map<int, _RequestInfo> _requestIdToInfo = {};
  int _nextRequestId = 1;

  /// Interceptors are used for intercepting requests, responses and performing operations on them.
  ///
  /// This method is the main entry point for the interceptor chain. It:
  /// 1. Generates a unique ID for the request
  /// 2. Processes and logs the request
  /// 3. Executes the request through the chain
  /// 4. Processes and logs the response
  /// 5. Returns the response
  ///
  /// @param chain The interceptor chain containing the request
  /// @param BodyType The expected response body type
  /// @returns FutureOr<Response<BodyType>> The processed response
  ///
  /// @throws DioException if the request fails
  /// @throws FormatException if response parsing fails
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
      Chain<BodyType> chain,
      ) async {
    final request = chain.request;

    // Generate unique ID for this request
    final requestId = _generateRequestId(request);

    // Save request information for correlation
    _requestIdToInfo[requestId] = _RequestInfo(
      id: requestId,
      url: request.url.toString(),
      method: request.method,
      timestamp: DateTime.now(),
    );

    print('🔗 Request generated ID: $requestId for ${request.method} ${request.url}');

    // Process request (logging, saving to NetworkInspector)
    await _processRequest(request, requestId);

    // Execute request through the interceptor chain
    final response = await chain.proceed(request);

    // Process response (logging, saving to NetworkInspector)
    await _processResponse(response, requestId);

    return response;
  }

  /// Processes and logs a request before it's sent
  ///
  /// @param request The Chopper request to process
  /// @param requestId Unique identifier for this request
  /// @returns Future<void> completes when request processing is done
  Future<void> _processRequest(Request request, int requestId) async {
    final base = await request.toBaseRequest();

    // Log to console if enabled
    if (isConsoleLogAllowed) {
      _logRequest(base);
    }

    print('📤 Processing request ID: $requestId');

    // Save to NetworkInspector if enabled
    if (logIsAllowed && networkInspector != null) {
      await _saveRequest(request, requestId);
    }
  }

  /// Processes and logs a response after it's received
  ///
  /// @param response The Chopper response to process
  /// @param requestId Unique identifier for the corresponding request
  /// @returns Future<void> completes when response processing is done
  Future<void> _processResponse(Response<dynamic> response, int requestId) async {
    // Check if NetworkInspector is enabled
    if (!NetworkInspector.isEnabled) return;

    print('📥 Processing response for request ID: $requestId');

    // Log to console if enabled
    if (isConsoleLogAllowed) {
      _logResponse(response);
    }

    // Handle errors for unsuccessful responses
    if (!response.isSuccessful) {
      await _handleError(response, requestId);
      return;
    }

    // Save successful response to NetworkInspector
    if (logIsAllowed) {
      await _saveResponse(response, requestId);
      await _finishActivity(
        requestId,
        response.base.request?.url.toString() ?? '',
        response.bodyString,
      );
    }
  }

  /// Logs a request to the console with formatted output
  ///
  /// @param base The HTTP base request to log
  void _logRequest(http.BaseRequest base) {
    final isRequest = base is http.Request;
    final hasBody = isRequest && base.body.isNotEmpty;
    final buffer = StringBuffer(base.url.toString());

    if (isRequest && hasBody && !_logHeaders) {
      buffer.write(' (${base.bodyBytes.length}-byte body)');
    }

    _printRequestOrResponse(
      title: 'Request ║ ${base.method}',
      text: buffer.toString(),
    );

    if (_logHeaders) {
      final headers = _jsonFormat(base.headers);
      _printHeaderOrBody(title: 'Headers', prettyJson: headers);
    }

    if (_logBody && isRequest) {
      final body = _jsonFormat(base.body);
      _printHeaderOrBody(title: 'Body', prettyJson: body);
    }
  }

  /// Logs a response to the console with formatted output
  ///
  /// @param response The Chopper response to log
  void _logResponse(Response<dynamic> response) {
    final baseResponse = response.base;
    final buffer = StringBuffer(response.statusCode.toString());

    // Build reason phrase
    if (baseResponse.reasonPhrase != null &&
        baseResponse.reasonPhrase != response.statusCode.toString()) {
      buffer.write(' ${baseResponse.reasonPhrase}');
    }
    final reasonPhrase = buffer.toString();

    // Build URL with optional bytes info
    buffer
      ..clear()
      ..write(baseResponse.request?.url.toString());
    if (!_logBody && !_logHeaders && response.bodyBytes.isNotEmpty) {
      buffer.write(' (${response.bodyBytes.length}-byte body)');
    }
    final urlText = buffer.toString();

    _printRequestOrResponse(
      title: 'Response ║ ${baseResponse.request?.method} ║ Status: $reasonPhrase',
      text: urlText,
    );

    if (_logHeaders) {
      final responseHeaders = _jsonFormat(baseResponse.headers);
      _printHeaderOrBody(
        title: 'Response Headers',
        prettyJson: responseHeaders,
      );
    }

    if (_logBody) {
      final responseBody = _jsonFormat(response.bodyString);
      _printHeaderOrBody(title: 'Response Body', prettyJson: responseBody);
    }
  }

  /// Saves a request to NetworkInspector
  ///
  /// @param request The Chopper request to save
  /// @param requestId Unique identifier for this request
  /// @returns Future<void> completes when request is saved
  Future<void> _saveRequest(Request request, int requestId) async {
    print('💾 Saving request ID: $requestId');
    print('🔑 Request hashCode: ${request.hashCode}');
    print('📝 URL: ${request.url}');
    print('📝 Method: ${request.method}');
    print('📝 Headers: ${request.headers}');

    final payload = HttpRequest(
      baseUrl: request.url.origin,
      path: request.url.path,
      params: _jsonUtil.encodeRawJson(request.parameters),
      method: request.method,
      requestHeader: _jsonUtil.encodeRawJson(request.headers),
      requestBody: _jsonUtil.encodeRawJson(request.body),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      requestSize: _byteUtil.stringToBytes(request.body?.toString() ?? ''),
      requestHashCode: requestId,
      cUrl: _toCurlCmd(request),
    );

    print('📦 Payload created with hashCode: $requestId');

    try {
      final result = await networkInspector?.writeHttpRequestLog(payload);
      print('✅ writeHttpRequestLog result: $result');
    } catch (e) {
      print('🔴 Error in writeHttpRequestLog: $e');
    }
  }

  /// Saves a response to NetworkInspector
  ///
  /// @param response The Chopper response to save
  /// @param requestId Unique identifier for the corresponding request
  /// @returns Future<void> completes when response is saved
  Future<void> _saveResponse(Response<dynamic> response, int requestId) async {
    print('💾 Saving response for request ID: $requestId');
    print('📊 Response status: ${response.statusCode}');
    print('📊 Response body length: ${response.bodyString.length} chars');

    final payload = HttpResponse(
      createdAt: DateTime.now().millisecondsSinceEpoch,
      responseHeader: _jsonUtil.encodeRawJson(response.headers),
      responseBody: _jsonUtil.encodeRawJson(response.body),
      responseStatusCode: response.statusCode,
      responseStatusMessage:
      response.base.reasonPhrase ?? response.error?.toString() ?? '',
      responseSize: _byteUtil.stringToBytes(response.bodyString),
      requestHashCode: requestId,
      cUrl: null,
    );

    print('📦 Response payload created for hashCode: $requestId');

    try {
      final result = await networkInspector?.writeHttpResponseLog(payload);
      print('✅ writeHttpResponseLog result: $result');
    } catch (e) {
      print('🔴 Error in writeHttpResponseLog: $e');
    }
  }

  /// Handles error responses (non-2xx status codes)
  ///
  /// @param response The error response
  /// @param requestId Unique identifier for the corresponding request
  /// @returns Future<void> completes when error is processed
  Future<void> _handleError(Response<dynamic> response, int requestId) async {
    print('⚠️ Handling error for request ID: $requestId');

    if (!logIsAllowed || networkInspector == null) return;

    // Log error to console
    if (isConsoleLogAllowed) {
      final logError = '\n[Error Message]: ${response.error}';
      developer.log(logError);
    }

    // Save error response to NetworkInspector
    await _saveResponse(response, requestId);

    // Log detailed error to console
    if (isConsoleLogAllowed) {
      final errorResponse = '\n[Error Response]'
          '\nHeaders : ${response.headers.toString()}'
          '\nStatus: ${response.statusCode}'
          '\nData : ${_jsonUtil.encodeRawJson(response.body)}'
          '\nError: ${response.error}';
      developer.log(errorResponse);
    }

    await _finishActivity(
      requestId,
      response.base.request?.url.toString() ?? '',
      response.error?.toString() ?? '',
    );
  }

  /// Finalizes activity for a completed request
  ///
  /// Called when a request finishes (success or error). Triggers the
  /// onHttpFinish callback and cleans up tracking information.
  ///
  /// @param requestId Unique identifier for the completed request
  /// @param title Request URL or descriptive title
  /// @param message Response summary or error message
  /// @returns Future<void> completes when activity is finalized
  Future<void> _finishActivity(
      int requestId,
      String title,
      String message,
      ) async {
    print('🏁 Finishing activity for request ID: $requestId');
    print('📝 Title: $title');
    print('📝 Message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}');
    print('🎯 onHttpFinish callback: ${onHttpFinish != null ? "available" : "null"}');

    if (onHttpFinish != null) {
      onHttpFinish!(requestId, title, message);
    } else {
      print('ℹ️ No onHttpFinish callback provided');
    }

    // Clean up tracking information after completion
    _requestIdToInfo.remove(requestId);
    print('🧹 Cleared request info for ID: $requestId');
  }

  /// Generates a unique identifier for a request
  ///
  /// Creates a stable hash based on request parameters to ensure
  /// the same request gets the same ID across retries.
  ///
  /// @param request The request to generate ID for
  /// @returns int Unique positive integer identifier
  int _generateRequestId(Request request) {
    // Create stable hash based on request parameters
    final hash = Object.hash(
      request.url.toString(),
      request.method,
      jsonEncode(request.headers),
      jsonEncode(request.parameters),
      jsonEncode(request.body),
      DateTime.now().millisecondsSinceEpoch,
      _nextRequestId++,
    );

    // Ensure hash is positive
    return hash.abs();
  }

  /// Generates a cURL command string for a request
  ///
  /// Useful for debugging or manual testing of API endpoints.
  ///
  /// @param request The request to convert to cURL
  /// @returns String cURL command that can be executed in terminal
  String _toCurlCmd(Request request) {
    var curl = 'curl -X ${request.method}';

    // Add headers
    request.headers.forEach((key, value) {
      if (key != 'Content-Length' && key != 'Host') {
        curl += ' -H \'$key: $value\'';
      }
    });

    // Add request body
    if (request.body != null) {
      if (request.body is String && (request.body as String).isNotEmpty) {
        curl += ' -d \'${request.body}\'';
      } else if (request.body is Map) {
        curl += ' -d \'${_jsonUtil.encodeRawJson(request.body)}\'';
      }
    }

    // Add request parameters
    if (request.parameters.isNotEmpty) {
      final params = request.parameters.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      curl += ' \'${request.url.origin}${request.url.path}?$params\'';
    } else {
      curl += ' \'${request.url.toString()}\'';
    }

    return curl;
  }

  /// Prints request or response header with border formatting
  ///
  /// @param title The title to display
  /// @param text The main content text
  void _printRequestOrResponse({required String title, required String text}) {
    debugPrint('╔╣ $title');
    debugPrint('║  $text');
    debugPrint('╚═$_borderLine');
  }

  /// Prints headers or body content with border formatting
  ///
  /// @param title The section title (e.g., "Headers", "Body")
  /// @param prettyJson Formatted JSON string to display
  void _printHeaderOrBody({required String title, required String prettyJson}) {
    if (prettyJson.trim().isEmpty || prettyJson == '{}') return;

    final buffer = StringBuffer()..writeln('╔╣ $title');

    final lines = prettyJson.split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;

      if (line.length == 1 && (line == '{' || line == '}')) {
        buffer.writeln('║  $line');
      } else {
        buffer.writeln('║   ${line.substring(1)}');
      }
    }

    buffer.write('╚═$_borderLine');
    debugPrint(buffer.toString());
  }

  /// Formats input data as pretty JSON string
  ///
  /// Handles various input types (Map, String, List, etc.) and attempts
  /// to format them as readable JSON. Falls back to string representation
  /// if JSON formatting fails.
  ///
  /// @param source The data to format
  /// @returns String Formatted JSON or original string
  String _jsonFormat(dynamic source) {
    if (source == null || source == '') return '';

    if (source is Map) {
      return _encoder.convert(source);
    }

    if (source is String) {
      if (source.isEmpty) return '';

      // Quick check for JSON-like content before attempting parse
      final trimmed = source.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          return _encoder.convert(_decoder.convert(source));
        } catch (_) {
          // Fallback to plain string if JSON parsing fails
          return source;
        }
      }
      // Not JSON-like, return as-is
      return source;
    }

    // Handle other types (List, numbers, etc.)
    try {
      return _encoder.convert(source);
    } catch (_) {
      return source.toString();
    }
  }

  /// Debug method to print all currently tracked requests
  ///
  /// Useful for debugging request/response correlation issues.
  /// Shows all requests that have been sent but not yet completed.
  void printTrackedRequests() {
    print('\n📋 CURRENTLY TRACKED REQUESTS:');
    print('══════════════════════════════');

    if (_requestIdToInfo.isEmpty) {
      print('No requests currently tracked');
      return;
    }

    _requestIdToInfo.forEach((id, info) {
      print('ID: $id');
      print('  URL: ${info.url}');
      print('  Method: ${info.method}');
      print('  Timestamp: ${info.timestamp}');
      print('  Age: ${DateTime.now().difference(info.timestamp)}');
      print('');
    });
  }
}

/// Internal class to store request information for tracking
///
/// Used to correlate requests with their responses and clean up
/// tracking information after completion.
class _RequestInfo {
  final int id;
  final String url;
  final String method;
  final DateTime timestamp;

  _RequestInfo({
    required this.id,
    required this.url,
    required this.method,
    required this.timestamp,
  });
}

/// Internal utility for JSON encoding operations
///
/// Provides safe JSON encoding with fallback to string representation.
class _JsonUtil {
  /// Encodes raw JSON data to string
  ///
  /// @param rawJson The data to encode (Map, List, String, etc.)
  /// @returns String JSON string or fallback representation
  String encodeRawJson(dynamic rawJson) {
    if (rawJson == null) {
      return '';
    }

    if (rawJson is String) {
      return rawJson;
    }

    try {
      return jsonEncode(rawJson);
    } catch (e) {
      return rawJson.toString();
    }
  }
}

/// Internal utility for byte operations
///
/// Provides byte-related calculations for logging purposes.
class _ByteUtil {
  /// Converts a string to its byte length
  ///
  /// @param text The string to measure
  /// @returns int Number of bytes in UTF-8 encoding
  int stringToBytes(String text) {
    if (text.isEmpty) return 0;
    return utf8.encode(text).length;
  }
}