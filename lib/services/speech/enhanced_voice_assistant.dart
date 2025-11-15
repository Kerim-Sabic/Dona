import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/logger.dart';
import '../ai/ai_service.dart';
import '../ai/intent_recognition.dart';
import '../../data/user_profile.dart';

/// Enhanced Voice Assistant with conversation memory and context
class EnhancedVoiceAssistant {
  static final EnhancedVoiceAssistant _instance = EnhancedVoiceAssistant._internal();
  static EnhancedVoiceAssistant get instance => _instance;

  EnhancedVoiceAssistant._internal();

  // Conversation state
  final ConversationContext _context = ConversationContext();
  bool _isListening = false;
  bool _isSpeaking = false;
  String? _currentTranscription;

  // Callbacks
  Function(String)? onTranscriptionUpdate;
  Function(String)? onResponse;
  Function(VoiceAssistantState)? onStateChange;
  Function(double)? onVolumeChange;

  /// Initialize voice assistant
  Future<void> init() async {
    try {
      AppLogger.info('Enhanced Voice Assistant initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize voice assistant', e, stackTrace);
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;
    _updateState(VoiceAssistantState.listening);
    AppLogger.info('Started listening');

    // In production, integrate with speech_to_text package
    // For now, simulating voice input
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _updateState(VoiceAssistantState.processing);
    AppLogger.info('Stopped listening');

    // Process the transcription
    if (_currentTranscription != null && _currentTranscription!.isNotEmpty) {
      await _processVoiceCommand(_currentTranscription!);
    }
  }

  /// Process voice command with context
  Future<void> _processVoiceCommand(String spokenText) async {
    try {
      AppLogger.debug('Processing: $spokenText');

      // Add to conversation history
      _context.addUserMessage(spokenText);

      // Learn from interaction
      await UserProfile.instance.learnFromInteraction(spokenText, 'voice');

      // Detect if this is a follow-up
      final isFollowUp = _context.isFollowUp(spokenText);

      String response;

      if (isFollowUp && _context.currentIntent != null) {
        // Handle follow-up with context
        response = await _handleFollowUp(spokenText);
      } else {
        // Parse new intent
        final intent = await IntentRecognizer.instance.parseIntent(spokenText);
        _context.currentIntent = intent;

        // Generate contextual response
        response = await _generateContextualResponse(intent, spokenText);
      }

      // Add to context
      _context.addAssistantMessage(response);

      // Speak response
      await _speakResponse(response);

      // Notify listeners
      if (onResponse != null) {
        onResponse!(response);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error processing voice command', e, stackTrace);
      await _speakResponse('Sorry, I encountered an error. Could you try again?');
    }
  }

  /// Handle follow-up questions
  Future<String> _handleFollowUp(String followUp) async {
    final previousIntent = _context.currentIntent!;
    final previousMessages = _context.getLastMessages(5);

    final contextualPrompt = '''
Previous conversation:
$previousMessages

User now says: "$followUp"

This is a follow-up to their previous request about ${previousIntent.type.name}.

Respond naturally, using the conversation context. Be helpful and conversational.
''';

    return await AIService.instance.chat(contextualPrompt);
  }

  /// Generate contextual response based on intent
  Future<String> _generateContextualResponse(Intent intent, String originalText) async {
    // Quick responses for common intents
    final quickResponse = IntentRecognizer.instance.generateResponse(intent);

    // If high confidence and simple intent, return quick response
    if (intent.confidence > 0.9 && _isSimpleIntent(intent.type)) {
      return quickResponse;
    }

    // For complex intents, use AI with context
    final userName = UserProfile.instance.userName ?? 'there';
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'morning' : (hour < 17 ? 'afternoon' : 'evening');

    final prompt = '''
You are Dona, an elite personal assistant inspired by Donna Paulsen from Suits.

Personality:
- Confident and capable
- Warm but professional
- Slightly witty, never patronizing
- Anticipates needs
- Addresses user naturally

User said: "$originalText"
Intent detected: ${intent.type.name}
Confidence: ${intent.confidence}

Context:
- User's name: $userName
- Time: $greeting
- User prefers: ${UserProfile.instance.prefersConciseMessages ? 'concise messages' : 'detailed explanations'}

Generate a response that:
1. Acknowledges their request
2. Takes action or asks for clarification
3. Is natural and conversational
4. Matches Dona's personality

Keep it brief (1-2 sentences) unless more detail is needed.
''';

    return await AIService.instance.chat(prompt);
  }

  /// Check if intent is simple (doesn't need AI elaboration)
  bool _isSimpleIntent(IntentType type) {
    return [
      IntentType.greeting,
      IntentType.checkWeather,
      IntentType.checkCalendar,
    ].contains(type);
  }

  /// Speak response (text-to-speech)
  Future<void> _speakResponse(String text) async {
    _isSpeaking = true;
    _updateState(VoiceAssistantState.speaking);

    AppLogger.debug('Speaking: $text');

    // In production, integrate with flutter_tts
    // Simulate speaking duration
    await Future.delayed(Duration(milliseconds: text.length * 50));

    _isSpeaking = false;
    _updateState(VoiceAssistantState.idle);
  }

  /// Update transcription as user speaks
  void updateTranscription(String text) {
    _currentTranscription = text;
    if (onTranscriptionUpdate != null) {
      onTranscriptionUpdate!(text);
    }
  }

  /// Update state
  void _updateState(VoiceAssistantState state) {
    if (onStateChange != null) {
      onStateChange!(state);
    }
  }

  /// Quick voice command shortcuts
  Future<void> triggerCommand(VoiceCommand command) async {
    switch (command) {
      case VoiceCommand.morningBriefing:
        await _processVoiceCommand('Give me my morning briefing');
        break;
      case VoiceCommand.checkCalendar:
        await _processVoiceCommand('What\'s on my calendar today?');
        break;
      case VoiceCommand.checkWeather:
        await _processVoiceCommand('What\'s the weather?');
        break;
      case VoiceCommand.readNews:
        await _processVoiceCommand('Read me the news');
        break;
      case VoiceCommand.todayTasks:
        await _processVoiceCommand('What tasks do I have today?');
        break;
    }
  }

  /// Wake word detection (passive listening)
  void startWakeWordDetection() {
    AppLogger.info('Wake word detection started (Hey Dona)');
    // In production, implement wake word detection
    // When "Hey Dona" is detected, call startListening()
  }

  void stopWakeWordDetection() {
    AppLogger.info('Wake word detection stopped');
  }

  /// Clear conversation context
  void clearContext() {
    _context.clear();
    AppLogger.info('Conversation context cleared');
  }

  /// Get conversation history
  List<Message> get conversationHistory => _context.messages;

  /// Current state
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  VoiceAssistantState get currentState {
    if (_isListening) return VoiceAssistantState.listening;
    if (_isSpeaking) return VoiceAssistantState.speaking;
    return VoiceAssistantState.idle;
  }
}

enum VoiceAssistantState {
  idle,
  listening,
  processing,
  speaking,
}

enum VoiceCommand {
  morningBriefing,
  checkCalendar,
  checkWeather,
  readNews,
  todayTasks,
}
