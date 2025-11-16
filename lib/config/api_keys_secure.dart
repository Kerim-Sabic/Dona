/// API Keys and Configuration for Dona AI
/// This file uses environment variables for secure configuration
/// Use --dart-define flags when running:
/// flutter run --dart-define=DEEPSEEK_API_KEY=your-key-here
///
/// OR use flutter_dotenv package (recommended for easier management)

class ApiKeys {
  // ==================== AI Services ====================

  /// Get API keys from environment variables (--dart-define)
  /// Falls back to 'NOT_SET' if not provided
  static const String claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: 'NOT_SET',
  );

  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'NOT_SET',
  );

  static const String deepSeekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: 'NOT_SET',
  );

  static const String deepSeekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com',
  );

  // ==================== Google Cloud APIs ====================

  static const String googleCloudApiKey = String.fromEnvironment(
    'GOOGLE_CLOUD_API_KEY',
    defaultValue: 'NOT_SET',
  );

  // Google OAuth Configuration
  static const String googleOAuthClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
    defaultValue: 'NOT_SET',
  );

  static const String googleOAuthClientSecret = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_SECRET',
    defaultValue: 'NOT_SET',
  );

  static const String googleOAuthRedirectUri = String.fromEnvironment(
    'GOOGLE_OAUTH_REDIRECT_URI',
    defaultValue: 'http://localhost:8080/auth/callback',
  );

  // Aliases for backward compatibility
  static String get googleCalendarClientId => googleOAuthClientId;
  static String get googleCalendarClientSecret => googleOAuthClientSecret;
  static String get googleCalendarRedirectUri => googleOAuthRedirectUri;
  static String get gmailClientId => googleOAuthClientId;
  static String get gmailClientSecret => googleOAuthClientSecret;


  // Google Calendar API Scopes (public, safe to hardcode)
  static const List<String> googleCalendarScopes = [
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/calendar.events',
  ];

  // Gmail API Scopes (public, safe to hardcode)
  static const List<String> gmailScopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/gmail.compose',
    'https://www.googleapis.com/auth/gmail.modify',
  ];

  // Google Tasks API Scopes
  static const List<String> googleTasksScopes = [
    'https://www.googleapis.com/auth/tasks',
    'https://www.googleapis.com/auth/tasks.readonly',
  ];

  // Google Drive API Scopes
  static const List<String> googleDriveScopes = [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
    'https://www.googleapis.com/auth/drive.metadata',
  ];

  // Combined Google OAuth Scopes
  static List<String> get allGoogleScopes => [
        ...googleCalendarScopes,
        ...gmailScopes,
        ...googleTasksScopes,
        ...googleDriveScopes,
      ];

  // ==================== Google Maps APIs ====================

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'NOT_SET',
  );

  // ==================== Twilio ====================

  static const String twilioAccountSid = String.fromEnvironment(
    'TWILIO_ACCOUNT_SID',
    defaultValue: 'NOT_SET',
  );

  static const String twilioAuthToken = String.fromEnvironment(
    'TWILIO_AUTH_TOKEN',
    defaultValue: 'NOT_SET',
  );

  static const String twilioPhoneNumber = String.fromEnvironment(
    'TWILIO_PHONE_NUMBER',
    defaultValue: 'NOT_SET',
  );

  // ==================== News API ====================

  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: 'NOT_SET',
  );

  static const String newsBaseUrl = 'https://newsapi.org/v2';

  // WorldNewsAPI (alternative news source)
  static const String worldNewsApiKey = String.fromEnvironment(
    'WORLD_NEWS_API_KEY',
    defaultValue: 'NOT_SET',
  );

  static const String worldNewsBaseUrl = 'https://api.worldnewsapi.com';


  // ==================== Weather API ====================

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'NOT_SET',
  );

  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  // ==================== Firebase ====================
  // Firebase configuration is in google-services.json and GoogleService-Info.plist

  // ==================== Validation ====================

  /// Check if all required API keys are set
  /// Call this at app startup to ensure configuration is complete
  static bool validateConfiguration({bool throwOnMissing = false}) {
    final requiredKeys = <String, String>{
      'DEEPSEEK_API_KEY': deepSeekApiKey,
      'GOOGLE_OAUTH_CLIENT_ID': googleOAuthClientId,
      'GOOGLE_OAUTH_CLIENT_SECRET': googleOAuthClientSecret,
    };

    final missingKeys = <String>[];

    for (final entry in requiredKeys.entries) {
      if (entry.value == 'NOT_SET') {
        missingKeys.add(entry.key);
      }
    }

    if (missingKeys.isNotEmpty) {
      final message = 'Missing required API keys: ${missingKeys.join(", ")}\n'
          'Set them using --dart-define flags:\n'
          'flutter run ${missingKeys.map((k) => '--dart-define=$k=your-key-here').join(' ')}';

      if (throwOnMissing) {
        throw StateError(message);
      } else {
        // ignore: avoid_print
        print('⚠️ WARNING: $message');
        return false;
      }
    }

    return true;
  }

  /// Check if a specific key is available
  static bool isKeyAvailable(String key) {
    return key != 'NOT_SET';
  }
}

/// API Configuration (non-sensitive settings)
class ApiConfig {
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // AI Model Configuration
  static const String aiModel = 'deepseek-chat';
  static const double aiTemperature = 0.7;
  static const int aiMaxTokens = 2000;

  // Default values
  static const String defaultCity = 'Sarajevo';
  static const String defaultCountry = 'ba'; // Bosnia and Herzegovina
  static const String defaultCountryCode = 'ba'; // Alias for compatibility
  static const String defaultLanguage = 'en';
  static const String temperatureUnit = 'metric'; // Celsius

  // API Base URLs (public endpoints)
  static const String googleApisBaseUrl = 'https://www.googleapis.com';
  static const String googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api';

  // Google Maps API Endpoints
  static String get directionsEndpoint => '$googleMapsBaseUrl/directions/json';
  static String get placesEndpoint => '$googleMapsBaseUrl/place/nearbysearch/json';
  static String get geocodingEndpoint => '$googleMapsBaseUrl/geocode/json';
  static String get airQualityEndpoint => '$googleMapsBaseUrl/air-quality';
  static String get pollenEndpoint => '$googleMapsBaseUrl/pollen';
  static String get roadsEndpoint => '$googleMapsBaseUrl/roads/v1';

  // Twilio API
  static const String twilioBaseUrl = 'https://api.twilio.com/2010-04-01';
}
