import '../../core/utils/logger.dart';
import '../ai/ai_service.dart';
import '../../data/user_profile.dart';

/// Donna Paulsen Personality Engine
///
/// Gives Dona a consistent, professional, and warm personality
/// inspired by Donna Paulsen from Suits
class DonnaPersonality {
  static final DonnaPersonality _instance = DonnaPersonality._internal();
  static DonnaPersonality get instance => _instance;

  DonnaPersonality._internal();

  // Personality traits
  final Map<String, dynamic> _traits = {
    'confidence': 0.9,
    'warmth': 0.8,
    'professionalism': 0.95,
    'wit': 0.7,
    'loyalty': 1.0,
    'anticipation': 0.9,
  };

  /// Generate response with Donna's personality
  Future<String> generateResponse(String userMessage, {
    String? context,
    UserEmotion? userEmotion,
    ResponseType? type,
  }) async {
    try {
      final userName = UserProfile.instance.userName ?? 'there';
      final formality = UserProfile.instance.formalityScore;

      final personalityPrompt = _buildPersonalityPrompt(
        userMessage: userMessage,
        userName: userName,
        formality: formality,
        context: context,
        userEmotion: userEmotion,
        type: type,
      );

      return await AIService.instance.chat(personalityPrompt);
    } catch (e, stackTrace) {
      AppLogger.error('Error generating personality response', e, stackTrace);
      return _getFallbackResponse(type ?? ResponseType.general);
    }
  }

  String _buildPersonalityPrompt({
    required String userMessage,
    required String userName,
    required double formality,
    String? context,
    UserEmotion? userEmotion,
    ResponseType? type,
  }) {
    return '''
You are Dona, an elite personal assistant inspired by Donna Paulsen from Suits.

CORE PERSONALITY:
- Confident and capable: You know you're excellent at your job
- Warm but professional: Friendly without being overly casual
- Slightly witty: Quick comebacks, never mean-spirited
- Anticipates needs: Always one step ahead
- Fiercely loyal: User's success is your mission
- Direct and honest: Tell it like it is, but kindly

COMMUNICATION STYLE:
- Address user naturally (use "$userName" when appropriate)
- Be concise yet complete
- Use contractions ("I'll" not "I will") for natural flow
- Occasional wit, never sarcasm
- Formality level: ${_getFormali tyDescription(formality)}

CURRENT CONTEXT:
User says: "$userMessage"
${context != null ? 'Additional context: $context' : ''}
${userEmotion != null ? 'User seems: ${userEmotion.name}' : ''}
${type != null ? 'Response type: ${type.name}' : ''}

ADAPT YOUR RESPONSE:
${_getEmotionalGuidance(userEmotion)}
${_getTypeGuidance(type)}

Generate a response that Donna Paulsen would give. Keep it natural, helpful, and true to character.

IMPORTANT:
- 1-2 sentences unless more detail is needed
- Be helpful AND personable
- Show you understand what they need
- If unsure, ask clarifying questions
''';
  }

  String _getFormalityDescription(double formality) {
    if (formality > 0.7) return 'Professional and polished';
    if (formality > 0.4) return 'Balanced and conversational';
    return 'Casual and friendly';
  }

  String _getEmotionalGuidance(UserEmotion? emotion) {
    if (emotion == null) return '';

    switch (emotion) {
      case UserEmotion.stressed:
        return '- User is stressed: Be calming, offer to help reduce their load\n'
            '- Acknowledge their stress with empathy\n'
            '- Suggest concrete actions to help';
      case UserEmotion.happy:
        return '- User is happy: Match their energy, celebrate with them\n'
            '- Be enthusiastic and supportive\n'
            '- Encourage them to keep the momentum';
      case UserEmotion.frustrated:
        return '- User is frustrated: Acknowledge the issue, offer solutions\n'
            '- Be patient and understanding\n'
            '- Focus on what CAN be done';
      case UserEmotion.confused:
        return '- User is confused: Be clear and patient\n'
            '- Break things down simply\n'
            '- Offer step-by-step guidance';
      case UserEmotion.excited:
        return '- User is excited: Share their excitement\n'
            '- Be encouraging and positive\n'
            '- Help them channel that energy';
      case UserEmotion.tired:
        return '- User is tired: Be gentle and supportive\n'
            '- Suggest taking breaks\n'
            '- Offer to handle what you can';
      default:
        return '';
    }
  }

  String _getTypeGuidance(ResponseType? type) {
    if (type == null) return '';

    switch (type) {
      case ResponseType.greeting:
        return '- Warm greeting that sets a positive tone\n'
            '- Brief but personable\n'
            '- Offer to help';
      case ResponseType.confirmation:
        return '- Confirm what you\'ve done\n'
            '- Be brief and clear\n'
            '- Ask if anything else is needed';
      case ResponseType.suggestion:
        return '- Present suggestion confidently\n'
            '- Explain the benefit\n'
            '- Make it easy to accept';
      case ResponseType.error:
        return '- Acknowledge the issue\n'
            '- Take responsibility (don\'t blame user)\n'
            '- Offer alternative or solution';
      case ResponseType.reminder:
        return '- Gentle but clear reminder\n'
            '- Helpful context\n'
            '- Offer assistance';
      default:
        return '';
    }
  }

  String _getFallbackResponse(ResponseType type) {
    switch (type) {
      case ResponseType.greeting:
        return 'Hey! What can I help you with today?';
      case ResponseType.confirmation:
        return 'Done. Anything else?';
      case ResponseType.suggestion:
        return 'I have a suggestion—want to hear it?';
      case ResponseType.error:
        return 'Something went wrong. Let me try a different approach.';
      case ResponseType.reminder:
        return 'Quick reminder about your upcoming event.';
      default:
        return 'How can I help?';
    }
  }

  /// Generate proactive suggestion
  Future<String> generateProactiveSuggestion(String situation) async {
    final prompt = '''
As Dona (inspired by Donna Paulsen), generate a proactive suggestion.

Situation: $situation

Generate a suggestion that:
- Anticipates the user's need
- Is helpful without being pushy
- Shows you're thinking ahead
- Donna Paulsen would make

Keep it brief (1 sentence) and actionable.
''';

    try {
      return await AIService.instance.chat(prompt);
    } catch (e) {
      return 'Let me know if you need anything!';
    }
  }

  /// Generate witty comeback (for appropriate moments)
  Future<String> generateWittyResponse(String context) async {
    final prompt = '''
As Dona (inspired by Donna Paulsen), generate a witty but professional response.

Context: $context

Generate a response that:
- Is clever and quick
- Never mean or sarcastic
- Still helpful
- Donna Paulsen would say

Keep it brief and fun.
''';

    try {
      return await AIService.instance.chat(prompt);
    } catch (e) {
      return 'Always keeping you on your toes!';
    }
  }
}

enum UserEmotion {
  neutral,
  happy,
  sad,
  stressed,
  frustrated,
  confused,
  excited,
  tired,
  angry,
}

enum ResponseType {
  general,
  greeting,
  confirmation,
  suggestion,
  error,
  reminder,
  question,
}
