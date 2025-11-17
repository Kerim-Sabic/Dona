import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/utils/logger.dart';
import 'services/storage/local_storage_service.dart';
import 'services/ai/ai_service.dart';
import 'services/weather/weather_service.dart';
import 'services/news/news_service.dart';
import 'services/calendar/calendar_service.dart';
import 'services/gmail/gmail_service.dart';
import 'services/google_tasks/google_tasks_service.dart';
import 'services/twilio/twilio_service.dart';
import 'services/speech/speech_service.dart';
import 'services/quotes/quotes_service.dart';
import 'services/jokes/jokes_service.dart';
import 'services/facts/facts_service.dart';
import 'services/activity/activity_service.dart';
import 'services/advice/advice_service.dart';
import 'services/affirmations/affirmations_service.dart';
import 'services/smart_assistant/smart_assistant_coordinator.dart';
import 'data/user_profile.dart';

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

    // 1. Initialize Hive (Local Database)
    await _initializeHive();

    // 2. Initialize Local Storage (Shared Preferences)
    await LocalStorageService.instance.init();

    // 3. Initialize User Profile
    await UserProfile.instance.init();

    // 4. Initialize Core Services (in parallel for speed)
    await Future.wait([
      AIService.instance.init(),
      WeatherService.instance.init(),
      NewsService.instance.init(),
    ]);

    // 5. Initialize Google Services
    await Future.wait([
      CalendarService.instance.init(),
      GmailService.instance.init(),
      GoogleTasksService.instance.init(),
    ]);

    // 6. Initialize Communication Services
    await TwilioService.instance.init();

    // 7. Initialize Entertainment & Wellness Services (in parallel)
    await Future.wait([
      QuotesService.instance.init(),
      JokesService.instance.init(),
      FactsService.instance.init(),
      ActivityService.instance.init(),
      AdviceService.instance.init(),
      AffirmationsService.instance.init(),
    ]);

    // 8. Initialize Speech Service (may fail on some devices)
    try {
      await SpeechService.instance.init();
    } catch (e) {
      AppLogger.warning('Speech service not available on this device: $e');
    }

    // 9. Initialize Smart Assistant Coordinator (orchestrates everything)
    await SmartAssistantCoordinator.instance.init();

    // 10. Initialize Firebase (optional - only if configured)
    await _initializeFirebase();

    AppLogger.info('✅ All services initialized successfully!');
    AppLogger.info('🎉 Dona AI is ready to assist!');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Failed to initialize services', e, stackTrace);
    // App can still run with limited functionality
  }
}

/// Initialize Hive local database
Future<void> _initializeHive() async {
  try {
    await Hive.initFlutter();

    // Open necessary boxes
    await Hive.openBox('user_profile');
    await Hive.openBox('conversation_history');
    await Hive.openBox('settings');
    await Hive.openBox('cache');

    AppLogger.info('Hive database initialized');
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize Hive', e, stackTrace);
  }
}

/// Initialize Firebase (optional)
Future<void> _initializeFirebase() async {
  try {
    // Only initialize if Firebase is configured
    // Uncomment when you have google-services.json configured

    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );

    // Initialize Firebase Cloud Messaging
    // await FirebaseMessaging.instance.requestPermission(
    //   alert: true,
    //   announcement: false,
    //   badge: true,
    //   carPlay: false,
    //   criticalAlert: false,
    //   provisional: false,
    //   sound: true,
    // );

    // AppLogger.info('Firebase initialized');
  } catch (e) {
    AppLogger.warning('Firebase not configured or failed to initialize: $e');
  }
}
