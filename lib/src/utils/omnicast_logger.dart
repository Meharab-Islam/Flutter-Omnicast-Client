import 'package:flutter/foundation.dart';

/// Centralized logger for the OmniCast Client SDK.
///
/// By default, logging is disabled (`enableLogging = false`) to keep the console clean.
/// Developers can enable logging by setting `OmniCastClient.enableLogging = true` or passing
/// `enableLogging: true` when initializing `OmniCastClient.init()`.
class OmniCastLogger {
  OmniCastLogger._();

  /// Global master switch for SDK console logs. Defaults to `false`.
  static bool enableLogging = false;

  /// Logs a standard informational message to console if [enableLogging] is true.
  static void log(String message) {
    if (enableLogging) {
      debugPrint(message);
    }
  }

  /// Logs an error or warning message to console if [enableLogging] is true.
  static void error(String message, [dynamic error]) {
    if (enableLogging) {
      debugPrint('$message ${error ?? ""}');
    }
  }
}
