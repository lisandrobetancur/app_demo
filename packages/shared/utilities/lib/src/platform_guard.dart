import 'package:flutter/foundation.dart';

/// Central platform guard.
///
/// The rest of the workspace never checks `kIsWeb` or `defaultTargetPlatform`
/// directly, and never imports `dart:io` outside the conditionally-imported
/// implementation files of this package. Every platform decision funnels
/// through here so the differences stay documented in one place.
class PlatformGuard {
  const PlatformGuard._();

  /// True when running on the web (sqflite ffi web factory, data-URI images).
  static bool get isWeb => kIsWeb;

  /// True on Android devices.
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True on iOS devices.
  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// True on either mobile platform (file-based image storage, sqflite
  /// default factory).
  static bool get isMobile => isAndroid || isIos;

  /// Human readable platform name for the "about" screen.
  static String get platformName {
    if (kIsWeb) {
      return 'Web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
