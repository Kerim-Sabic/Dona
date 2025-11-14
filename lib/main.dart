import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/utils/logger.dart';
import 'services/storage/local_storage_service.dart';

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
    AppLogger.info('Initializing Dona AI services...');

    // Initialize local storage
    await LocalStorageService.instance.init();

    // TODO: Initialize Firebase
    // await Firebase.initializeApp();

    // TODO: Initialize Hive
    // await Hive.initFlutter();

    // TODO: Initialize notification services
    // await NotificationService.instance.init();

    AppLogger.info('Services initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize services', e, stackTrace);
  }
}
