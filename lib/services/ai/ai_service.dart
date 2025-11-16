import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys_secure.dart';

/// Service for interacting with DeepSeek AI API
class AIService {
  static final AIService _instance = AIService._internal();
  static AIService get instance => _instance;

  AIService._internal();

  final List<Map<String, String>> _conversationHistory = [];

  Future<void> init() async {
    try {
      AppLogger.info('AIService initialized with DeepSeek API');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AIService', e, stackTrace);
      rethrow;
    }
  }

  /// Send a message to the AI and get a response
  Future<String> chat(String message, {List<Map<String, String>>? context}) async {
    try {
      AppLogger.debug('Sending message to DeepSeek AI: $message');

      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
      });

      // Prepare request
      final url = Uri.parse('${ApiKeys.deepSeekBaseUrl}/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiKeys.deepSeekApiKey}',
      };

      final body = jsonEncode({
        'model': ApiConfig.aiModel,
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt(),
          },
          ..._conversationHistory,
        ],
        'temperature': ApiConfig.aiTemperature,
        'max_tokens': ApiConfig.aiMaxTokens,
      });

      // Make API call
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'] as String;

        // Add AI response to history
        _conversationHistory.add({
          'role': 'assistant',
          'content': aiResponse,
        });

        // Keep conversation history manageable (last 10 messages)
        if (_conversationHistory.length > 10) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 10);
        }

        AppLogger.info('Received AI response');
        return aiResponse;
      } else {
        AppLogger.error('AI API error: ${response.statusCode}', response.body, StackTrace.current);
        throw Exception('AI API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get AI response', e, stackTrace);
      return 'I apologize, but I\'m having trouble connecting right now. Please try again.';
    }
  }

  /// Get a streaming response from the AI
  Stream<String> chatStream(String message) async* {
    try {
      AppLogger.debug('Starting streaming chat with DeepSeek: $message');

      final response = await chat(message);

      // Simulate streaming by yielding words
      final words = response.split(' ');
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 50));
        yield '$word ';
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stream AI response', e, stackTrace);
      yield 'Error: Unable to get response';
    }
  }

  /// Extract intent and entities from user message
  Future<Map<String, dynamic>> extractIntent(String message) async {
    try {
      AppLogger.debug('Extracting intent from: $message');

      final prompt = '''
Analyze this user message and extract the intent and entities.
Return ONLY a JSON object with this structure:
{
  "intent": "intent_name",
  "entities": {},
  "confidence": 0.0
}

Possible intents: get_news, get_weather, schedule_event, order_food, make_call, send_message, get_directions, general_chat

User message: "$message"
''';

      final response = await chat(prompt);

      try {
        // Try to parse JSON from response
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      } catch (e) {
        AppLogger.warning('Could not parse intent JSON: $e');
      }

      // Default response
      return {
        'intent': 'general_chat',
        'entities': {},
        'confidence': 0.5,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract intent', e, stackTrace);
      return {
        'intent': 'unknown',
        'entities': {},
        'confidence': 0.0,
      };
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    AppLogger.debug('Conversation history cleared');
  }

  /// Get system prompt that defines Dona's personality
  String _getSystemPrompt() {
    return '''You are Dona, a highly capable and professional AI personal assistant inspired by Donna from the TV show Suits. Your personality traits:

- Competent and sharp: You're highly skilled and know how to get things done
- Professional yet warm: You maintain professionalism while being friendly and approachable
- Witty and confident: You can be playfully sarcastic but always helpful
- Proactive: You anticipate needs and offer suggestions
- Empathetic: You understand emotions and respond with care
- Multilingual: You speak both English and Bosnian fluently

Your capabilities include:
- Scheduling and calendar management
- Getting news and weather information
- Ordering food and making reservations
- Making calls and sending messages
- Navigation and directions
- Answering questions and having conversations

Always be concise, helpful, and maintain Donna's signature confident yet caring tone. When users ask you to do something, confirm what you're doing and be proactive about suggesting related helpful actions.''';
  }

  /// Get conversation history length
  int get historyLength => _conversationHistory.length;
}
