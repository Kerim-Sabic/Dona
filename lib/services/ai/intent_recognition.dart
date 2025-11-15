import 'dart:convert';
import '../../core/utils/logger.dart';
import 'ai_service.dart';

/// Recognized intent from user input
class Intent {
  final IntentType type;
  final Map<String, dynamic> entities;
  final IntentUrgency urgency;
  final bool requiresConfirmation;
  final double confidence;
  final String? suggestedAction;

  Intent({
    required this.type,
    this.entities = const {},
    this.urgency = IntentUrgency.normal,
    this.requiresConfirmation = false,
    this.confidence = 1.0,
    this.suggestedAction,
  });

  factory Intent.fromJson(Map<String, dynamic> json) {
    return Intent(
      type: IntentType.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => IntentType.unknown,
      ),
      entities: json['entities'] ?? {},
      urgency: IntentUrgency.values.firstWhere(
        (e) => e.name == json['urgency'],
        orElse: () => IntentUrgency.normal,
      ),
      requiresConfirmation: json['requires_confirmation'] ?? false,
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      suggestedAction: json['suggested_action'],
    );
  }
}

enum IntentType {
  // Calendar & Time
  scheduleEvent,
  rescheduleEvent,
  cancelEvent,
  checkCalendar,

  // Communication
  sendEmail,
  readEmail,
  sendSMS,
  makeCall,

  // Tasks
  createTask,
  completeTask,
  listTasks,

  // Navigation & Location
  navigate,
  findPlace,
  checkTraffic,

  // Information
  checkWeather,
  readNews,
  search,

  // Files & Documents
  uploadFile,
  downloadFile,
  searchFiles,

  // Reminders
  setReminder,
  listReminders,

  // General
  greeting,
  help,
  unknown,
}

enum IntentUrgency { low, normal, high, critical }

/// Service for recognizing user intent from natural language
class IntentRecognizer {
  static final IntentRecognizer _instance = IntentRecognizer._internal();
  static IntentRecognizer get instance => _instance;

  IntentRecognizer._internal();

  /// Parse intent from user input
  Future<Intent> parseIntent(String userInput) async {
    try {
      AppLogger.debug('Parsing intent: $userInput');

      // Quick pattern matching for common intents
      final quickIntent = _tryQuickPatternMatch(userInput);
      if (quickIntent != null) {
        AppLogger.debug('Quick match: ${quickIntent.type.name}');
        return quickIntent;
      }

      // Use AI for complex intent recognition
      final aiIntent = await _parseWithAI(userInput);
      AppLogger.info('Parsed intent: ${aiIntent.type.name}');
      return aiIntent;
    } catch (e, stackTrace) {
      AppLogger.error('Error parsing intent', e, stackTrace);
      return Intent(type: IntentType.unknown, confidence: 0.0);
    }
  }

  /// Quick pattern matching for common intents
  Intent? _tryQuickPatternMatch(String input) {
    final lower = input.toLowerCase().trim();

    // Greetings
    if (_matches(lower, ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'])) {
      return Intent(
        type: IntentType.greeting,
        confidence: 1.0,
      );
    }

    // Help
    if (_matches(lower, ['help', 'what can you do', 'how do i', 'show me'])) {
      return Intent(
        type: IntentType.help,
        confidence: 1.0,
      );
    }

    // Weather
    if (_matches(lower, ['weather', 'temperature', 'forecast', 'rain', 'sunny'])) {
      final city = _extractCity(input);
      return Intent(
        type: IntentType.checkWeather,
        entities: {'city': city},
        confidence: 0.9,
      );
    }

    // Calendar check
    if (_matches(lower, ['what\'s on my calendar', 'my schedule', 'my meetings', 'what do i have'])) {
      return Intent(
        type: IntentType.checkCalendar,
        confidence: 0.9,
      );
    }

    // Navigation
    if (_matches(lower, ['take me to', 'navigate to', 'directions to', 'how do i get to'])) {
      final destination = _extractDestination(input);
      return Intent(
        type: IntentType.navigate,
        entities: {'destination': destination},
        confidence: 0.9,
      );
    }

    return null;
  }

  /// Parse intent using AI
  Future<Intent> _parseWithAI(String userInput) async {
    final prompt = '''
You are an intent recognition system. Analyze the user's request and extract structured data.

User request: "$userInput"

Return JSON with this exact structure:
{
  "intent": "scheduleEvent|sendEmail|checkWeather|navigate|etc",
  "entities": {
    "who": "person name if mentioned",
    "what": "main subject/topic",
    "when": "date/time if mentioned",
    "where": "location if mentioned",
    "why": "reason/context if mentioned"
  },
  "urgency": "low|normal|high|critical",
  "requires_confirmation": true or false,
  "confidence": 0.0 to 1.0,
  "suggested_action": "brief description of what should be done"
}

Intent types:
- scheduleEvent: Create calendar event
- sendEmail: Send an email
- sendSMS: Send text message
- checkWeather: Get weather info
- navigate: Get directions
- createTask: Add to todo list
- search: Search for information

Examples:

Input: "Schedule a meeting with John tomorrow at 2pm to discuss budget"
Output: {
  "intent": "scheduleEvent",
  "entities": {
    "who": "John",
    "what": "Meeting about budget",
    "when": "tomorrow 2pm",
    "where": null
  },
  "urgency": "normal",
  "requires_confirmation": true,
  "confidence": 0.95,
  "suggested_action": "Create calendar event with John tomorrow at 2pm"
}

Input: "What's the weather?"
Output: {
  "intent": "checkWeather",
  "entities": {
    "where": "current location"
  },
  "urgency": "low",
  "requires_confirmation": false,
  "confidence": 1.0,
  "suggested_action": "Fetch current weather"
}

Now analyze: "$userInput"

Return ONLY the JSON, no other text.
''';

    try {
      final response = await AIService.instance.chat(prompt);

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr);
        return Intent.fromJson(data);
      }

      // Fallback
      return Intent(type: IntentType.unknown, confidence: 0.0);
    } catch (e, stackTrace) {
      AppLogger.error('Error parsing with AI', e, stackTrace);
      return Intent(type: IntentType.unknown, confidence: 0.0);
    }
  }

  /// Check if input matches any pattern
  bool _matches(String input, List<String> patterns) {
    return patterns.any((pattern) => input.contains(pattern));
  }

  /// Extract city from weather query
  String? _extractCity(String input) {
    // Simple extraction - in production would use NER
    final matches = RegExp(r'\bin\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false).allMatches(input);
    if (matches.isNotEmpty) {
      return matches.first.group(1);
    }
    return null;
  }

  /// Extract destination from navigation query
  String _extractDestination(String input) {
    // Remove common prefixes
    String dest = input.toLowerCase()
        .replaceAll('take me to', '')
        .replaceAll('navigate to', '')
        .replaceAll('directions to', '')
        .replaceAll('how do i get to', '')
        .trim();

    return dest;
  }

  /// Generate contextual response based on intent
  String generateResponse(Intent intent) {
    switch (intent.type) {
      case IntentType.scheduleEvent:
        final who = intent.entities['who'];
        final when = intent.entities['when'];
        if (who != null && when != null) {
          return 'I\'ll schedule a meeting with $who for $when. Let me check your calendar...';
        }
        return 'I\'ll help you schedule that. When would you like to meet?';

      case IntentType.checkWeather:
        final city = intent.entities['where'] ?? intent.entities['city'];
        if (city != null) {
          return 'Let me check the weather in $city...';
        }
        return 'Checking the weather for you...';

      case IntentType.navigate:
        final dest = intent.entities['destination'] ?? intent.entities['where'];
        if (dest != null) {
          return 'Getting directions to $dest...';
        }
        return 'Where would you like to go?';

      case IntentType.sendEmail:
        final who = intent.entities['who'];
        if (who != null) {
          return 'I\'ll draft an email to $who. What should I say?';
        }
        return 'Who would you like to email?';

      case IntentType.greeting:
        final hour = DateTime.now().hour;
        if (hour < 12) return 'Good morning! How can I help?';
        if (hour < 17) return 'Good afternoon! What can I do for you?';
        return 'Good evening! How may I assist you?';

      case IntentType.help:
        return 'I can help you with:\n'
            '- Scheduling meetings\n'
            '- Checking weather\n'
            '- Sending emails\n'
            '- Navigation\n'
            '- Managing tasks\n'
            'What would you like to do?';

      case IntentType.unknown:
        return 'I\'m not sure I understood that. Could you rephrase?';

      default:
        return 'Let me help you with that...';
    }
  }
}

/// Conversation context for multi-turn dialogue
class ConversationContext {
  final List<Message> messages = [];
  Intent? currentIntent;
  Map<String, dynamic> collectedEntities = {};

  void addUserMessage(String text) {
    messages.add(Message(role: 'user', content: text, timestamp: DateTime.now()));

    // Keep only last 10 messages
    if (messages.length > 10) {
      messages.removeAt(0);
    }
  }

  void addAssistantMessage(String text) {
    messages.add(Message(role: 'assistant', content: text, timestamp: DateTime.now()));
  }

  String getLastMessages(int count) {
    final recent = messages.length > count ? messages.sublist(messages.length - count) : messages;
    return recent.map((m) => '${m.role}: ${m.content}').join('\n');
  }

  bool isFollowUp(String text) {
    if (messages.isEmpty) return false;

    final followUpPatterns = [
      'yes',
      'no',
      'sure',
      'okay',
      'what about',
      'and',
      'also',
      'tomorrow',
      'later',
    ];

    return followUpPatterns.any((pattern) => text.toLowerCase().contains(pattern));
  }

  void clear() {
    messages.clear();
    currentIntent = null;
    collectedEntities.clear();
  }
}

class Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
