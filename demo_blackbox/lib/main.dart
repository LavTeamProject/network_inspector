import 'package:demo_blackbox/screens/client_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:network_inspector/common/utils/dio_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';
import 'package:network_inspector/presentation/widgets/touch_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common/enums.dart';
import 'package:dio/dio.dart';

Dio? _globalDio;

/// Current application environment (development, staging, production, etc.)
/// This is the app's internal representation of the selected environment
AppEnvironment currentAppEnv = AppEnvironment.stage;

/// SharedPreferences instance for persistent storage of user settings
/// Used to save and load the selected environment between app sessions
SharedPreferences? _prefs;

/// Saves the selected environment to persistent storage
///
/// This allows the app to remember the user's environment choice
/// even after the app is closed and reopened.
///
/// @param env The AppEnvironment to save
/// @throws Exception if SharedPreferences fails to save
///
/// Example:
/// ```dart
/// await saveEnvironment(AppEnvironment.production);
/// ```
Future<void> saveEnvironment(AppEnvironment env) async {
  await _prefs?.setString('selected_environment', env.name);
}

/// Loads the previously saved environment from persistent storage
///
/// Called during app initialization to restore the user's last environment choice.
/// If no saved environment exists, defaults to `AppEnvironment.stage`.
///
/// @returns Future<void> - completes when environment is loaded
///
/// Example:
/// ```dart
/// await loadEnvironment();
/// print('Current environment: ${currentAppEnv.name}');
/// ```
Future<void> loadEnvironment() async {
  _prefs = await SharedPreferences.getInstance();
  final savedEnvName = _prefs?.getString('selected_environment') ?? 'Stage';
  currentAppEnv = AppEnvironment.fromName(savedEnvName) ?? AppEnvironment.stage;
  print('📂 Loaded environment: ${currentAppEnv.name}');
}

/// Main application entry point
///
/// This function:
/// 1. Initializes Flutter bindings
/// 2. Loads saved environment from storage
/// 3. Initializes NetworkInspector with environment configurations
/// 4. Sets up two-way synchronization between app and NetworkInspector
/// 5. Enables network monitoring
/// 6. Runs the Flutter application
///
/// ## Two-Way Environment Synchronization
/// The app maintains two-way sync with NetworkInspector:
///
/// ### App → Library (Initial Setup)
/// When the app starts, it tells NetworkInspector which environment to use:
/// ```dart
/// NetworkInspector.selectedEnvironment = currentAppEnv.toLibraryConfig();
/// ```
///
/// ### Library → App (Runtime Changes)
/// When user changes environment in NetworkInspector UI:
/// ```dart
/// NetworkInspector.onEnvironmentSelected = (config) {
///   // Update app's environment
///   // Update Dio baseUrl
///   // Save to persistent storage
/// };
/// ```
///
/// This ensures that environment changes made through the NetworkInspector
/// floating circle are reflected in the app and persisted for future sessions.
///
/// ## Initialization Flow
/// 1. Load saved environment from SharedPreferences
/// 2. Initialize NetworkInspector with all available environments
/// 3. Set NetworkInspector's current environment to match app's saved environment
/// 4. Setup callback for when user changes environment in NetworkInspector UI
/// 5. Enable network monitoring
/// 6. Run the app
///
/// @throws Exception if NetworkInspector initialization fails
/// @see [NetworkInspector]
/// @see [AppEnvironment]
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Step 1: Load previously saved environment from storage
  await loadEnvironment();
  print('🚀 Starting app with environment: ${currentAppEnv.name}');

  // ✅ Step 2: Initialize NetworkInspector with all available environments
  // This makes all app environments available in the NetworkInspector UI
  await NetworkInspector.initializeWithEnvironments(
    environments: AppEnvironment.allConfigs,
  );

  // ✅ Step 3: Sync app environment → NetworkInspector
  // Tell NetworkInspector to use the environment we loaded from storage
  NetworkInspector.selectedEnvironment = currentAppEnv.toLibraryConfig();
  print('🔄 Synced app environment to NetworkInspector');

  // ✅ Step 4: Setup callback: Library → App synchronization
  // This callback is triggered when user changes environment in NetworkInspector UI
  NetworkInspector.onEnvironmentSelected = (EnvironmentConfig config) async {
    print('🎉 Library → App: ${config.name} → ${config.baseUrl}');

    // Convert NetworkInspector config to app's environment enum
    final appEnv = AppEnvironment.fromName(config.name);
    if (appEnv != null) {
      // Update app's current environment
      currentAppEnv = appEnv;

      // Update global Dio instance if it exists
      _globalDio?.options.baseUrl = config.baseUrl;

      // ✅ Save the new environment to persistent storage
      await saveEnvironment(currentAppEnv);
      print('💾 Saved environment: ${currentAppEnv.name}');

      // You could also trigger app-wide updates here, such as:
      // - Refreshing API clients
      // - Clearing caches
      // - Notifying other parts of the app
      // - Updating UI state
    }
  };

  // ✅ Step 5: Enable network monitoring
  // This activates the NetworkInspector and shows the floating circle
  NetworkInspector.enable();
  print('🔍 NetworkInspector enabled');

  // ✅ Step 6: Run the Flutter application
  runApp(const MyApp());
}

/// Root widget of the application
///
/// Configures the MaterialApp with:
/// - App theme and color scheme
/// - TouchIndicator wrapper for visual debugging
/// - ClientSelectionScreen as the home page
/// - Clean layout without debug banner
///
/// ## TouchIndicator Integration
/// The `TouchIndicator` widget wraps the entire application to provide
/// visual feedback for touch events when enabled via NetworkInspector.
/// This is useful for debugging touch interactions and user flows.
///
/// ## Theme Configuration
/// Uses Material 3 with a blue color scheme seed for consistent theming.
///
/// @see [TouchIndicator]
/// @see [ClientSelectionScreen]
/// @see [NetworkInspector.toggleTouchIndicators]
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP Client Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // Wrap entire app with TouchIndicator for visual debugging
      builder: (context, child) => TouchIndicator(child: child!),
      home: const ClientSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}