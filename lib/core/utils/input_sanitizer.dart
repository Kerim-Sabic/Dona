import 'dart:math' as math;

/// Input Sanitization Utility
/// Provides centralized input validation and sanitization methods
/// to prevent injection attacks and ensure data integrity
class InputSanitizer {
  /// Sanitize general text input
  /// Removes potentially dangerous characters while keeping common punctuation
  static String sanitizeText(String input, {int maxLength = 500}) {
    if (input.isEmpty) return '';

    // Remove dangerous characters: < > " ' ` \ ; ( ) { } [ ]
    var sanitized = input.replaceAll(RegExp(r'[<>\"\'`\\;(){}[\]]'), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Sanitize city/location names
  /// Only allows letters, spaces, hyphens, commas, and periods
  static String sanitizeLocationName(String input, {int maxLength = 100}) {
    if (input.isEmpty) return '';

    // Allow only letters, spaces, hyphens, commas, and periods
    var sanitized = input.replaceAll(RegExp(r'[^a-zA-Z\s,\-\.]'), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Sanitize search queries
  /// More permissive than general text, allows numbers and basic punctuation
  static String sanitizeSearchQuery(String input, {int maxLength = 200}) {
    if (input.isEmpty) return '';

    // Remove only extremely dangerous characters
    var sanitized = input.replaceAll(RegExp(r'[<>\\;{}]'), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Sanitize file names
  /// Only allows alphanumeric, hyphen, underscore, and period
  static String sanitizeFileName(String input, {int maxLength = 255}) {
    if (input.isEmpty) return 'unnamed';

    // Allow only alphanumeric, hyphen, underscore, and period
    var sanitized = input.replaceAll(RegExp(r'[^a-zA-Z0-9\-_\.]'), '_');

    // Prevent directory traversal
    sanitized = sanitized.replaceAll('..', '_');

    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    // Ensure not empty after sanitization
    if (sanitized.isEmpty) {
      sanitized = 'unnamed';
    }

    return sanitized;
  }

  /// Validate and sanitize email address
  static String? sanitizeEmail(String input) {
    if (input.isEmpty) return null;

    // Remove whitespace
    final trimmed = input.trim();

    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (emailRegex.hasMatch(trimmed)) {
      return trimmed.toLowerCase();
    }

    return null;
  }

  /// Validate and sanitize URL
  static String? sanitizeUrl(String input) {
    if (input.isEmpty) return null;

    // Remove whitespace
    final trimmed = input.trim();

    // Basic URL validation
    final urlRegex = RegExp(
      r'^https?:\/\/([\w\-]+\.)+[\w\-]+(\/[\w\-._~:/?#[\]@!$&()*+,;=]*)?$',
      caseSensitive: false,
    );

    if (urlRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// Validate and sanitize phone number
  /// Returns null if invalid format
  static String? sanitizePhoneNumber(String input) {
    if (input.isEmpty) return null;

    // Remove all non-digit characters except +
    var sanitized = input.replaceAll(RegExp(r'[^\d+]'), '');

    // Basic validation: should have at least 10 digits
    final digitsOnly = sanitized.replaceAll('+', '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return null;
    }

    // Ensure + only appears at the start
    if (sanitized.contains('+')) {
      if (!sanitized.startsWith('+')) {
        return null;
      }
      if (sanitized.indexOf('+') != sanitized.lastIndexOf('+')) {
        return null;
      }
    }

    return sanitized;
  }

  /// Validate numeric input
  /// Returns the number if valid, null otherwise
  static double? sanitizeNumber(String input, {double? min, double? max}) {
    if (input.isEmpty) return null;

    try {
      final number = double.parse(input.trim());

      // Check bounds if specified
      if (min != null && number < min) return null;
      if (max != null && number > max) return null;

      return number;
    } catch (_) {
      return null;
    }
  }

  /// Validate integer input
  static int? sanitizeInteger(String input, {int? min, int? max}) {
    if (input.isEmpty) return null;

    try {
      final number = int.parse(input.trim());

      // Check bounds if specified
      if (min != null && number < min) return null;
      if (max != null && number > max) return null;

      return number;
    } catch (_) {
      return null;
    }
  }

  /// Validate date range
  static DateTime? sanitizeDate(String input) {
    if (input.isEmpty) return null;

    try {
      return DateTime.parse(input.trim());
    } catch (_) {
      return null;
    }
  }

  /// Validate geographic coordinates
  static Map<String, double>? sanitizeCoordinates(double lat, double lon) {
    if (lat < -90 || lat > 90) return null;
    if (lon < -180 || lon > 180) return null;

    return {'lat': lat, 'lon': lon};
  }

  /// Sanitize user age (for health/fitness services)
  static int? sanitizeAge(int age) {
    if (age < 1 || age > 150) return null;
    return age;
  }

  /// Sanitize weight in kg (for health/fitness services)
  static double? sanitizeWeight(double weight) {
    if (weight < 1 || weight > 500) return null;
    return weight;
  }

  /// Sanitize height in cm (for health/fitness services)
  static double? sanitizeHeight(double height) {
    if (height < 30 || height > 300) return null;
    return height;
  }

  /// Remove SQL injection attempts
  static String removeSqlInjection(String input) {
    // Remove common SQL keywords and dangerous patterns
    var sanitized = input.replaceAll(
      RegExp(
        r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE|UNION|WHERE|FROM|TABLE)\b)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove SQL comment patterns
    sanitized = sanitized.replaceAll(RegExp(r'(--|#|\/\*|\*\/)'), '');

    return sanitized;
  }

  /// Remove XSS (Cross-Site Scripting) attempts
  static String removeXss(String input) {
    // Remove script tags
    var sanitized = input.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');

    // Remove event handlers (onclick, onerror, etc.)
    sanitized = sanitized.replaceAll(RegExp(r'\s*on\w+\s*=', caseSensitive: false), '');

    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    return sanitized;
  }

  /// Comprehensive sanitization for user-generated content
  static String sanitizeUserContent(String input, {int maxLength = 1000}) {
    if (input.isEmpty) return '';

    var sanitized = input;

    // Remove SQL injection attempts
    sanitized = removeSqlInjection(sanitized);

    // Remove XSS attempts
    sanitized = removeXss(sanitized);

    // Remove dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>\"\'`\\;{}]'), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Validate and sanitize language code (ISO 639-1)
  static String? sanitizeLanguageCode(String input) {
    if (input.isEmpty) return null;

    final code = input.trim().toLowerCase();

    // ISO 639-1 codes are 2 or 3 letters, sometimes with hyphen for regional variants
    final languageRegex = RegExp(r'^[a-z]{2,3}(-[A-Z]{2})?$');

    if (languageRegex.hasMatch(code)) {
      return code;
    }

    return null;
  }

  /// Validate and sanitize currency code (ISO 4217)
  static String? sanitizeCurrencyCode(String input) {
    if (input.isEmpty) return null;

    final code = input.trim().toUpperCase();

    // ISO 4217 codes are 3 letters
    if (code.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      return code;
    }

    return null;
  }

  /// Validate and sanitize country code (ISO 3166-1 alpha-2)
  static String? sanitizeCountryCode(String input) {
    if (input.isEmpty) return null;

    final code = input.trim().toUpperCase();

    // ISO 3166-1 alpha-2 codes are 2 letters
    if (code.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(code)) {
      return code;
    }

    return null;
  }

  /// Escape HTML entities
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Unescape HTML entities
  static String unescapeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// Validate and sanitize hex color code
  static String? sanitizeHexColor(String input) {
    if (input.isEmpty) return null;

    var color = input.trim();

    // Add # if missing
    if (!color.startsWith('#')) {
      color = '#$color';
    }

    // Validate hex color (3 or 6 digits)
    final hexRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');

    if (hexRegex.hasMatch(color)) {
      return color.toUpperCase();
    }

    return null;
  }

  /// Rate limiting check (simple implementation)
  static final Map<String, List<DateTime>> _rateLimitMap = {};

  static bool checkRateLimit(String identifier, {int maxRequests = 10, Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Get or create request history for this identifier
    _rateLimitMap[identifier] ??= [];

    // Remove old requests outside the window
    _rateLimitMap[identifier]!.removeWhere((time) => time.isBefore(windowStart));

    // Check if limit exceeded
    if (_rateLimitMap[identifier]!.length >= maxRequests) {
      return false; // Rate limit exceeded
    }

    // Add current request
    _rateLimitMap[identifier]!.add(now);

    return true; // Within rate limit
  }

  /// Clear rate limit history (useful for testing)
  static void clearRateLimits() {
    _rateLimitMap.clear();
  }
}
