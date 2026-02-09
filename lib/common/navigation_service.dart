import 'package:flutter/material.dart';

/// Service for handling navigation throughout the application.
///
/// This service provides a global navigator key that allows navigation
/// from anywhere in the app without requiring a BuildContext.
/// It's particularly useful for showing dialogs or navigating from
/// background services or network interceptors.
class NavigationService {
  /// Global navigator key for the application.
  ///
  /// This key should be set in the MaterialApp's navigatorKey property
  /// to enable global navigation capabilities.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Gets the current BuildContext from the navigator.
  ///
  /// Returns null if no context is available (e.g., app not fully initialized).
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Pushes a new route onto the navigation stack.
  ///
  /// [route] is the route to push onto the stack.
  /// Returns a Future that completes with the result when the route is popped.
  static Future<T?> push<T>(Route<T> route) {
    return navigatorKey.currentState!.push(route);
  }

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }

  static Future<T?> pushReplacement<T, TO>(Route<T> route, {TO? result}) {
    return navigatorKey.currentState!.pushReplacement(route, result: result);
  }

  static Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
    Route<T> newRoute,
    RoutePredicate predicate,
  ) {
    return navigatorKey.currentState!.pushAndRemoveUntil(newRoute, predicate);
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }
}