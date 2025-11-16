import 'package:uuid/uuid.dart';
import '../autopilot_models.dart';
import '../autopilot_engine.dart';
import '../../../assistant/context/context_engine.dart';
import '../../../assistant/memory/memory_engine.dart';
import '../../../core/utils/logger.dart';
import '../../../services/calendar/calendar_service.dart';
import '../../../data/models/memory/memory.dart';

/// Relationship Autopilot
///
/// Helps maintain important relationships by:
/// - Identifying people to reconnect with
/// - Reminding about birthdays and anniversaries
/// - Suggesting check-ins for key relationships
/// - Creating reminder tasks (NEVER sends messages automatically)
/// - All suggestions require explicit user approval
///
/// Privacy-First Design:
/// - Only uses relationship hints from memories
/// - Never stores full conversations
/// - All actions are reminders/tasks, not direct messages
/// - Respects user privacy and relationship boundaries
class RelationshipAutopilot {
  static final RelationshipAutopilot _instance = RelationshipAutopilot._internal();
  static RelationshipAutopilot get instance => _instance;

  RelationshipAutopilot._internal();

  final _uuid = const Uuid();

  /// Generate a Relationship autopilot plan
  Future<AutopilotPlan> generatePlan({
    Map<String, dynamic>? preferences,
  }) async {
    try {
      AppLogger.info('Generating Relationship autopilot');

      // Analyze relationships from memories and calendar
      final analysis = await _analyzeRelationships();

      // Build gentle relationship maintenance suggestions
      final actions = await _buildRelationshipActions(analysis, preferences);

      final plan = AutopilotPlan(
        id: _uuid.v4(),
        intentId: _uuid.v4(),
        planName: 'Relationship Maintenance',
        description: 'Stay connected with important people in your life',
        actions: actions,
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      AppLogger.info('Generated Relationship autopilot with ${actions.length} actions');
      return plan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate Relationship autopilot', e, stackTrace);
      rethrow;
    }
  }

  /// Analyze relationships from memories and events
  Future<RelationshipAnalysis> _analyzeRelationships() async {
    try {
      // Get relationship-related memories
      final relationshipMemories = await MemoryEngine.instance.searchMemories(
        'relationship',
        category: MemoryCategory.relationship,
        limit: 20,
      );

      // Get upcoming birthdays/anniversaries from calendar
      final upcomingEvents = await CalendarService.instance.getEvents(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      final birthdays = upcomingEvents.where((e) =>
        e.summary.toLowerCase().contains('birthday') ||
        e.summary.toLowerCase().contains('anniversary')
      ).toList();

      // Identify people to reconnect with (simplified logic)
      final reconnectSuggestions = _identifyReconnectOpportunities(relationshipMemories);

      return RelationshipAnalysis(
        totalRelationships: relationshipMemories.length,
        upcomingBirthdays: birthdays,
        reconnectSuggestions: reconnectSuggestions,
        relationshipMemories: relationshipMemories,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to analyze relationships', e, stackTrace);
      return RelationshipAnalysis.empty();
    }
  }

  /// Identify reconnection opportunities
  List<Map<String, dynamic>> _identifyReconnectOpportunities(List<Memory> memories) {
    final opportunities = <Map<String, dynamic>>[];

    // Look for relationships that haven't been mentioned recently
    final now = DateTime.now();

    for (final memory in memories) {
      final daysSince = now.difference(memory.lastAccessed).inDays;

      // Suggest reconnecting if 30+ days without contact
      if (daysSince >= 30 && daysSince <= 90) {
        opportunities.add({
          'name': memory.key,
          'daysSince': daysSince,
          'context': memory.value.toString(),
          'importance': memory.importance,
        });
      }
    }

    // Sort by importance
    opportunities.sort((a, b) =>
      (b['importance'] as double).compareTo(a['importance'] as double)
    );

    return opportunities.take(5).toList();
  }

  /// Build relationship maintenance actions
  Future<List<AutopilotAction>> _buildRelationshipActions(
    RelationshipAnalysis analysis,
    Map<String, dynamic>? preferences,
  ) async {
    final actions = <AutopilotAction>[];
    int stepNumber = 1;

    // 1. Create relationship summary
    final summary = _buildRelationshipSummary(analysis);
    actions.add(AutopilotAction(
      id: _uuid.v4(),
      actionType: AutopilotActionType.createNote,
      description: 'Create relationship summary',
      parameters: {
        'title': 'Relationship Maintenance - ${_formatDate(DateTime.now())}',
        'content': summary,
      },
      status: AutopilotActionStatus.pending,
      stepNumber: stepNumber++,
    ));

    // 2. Birthday/anniversary reminders
    for (final event in analysis.upcomingBirthdays.take(3)) {
      final daysUntil = event.start.difference(DateTime.now()).inDays;

      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Prepare for: ${event.summary}',
        parameters: {
          'title': '🎉 ${event.summary}',
          'due': event.start.subtract(const Duration(days: 2)),
          'notes': 'Send wishes or plan celebration (in $daysUntil days)',
          'priority': 'medium',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 3. Reconnect suggestions (gentle)
    for (final suggestion in analysis.reconnectSuggestions.take(3)) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Consider reaching out: ${suggestion['name']}',
        parameters: {
          'title': '💬 Check in: ${suggestion['name']}',
          'due': DateTime.now().add(const Duration(days: 3)),
          'notes': 'Last contact: ${suggestion['daysSince']} days ago\n'
              'Context: ${suggestion['context']}\n\n'
              'Ideas:\n'
              '- Send a quick message\n'
              '- Schedule a call\n'
              '- Grab coffee if nearby',
          'priority': 'low',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 4. Weekly relationship review
    if (preferences?['weeklyReview'] != false && analysis.totalRelationships > 0) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Schedule weekly relationship review',
        parameters: {
          'title': '🤝 Weekly Relationship Review',
          'due': _getNextSunday(),
          'notes': 'Take 10 minutes to:\n'
              '- Review who you connected with this week\n'
              '- Identify who needs attention next week\n'
              '- Plan quality time with important people',
          'priority': 'low',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 5. Quality time blocking for key relationships
    if (analysis.reconnectSuggestions.isNotEmpty) {
      final topPerson = analysis.reconnectSuggestions.first;

      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createEvent,
        description: 'Block time for: ${topPerson['name']}',
        parameters: {
          'title': '☕ Quality Time: ${topPerson['name']}',
          'startTime': _findQualityTimeSlot(),
          'duration': 60,
          'description': 'Dedicated time to connect. Plan a call, coffee, or activity together.',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    // 6. Gratitude reminder (optional)
    if (preferences?['gratitude'] != false) {
      actions.add(AutopilotAction(
        id: _uuid.v4(),
        actionType: AutopilotActionType.createTask,
        description: 'Express gratitude to someone',
        parameters: {
          'title': '🙏 Express Gratitude',
          'due': DateTime.now().add(const Duration(days: 1)),
          'notes': 'Send a quick thank you or appreciation message to someone who helped you recently.',
          'priority': 'low',
        },
        status: AutopilotActionStatus.pending,
        stepNumber: stepNumber++,
      ));
    }

    return actions;
  }

  /// Build relationship summary
  String _buildRelationshipSummary(RelationshipAnalysis analysis) {
    final buffer = StringBuffer();

    buffer.writeln('# Relationship Maintenance\n');

    buffer.writeln('## Overview');
    buffer.writeln('👥 Tracked Relationships: ${analysis.totalRelationships}');
    buffer.writeln('🎉 Upcoming Celebrations: ${analysis.upcomingBirthdays.length}');
    buffer.writeln('💬 Reconnect Opportunities: ${analysis.reconnectSuggestions.length}\n');

    if (analysis.upcomingBirthdays.isNotEmpty) {
      buffer.writeln('## Upcoming Celebrations');
      for (final event in analysis.upcomingBirthdays.take(3)) {
        final days = event.start.difference(DateTime.now()).inDays;
        buffer.writeln('- ${event.summary} (in $days days)');
      }
      buffer.writeln();
    }

    if (analysis.reconnectSuggestions.isNotEmpty) {
      buffer.writeln('## Reconnect Suggestions');
      buffer.writeln('These important people might appreciate hearing from you:\n');
      for (final person in analysis.reconnectSuggestions.take(3)) {
        buffer.writeln('- ${person['name']} (${person['daysSince']} days since last contact)');
      }
      buffer.writeln();
    }

    buffer.writeln('## Tips for Meaningful Connection');
    buffer.writeln('- Quality over quantity - even a 5-min call matters');
    buffer.writeln('- Be genuine - ask how they\'re doing and listen');
    buffer.writeln('- Share something specific you appreciate about them');
    buffer.writeln('- Suggest a specific next step (call, coffee, etc.)\n');

    buffer.writeln('---\nGenerated by Dona Relationship Autopilot');
    buffer.writeln('*All suggestions are gentle reminders - you\'re in control*');

    return buffer.toString();
  }

  /// Find a good time slot for quality time
  DateTime _findQualityTimeSlot() {
    final now = DateTime.now();

    // Suggest weekend morning (Saturday 10 AM)
    final nextSaturday = _getNextWeekday(6);
    return DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 10, 0);
  }

  /// Get next Sunday
  DateTime _getNextSunday() {
    return _getNextWeekday(7);
  }

  /// Get next occurrence of a weekday (1-7)
  DateTime _getNextWeekday(int weekday) {
    final now = DateTime.now();
    int daysUntil = weekday - now.weekday;
    if (daysUntil <= 0) {
      daysUntil += 7;
    }
    return now.add(Duration(days: daysUntil));
  }

  /// Format date as "MMM d"
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Relationship analysis data
class RelationshipAnalysis {
  final int totalRelationships;
  final List<dynamic> upcomingBirthdays;
  final List<Map<String, dynamic>> reconnectSuggestions;
  final List<Memory> relationshipMemories;

  const RelationshipAnalysis({
    required this.totalRelationships,
    required this.upcomingBirthdays,
    required this.reconnectSuggestions,
    required this.relationshipMemories,
  });

  factory RelationshipAnalysis.empty() {
    return const RelationshipAnalysis(
      totalRelationships: 0,
      upcomingBirthdays: [],
      reconnectSuggestions: [],
      relationshipMemories: [],
    );
  }
}
