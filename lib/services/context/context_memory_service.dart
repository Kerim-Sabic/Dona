import 'dart:async';
import 'package:hive/hive.dart';
import '../../core/utils/logger.dart';

/// Conversation message model
class ConversationMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// User preference model
class UserPreference {
  final String key;
  final dynamic value;
  final DateTime lastUpdated;

  UserPreference({
    required this.key,
    required this.value,
    required this.lastUpdated,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      key: json['key'] ?? '',
      value: json['value'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Context & Memory Service
/// Maintains conversation history, user preferences, and contextual memory
class ContextMemoryService {
  static final ContextMemoryService _instance = ContextMemoryService._internal();
  static ContextMemoryService get instance => _instance;

  ContextMemoryService._internal();

  Box? _conversationBox;
  Box? _preferencesBox;
  Box? _contextBox;

  final List<ConversationMessage> _shortTermMemory = [];
  static const int _maxShortTermMessages = 50;
  static const Duration _sessionTimeout = Duration(hours: 2);

  DateTime _lastInteraction = DateTime.now();
  String? _currentSession;

  Future<void> init() async {
    try {
      _conversationBox = await Hive.openBox('conversation_history');
      _preferencesBox = await Hive.openBox('user_preferences');
      _contextBox = await Hive.openBox('context_memory');

      _currentSession = DateTime.now().millisecondsSinceEpoch.toString();

      // Load recent messages into short-term memory
      await _loadRecentMessages();

      AppLogger.info('ContextMemoryService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ContextMemoryService', e, stackTrace);
    }
  }

  /// Add user message to conversation
  Future<void> addUserMessage(String content, {Map<String, dynamic>? metadata}) async {
    await _addMessage('user', content, metadata);
    _lastInteraction = DateTime.now();
  }

  /// Add assistant message to conversation
  Future<void> addAssistantMessage(String content, {Map<String, dynamic>? metadata}) async {
    await _addMessage('assistant', content, metadata);
    _lastInteraction = DateTime.now();
  }

  Future<void> _addMessage(String role, String content, Map<String, dynamic>? metadata) async {
    try {
      final message = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: role,
        content: content,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      // Add to short-term memory
      _shortTermMemory.add(message);
      if (_shortTermMemory.length > _maxShortTermMessages) {
        _shortTermMemory.removeAt(0);
      }

      // Save to persistent storage
      await _conversationBox?.put(message.id, message.toJson());

      AppLogger.debug('Added $role message to context');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add message', e, stackTrace);
    }
  }

  /// Get recent conversation history
  Future<List<ConversationMessage>> getRecentConversation({int limit = 20}) async {
    try {
      if (_shortTermMemory.length <= limit) {
        return List.from(_shortTermMemory);
      }

      return _shortTermMemory.sublist(_shortTermMemory.length - limit);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get recent conversation', e, stackTrace);
      return [];
    }
  }

  /// Get conversation history for a date range
  Future<List<ConversationMessage>> getConversationHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final messages = <ConversationMessage>[];

      if (_conversationBox == null) return messages;

      for (var key in _conversationBox!.keys) {
        final messageJson = _conversationBox!.get(key);
        if (messageJson != null) {
          final message = ConversationMessage.fromJson(Map<String, dynamic>.from(messageJson));

          if (startDate != null && message.timestamp.isBefore(startDate)) continue;
          if (endDate != null && message.timestamp.isAfter(endDate)) continue;

          messages.add(message);
        }
      }

      // Sort by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get conversation history', e, stackTrace);
      return [];
    }
  }

  /// Set user preference
  Future<void> setPreference(String key, dynamic value) async {
    try {
      final preference = UserPreference(
        key: key,
        value: value,
        lastUpdated: DateTime.now(),
      );

      await _preferencesBox?.put(key, preference.toJson());
      AppLogger.debug('Set preference: $key = $value');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set preference', e, stackTrace);
    }
  }

  /// Get user preference
  Future<dynamic> getPreference(String key, {dynamic defaultValue}) async {
    try {
      final preferenceJson = _preferencesBox?.get(key);
      if (preferenceJson == null) return defaultValue;

      final preference = UserPreference.fromJson(Map<String, dynamic>.from(preferenceJson));
      return preference.value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get preference', e, stackTrace);
      return defaultValue;
    }
  }

  /// Save contextual information
  Future<void> saveContext(String key, dynamic value) async {
    try {
      await _contextBox?.put(key, {
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save context', e, stackTrace);
    }
  }

  /// Get contextual information
  Future<dynamic> getContext(String key) async {
    try {
      final contextData = _contextBox?.get(key);
      if (contextData == null) return null;

      return contextData['value'];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get context', e, stackTrace);
      return null;
    }
  }

  /// Clear old conversation history
  Future<void> clearOldHistory({Duration age = const Duration(days: 30)}) async {
    try {
      final cutoffDate = DateTime.now().subtract(age);
      final keysToDelete = <String>[];

      if (_conversationBox == null) return;

      for (var key in _conversationBox!.keys) {
        final messageJson = _conversationBox!.get(key);
        if (messageJson != null) {
          final message = ConversationMessage.fromJson(Map<String, dynamic>.from(messageJson));
          if (message.timestamp.isBefore(cutoffDate)) {
            keysToDelete.add(key);
          }
        }
      }

      for (var key in keysToDelete) {
        await _conversationBox?.delete(key);
      }

      AppLogger.info('Cleared ${keysToDelete.length} old conversation messages');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear old history', e, stackTrace);
    }
  }

  /// Check if session is still active
  bool isSessionActive() {
    final elapsed = DateTime.now().difference(_lastInteraction);
    return elapsed < _sessionTimeout;
  }

  /// Start new session
  void startNewSession() {
    _currentSession = DateTime.now().millisecondsSinceEpoch.toString();
    _shortTermMemory.clear();
    _lastInteraction = DateTime.now();
    AppLogger.info('Started new conversation session');
  }

  /// Get session summary
  Future<String> getSessionSummary() async {
    try {
      final messages = await getRecentConversation();
      final userMessages = messages.where((m) => m.role == 'user').length;
      final assistantMessages = messages.where((m) => m.role == 'assistant').length;
      final duration = DateTime.now().difference(_lastInteraction);

      return '''
📊 Session Summary:

🆔 Session: ${_currentSession?.substring(0, 8)}...
⏱️ Duration: ${_formatDuration(duration)}
💬 Messages: ${messages.length} total
   • User: $userMessages
   • Assistant: $assistantMessages
🔄 Status: ${isSessionActive() ? "Active" : "Inactive"}
''';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get session summary', e, stackTrace);
      return 'Unable to generate session summary.';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Load recent messages from storage
  Future<void> _loadRecentMessages() async {
    try {
      if (_conversationBox == null) return;

      final messages = <ConversationMessage>[];

      for (var key in _conversationBox!.keys) {
        final messageJson = _conversationBox!.get(key);
        if (messageJson != null) {
          messages.add(ConversationMessage.fromJson(Map<String, dynamic>.from(messageJson)));
        }
      }

      // Sort by timestamp and take last N messages
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (messages.length > _maxShortTermMessages) {
        _shortTermMemory.addAll(messages.sublist(messages.length - _maxShortTermMessages));
      } else {
        _shortTermMemory.addAll(messages);
      }

      AppLogger.info('Loaded ${_shortTermMemory.length} messages into short-term memory');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load recent messages', e, stackTrace);
    }
  }

  /// Export conversation history
  Future<String> exportConversation({DateTime? startDate, DateTime? endDate}) async {
    try {
      final messages = await getConversationHistory(startDate: startDate, endDate: endDate);

      final buffer = StringBuffer();
      buffer.writeln('=== Conversation Export ===\n');
      buffer.writeln('Generated: ${DateTime.now()}\n');

      if (startDate != null || endDate != null) {
        buffer.writeln('Date Range: ${startDate ?? "Beginning"} to ${endDate ?? "Now"}\n');
      }

      buffer.writeln('Total Messages: ${messages.length}\n');
      buffer.writeln('===========================\n\n');

      for (var message in messages) {
        buffer.writeln('[${message.timestamp}] ${message.role.toUpperCase()}:');
        buffer.writeln(message.content);
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export conversation', e, stackTrace);
      return 'Unable to export conversation.';
    }
  }
}
