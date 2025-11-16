import 'package:uuid/uuid.dart';
import '../domain/autopilot/history/autopilot_history_service.dart';
import '../domain/autopilot/history/autopilot_history_entry.dart';
import '../core/utils/logger.dart';
import '../services/storage/local_storage_service.dart';

/// Demo Data Service
///
/// Generates realistic demo data for showcases, screenshots, and presentations.
/// All demo data is clearly marked and can be wiped separately.
class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  static DemoDataService get instance => _instance;

  DemoDataService._internal();

  static const String _demoModeKey = 'demo_mode_active';
  final _uuid = const Uuid();

  /// Check if demo mode is active
  bool isDemoMode() {
    return LocalStorageService.instance.getBool(_demoModeKey) ?? false;
  }

  /// Enter demo mode
  Future<void> enterDemoMode() async {
    try {
      AppLogger.info('Entering demo mode');

      // Mark demo mode as active
      await LocalStorageService.instance.setBool(_demoModeKey, true);

      // Generate demo data
      await _generateDemoAutopilotHistory();

      AppLogger.info('Demo mode activated with sample data');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enter demo mode', e, stackTrace);
      rethrow;
    }
  }

  /// Exit demo mode and clear demo data
  Future<void> exitDemoMode() async {
    try {
      AppLogger.info('Exiting demo mode');

      // Clear demo data
      await AutopilotHistoryService.instance.clearHistory();

      // Mark demo mode as inactive
      await LocalStorageService.instance.setBool(_demoModeKey, false);

      AppLogger.info('Demo mode deactivated, data cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to exit demo mode', e, stackTrace);
    }
  }

  /// Generate demo autopilot history
  Future<void> _generateDemoAutopilotHistory() async {
    try {
      final now = DateTime.now();

      // Sample history entries for the past week
      final entries = [
        // Today
        DemoHistoryEntry(
          type: AutopilotType.planMyDay,
          summary: 'Planned day with 5 focus blocks and break reminders',
          totalActions: 7,
          executedActions: 7,
          status: AutopilotHistoryStatus.success,
          daysAgo: 0,
        ),
        DemoHistoryEntry(
          type: AutopilotType.focusMode,
          summary: 'Deep work session: Strategic planning (2 hours)',
          totalActions: 6,
          executedActions: 6,
          status: AutopilotHistoryStatus.success,
          daysAgo: 0,
        ),

        // Yesterday
        DemoHistoryEntry(
          type: AutopilotType.weeklyReview,
          summary: 'Weekly review - 12 tasks completed, 3 goals set',
          totalActions: 8,
          executedActions: 8,
          status: AutopilotHistoryStatus.success,
          daysAgo: 1,
        ),
        DemoHistoryEntry(
          type: AutopilotType.triage,
          summary: 'Triaged 23 tasks and 15 emails',
          totalActions: 5,
          executedActions: 4,
          status: AutopilotHistoryStatus.partial,
          daysAgo: 1,
        ),

        // 2 days ago
        DemoHistoryEntry(
          type: AutopilotType.studyAutopilot,
          summary: 'Study plan for CS 101 midterm',
          totalActions: 5,
          executedActions: 5,
          status: AutopilotHistoryStatus.success,
          daysAgo: 2,
        ),
        DemoHistoryEntry(
          type: AutopilotType.relationship,
          summary: 'Scheduled 2 check-ins and 1 birthday reminder',
          totalActions: 4,
          executedActions: 4,
          status: AutopilotHistoryStatus.success,
          daysAgo: 2,
        ),

        // 3 days ago
        DemoHistoryEntry(
          type: AutopilotType.planMyDay,
          summary: 'Planned day with calendar optimization',
          totalActions: 6,
          executedActions: 6,
          status: AutopilotHistoryStatus.success,
          daysAgo: 3,
        ),
        DemoHistoryEntry(
          type: AutopilotType.focusMode,
          summary: 'Deep work: Product roadmap planning',
          totalActions: 6,
          executedActions: 5,
          status: AutopilotHistoryStatus.partial,
          daysAgo: 3,
        ),

        // 4 days ago
        DemoHistoryEntry(
          type: AutopilotType.triage,
          summary: 'Inbox cleanup - 18 items processed',
          totalActions: 6,
          executedActions: 6,
          status: AutopilotHistoryStatus.success,
          daysAgo: 4,
        ),

        // 5 days ago
        DemoHistoryEntry(
          type: AutopilotType.planMyDay,
          summary: 'Daily plan with 4 meetings and 3 tasks',
          totalActions: 7,
          executedActions: 6,
          status: AutopilotHistoryStatus.partial,
          daysAgo: 5,
        ),
        DemoHistoryEntry(
          type: AutopilotType.focusMode,
          summary: 'Deep work: Investor deck preparation',
          totalActions: 6,
          executedActions: 0,
          status: AutopilotHistoryStatus.cancelled,
          daysAgo: 5,
        ),

        // 6 days ago
        DemoHistoryEntry(
          type: AutopilotType.studyAutopilot,
          summary: 'Created study plan for finals week',
          totalActions: 8,
          executedActions: 8,
          status: AutopilotHistoryStatus.success,
          daysAgo: 6,
        ),
        DemoHistoryEntry(
          type: AutopilotType.relationship,
          summary: 'Reconnect suggestions for 3 contacts',
          totalActions: 5,
          executedActions: 5,
          status: AutopilotHistoryStatus.success,
          daysAgo: 6,
        ),
      ];

      // Record each entry with proper timestamp
      for (final entry in entries) {
        final timestamp = now.subtract(Duration(days: entry.daysAgo));

        await AutopilotHistoryService.instance.recordExecution(
          type: entry.type,
          summary: entry.summary,
          totalActions: entry.totalActions,
          executedActions: entry.executedActions,
          status: entry.status,
          metadata: {
            'demo': true,
            'generated_at': DateTime.now().toIso8601String(),
          },
        );

        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
      }

      AppLogger.info('Generated ${entries.length} demo autopilot history entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate demo autopilot history', e, stackTrace);
    }
  }

  /// Generate demo tasks (placeholder - to be implemented with actual task models)
  Future<void> _generateDemoTasks() async {
    // TODO: Generate sample tasks when task models are available
    // Sample tasks for student profile:
    // - "Complete CS 101 assignment" (due tomorrow)
    // - "Study for midterm" (due in 3 days)
    // - "Team project meeting" (today)
    // Sample tasks for founder profile:
    // - "Review Q4 financial projections"
    // - "Investor update call"
    // - "Product roadmap planning"
  }

  /// Generate demo courses (placeholder)
  Future<void> _generateDemoCourses() async {
    // TODO: Generate sample courses
    // - CS 101: Introduction to Computer Science
    // - MATH 201: Calculus II
    // - BUS 301: Entrepreneurship
  }

  /// Generate demo calendar events (placeholder)
  Future<void> _generateDemoCalendarEvents() async {
    // TODO: Generate sample calendar events
    // - Team standup (daily)
    // - Investor meeting (next week)
    // - Study session (tomorrow)
  }
}

/// Demo history entry helper class
class DemoHistoryEntry {
  final AutopilotType type;
  final String summary;
  final int totalActions;
  final int executedActions;
  final AutopilotHistoryStatus status;
  final int daysAgo;

  const DemoHistoryEntry({
    required this.type,
    required this.summary,
    required this.totalActions,
    required this.executedActions,
    required this.status,
    required this.daysAgo,
  });
}
