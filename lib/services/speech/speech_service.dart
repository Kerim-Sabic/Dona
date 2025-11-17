import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../core/utils/logger.dart';

/// Service for speech-to-text and text-to-speech
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  static SpeechService get instance => _instance;

  SpeechService._internal();

  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _isSpeechAvailable = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isSpeechAvailable;
  bool get isInitialized => _isInitialized;

  final StreamController<String> _speechResultController = StreamController<String>.broadcast();
  final StreamController<double> _confidenceController = StreamController<double>.broadcast();

  /// Speech recognition results stream
  Stream<String> get speechResultStream => _speechResultController.stream;

  /// Confidence level stream
  Stream<double> get confidenceStream => _confidenceController.stream;

  Future<void> init() async {
    try {
      AppLogger.info('Initializing SpeechService...');

      // Initialize Speech-to-Text
      _speech = stt.SpeechToText();
      _isSpeechAvailable = await _speech.initialize(
        onError: (error) {
          AppLogger.error('Speech recognition error: ${error.errorMsg}', null, null);
          _isListening = false;
        },
        onStatus: (status) {
          AppLogger.debug('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      // Initialize Text-to-Speech
      _tts = FlutterTts();
      await _configureTts();

      _isInitialized = true;

      if (_isSpeechAvailable) {
        AppLogger.info('SpeechService initialized successfully');
      } else {
        AppLogger.warning('Speech recognition not available on this device');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize SpeechService', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// Configure Text-to-Speech settings
  Future<void> _configureTts() async {
    try {
      // Set language
      await _tts.setLanguage('en-US');

      // Set speech rate (0.0 to 1.0, default 0.5)
      await _tts.setSpeechRate(0.5);

      // Set volume (0.0 to 1.0, default 1.0)
      await _tts.setVolume(1.0);

      // Set pitch (0.5 to 2.0, default 1.0)
      await _tts.setPitch(1.0);

      // Set completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.debug('TTS completed');
      });

      // Set error handler
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        AppLogger.error('TTS error: $msg', null, null);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to configure TTS', e, stackTrace);
    }
  }

  /// Start listening for speech input
  Future<String?> listen({
    String locale = 'en-US',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized || !_isSpeechAvailable) {
      AppLogger.warning('Speech recognition not available');
      return null;
    }

    try {
      if (_isListening) {
        await stopListening();
      }

      _isListening = true;
      String recognizedText = '';
      AppLogger.debug('Starting speech recognition with locale: $locale');

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          recognizedText = result.recognizedWords;
          _speechResultController.add(recognizedText);
          _confidenceController.add(result.confidence);

          AppLogger.debug(
            'Speech result: $recognizedText (confidence: ${result.confidence})',
          );
        },
        localeId: locale,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // Wait for listening to complete
      while (_isListening && _speech.isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _isListening = false;
      return recognizedText.isNotEmpty ? recognizedText : null;
    } catch (e, stackTrace) {
      _isListening = false;
      AppLogger.error('Failed to listen', e, stackTrace);
      return null;
    }
  }

  /// Start continuous listening (for wake word detection or continuous recognition)
  Future<void> startContinuousListening({
    String locale = 'en-US',
    required Function(String) onResult,
  }) async {
    if (!_isInitialized || !_isSpeechAvailable) {
      AppLogger.warning('Speech recognition not available');
      return;
    }

    try {
      if (_isListening) {
        await stopListening();
      }

      _isListening = true;
      AppLogger.debug('Starting continuous speech recognition');

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          final recognizedText = result.recognizedWords;
          _speechResultController.add(recognizedText);
          _confidenceController.add(result.confidence);
          onResult(recognizedText);
        },
        localeId: locale,
        listenFor: const Duration(hours: 1), // Long duration for continuous
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e, stackTrace) {
      _isListening = false;
      AppLogger.error('Failed to start continuous listening', e, stackTrace);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      _isListening = false;
      AppLogger.debug('Stopped listening');
    } catch (e, stackTrace) {
      AppLogger.error('Error stopping listening', e, stackTrace);
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
      _isListening = false;
      AppLogger.debug('Cancelled listening');
    } catch (e, stackTrace) {
      AppLogger.error('Error cancelling listening', e, stackTrace);
    }
  }

  /// Speak text using TTS
  Future<void> speak(
    String text, {
    String locale = 'en-US',
    double rate = 0.5,
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('TTS not initialized');
      return;
    }

    try {
      // Stop any ongoing speech
      if (_isSpeaking) {
        await stopSpeaking();
      }

      _isSpeaking = true;
      AppLogger.debug('Speaking: $text');

      // Configure voice parameters
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(rate);
      await _tts.setVolume(volume);
      await _tts.setPitch(pitch);

      // Speak the text
      await _tts.speak(text);
    } catch (e, stackTrace) {
      _isSpeaking = false;
      AppLogger.error('Failed to speak', e, stackTrace);
    }
  }

  /// Speak with a specific voice (if supported)
  Future<void> speakWithVoice(
    String text,
    String voice, {
    double rate = 0.5,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('TTS not initialized');
      return;
    }

    try {
      if (_isSpeaking) {
        await stopSpeaking();
      }

      _isSpeaking = true;

      await _tts.setVoice({'name': voice, 'locale': 'en-US'});
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    } catch (e, stackTrace) {
      _isSpeaking = false;
      AppLogger.error('Failed to speak with voice', e, stackTrace);
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      AppLogger.debug('Stopped speaking');
    } catch (e, stackTrace) {
      AppLogger.error('Error stopping TTS', e, stackTrace);
    }
  }

  /// Pause speaking (if supported)
  Future<void> pauseSpeaking() async {
    try {
      await _tts.pause();
      AppLogger.debug('Paused speaking');
    } catch (e, stackTrace) {
      AppLogger.error('Error pausing TTS', e, stackTrace);
    }
  }

  /// Get available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    if (!_isSpeechAvailable) {
      return [];
    }

    try {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get available locales', e, stackTrace);
      return [];
    }
  }

  /// Get available voices for TTS
  Future<List<Map<String, String>>> getAvailableVoices() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      final voices = await _tts.getVoices;
      return List<Map<String, String>>.from(voices ?? []);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get available voices', e, stackTrace);
      return [];
    }
  }

  /// Check if speech recognition is available
  Future<bool> checkAvailability() async {
    try {
      _isSpeechAvailable = await _speech.initialize();
      return _isSpeechAvailable;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check speech availability', e, stackTrace);
      return false;
    }
  }

  /// Get current speech recognition status
  String getSpeechStatus() {
    if (!_isInitialized) return 'not_initialized';
    if (!_isSpeechAvailable) return 'not_available';
    if (_isListening) return 'listening';
    return 'ready';
  }

  /// Get current TTS status
  String getTtsStatus() {
    if (!_isInitialized) return 'not_initialized';
    if (_isSpeaking) return 'speaking';
    return 'ready';
  }

  /// Dispose resources
  void dispose() {
    _speechResultController.close();
    _confidenceController.close();
    _speech.cancel();
    _tts.stop();
    AppLogger.info('SpeechService disposed');
  }
}
