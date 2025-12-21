library;

/// Import section
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'common/utils/database_helper.dart';
import 'domain/entities/http_request.dart';
import 'domain/entities/http_response.dart';
import 'domain/repositories/log_repository.dart';
import 'domain/usecases/log_http_request.dart';
import 'domain/usecases/log_http_response.dart';
import 'infrastructure/datasources/log_datasource.dart';
import 'infrastructure/datasources/log_datasource_impl.dart';
import 'infrastructure/repositories/log_repository_impl.dart';
import 'presentation/pages/activity_page.dart';
import 'presentation/widgets/floating_circle.dart';

/// Export
export 'presentation/pages/activity_page.dart';

/// NetworkInspector is a singleton class that provides HTTP request/response logging
/// functionality with an optional floating UI indicator.
///
/// ## Initialization
/// Call during app startup to initialize the local SQLite database:
/// ```dart
/// await NetworkInspector.initialize();
/// ```
///
/// ## Usage with Network Interceptors
/// Pass the singleton instance to your Dio or Http interceptors:
///
/// **Dio Example:**
/// ```dart
/// Dio(
///   BaseOptions(
///     baseUrl: 'http://192.168.1.6:8000/',
///     connectTimeout: 10 * 1000, // 10 second
///     headers: {
///       'Content-type': 'application/json',
///       'Accept': 'application/json',
///       'Authorization': 'Bearer i109gh23j9u1h3811io2n391'
///     },
///   ),
/// )..interceptors.add(
///   DioInterceptor(
///     logIsAllowed: true,
///     networkInspector: NetworkInspector.instance,
///     onHttpFinish: (hashCode, title, message) {
///       NetworkInspector.notifyActivity(title: title, message: message);
///     },
///   ),
/// );
/// ```
///
/// **Http Example:**
/// ```dart
/// HttpInterceptor(
///   logIsAllowed: true,
///   client: client,
///   baseUrl: Uri.parse('http://192.168.1.3:8000/'),
///   networkInspector: NetworkInspector.instance,
///   onHttpFinish: (hashCode, title, message) {
///     NetworkInspector.notifyActivity(title: title, message: message);
///   },
///   headers: {
///     'Content-type': 'application/json',
///     'Accept': 'application/json',
///     'Authorization': 'Bearer WEKLSSS'
///   },
/// );
/// ```
///
/// ## Key Features
/// - **Singleton pattern** with private constructor and factory
/// - **Enable/Disable logging** globally with `enable()` / `disable()`
/// - **Floating draggable circle** shows active requests and navigates to ActivityPage
/// - **Conditional logging** - logs only when `isEnabled == true`
/// - **Database initialization** and dependency injection handled automatically
///
/// ## Integration Steps
/// 1. Call `NetworkInspector.initialize()` in your app's main() or initState()
/// 2. Use `NetworkInspector.instance` in your network interceptors
/// 3. Call `NetworkInspector.enable()` to activate logging + floating UI
/// 4. Tap floating circle to view logged HTTP activities
/// 5. Call `NetworkInspector.disable()` or `hideFloatingCircle()` when done
class NetworkInspector {
  /// Singleton instance
  static final NetworkInspector _instance = NetworkInspector._internal();
  factory NetworkInspector() => _instance;
  NetworkInspector._internal();

  /// Public static access for interceptors
  static NetworkInspector get instance => _instance;

  /// Global logging state
  static bool _isEnabled = false;

  /// Overlay entry for floating circle
  static OverlayEntry? _circleOverlayEntry;

  /// Existing dependencies (private)
  Database? _database;
  LogDatasource? _logDatasource;
  LogRepository? _logRepository;
  LogHttpRequest? _logHttpRequest;
  LogHttpResponse? _logHttpResponse;

  /// Enable logging and floating UI
  static void enable() {
    _isEnabled = true;
    print('✅ NetworkInspector enabled');
  }

  /// Disable logging and hide floating UI
  static void disable() {
    _isEnabled = false;
    hideFloatingCircle();
    print('❌ NetworkInspector disabled');
  }

  /// Check if logging is enabled
  static bool get isEnabled => _isEnabled;

  /// Initialize database and dependencies
  static Future<void> initialize() async {
    await DatabaseHelper.initialize();
    await _instance._injectDependencies();
  }

  /// Inject all dependencies (called automatically during initialize)
  Future<void> _injectDependencies() async {
    _database = await DatabaseHelper.connect();
    _logDatasource = LogDatasourceImpl(database: _database!);
    _logRepository = LogRepositoryImpl(logDatasource: _logDatasource!);
    _logHttpRequest = LogHttpRequest(logRepository: _logRepository!);
    _logHttpResponse = LogHttpResponse(logRepository: _logRepository!);
  }

  /// Log HTTP request (only if enabled)
  Future<bool?> writeHttpRequestLog(HttpRequest param) async {
    if (!_isEnabled) return null;
    return await _logHttpRequest?.execute(param);
  }

  /// Log HTTP response (only if enabled)
  Future<bool?> writeHttpResponseLog(HttpResponse param) async {
    if (!_isEnabled) return null;
    return await _logHttpResponse?.execute(param);
  }

  /// Hide floating activity indicator
  static void hideFloatingCircle() {
    _circleOverlayEntry?.remove();
    _circleOverlayEntry = null;
  }

  /// Show draggable floating circle (call from interceptor on activity)
  static void showFloatingCircle(BuildContext context) {
    if (!_isEnabled) {
      print('⚠️ Logger disabled, circle not shown');
      return;
    }
    if (_circleOverlayEntry != null) return;

    _circleOverlayEntry = OverlayEntry(
      builder: (overlayContext) => FloatingCircleWidget(
        onActivityTap: () {
          hideFloatingCircle();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ActivityPage()),
          );
        },
      ),
    );

    Overlay.of(context, rootOverlay: true)?.insert(_circleOverlayEntry!);
  }

  /// Notify new network activity (call from interceptors)
  static void notifyActivity({
    required String title,
    required String message,
  }) {
    // Implementation depends on your interceptor setup
    // Typically shows floating circle when new activity detected
    print('📱 New activity: $title - $message');
  }
}
