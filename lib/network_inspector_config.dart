import 'package:flutter/material.dart';

/// Configuration class for the NetworkInspector floating test button.
///
/// This class provides static methods to configure the appearance and behavior
/// of the floating test button that provides quick access to the network inspector.
/// The button can be customized with different alignments, margins, and custom icons.
class NetworkInspectorConfig {
  static bool _isTestButtonEnabled = false;
  static Alignment _buttonAlignment = Alignment.bottomRight;
  static double _buttonMargin = 16.0;
  static Widget _customButton = const Icon(Icons.bug_report);

  /// Returns whether the test button is currently enabled.
  static bool get isTestButtonEnabled => _isTestButtonEnabled;

  /// Returns the alignment of the test button.
  static Alignment get buttonAlignment => _buttonAlignment;

  /// Returns the margin of the test button from screen edges.
  static double get buttonMargin => _buttonMargin;

  /// Returns the custom widget used for the test button.
  static Widget get customButton => _customButton;

  /// Enables the floating test button with optional customization.
  ///
  /// [alignment] determines where the button is positioned on screen.
  /// [margin] specifies the distance from screen edges.
  /// [customButton] allows replacing the default bug icon with a custom widget.
  static void enableTestButton({
    Alignment alignment = Alignment.bottomRight,
    double margin = 16.0,
    Widget? customButton,
  }) {
    _isTestButtonEnabled = true;
    _buttonAlignment = alignment;
    _buttonMargin = margin;
    if (customButton != null) {
      _customButton = customButton;
    }
  }

  static void disableTestButton() {
    _isTestButtonEnabled = false;
  }

  static void setButtonPosition(Alignment alignment) {
    _buttonAlignment = alignment;
  }

  static void setButtonMargin(double margin) {
    _buttonMargin = margin;
  }

  static void setCustomButton(Widget button) {
    _customButton = button;
  }
}