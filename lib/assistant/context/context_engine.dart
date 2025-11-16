import 'context_models.dart';
import '../memory/user_model.dart';
import '../../services/calendar/calendar_service.dart';
import '../../services/weather/weather_service.dart';
import '../../services/student/exam_manager.dart';
import '../../services/student/assignment_manager.dart';
import '../../core/utils/logger.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/weather_data.dart';
import '../../data/models/student/exam.dart';
import '../../data/models/student/assignment.dart';

/// Context Engine - Aggregates all relevant context for intelligent decision-making
class ContextEngine {
  static final ContextEngine _instance = ContextEngine._internal();
  static ContextEngine get instance => _instance;

  ContextEngine._internal();

  // Cache for performance
  LifeContext? _cachedTodayContext;
  DateTime? _cacheTimestamp;
  static const _cacheValidityDuration = Duration(minutes: 5);

  Future<void> init() async {
    try {
      AppLogger.info('ContextEngine initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ContextEngine', e, stackTrace);
    }
  }

  /// Get today's context
  Future<LifeContext> getTodayContext({bool forceRefresh = false}) async {
    try {
      // Check cache
      if (!forceRefresh &&
          _cachedTodayContext != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration) {
        return _cachedTodayContext!;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Gather all context in parallel
      final results = await Future.wait([
        _getCalendarContext(startOfDay, endOfDay),
        _getTaskContext(),
        _getStudentContext(),
        _getEnvironmentContext(),
        UserModelService.instance.getUserSnapshot(),
      ]);

      final context = LifeContext(
        timestamp: now,
        timeContext: TimeContext.fromDateTime(now),
        calendarContext: results[0] as CalendarContext,
        taskContext: results[1] as TaskContext,
        studentContext: results[2] as StudentContext,
        environmentContext: results[3] as EnvironmentContext,
        userSnapshot: results[4] as UserSnapshot,
      );

      // Cache the result
      _cachedTodayContext = context;
      _cacheTimestamp = now;

      AppLogger.debug('Generated today context with ${context.calendarContext.todayEvents.length} events');
      return context;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get today context', e, stackTrace);
      return LifeContext.empty();
    }
  }

  /// Get this week's context
  Future<LifeContext> getThisWeekContext() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final calendarContext = await _getCalendarContext(startOfWeek, endOfWeek);
      final taskContext = await _getTaskContext();
      final studentContext = await _getStudentContext(daysAhead: 7);
      final environmentContext = await _getEnvironmentContext();
      final userSnapshot = await UserModelService.instance.getUserSnapshot();

      return LifeContext(
        timestamp: now,
        timeContext: TimeContext.fromDateTime(now),
        calendarContext: calendarContext,
        taskContext: taskContext,
        studentContext: studentContext,
        environmentContext: environmentContext,
        userSnapshot: userSnapshot,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get week context', e, stackTrace);
      return LifeContext.empty();
    }
  }

  /// Get important context for right now
  Future<LifeContext> getImportantNowContext() async {
    try {
      final todayContext = await getTodayContext();

      // For "now" context, we focus on immediate priorities
      // This is used for proactive suggestions and urgent notifications

      return todayContext; // For now, same as today context
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get important now context', e, stackTrace);
      return LifeContext.empty();
    }
  }

  /// Get top priority items for today
  Future<List<PriorityItem>> getTopPriorities({int limit = 5}) async {
    try {
      final context = await getTodayContext();
      final priorities = <PriorityItem>[];

      // Add upcoming events
      for (final event in context.calendarContext.todayEvents.take(3)) {
        priorities.add(PriorityItem(
          id: event.id ?? '',
          title: event.title,
          type: 'event',
          dueDate: event.startTime,
          priority: 0.8,
          description: event.description,
        ));
      }

      // Add urgent exams
      for (final exam in context.studentContext.upcomingExams.take(2)) {
        final daysUntil = exam.examDate.difference(DateTime.now()).inDays;
        final priority = daysUntil <= 3 ? 0.95 : 0.7;

        priorities.add(PriorityItem(
          id: exam.id,
          title: 'Exam: ${exam.examName}',
          type: 'exam',
          dueDate: exam.examDate,
          priority: priority,
          description: 'Prepare for ${exam.courseName} exam',
        ));
      }

      // Add due assignments
      for (final assignment in context.studentContext.dueAssignments.take(2)) {
        final daysUntil = assignment.dueDate.difference(DateTime.now()).inDays;
        final priority = daysUntil == 0 ? 0.9 : 0.6;

        priorities.add(PriorityItem(
          id: assignment.id,
          title: assignment.title,
          type: 'assignment',
          dueDate: assignment.dueDate,
          priority: priority,
          description: assignment.description,
        ));
      }

      // Sort by priority and return top N
      priorities.sort((a, b) => b.priority.compareTo(a.priority));
      return priorities.take(limit).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get top priorities', e, stackTrace);
      return [];
    }
  }

  /// Clear cached context (call after major changes)
  void invalidateCache() {
    _cachedTodayContext = null;
    _cacheTimestamp = null;
    AppLogger.debug('Context cache invalidated');
  }

  // ==================== PRIVATE HELPERS ====================

  Future<CalendarContext> _getCalendarContext(DateTime start, DateTime end) async {
    try {
      // Get events from calendar service
      final events = await CalendarService.instance.getEventsInRange(start, end);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Filter today's events
      final todayEvents = events
          .where((e) => e.startTime.isAfter(today) && e.startTime.isBefore(tomorrow))
          .toList();

      // Find current event
      CalendarEvent? currentEvent;
      for (final event in todayEvents) {
        if (event.startTime.isBefore(now) && event.endTime.isAfter(now)) {
          currentEvent = event;
          break;
        }
      }

      // Find next event
      CalendarEvent? nextEvent;
      for (final event in todayEvents) {
        if (event.startTime.isAfter(now)) {
          nextEvent = event;
          break;
        }
      }

      return CalendarContext(
        todayEvents: todayEvents,
        currentEvent: currentEvent,
        nextEvent: nextEvent,
        thisWeekEvents: events,
        eventCount: events.length,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get calendar context', e, stackTrace);
      return const CalendarContext.empty();
    }
  }

  Future<TaskContext> _getTaskContext() async {
    try {
      // TODO: Integrate with Google Tasks service when available
      // For now, return empty context
      return const TaskContext.empty();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get task context', e, stackTrace);
      return const TaskContext.empty();
    }
  }

  Future<StudentContext> _getStudentContext({int daysAhead = 1}) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      // Get upcoming exams
      final allExams = ExamManager.instance.getAllExams();
      final upcomingExams = allExams
          .where((exam) => exam.examDate.isAfter(now) && exam.examDate.isBefore(futureDate))
          .toList();

      // Get due assignments
      final allAssignments = AssignmentManager.instance.getAllAssignments();
      final dueAssignments = allAssignments
          .where((a) =>
              !a.isCompleted && a.dueDate.isAfter(now) && a.dueDate.isBefore(futureDate))
          .toList();

      // TODO: Get flashcards and quizzes counts
      final flashcardsDue = 0;
      final quizzesPending = 0;

      return StudentContext(
        upcomingExams: upcomingExams,
        dueAssignments: dueAssignments,
        flashcardsDue: flashcardsDue,
        quizzesPending: quizzesPending,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get student context', e, stackTrace);
      return const StudentContext.empty();
    }
  }

  Future<EnvironmentContext> _getEnvironmentContext() async {
    try {
      // Get current weather
      WeatherData? weather;
      try {
        weather = await WeatherService.instance.getCurrentWeather();
      } catch (e) {
        // Weather is optional, log but don't fail
        AppLogger.debug('Could not fetch weather: $e');
      }

      // TODO: Get location when location services are implemented
      const String? currentLocation = null;
      const bool isAtHome = false;
      const bool isAtWork = false;

      return EnvironmentContext(
        weather: weather,
        currentLocation: currentLocation,
        isAtHome: isAtHome,
        isAtWork: isAtWork,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get environment context', e, stackTrace);
      return const EnvironmentContext.empty();
    }
  }
}
