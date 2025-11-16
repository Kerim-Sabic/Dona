import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Enhanced App Logger with ring buffer for diagnostics and privacy controls
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.info,
  );

  // Ring buffer for recent logs (diagnostics screen)
  static final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 100;

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
      _addToBuffer(LogLevel.debug, message, error);
    }
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    _addToBuffer(LogLevel.info, message, error);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    _addToBuffer(LogLevel.warning, message, error);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _addToBuffer(LogLevel.error, message, error);
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    _addToBuffer(LogLevel.fatal, message, error);
  }

  /// Add entry to ring buffer (for diagnostics)
  static void _addToBuffer(LogLevel level, String message, dynamic error) {
    // Privacy: don't log sensitive data in production
    final sanitizedMessage = kDebugMode ? message : _sanitize(message);

    final entry = LogEntry(
      level: level,
      message: sanitizedMessage,
      error: error?.toString(),
      timestamp: DateTime.now(),
    );

    _logBuffer.add(entry);

    // Keep buffer size limited
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0); // Remove oldest
    }
  }

  /// Sanitize message for production (remove potential PII)
  static String _sanitize(String message) {
    // Remove email patterns
    var sanitized = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL]',
    );

    // Remove phone patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE]',
    );

    // Remove potential API keys/tokens (long alphanumeric strings)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9]{32,}\b'),
      '[TOKEN]',
    );

    return sanitized;
  }

  /// Get recent logs (for diagnostics screen)
  static List<LogEntry> getRecentLogs({int? limit}) {
    if (limit == null) {
      return List.unmodifiable(_logBuffer);
    }
    final start = _logBuffer.length > limit ? _logBuffer.length - limit : 0;
    return List.unmodifiable(_logBuffer.sublist(start));
  }

  /// Clear log buffer
  static void clearBuffer() {
    _logBuffer.clear();
  }

  /// Get buffer size
  static int get bufferSize => _logBuffer.length;
}

/// Log entry for buffer storage
class LogEntry {
  final LogLevel level;
  final String message;
  final String? error;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.error,
    required this.timestamp,
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.fatal:
        return '💀';
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}
