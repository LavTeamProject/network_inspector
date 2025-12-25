library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import 'presentation/widgets/touch_indicator.dart';

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
/// Environment configuration model
class EnvironmentConfig {
  final String name;
  final String baseUrl;
  final Color color;
  final Map<String, String>? headers;

  const EnvironmentConfig({
    required this.name,
    required this.baseUrl,
    this.color = const Color(0xFF2196F3),
    this.headers,
  });
}

/// Callback when environment is selected
typedef EnvironmentSelectedCallback = void Function(EnvironmentConfig config);

/// NetworkInspector singleton with HTTP logging and environment switching
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
  static final List<EnvironmentConfig> _environments = [];
  static EnvironmentConfig? selectedEnvironment;
  static EnvironmentSelectedCallback? onEnvironmentSelected;

  static Database? _database;
  static LogDatasource? _logDatasource;
  static LogRepository? _logRepository;
  static LogHttpRequest? _logHttpRequest;
  static LogHttpResponse? _logHttpResponse;
  /// Check if logging is enabled
  static bool get isEnabled => _isEnabled;

  /// State for touch indicators
  static bool _showTouchIndicators = false;
  static ValueChanged<bool>? _onTouchIndicatorsChanged;

  /// Getter for touch indicators state
  static bool get showTouchIndicators => _showTouchIndicators;

  /// Set touch indicators state
  static void setTouchIndicators(bool show) {
    _showTouchIndicators = show;
    _onTouchIndicatorsChanged?.call(show);
  }

  /// Subscribe to touch indicators changes
  static void onTouchIndicatorsChanged(ValueChanged<bool> callback) {
    _onTouchIndicatorsChanged = callback;
  }

  /// Toggle touch indicators
  static void toggleTouchIndicators() {
    setTouchIndicators(!_showTouchIndicators);
  }


  /// Enable logging and floating UI
  static void enable() {
    _isEnabled = true;
  }

  /// Disable logging and hide floating UI
  static void disable() {
    _isEnabled = false;
    hideFloatingCircle();
  }

  static List<EnvironmentConfig> get availableEnvironments =>
      List.unmodifiable(_environments);

  static Future<void> initializeWithEnvironments({
    required List<EnvironmentConfig> environments,
  }) async {
    _environments.clear();
    _environments.addAll(environments);
    if (_environments.isNotEmpty) {
      selectedEnvironment = _environments.first;
    }
    await DatabaseHelper.initialize();
    await _instance._injectDependencies();
    print('🌐 Initialized with ${_environments.length} environments');
  }

  static EnvironmentConfig? selectEnvironment(int index) {
    if (index >= 0 && index < _environments.length) {
      selectedEnvironment = _environments[index];
      print('🔄 Selected: ${selectedEnvironment!.name}');
      onEnvironmentSelected?.call(selectedEnvironment!);
      return selectedEnvironment;
    }
    return null;
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
        onRequestsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ActivityPage()),
          );
        },
        onEnvironmentTap: () => _showEnvironmentPicker(context),
      ),
    );

    Overlay.of(context, rootOverlay: true)?.insert(_circleOverlayEntry!);
  }

  static void _showEnvironmentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: const Row(
                children: [
                  Icon(Icons.settings_ethernet, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Select Environment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedEnvironment != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      selectedEnvironment!.color.withOpacity(0.3),
                      selectedEnvironment!.color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: selectedEnvironment!.color,
                      radius: 16,
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedEnvironment!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          selectedEnvironment!.baseUrl,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _environments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final env = _environments[index];
                  final isSelected = env == selectedEnvironment;
                  return Material(
                    color: env.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        selectEnvironment(index);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: env.color,
                              radius: 16,
                              child: Text(
                                env.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    env.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    env.baseUrl,
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void notifyActivity({
    required String title,
    required String message,
  }) {
    print('📱 New activity: $title - $message');
  }
}