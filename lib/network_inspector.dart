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
export 'network_inspector_config.dart';
export 'presentation/widgets/floating_test_button.dart';
export 'common/navigation_service.dart';

/// NetworkInspector is a comprehensive HTTP monitoring and debugging tool
/// that provides real-time request/response logging, environment switching,
/// and visual debugging capabilities for Flutter applications.
///
/// ## Features
/// - **Real-time HTTP logging**: Capture all network requests and responses
/// - **Multiple client support**: Works with Dio, Chopper, and standard HTTP client
/// - **Environment management**: Switch between different API environments
/// - **Visual debugging**: Floating draggable indicator with touch visualization
/// - **SQLite storage**: Persistent storage of network logs for later inspection
/// - **Clean architecture**: Built with domain-driven design principles
///
/// ## Initialization
/// Call during app startup to initialize the local SQLite database:
/// ```dart
/// await NetworkInspector.initialize();
///
/// // Or with environment configurations
/// await NetworkInspector.initializeWithEnvironments(
///   environments: [
///     EnvironmentConfig(
///       name: 'Development',
///       baseUrl: 'https://dev-api.example.com',
///       color: Colors.blue,
///       headers: {'X-API-Key': 'dev-key'},
///     ),
///     EnvironmentConfig(
///       name: 'Production',
///       baseUrl: 'https://api.example.com',
///       color: Colors.green,
///       headers: {'X-API-Key': 'prod-key'},
///     ),
///   ],
/// );
/// ```
///
/// ## Usage with Network Interceptors
/// Pass the singleton instance to your HTTP client interceptors:
///
/// ### **Dio Interceptor Example:**
/// ```dart
/// final dio = Dio(
///   BaseOptions(
///     baseUrl: 'https://api.example.com',
///     connectTimeout: const Duration(seconds: 10),
///     headers: {
///       'Content-type': 'application/json',
///       'Accept': 'application/json',
///       'Authorization': 'Bearer your-token-here'
///     },
///   ),
/// )..interceptors.add(
///   DioInterceptor(
///     logIsAllowed: true,
///     networkInspector: NetworkInspector.instance,
///     onHttpFinish: (hashCode, title, message) {
///       // Optional callback when request completes
///       NetworkInspector.notifyActivity(title: title, message: message);
///     },
///   ),
/// );
/// ```
///
/// ### **Chopper Interceptor Example:**
/// ```dart
/// final chopper = ChopperClient(
///   baseUrl: 'https://api.example.com',
///   interceptors: [
///     ChopperInterceptor(
///       logIsAllowed: true,
///       networkInspector: NetworkInspector.instance,
///       onHttpFinish: (hashCode, title, message) {
///         NetworkInspector.notifyActivity(title: title, message: message);
///       },
///     ),
///     HttpLoggingInterceptor(),
///   ],
///   converter: const JsonConverter(),
///   services: [
///     // Your generated services here
///     MyApiService.create(),
///   ],
/// );
/// ```
///
/// ### **Standard HTTP Interceptor Example:**
/// ```dart
/// final client = HttpInterceptor(
///   logIsAllowed: true,
///   client: http.Client(),
///   baseUrl: Uri.parse('https://api.example.com'),
///   networkInspector: NetworkInspector.instance,
///   onHttpFinish: (hashCode, title, message) {
///     NetworkInspector.notifyActivity(title: title, message: message);
///   },
///   headers: {
///     'Content-type': 'application/json',
///     'Accept': 'application/json',
///     'Authorization': 'Bearer your-token-here'
///   },
/// );
/// ```
///
/// ## Environment Switching
/// ```dart
/// // Get available environments
/// final environments = NetworkInspector.availableEnvironments;
///
/// // Switch to specific environment
/// NetworkInspector.selectEnvironment(0);
///
/// // Listen for environment changes
/// NetworkInspector.onEnvironmentSelected = (config) {
///   print('Switched to ${config.name} environment');
///   print('Base URL: ${config.baseUrl}');
/// };
/// ```
///
/// ## Touch Indicators (UI Debugging)
/// ```dart
/// // Enable/disable touch visualization
/// NetworkInspector.setTouchIndicators(true);
///
/// // Toggle touch indicators
/// NetworkInspector.toggleTouchIndicators();
///
/// // Check current state
/// final showIndicators = NetworkInspector.showTouchIndicators;
///
/// // Listen for changes
/// NetworkInspector.onTouchIndicatorsChanged = (show) {
///   print('Touch indicators ${show ? 'enabled' : 'disabled'}');
/// };
/// ```
///
/// ## Integration Steps
/// 1. **Initialize** during app startup:
///    ```dart
///    void main() async {
///      WidgetsFlutterBinding.ensureInitialized();
///      await NetworkInspector.initializeWithEnvironments(...);
///      runApp(MyApp());
///    }
///    ```
///
/// 2. **Configure** your HTTP clients with interceptors
///
/// 3. **Enable** monitoring when needed:
///    ```dart
///    NetworkInspector.enable();  // Shows floating circle and starts logging
///    ```
///
/// 4. **Access** logs via the floating circle or programmatically:
///    ```dart
///    // Show floating UI indicator
///    NetworkInspector.showFloatingCircle(context);
///
///    // Navigate to activity page manually
///    Navigator.push(context, MaterialPageRoute(
///      builder: (_) => ActivityPage(),
///    ));
///    ```
///
/// 5. **Disable** when done:
///    ```dart
///    NetworkInspector.disable();  // Hides UI and stops logging
///    ```
///
/// ## Key Benefits
/// - **Non-intrusive**: Zero impact on production when disabled
/// - **Cross-platform**: Works on iOS, Android, Web, and Desktop
/// - **Performance optimized**: Async operations with minimal overhead
/// - **Developer friendly**: Clean API with comprehensive documentation
/// - **Extensible**: Easy to add custom interceptors and features
///
/// ## Debugging Tips
/// - Use `NetworkInspector.notifyActivity()` to log custom events
/// - Enable touch indicators to visualize user interactions
/// - Switch environments without restarting the app
/// - Inspect detailed request/response data in ActivityPage
///
/// @since 1.0.0
/// @author Your Name
/// @see [Dio](https://pub.dev/packages/dio)
/// @see [Chopper](https://pub.dev/packages/chopper)
/// @see [http](https://pub.dev/packages/http)
class EnvironmentConfig {
  /// Display name of the environment (e.g., "Development", "Staging", "Production")
  final String name;

  /// Base URL for API requests in this environment
  final String baseUrl;

  /// Color theme for this environment in UI elements
  final Color color;

  /// Default headers to include with all requests in this environment
  final Map<String, String>? headers;

  /// Creates a new environment configuration
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

  /// Overlay entry for the floating circle UI indicator
  static OverlayEntry? _circleOverlayEntry;

  /// List of available environments
  static final List<EnvironmentConfig> _environments = [];

  /// Currently selected environment
  static EnvironmentConfig? selectedEnvironment;

  /// Callback triggered when environment changes
  static EnvironmentSelectedCallback? onEnvironmentSelected;

  /// Database instance for log storage
  static Database? _database;

  /// Data source for log operations
  static LogDatasource? _logDatasource;

  /// Repository for log business logic
  static LogRepository? _logRepository;

  /// Use case for logging HTTP requests
  static LogHttpRequest? _logHttpRequest;

  /// Use case for logging HTTP responses
  static LogHttpResponse? _logHttpResponse;

  /// Check if logging is currently enabled
  ///
  /// Returns `true` if NetworkInspector is actively monitoring network activity
  static bool get isEnabled => _isEnabled;

  /// State for touch indicators visibility
  static bool _showTouchIndicators = false;

  /// Callback for touch indicators state changes
  static ValueChanged<bool>? _onTouchIndicatorsChanged;

  /// Get current touch indicators state
  ///
  /// Returns `true` if touch visualization is currently enabled
  static bool get showTouchIndicators => _showTouchIndicators;

  /// Set touch indicators visibility
  ///
  /// @param show Whether to show touch indicators
  static void setTouchIndicators(bool show) {
    _showTouchIndicators = show;
    _onTouchIndicatorsChanged?.call(show);
  }

  /// Subscribe to touch indicators state changes
  ///
  /// @param callback Function called when touch indicators state changes
  static void onTouchIndicatorsChanged(ValueChanged<bool> callback) {
    _onTouchIndicatorsChanged = callback;
  }

  /// Toggle touch indicators
  static void toggleTouchIndicators() {
    setTouchIndicators(!_showTouchIndicators);
  }

  /// Enable network monitoring and floating UI
  ///
  /// Call this method to start logging network activity and show the
  /// floating circle indicator. This should be called after initialization
  /// and when you want to begin monitoring.
  static void enable() {
    _isEnabled = true;
  }

  /// Disable network monitoring and hide floating UI
  ///
  /// Call this method to stop logging network activity and hide the
  /// floating circle indicator. This is useful for production builds
  /// or when debugging is complete.
  // static void disable() {
  //   _isEnabled = false;
  //   hideFloatingCircle();
  // }

  /// Get list of available environments
  ///
  /// Returns an unmodifiable list of all configured environments
  static List<EnvironmentConfig> get availableEnvironments =>
      List.unmodifiable(_environments);

  /// Initialize NetworkInspector with environment configurations
  ///
  /// @param environments List of environment configurations
  /// @throws Exception if database initialization fails
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
    print('🌐 NetworkInspector initialized with ${_environments.length} environments');
  }

  /// Select a specific environment by index
  ///
  /// @param index Zero-based index of the environment to select
  /// @returns The selected EnvironmentConfig or null if index is invalid
  /// @triggers onEnvironmentSelected callback if set
  static EnvironmentConfig? selectEnvironment(int index) {
    if (index >= 0 && index < _environments.length) {
      selectedEnvironment = _environments[index];
      print('🔄 Switched to environment: ${selectedEnvironment!.name}');
      onEnvironmentSelected?.call(selectedEnvironment!);
      return selectedEnvironment;
    }
    return null;
  }

  /// Inject all dependencies (called automatically during initialization)
  ///
  /// Sets up the complete dependency chain following Clean Architecture:
  /// Database → Datasource → Repository → Use Cases
  Future<void> _injectDependencies() async {
    _database = await DatabaseHelper.connect();
    _logDatasource = LogDatasourceImpl(database: _database!);
    _logRepository = LogRepositoryImpl(logDatasource: _logDatasource!);
    _logHttpRequest = LogHttpRequest(logRepository: _logRepository!);
    _logHttpResponse = LogHttpResponse(logRepository: _logRepository!);
  }

  /// Log an HTTP request
  ///
  /// @param param HTTP request data to log
  /// @returns Future<bool?> indicating success (true) or null if logging disabled
  /// @note Only logs if NetworkInspector is enabled via `enable()`
  Future<bool?> writeHttpRequestLog(HttpRequest param) async {
    if (!_isEnabled) return null;
    return await _logHttpRequest?.execute(param);
  }

  /// Log an HTTP response
  ///
  /// @param param HTTP response data to log
  /// @returns Future<bool?> indicating success (true) or null if logging disabled
  /// @note Only logs if NetworkInspector is enabled via `enable()`
  Future<bool?> writeHttpResponseLog(HttpResponse param) async {
    if (!_isEnabled) return null;
    return await _logHttpResponse?.execute(param);
  }

  /// Hide the floating circle UI indicator
  ///
  /// Removes the floating circle from the overlay if it's currently visible.
  /// Called automatically by `disable()` but can be called separately if needed.
  // static void hideFloatingCircle() {
  //   _circleOverlayEntry?.remove();
  //   _circleOverlayEntry = null;
  // }

  /// Show draggable floating circle UI indicator
  ///
  /// @param context BuildContext to attach the overlay to
  /// @note Only shows if logging is enabled via `enable()`
  /// @note Won't show if already visible
  // static void showFloatingCircle(BuildContext context) {
  //   if (!_isEnabled) {
  //     print('⚠️ NetworkInspector is disabled, floating circle not shown');
  //     return;
  //   }
  //   if (_circleOverlayEntry != null) return;
  //
  //   _circleOverlayEntry = OverlayEntry(
  //     builder: (overlayContext) => FloatingCircleWidget(
  //       onRequestsTap: () {
  //         Navigator.of(context).push(
  //           MaterialPageRoute(builder: (_) => ActivityPage()),
  //         );
  //       },
  //       onEnvironmentTap: () => _showEnvironmentPicker(context),
  //     ),
  //   );
  //
  //   Overlay.of(context, rootOverlay: true)?.insert(_circleOverlayEntry!);
  // }

  /// Display environment selection picker
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

  /// Notify about custom activity (for integration with other systems)
  ///
  /// @param title Brief title of the activity
  /// @param message Detailed description of the activity
  /// @note This is primarily for logging and debugging purposes
  static void notifyActivity({
    required String title,
    required String message,
  }) {
    print('📱 Network activity: $title - $message');
  }
}