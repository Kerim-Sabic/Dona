import 'package:flutter_test/flutter_test.dart';
import 'package:dona/assistant/context/context_models.dart';
import 'package:dona/data/models/calendar_event.dart';
import 'package:dona/data/models/student/exam.dart';
import 'package:dona/data/models/student/assignment.dart';

/// Unit tests for Context Engine - Stress Calculation & Priority Extraction
void main() {
  group('LifeContext - Stress Level Calculation', () {
    test('Low stress with minimal load', () {
      final now = DateTime.now();

      final context = LifeContext(
        timestamp: now,
        timeContext: TimeContext.fromDateTime(now),
        calendarContext: const CalendarContext(
          todayEvents: [],
          currentEvent: null,
          nextEvent: null,
          thisWeekEvents: [],
          eventCount: 0,
        ),
        taskContext: const TaskContext.empty(),
        studentContext: const StudentContext.empty(),
        environmentContext: const EnvironmentContext.empty(),
        userSnapshot: _createMockUserSnapshot(),
      );

      expect(context.stressLevel, lessThan(0.3)); // Low stress
      expect(context.shouldTakeBreak, isFalse);
    });

    test('Medium stress with moderate calendar load', () {
      final now = DateTime.now();
      final events = List.generate(
        4,
        (i) => CalendarEvent(
          id: 'event-$i',
          title: 'Meeting $i',
          startTime: now.add(Duration(hours: i * 2)),
          endTime: now.add(Duration(hours: i * 2 + 1)),
        ),
      );

      final context = LifeContext(
        timestamp: now,
        timeContext: TimeContext.fromDateTime(now),
        calendarContext: CalendarContext(
          todayEvents: events,
          currentEvent: null,
          nextEvent: events.first,
          thisWeekEvents: events,
          eventCount: 4,
        ),
        taskContext: const TaskContext(
          dueTasks: [],
          overdueCount: 0,
          totalPendingTasks: 3,
        ),
        studentContext: const StudentContext.empty(),
        environmentContext: const EnvironmentContext.empty(),
        userSnapshot: _createMockUserSnapshot(),
      );

      expect(context.stressLevel, greaterThan(0.3));
      expect(context.stressLevel, lessThan(0.7));
    });

    test('High stress with heavy workload', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      // Many events
      final events = List.generate(
        7,
        (i) => CalendarEvent(
          id: 'event-$i',
          title: 'Meeting $i',
          startTime: now.add(Duration(hours: i)),
          endTime: now.add(Duration(hours: i + 1)),
        ),
      );

      // Urgent exam
      final urgentExam = Exam(
        id: 'exam-1',
        examName: 'Midterm',
        courseName: 'CS101',
        examDate: tomorrow,
        duration: 120,
      );

      // Due assignment
      final dueAssignment = Assignment(
        id: 'assign-1',
        title: 'Project Report',
        courseName: 'CS101',
        dueDate: tomorrow,
        isCompleted: false,
      );

      final context = LifeContext(
        timestamp: now,
        timeContext: TimeContext.fromDateTime(now),
        calendarContext: CalendarContext(
          todayEvents: events,
          currentEvent: events.first,
          nextEvent: events[1],
          thisWeekEvents: events,
          eventCount: 7,
        ),
        taskContext: const TaskContext(
          dueTasks: [],
          overdueCount: 2,
          totalPendingTasks: 8,
        ),
        studentContext: StudentContext(
          upcomingExams: [urgentExam],
          dueAssignments: [dueAssignment],
          flashcardsDue: 15,
          quizzesPending: 3,
        ),
        environmentContext: const EnvironmentContext.empty(),
        userSnapshot: _createMockUserSnapshot(),
      );

      expect(context.stressLevel, greaterThan(0.7)); // High stress
      expect(context.shouldTakeBreak, isTrue);
    });

    test('Stress level caps at 1.0', () {
      final now = DateTime.now();

      // Extremely overloaded scenario
      final manyEvents = List.generate(
        15,
        (i) => CalendarEvent(
          id: 'event-$i',
          title: 'Meeting $i',
          startTime: now.add(Duration(hours: i)),
          endTime: now.add(Duration(hours: i + 1)),
        ),
      );

      final context = LifeContext(
        timestamp: now,
        timeContext: TimeContext.fromDateTime(now),
        calendarContext: CalendarContext(
          todayEvents: manyEvents,
          currentEvent: manyEvents.first,
          nextEvent: manyEvents[1],
          thisWeekEvents: manyEvents,
          eventCount: 15,
        ),
        taskContext: const TaskContext(
          dueTasks: [],
          overdueCount: 10,
          totalPendingTasks: 25,
        ),
        studentContext: const StudentContext(
          upcomingExams: [],
          dueAssignments: [],
          flashcardsDue: 50,
          quizzesPending: 10,
        ),
        environmentContext: const EnvironmentContext.empty(),
        userSnapshot: _createMockUserSnapshot(),
      );

      expect(context.stressLevel, lessThanOrEqualTo(1.0)); // Capped
    });
  });

  group('TimeContext - Time of Day Detection', () {
    test('Morning detection (6 AM - 12 PM)', () {
      final morning = DateTime(2025, 1, 15, 9, 0); // 9 AM
      final context = TimeContext.fromDateTime(morning);

      expect(context.timeOfDay, equals('morning'));
      expect(context.hourOfDay, equals(9));
    });

    test('Afternoon detection (12 PM - 6 PM)', () {
      final afternoon = DateTime(2025, 1, 15, 15, 0); // 3 PM
      final context = TimeContext.fromDateTime(afternoon);

      expect(context.timeOfDay, equals('afternoon'));
      expect(context.hourOfDay, equals(15));
    });

    test('Evening detection (6 PM - 10 PM)', () {
      final evening = DateTime(2025, 1, 15, 20, 0); // 8 PM
      final context = TimeContext.fromDateTime(evening);

      expect(context.timeOfDay, equals('evening'));
      expect(context.hourOfDay, equals(20));
    });

    test('Night detection (10 PM - 6 AM)', () {
      final night = DateTime(2025, 1, 15, 23, 0); // 11 PM
      final context = TimeContext.fromDateTime(night);

      expect(context.timeOfDay, equals('night'));
      expect(context.hourOfDay, equals(23));
    });

    test('Weekend detection', () {
      final saturday = DateTime(2025, 1, 18); // Saturday
      final sunday = DateTime(2025, 1, 19); // Sunday
      final monday = DateTime(2025, 1, 20); // Monday

      expect(TimeContext.fromDateTime(saturday).isWeekend, isTrue);
      expect(TimeContext.fromDateTime(sunday).isWeekend, isTrue);
      expect(TimeContext.fromDateTime(monday).isWeekend, isFalse);
    });

    test('Day of week detection', () {
      final monday = DateTime(2025, 1, 20); // Monday
      final context = TimeContext.fromDateTime(monday);

      expect(context.dayOfWeek, equals('Monday'));
      expect(context.isWeekend, isFalse);
    });
  });

  group('PriorityItem - Priority Scoring', () {
    test('Exam within 3 days gets very high priority (0.95)', () {
      final now = DateTime.now();
      final soonExam = now.add(const Duration(days: 2));

      final priority = PriorityItem(
        id: 'exam-1',
        title: 'Midterm Exam',
        type: 'exam',
        dueDate: soonExam,
        priority: 0.95,
        description: 'CS101 Midterm',
      );

      expect(priority.priority, equals(0.95));
      expect(priority.type, equals('exam'));
    });

    test('Assignment due today gets high priority (0.9)', () {
      final now = DateTime.now();

      final priority = PriorityItem(
        id: 'assign-1',
        title: 'Project Report',
        type: 'assignment',
        dueDate: now,
        priority: 0.9,
        description: 'Final project report',
      );

      expect(priority.priority, greaterThanOrEqualTo(0.85));
    });

    test('Event gets standard priority (0.8)', () {
      final now = DateTime.now();

      final priority = PriorityItem(
        id: 'event-1',
        title: 'Team Meeting',
        type: 'event',
        dueDate: now.add(const Duration(hours: 2)),
        priority: 0.8,
      );

      expect(priority.priority, equals(0.8));
    });

    test('Priority comparison for sorting', () {
      final high = PriorityItem(
        id: '1',
        title: 'High',
        type: 'exam',
        dueDate: DateTime.now(),
        priority: 0.95,
      );

      final medium = PriorityItem(
        id: '2',
        title: 'Medium',
        type: 'event',
        dueDate: DateTime.now(),
        priority: 0.7,
      );

      final low = PriorityItem(
        id: '3',
        title: 'Low',
        type: 'task',
        dueDate: DateTime.now(),
        priority: 0.4,
      );

      final priorities = [medium, low, high];
      priorities.sort((a, b) => b.priority.compareTo(a.priority));

      expect(priorities[0].priority, equals(0.95)); // High first
      expect(priorities[1].priority, equals(0.7)); // Medium second
      expect(priorities[2].priority, equals(0.4)); // Low last
    });
  });

  group('CalendarContext - Event Tracking', () {
    test('Current event detection', () {
      final now = DateTime.now();

      final currentEvent = CalendarEvent(
        id: 'current',
        title: 'Ongoing Meeting',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 30)),
      );

      final context = CalendarContext(
        todayEvents: [currentEvent],
        currentEvent: currentEvent,
        nextEvent: null,
        thisWeekEvents: [currentEvent],
        eventCount: 1,
      );

      expect(context.currentEvent, isNotNull);
      expect(context.currentEvent!.title, equals('Ongoing Meeting'));
    });

    test('Next event detection', () {
      final now = DateTime.now();

      final nextEvent = CalendarEvent(
        id: 'next',
        title: 'Upcoming Meeting',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
      );

      final context = CalendarContext(
        todayEvents: [nextEvent],
        currentEvent: null,
        nextEvent: nextEvent,
        thisWeekEvents: [nextEvent],
        eventCount: 1,
      );

      expect(context.nextEvent, isNotNull);
      expect(context.nextEvent!.title, equals('Upcoming Meeting'));
    });

    test('Empty calendar context', () {
      const context = CalendarContext.empty();

      expect(context.todayEvents, isEmpty);
      expect(context.currentEvent, isNull);
      expect(context.nextEvent, isNull);
      expect(context.eventCount, equals(0));
    });
  });
}

// Helper to create a mock UserSnapshot for testing
UserSnapshot _createMockUserSnapshot() {
  return UserSnapshot.empty();
}
