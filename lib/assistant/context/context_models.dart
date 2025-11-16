import '../../data/models/calendar_event.dart';
import '../../data/models/weather_data.dart';
import '../../data/models/student/assignment.dart';
import '../../data/models/student/exam.dart';
import '../memory/user_model.dart';

/// Life context snapshot for a specific time period
class LifeContext {
  final DateTime timestamp;
  final TimeContext timeContext;
  final CalendarContext calendarContext;
  final TaskContext taskContext;
  final StudentContext studentContext;
  final EnvironmentContext environmentContext;
  final UserSnapshot userSnapshot;

  const LifeContext({
    required this.timestamp,
    required this.timeContext,
    required this.calendarContext,
    required this.taskContext,
    required this.studentContext,
    required this.environmentContext,
    required this.userSnapshot,
  });

  factory LifeContext.empty() {
    final now = DateTime.now();
    return LifeContext(
      timestamp: now,
      timeContext: TimeContext.fromDateTime(now),
      calendarContext: const CalendarContext.empty(),
      taskContext: const TaskContext.empty(),
      studentContext: const StudentContext.empty(),
      environmentContext: const EnvironmentContext.empty(),
      userSnapshot: UserSnapshot.empty(),
    );
  }

  /// Get a brief summary suitable for AI prompts
  String toBriefSummary() {
    final parts = <String>[];

    // Time context
    parts.add('Time: ${timeContext.timeOfDay}, ${timeContext.dayOfWeek}');

    // Calendar
    if (calendarContext.todayEvents.isNotEmpty) {
      parts.add('${calendarContext.todayEvents.length} events today');
    }
    if (calendarContext.nextEvent != null) {
      parts.add('Next: ${calendarContext.nextEvent!.title}');
    }

    // Tasks
    if (taskContext.dueTodayCount > 0) {
      parts.add('${taskContext.dueTodayCount} tasks due');
    }

    // Student
    if (studentContext.upcomingExams.isNotEmpty) {
      parts.add('${studentContext.upcomingExams.length} upcoming exams');
    }

    // Environment
    if (environmentContext.weather != null) {
      parts.add('Weather: ${environmentContext.weather!.description}');
    }

    return parts.join(' | ');
  }

  /// Get stress/load level (0.0 - 1.0)
  double get stressLevel {
    double stress = 0.0;

    // Tasks contribute to stress
    stress += taskContext.overdueCount * 0.15;
    stress += taskContext.dueTodayCount * 0.1;

    // Exams contribute significantly
    stress += studentContext.upcomingExams.length * 0.2;
    stress += studentContext.dueAssignments.length * 0.15;

    // Many events = busy day
    stress += calendarContext.todayEvents.length * 0.05;

    return stress.clamp(0.0, 1.0);
  }

  /// Check if user should take a break
  bool get shouldTakeBreak {
    return stressLevel > 0.7 && taskContext.dueTodayCount > 5;
  }
}

/// Time-related context
class TimeContext {
  final DateTime dateTime;
  final String timeOfDay; // 'morning', 'afternoon', 'evening', 'night'
  final String dayOfWeek; // 'Monday', etc.
  final bool isWeekend;
  final bool isHoliday;
  final int hourOfDay;

  const TimeContext({
    required this.dateTime,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isHoliday,
    required this.hourOfDay,
  });

  factory TimeContext.fromDateTime(DateTime dt) {
    final hour = dt.hour;
    String timeOfDay;

    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }

    final dayOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][dt.weekday - 1];

    final isWeekend = dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

    return TimeContext(
      dateTime: dt,
      timeOfDay: timeOfDay,
      dayOfWeek: dayOfWeek,
      isWeekend: isWeekend,
      isHoliday: false, // TODO: Implement holiday detection
      hourOfDay: hour,
    );
  }
}

/// Calendar-related context
class CalendarContext {
  final List<CalendarEvent> todayEvents;
  final CalendarEvent? currentEvent;
  final CalendarEvent? nextEvent;
  final List<CalendarEvent> thisWeekEvents;
  final int eventCount;

  const CalendarContext({
    required this.todayEvents,
    this.currentEvent,
    this.nextEvent,
    required this.thisWeekEvents,
    required this.eventCount,
  });

  const CalendarContext.empty()
      : todayEvents = const [],
        currentEvent = null,
        nextEvent = null,
        thisWeekEvents = const [],
        eventCount = 0;

  bool get hasEventsToday => todayEvents.isNotEmpty;
  bool get isCurrentlyInEvent => currentEvent != null;
}

/// Task-related context
class TaskContext {
  final int totalTaskCount;
  final int dueTodayCount;
  final int overdueCount;
  final int completedTodayCount;

  const TaskContext({
    required this.totalTaskCount,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.completedTodayCount,
  });

  const TaskContext.empty()
      : totalTaskCount = 0,
        dueTodayCount = 0,
        overdueCount = 0,
        completedTodayCount = 0;

  bool get hasOverdue => overdueCount > 0;
  bool get hasDueToday => dueTodayCount > 0;
}

/// Student academic context
class StudentContext {
  final List<Exam> upcomingExams;
  final List<Assignment> dueAssignments;
  final int flashcardsDue;
  final int quizzesPending;

  const StudentContext({
    required this.upcomingExams,
    required this.dueAssignments,
    required this.flashcardsDue,
    required this.quizzesPending,
  });

  const StudentContext.empty()
      : upcomingExams = const [],
        dueAssignments = const [],
        flashcardsDue = 0,
        quizzesPending = 0;

  bool get hasUpcomingExam => upcomingExams.isNotEmpty;
  bool get hasDueAssignments => dueAssignments.isNotEmpty;

  /// Get next exam
  Exam? get nextExam {
    if (upcomingExams.isEmpty) return null;
    return upcomingExams.first;
  }
}

/// Environmental context (weather, location, etc.)
class EnvironmentContext {
  final WeatherData? weather;
  final String? currentLocation;
  final bool isAtHome;
  final bool isAtWork;

  const EnvironmentContext({
    this.weather,
    this.currentLocation,
    required this.isAtHome,
    required this.isAtWork,
  });

  const EnvironmentContext.empty()
      : weather = null,
        currentLocation = null,
        isAtHome = false,
        isAtWork = false;
}

/// Priority item - something that needs attention
class PriorityItem {
  final String id;
  final String title;
  final String type; // 'event', 'task', 'exam', 'assignment'
  final DateTime? dueDate;
  final double priority; // 0.0 - 1.0
  final String? description;

  const PriorityItem({
    required this.id,
    required this.title,
    required this.type,
    this.dueDate,
    required this.priority,
    this.description,
  });
}
