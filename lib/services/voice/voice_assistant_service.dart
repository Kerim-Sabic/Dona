import 'dart:async';
import '../../core/utils/logger.dart';
import '../ai/ai_service.dart';
import '../student/assignment_manager.dart';
import '../student/exam_manager.dart';
import '../student/course_manager.dart';
import '../gamification/gamification_service.dart';

/// Voice Assistant Service
/// Enables hands-free interaction with Dona via voice commands
///
/// Commands supported:
/// - "Hey Dona, what's my next class?"
/// - "Hey Dona, when is my next assignment due?"
/// - "Hey Dona, create flashcards for Biology Chapter 5"
/// - "Hey Dona, what's my current GPA?"
/// - "Hey Dona, how many days is my study streak?"
class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  static VoiceAssistantService get instance => _instance;

  VoiceAssistantService._internal();

  bool _isListening = false;
  bool _isProcessing = false;
  String? _lastCommand;

  // Callbacks for UI
  Function(String)? onCommandRecognized;
  Function(String)? onResponseGenerated;
  Function(bool)? on ListeningStateChanged;
  Function(String)? onError;

  /// Initialize voice assistant
  Future<void> init() async {
    try {
      AppLogger.info('VoiceAssistantService initialized - Web Speech API ready');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize VoiceAssistantService', e, stackTrace);
    }
  }

  /// Start listening for voice input
  /// NOTE: Requires Web Speech API (browser native) or speech_to_text package
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _isListening = true;
      onListeningStateChanged?.call(true);

      // In production, this would use:
      // - Web: window.webkitSpeechRecognition (Chrome)
      // - Mobile: speech_to_text package
      // - Wake word: Picovoice Porcupine

      AppLogger.info('🎤 Voice assistant listening...');

      // Simulated for now - production would integrate actual speech recognition
      _simulateSpeechRecognition();
    } catch (e, stackTrace) {
      AppLogger.error('Error starting voice recognition', e, stackTrace);
      onError?.call('Failed to start listening: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  /// Stop listening
  void stopListening() {
    _isListening = false;
    onListeningStateChanged?.call(false);
    AppLogger.info('🎤 Voice assistant stopped');
  }

  /// Process voice command
  Future<void> processCommand(String command) async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      _lastCommand = command;
      onCommandRecognized?.call(command);

      AppLogger.info('🎤 Processing command: "$command"');

      // Check for direct commands first (faster response)
      final response = await _handleDirectCommand(command) ??
                      await _handleAICommand(command);

      onResponseGenerated?.call(response);

      // Text-to-speech response
      await _speak(response);

      _isProcessing = false;
    } catch (e, stackTrace) {
      AppLogger.error('Error processing voice command', e, stackTrace);
      onError?.call('Sorry, I couldn\'t process that command');
      _isProcessing = false;
    }
  }

  /// Handle direct commands (pattern matching for speed)
  Future<String?> _handleDirectCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    try {
      // Next class
      if (lowerCommand.contains('next class')) {
        final nextClass = CourseManager.instance.getNextClass();
        if (nextClass != null) {
          return 'Your next class is ${nextClass.code} at ${_formatTime(nextClass.startTime!)}';
        }
        return 'You don\'t have any more classes today';
      }

      // Today's classes
      if (lowerCommand.contains('today\'s classes') || lowerCommand.contains('classes today')) {
        final todaysClasses = CourseManager.instance.getTodaysClasses();
        if (todaysClasses.isEmpty) {
          return 'You don\'t have any classes today';
        }
        return 'You have ${todaysClasses.length} classes today: ${todaysClasses.map((c) => c.code).join(", ")}';
      }

      // Next assignment
      if (lowerCommand.contains('next assignment') || lowerCommand.contains('assignment due')) {
        final upcoming = AssignmentManager.instance.getUpcomingAssignments(limit: 1);
        if (upcoming.isEmpty) {
          return 'You don\'t have any upcoming assignments';
        }
        final assignment = upcoming.first;
        final hoursUntil = assignment.dueDate.difference(DateTime.now()).inHours;
        return '${assignment.title} is due in $hoursUntil hours';
      }

      // Study streak
      if (lowerCommand.contains('study streak') || lowerCommand.contains('streak')) {
        final streak = GamificationService.instance.progress.studyStreak;
        if (streak == 0) {
          return 'Start a study session today to begin your streak!';
        }
        return 'Your study streak is $streak day${streak == 1 ? '' : 's'}! Keep it up!';
      }

      // Level/XP
      if (lowerCommand.contains('my level') || lowerCommand.contains('how much xp')) {
        final progress = GamificationService.instance.progress;
        return 'You\'re level ${progress.currentLevel} with ${progress.totalXP} total XP. ${progress.currentLevelXP} XP towards level ${progress.currentLevel + 1}!';
      }

      // Upcoming exams
      if (lowerCommand.contains('exam') && !lowerCommand.contains('create')) {
        final upcomingExams = ExamManager.instance.upcomingExams.take(3).toList();
        if (upcomingExams.isEmpty) {
          return 'You don\'t have any upcoming exams';
        }
        final examsList = upcomingExams.map((e) => '${e.title} in ${e.daysUntil} days').join(', ');
        return 'Your upcoming exams: $examsList';
      }

      // Overdue assignments
      if (lowerCommand.contains('overdue')) {
        final overdue = AssignmentManager.instance.overdueAssignments;
        if (overdue.isEmpty) {
          return 'Great news! You don\'t have any overdue assignments!';
        }
        return 'You have ${overdue.length} overdue assignment${overdue.length == 1 ? '' : 's'}. Would you like to see them?';
      }

      return null; // No direct command matched, use AI
    } catch (e) {
      AppLogger.error('Error in direct command handling', e);
      return null;
    }
  }

  /// Handle command with AI (for complex queries)
  Future<String> _handleAICommand(String command) async {
    try {
      // Get context
      final progress = GamificationService.instance.progress;
      final upcomingAssignments = AssignmentManager.instance.getUpcomingAssignments(limit: 5);
      final upcomingExams = ExamManager.instance.upcomingExams.take(3).toList();
      final todaysClasses = CourseManager.instance.getTodaysClasses();

      final context = '''
User Info:
- Level: ${progress.currentLevel}
- Study Streak: ${progress.studyStreak} days
- Today's Classes: ${todaysClasses.map((c) => c.code).join(", ")}
- Upcoming Assignments: ${upcomingAssignments.length}
- Upcoming Exams: ${upcomingExams.length}

User Command: "$command"

Task: Respond to the user's voice command as Dona, their AI assistant. Be:
- Helpful and concise (1-2 sentences max)
- Encouraging and friendly
- Action-oriented (suggest next steps)
- Natural and conversational

If the command requires an action (create, schedule, etc.), acknowledge and confirm what you'll do.

Return ONLY your response, nothing else.
''';

      final response = await AIService.instance.chat(context);
      return response.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Error in AI command handling', e, stackTrace);
      return 'I\'m sorry, I had trouble processing that. Could you try again?';
    }
  }

  /// Speak text response (Text-to-Speech)
  Future<void> _speak(String text) async {
    try {
      // In production, this would use:
      // - Web: window.speechSynthesis (browser native TTS)
      // - Mobile: flutter_tts package
      // - Premium: ElevenLabs API for natural voice

      AppLogger.info('🔊 Speaking: "$text"');

      // Simulated for now - production would integrate actual TTS
      // Example Web implementation:
      // js.context.callMethod('eval', ['window.speechSynthesis.speak(new SpeechSynthesisUtterance("$text"))']);
    } catch (e, stackTrace) {
      AppLogger.error('Error in text-to-speech', e, stackTrace);
    }
  }

  /// Format time for speech
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Simulated speech recognition (for testing)
  void _simulateSpeechRecognition() {
    // In production, this would listen to actual microphone input
    // For now, it's a placeholder that the UI can trigger
  }

  /// Check if wake word is enabled
  /// In production, this would use Picovoice Porcupine for "Hey Dona" detection
  bool get isWakeWordEnabled => false; // Placeholder

  /// Enable wake word detection
  Future<void> enableWakeWord() async {
    // In production:
    // 1. Initialize Picovoice Porcupine
    // 2. Train on "Hey Dona" wake word
    // 3. Start background listening
    // 4. Trigger startListening() when detected

    AppLogger.info('Wake word "Hey Dona" enabled (placeholder)');
  }

  /// Disable wake word detection
  void disableWakeWord() {
    AppLogger.info('Wake word disabled');
  }

  /// Get suggested commands for user
  List<String> getSuggestedCommands() {
    return [
      "What's my next class?",
      "When is my next assignment due?",
      "How many days is my study streak?",
      "What's my current level?",
      "Do I have any exams this week?",
      "Show me my overdue assignments",
      "Create flashcards for Biology",
      "Start a study session",
      "What should I focus on today?",
    ];
  }

  /// Process text command (for testing without speech recognition)
  Future<void> processTextCommand(String text) async {
    await processCommand(text);
  }
}

/// Voice command intent
enum VoiceIntent {
  query,        // Asking for information
  action,       // Requesting an action
  navigation,   // Navigating the app
  conversation, // General chat
}

/// Voice command parser
class VoiceCommandParser {
  /// Parse command to determine intent
  static VoiceIntent parseIntent(String command) {
    final lower = command.toLowerCase();

    // Action words
    if (lower.contains('create') ||
        lower.contains('start') ||
        lower.contains('add') ||
        lower.contains('schedule')) {
      return VoiceIntent.action;
    }

    // Navigation words
    if (lower.contains('show') ||
        lower.contains('open') ||
        lower.contains('go to')) {
      return VoiceIntent.navigation;
    }

    // Question words
    if (lower.contains('what') ||
        lower.contains('when') ||
        lower.contains('how') ||
        lower.contains('why') ||
        lower.contains('where')) {
      return VoiceIntent.query;
    }

    // Default to conversation
    return VoiceIntent.conversation;
  }

  /// Extract entity from command
  static Map<String, String> extractEntities(String command) {
    final entities = <String, String>{};
    final lower = command.toLowerCase();

    // Extract course name
    final coursePattern = RegExp(r'(biology|chemistry|physics|math|cs\d+|history)', caseSensitive: false);
    final courseMatch = coursePattern.firstMatch(lower);
    if (courseMatch != null) {
      entities['course'] = courseMatch.group(0)!;
    }

    // Extract time expressions
    if (lower.contains('today')) entities['time'] = 'today';
    if (lower.contains('tomorrow')) entities['time'] = 'tomorrow';
    if (lower.contains('this week')) entities['time'] = 'this_week';

    return entities;
  }
}
