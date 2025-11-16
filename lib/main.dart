import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/utils/logger.dart';
import 'config/api_keys_secure.dart';
import 'services/storage/local_storage_service.dart';
import 'services/ai/ai_service.dart';
import 'services/gamification/gamification_service.dart';
import 'services/calendar/calendar_service.dart';
import 'services/news/news_service.dart';
import 'services/weather/weather_service.dart';
import 'services/twilio/twilio_service.dart';
import 'services/google_maps/google_maps_service.dart';
import 'services/gmail/gmail_service.dart';
import 'services/google_drive/google_drive_service.dart';
import 'services/google_tasks/google_tasks_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await _initializeServices();

  // Run app
  runApp(const DonaAIApp());
}

Future<void> _initializeServices() async {
  try {
    AppLogger.info('🚀 Initializing Dona AI services...');

    // Step 1: Validate API configuration
    AppLogger.info('📋 Validating API configuration...');
    final configValid = ApiKeys.validateConfiguration(throwOnMissing: false);
    if (!configValid) {
      AppLogger.warning('⚠️  Some API keys are not configured. Some features may not work.');
    } else {
      AppLogger.info('✅ API configuration validated successfully');
    }

    // Step 2: Initialize local storage (critical dependency)
    AppLogger.info('💾 Initializing local storage...');
    await LocalStorageService.instance.init();
    AppLogger.info('✅ Local storage initialized');

    // Step 3: Initialize core AI service
    try {
      AppLogger.info('🤖 Initializing AI service...');
      if (ApiKeys.isKeyAvailable(ApiKeys.deepSeekApiKey)) {
        await AIService.instance.init();
        AppLogger.info('✅ AI service initialized');
      } else {
        AppLogger.warning('⚠️  DeepSeek API key not set - AI features disabled');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize AI service', e, stackTrace);
    }

    // Step 4: Initialize gamification service
    try {
      AppLogger.info('🎮 Initializing gamification service...');
      await GamificationService.instance.init();
      AppLogger.info('✅ Gamification service initialized');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize gamification service', e, stackTrace);
    }

    // Step 5: Initialize external API services (non-critical)
    await _initializeExternalServices();

    // TODO: Initialize Firebase
    // if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    //   await Firebase.initializeApp();
    // }

    // TODO: Initialize Hive for local database
    // await Hive.initFlutter();

    // TODO: Initialize notification services
    // await NotificationService.instance.init();

    AppLogger.info('✅ All services initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Critical failure during service initialization', e, stackTrace);
    // Continue anyway - some features may work
  }
}

/// Initialize external API services (Google, Twilio, News, Weather)
/// These are non-critical and can fail without breaking the app
Future<void> _initializeExternalServices() async {
  final services = <String, Future<void> Function()>{
    'Calendar': () => CalendarService.instance.init(),
    'News': () => NewsService.instance.init(),
    'Weather': () => WeatherService.instance.init(),
    'Twilio': () => TwilioService.instance.init(),
    'Google Maps': () => GoogleMapsService.instance.init(),
    'Gmail': () => GmailService.instance.init(),
    'Google Drive': () => GoogleDriveService.instance.init(),
    'Google Tasks': () => GoogleTasksService.instance.init(),
  };

  for (final entry in services.entries) {
    try {
      AppLogger.debug('Initializing ${entry.key}...');
      await entry.value();
    } catch (e) {
      AppLogger.warning('⚠️  ${entry.key} initialization failed: $e');
      // Continue with other services
    }
  }
}
