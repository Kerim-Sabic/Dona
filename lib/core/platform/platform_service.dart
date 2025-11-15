import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

/// Platform Service for cross-platform compatibility
/// Handles Windows, macOS, Linux, iOS, Android, and Web
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  static PlatformService get instance => _instance;

  PlatformService._internal();

  /// Current platform
  TargetPlatform get currentPlatform {
    if (kIsWeb) return TargetPlatform.web;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    if (Platform.isLinux) return TargetPlatform.linux;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.iOS;
    return TargetPlatform.fuchsia;
  }

  /// Check if running on desktop (Windows, macOS, Linux)
  bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Check if running on mobile (iOS, Android)
  bool get isMobile => isIOS || isAndroid;

  /// Platform checks
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isWeb => kIsWeb;

  /// Get platform name
  String get platformName {
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWeb) return 'Web';
    return 'Unknown';
  }

  /// Get application documents directory (cross-platform)
  Future<String> getDocumentsPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      AppLogger.error('Error getting documents directory', e);
      // Fallback for web or unsupported platforms
      return '.';
    }
  }

  /// Get application support directory (cross-platform)
  Future<String> getAppSupportPath() async {
    try {
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    } catch (e) {
      AppLogger.error('Error getting app support directory', e);
      return '.';
    }
  }

  /// Get temporary directory (cross-platform)
  Future<String> getTempPath() async {
    try {
      final directory = await getTemporaryDirectory();
      return directory.path;
    } catch (e) {
      AppLogger.error('Error getting temp directory', e);
      return '.';
    }
  }

  /// Join paths in a platform-agnostic way
  String joinPath(String part1, [String? part2, String? part3, String? part4]) {
    if (part2 == null) return part1;
    if (part3 == null) return path.join(part1, part2);
    if (part4 == null) return path.join(part1, part2, part3);
    return path.join(part1, part2, part3, part4);
  }

  /// Get file basename
  String getBasename(String filePath) {
    return path.basename(filePath);
  }

  /// Get file extension
  String getExtension(String filePath) {
    return path.extension(filePath);
  }

  /// Normalize path for current platform
  String normalizePath(String filePath) {
    return path.normalize(filePath);
  }

  /// Get platform-specific features
  PlatformFeatures get features => PlatformFeatures(
    hasNotifications: !isWeb,
    hasLocationServices: isMobile || isWindows,
    hasSpeechRecognition: !isWeb,
    hasTextToSpeech: !isWeb,
    hasFileSystem: !isWeb,
    hasCamera: isMobile,
    hasContacts: isMobile,
    hasCalendar: !isWeb,
    hasBackgroundTasks: !isWeb,
    hasPushNotifications: isMobile,
    hasSystemTray: isDesktop,
    hasWindowControls: isDesktop,
    hasNativeMenus: isDesktop,
  );

  /// Initialize platform-specific services
  Future<void> init() async {
    try {
      AppLogger.info('Initializing platform services for $platformName');

      // Windows-specific initialization
      if (isWindows) {
        await _initWindows();
      }

      // macOS-specific initialization
      if (isMacOS) {
        await _initMacOS();
      }

      // Linux-specific initialization
      if (isLinux) {
        await _initLinux();
      }

      // Mobile-specific initialization
      if (isMobile) {
        await _initMobile();
      }

      AppLogger.info('Platform services initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing platform services', e, stackTrace);
    }
  }

  /// Initialize Windows-specific features
  Future<void> _initWindows() async {
    try {
      // Set up Windows-specific paths
      final appData = Platform.environment['APPDATA'];
      final localAppData = Platform.environment['LOCALAPPDATA'];

      AppLogger.info('Windows environment:');
      AppLogger.info('  APPDATA: $appData');
      AppLogger.info('  LOCALAPPDATA: $localAppData');

      // Create application directories if they don't exist
      final docsPath = await getDocumentsPath();
      final appPath = path.join(docsPath, 'Dona');

      final appDir = Directory(appPath);
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        AppLogger.info('Created app directory: $appPath');
      }

      // Windows notifications require special setup
      // This would be implemented with win32 or similar package
      AppLogger.info('Windows initialization complete');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing Windows features', e, stackTrace);
    }
  }

  /// Initialize macOS-specific features
  Future<void> _initMacOS() async {
    try {
      AppLogger.info('macOS initialization complete');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing macOS features', e, stackTrace);
    }
  }

  /// Initialize Linux-specific features
  Future<void> _initLinux() async {
    try {
      AppLogger.info('Linux initialization complete');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing Linux features', e, stackTrace);
    }
  }

  /// Initialize mobile-specific features
  Future<void> _initMobile() async {
    try {
      AppLogger.info('Mobile initialization complete');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing mobile features', e, stackTrace);
    }
  }

  /// Get platform-specific notification sound
  String? getNotificationSound() {
    if (isWindows) return 'windows_notification.wav';
    if (isMacOS) return 'macos_notification.aiff';
    if (isLinux) return 'linux_notification.ogg';
    if (isAndroid) return 'android_notification.mp3';
    if (isIOS) return 'ios_notification.caf';
    return null;
  }

  /// Check if feature is supported on current platform
  bool isFeatureSupported(String feature) {
    switch (feature) {
      case 'notifications':
        return features.hasNotifications;
      case 'location':
        return features.hasLocationServices;
      case 'speech':
        return features.hasSpeechRecognition;
      case 'tts':
        return features.hasTextToSpeech;
      case 'background':
        return features.hasBackgroundTasks;
      case 'system_tray':
        return features.hasSystemTray;
      default:
        return false;
    }
  }
}

/// Platform-specific feature availability
class PlatformFeatures {
  final bool hasNotifications;
  final bool hasLocationServices;
  final bool hasSpeechRecognition;
  final bool hasTextToSpeech;
  final bool hasFileSystem;
  final bool hasCamera;
  final bool hasContacts;
  final bool hasCalendar;
  final bool hasBackgroundTasks;
  final bool hasPushNotifications;
  final bool hasSystemTray;
  final bool hasWindowControls;
  final bool hasNativeMenus;

  PlatformFeatures({
    required this.hasNotifications,
    required this.hasLocationServices,
    required this.hasSpeechRecognition,
    required this.hasTextToSpeech,
    required this.hasFileSystem,
    required this.hasCamera,
    required this.hasContacts,
    required this.hasCalendar,
    required this.hasBackgroundTasks,
    required this.hasPushNotifications,
    required this.hasSystemTray,
    required this.hasWindowControls,
    required this.hasNativeMenus,
  });

  @override
  String toString() {
    return '''
Platform Features:
  Notifications: $hasNotifications
  Location: $hasLocationServices
  Speech Recognition: $hasSpeechRecognition
  Text-to-Speech: $hasTextToSpeech
  File System: $hasFileSystem
  Camera: $hasCamera
  Contacts: $hasContacts
  Calendar: $hasCalendar
  Background Tasks: $hasBackgroundTasks
  Push Notifications: $hasPushNotifications
  System Tray: $hasSystemTray
  Window Controls: $hasWindowControls
  Native Menus: $hasNativeMenus
''';
  }
}

/// Target platform enum
enum TargetPlatform {
  android,
  iOS,
  windows,
  macOS,
  linux,
  web,
  fuchsia,
}
