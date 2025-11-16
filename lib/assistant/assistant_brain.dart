import 'persona_manager.dart';
import 'persona_profiles.dart';
import 'prompts.dart';
import '../services/ai/ai_service.dart';
import '../core/utils/logger.dart';

/// The central brain of Dona that orchestrates AI responses
/// with persona, context, and intelligent routing
class AssistantBrain {
  static final AssistantBrain _instance = AssistantBrain._internal();
  static AssistantBrain get instance => _instance;

  AssistantBrain._internal();

  Future<void> init() async {
    try {
      await PersonaManager.instance.init();
      AppLogger.info('AssistantBrain initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AssistantBrain', e, stackTrace);
    }
  }

  /// Generate a reply with full context awareness
  Future<String> generateReply({
    required String userMessage,
    ConversationContext? context,
    PersonaProfile? overridePersona,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      final persona = overridePersona ?? PersonaManager.instance.currentPersona;

      // Build the system prompt with context
      final systemPrompt = _buildSystemPrompt(
        persona: persona,
        context: context,
        additionalContext: additionalContext,
      );

      // Prepare conversation history
      final conversationHistory = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ];

      // Generate response using AI service
      // Note: In future, this will use AiRouter for multi-model support
      final response = await AIService.instance.chat(
        userMessage,
        context: conversationHistory,
      );

      AppLogger.debug('Generated reply with persona: ${persona.name}');
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate reply', e, stackTrace);
      return _getFallbackResponse();
    }
  }

  /// Generate a streaming reply
  Stream<String> generateReplyStream({
    required String userMessage,
    ConversationContext? context,
    PersonaProfile? overridePersona,
  }) async* {
    try {
      final persona = overridePersona ?? PersonaManager.instance.currentPersona;

      // Build the system prompt with context
      final systemPrompt = _buildSystemPrompt(
        persona: persona,
        context: context,
      );

      // For now, use the non-streaming method
      // TODO: Implement true streaming when AI service supports it
      final response = await generateReply(
        userMessage: userMessage,
        context: context,
        overridePersona: overridePersona,
      );

      // Simulate streaming by yielding words
      final words = response.split(' ');
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 50));
        yield '$word ';
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate streaming reply', e, stackTrace);
      yield _getFallbackResponse();
    }
  }

  /// Extract intent from user message
  Future<Map<String, dynamic>> extractIntent(String userMessage) async {
    try {
      final prompt = DonaPrompts.intentExtractionPrompt(userMessage);
      final response = await AIService.instance.chat(prompt);

      // Try to parse JSON response
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        // In production, use jsonDecode here
        // For now, return a basic structure
        return {
          'intent': 'general_chat',
          'entities': {},
          'confidence': 0.7,
          'raw': jsonStr,
        };
      }

      return {
        'intent': 'unknown',
        'entities': {},
        'confidence': 0.0,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract intent', e, stackTrace);
      return {
        'intent': 'error',
        'entities': {},
        'confidence': 0.0,
      };
    }
  }

  /// Generate contextual suggestions
  Future<List<Suggestion>> generateSuggestions({
    required ConversationContext context,
  }) async {
    try {
      final prompt = DonaPrompts.proactiveSuggestionPrompt(
        context: context.summary,
        timeOfDay: context.timeOfDay,
        location: context.location ?? 'unknown',
      );

      final response = await AIService.instance.chat(prompt);

      // Parse suggestions from response
      // TODO: Properly parse JSON array
      return [
        Suggestion(
          text: 'Start a focus session',
          reason: 'Help you concentrate on important work',
          priority: SuggestionPriority.high,
        ),
      ];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate suggestions', e, stackTrace);
      return [];
    }
  }

  /// Build comprehensive system prompt with context
  String _buildSystemPrompt({
    required PersonaProfile persona,
    ConversationContext? context,
    Map<String, dynamic>? additionalContext,
  }) {
    final parts = <String>[persona.systemPrompt];

    if (context != null) {
      parts.add('\n\nCurrent Context:');
      parts.add('Time: ${context.timeOfDay}');
      if (context.location != null) {
        parts.add('Location: ${context.location}');
      }
      if (context.summary.isNotEmpty) {
        parts.add('User context: ${context.summary}');
      }
    }

    if (additionalContext != null && additionalContext.isNotEmpty) {
      parts.add('\n\nAdditional Information:');
      additionalContext.forEach((key, value) {
        parts.add('$key: $value');
      });
    }

    return parts.join('\n');
  }

  /// Get fallback response when AI fails
  String _getFallbackResponse() {
    final persona = PersonaManager.instance.currentPersona;

    if (persona.id == PersonaProfiles.professionalMode.id) {
      return 'I apologize, but I\'m currently experiencing technical difficulties. Please try again in a moment.';
    } else if (persona.id == PersonaProfiles.studyCoach.id) {
      return 'Oops! I\'m having a small technical hiccup. Give me a moment and try again, okay?';
    } else {
      return 'I\'m having trouble connecting right now. Let me try again in a moment.';
    }
  }

  /// Get current persona
  PersonaProfile getCurrentPersona() {
    return PersonaManager.instance.currentPersona;
  }

  /// Switch persona
  Future<bool> switchPersona(String personaId) async {
    return await PersonaManager.instance.switchPersona(personaId);
  }

  /// Get all available personas
  List<PersonaProfile> getAllPersonas() {
    return PersonaManager.instance.getAllPersonas();
  }
}

/// Conversation context for intelligent responses
class ConversationContext {
  final String summary;
  final String timeOfDay;
  final String? location;
  final List<String> recentTopics;
  final Map<String, dynamic> metadata;

  const ConversationContext({
    required this.summary,
    required this.timeOfDay,
    this.location,
    this.recentTopics = const [],
    this.metadata = const {},
  });

  factory ConversationContext.fromMap(Map<String, dynamic> map) {
    return ConversationContext(
      summary: map['summary'] as String? ?? '',
      timeOfDay: map['timeOfDay'] as String? ?? 'unknown',
      location: map['location'] as String?,
      recentTopics: (map['recentTopics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'timeOfDay': timeOfDay,
      'location': location,
      'recentTopics': recentTopics,
      'metadata': metadata,
    };
  }
}

/// AI-generated suggestion
class Suggestion {
  final String text;
  final String reason;
  final SuggestionPriority priority;
  final Map<String, dynamic>? metadata;

  const Suggestion({
    required this.text,
    required this.reason,
    required this.priority,
    this.metadata,
  });
}

enum SuggestionPriority {
  low,
  medium,
  high,
}
