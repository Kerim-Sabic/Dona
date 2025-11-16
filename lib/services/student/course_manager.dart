import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../data/models/student/course.dart';
import '../../data/models/student/assignment.dart';
import '../../data/models/student/exam.dart';
import '../../data/models/student/grade.dart';
import '../storage/local_storage_service.dart';
import '../calendar/calendar_service.dart';
import '../../data/models/calendar_event.dart';
import 'package:flutter/material.dart';

/// Course Manager Service
/// Manages all academic courses and their schedules
class CourseManager {
  static final CourseManager _instance = CourseManager._internal();
  static CourseManager get instance => _instance;

  CourseManager._internal();

  List<Course> _courses = [];
  String? _currentSemester;

  /// Initialize course manager
  Future<void> init() async {
    try {
      await _loadCourses();
      _currentSemester = LocalStorageService.instance.getString('current_semester');
      AppLogger.info('CourseManager initialized with ${_courses.length} courses');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize CourseManager', e, stackTrace);
    }
  }

  /// Add a new course
  Future<Course> addCourse({
    required String name,
    required String code,
    String? professor,
    List<ClassSchedule>? meetingTimes,
    String? location,
    int credits = 3,
    Color? color,
    String? semester,
    GradingScale gradingScale = GradingScale.standard,
    String? officeHours,
    String? syllabus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        code: code,
        professor: professor,
        meetingTimes: meetingTimes ?? [],
        location: location,
        credits: credits,
        color: color ?? _generateRandomColor(),
        semester: semester ?? _currentSemester ?? 'Current',
        gradingScale: gradingScale,
        officeHours: officeHours,
        syllabus: syllabus,
        startDate: startDate,
        endDate: endDate,
      );

      _courses.add(course);
      await _saveCourses();

      // Sync to calendar if available
      await _syncCourseToCalendar(course);

      AppLogger.info('Added course: $name ($code)');
      return course;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding course', e, stackTrace);
      rethrow;
    }
  }

  /// Update course
  Future<void> updateCourse(Course course) async {
    try {
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = course;
        await _saveCourses();
        await _syncCourseToCalendar(course);
        AppLogger.info('Updated course: ${course.name}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating course', e, stackTrace);
      rethrow;
    }
  }

  /// Delete course
  Future<bool> deleteCourse(String courseId) async {
    try {
      final removedCount = _courses.removeWhere((c) => c.id == courseId);
      if (removedCount > 0) {
        await _saveCourses();
        AppLogger.info('Deleted course: $courseId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting course', e, stackTrace);
      return false;
    }
  }

  /// Get course by ID
  Course? getCourse(String courseId) {
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (e) {
      return null;
    }
  }

  /// Get all courses
  List<Course> get allCourses => List.unmodifiable(_courses);

  /// Get active courses
  List<Course> get activeCourses =>
      _courses.where((c) => c.isActive).toList();

  /// Get courses for current semester
  List<Course> get currentSemesterCourses =>
      _courses.where((c) => c.semester == _currentSemester && c.isActive).toList();

  /// Get courses by semester
  List<Course> getCoursesBySemester(String semester) =>
      _courses.where((c) => c.semester == semester).toList();

  /// Get all semesters
  List<String> get allSemesters {
    final semesters = <String>{};
    for (final course in _courses) {
      semesters.add(course.semester);
    }
    return semesters.toList()..sort();
  }

  /// Set current semester
  Future<void> setCurrentSemester(String semester) async {
    _currentSemester = semester;
    await LocalStorageService.instance.setString('current_semester', semester);
    AppLogger.info('Set current semester: $semester');
  }

  /// Get today's classes
  List<CourseScheduleItem> getTodaysClasses() {
    final today = DateTime.now().weekday; // 1=Monday, 7=Sunday
    final classes = <CourseScheduleItem>[];

    for (final course in activeCourses) {
      for (final schedule in course.meetingTimes) {
        if (schedule.days.contains(today)) {
          classes.add(CourseScheduleItem(
            course: course,
            schedule: schedule,
            date: DateTime.now(),
          ));
        }
      }
    }

    // Sort by start time
    classes.sort((a, b) {
      final aTime = a.schedule.startTime.hour * 60 + a.schedule.startTime.minute;
      final bTime = b.schedule.startTime.hour * 60 + b.schedule.startTime.minute;
      return aTime.compareTo(bTime);
    });

    return classes;
  }

  /// Get this week's classes
  List<CourseScheduleItem> getWeeksClasses() {
    final classes = <CourseScheduleItem>[];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayOfWeek = day.weekday;

      for (final course in activeCourses) {
        for (final schedule in course.meetingTimes) {
          if (schedule.days.contains(dayOfWeek)) {
            classes.add(CourseScheduleItem(
              course: course,
              schedule: schedule,
              date: day,
            ));
          }
        }
      }
    }

    return classes;
  }

  /// Get next class
  CourseScheduleItem? getNextClass() {
    final todaysClasses = getTodaysClasses();
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final classItem in todaysClasses) {
      final classMinutes = classItem.schedule.startTime.hour * 60 +
                          classItem.schedule.startTime.minute;
      if (classMinutes > currentMinutes) {
        return classItem;
      }
    }

    return null;
  }

  /// Archive course (set inactive)
  Future<void> archiveCourse(String courseId) async {
    final course = getCourse(courseId);
    if (course != null) {
      await updateCourse(course.copyWith(isActive: false));
      AppLogger.info('Archived course: ${course.name}');
    }
  }

  /// Sync course to calendar
  Future<void> _syncCourseToCalendar(Course course) async {
    try {
      if (!CalendarService.instance.isAuthenticated) {
        return;
      }

      // Create recurring calendar events for each class meeting
      for (final schedule in course.meetingTimes) {
        for (final dayOfWeek in schedule.days) {
          // Find next occurrence of this day
          final now = DateTime.now();
          int daysUntil = dayOfWeek - now.weekday;
          if (daysUntil < 0) daysUntil += 7;

          final nextOccurrence = now.add(Duration(days: daysUntil));
          final startTime = DateTime(
            nextOccurrence.year,
            nextOccurrence.month,
            nextOccurrence.day,
            schedule.startTime.hour,
            schedule.startTime.minute,
          );
          final endTime = DateTime(
            nextOccurrence.year,
            nextOccurrence.month,
            nextOccurrence.day,
            schedule.endTime.hour,
            schedule.endTime.minute,
          );

          final event = CalendarEvent(
            id: '${course.id}_${dayOfWeek}',
            title: '${course.code}: ${course.name}',
            description: 'Professor: ${course.professor ?? "TBA"}\nRoom: ${schedule.room ?? course.location ?? "TBA"}',
            startTime: startTime,
            endTime: endTime,
            location: course.location,
          );

          await CalendarService.instance.createEvent(event);
        }
      }

      AppLogger.debug('Synced course to calendar: ${course.name}');
    } catch (e) {
      AppLogger.warning('Could not sync course to calendar', e);
    }
  }

  /// Generate random color for course
  Color _generateRandomColor() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  /// Save courses to storage
  Future<void> _saveCourses() async {
    try {
      final json = jsonEncode(_courses.map((c) => c.toJson()).toList());
      await LocalStorageService.instance.setString('courses', json);
      AppLogger.debug('Saved ${_courses.length} courses');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving courses', e, stackTrace);
    }
  }

  /// Load courses from storage
  Future<void> _loadCourses() async {
    try {
      final json = LocalStorageService.instance.getString('courses');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _courses = data.map((item) => Course.fromJson(item)).toList();
        AppLogger.info('Loaded ${_courses.length} courses');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading courses', e, stackTrace);
    }
  }

  /// Get course statistics
  CourseStatistics getCourseStatistics(String courseId) {
    final course = getCourse(courseId);
    if (course == null) {
      return CourseStatistics(
        courseId: courseId,
        totalCredits: 0,
        totalClassHours: Duration.zero,
        averageAttendance: 0,
      );
    }

    // Calculate total class hours per week
    int totalMinutesPerWeek = 0;
    for (final schedule in course.meetingTimes) {
      final duration = (schedule.endTime.hour * 60 + schedule.endTime.minute) -
                      (schedule.startTime.hour * 60 + schedule.startTime.minute);
      totalMinutesPerWeek += duration * schedule.days.length;
    }

    return CourseStatistics(
      courseId: courseId,
      totalCredits: course.credits,
      totalClassHours: Duration(minutes: totalMinutesPerWeek),
      averageAttendance: 100, // Would track actual attendance
    );
  }
}

/// Course schedule item (course + schedule + date)
class CourseScheduleItem {
  final Course course;
  final ClassSchedule schedule;
  final DateTime date;

  CourseScheduleItem({
    required this.course,
    required this.schedule,
    required this.date,
  });

  /// Get formatted time range
  String get timeRange => schedule.timeString;

  /// Get course display name
  String get displayName => '${course.code}: ${course.name}';

  /// Check if class is now
  bool get isNow {
    final now = DateTime.now();
    if (date.day != now.day || date.month != now.month || date.year != now.year) {
      return false;
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
    final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// Get minutes until class starts
  int get minutesUntilStart {
    final now = DateTime.now();
    final classStart = DateTime(
      date.year,
      date.month,
      date.day,
      schedule.startTime.hour,
      schedule.startTime.minute,
    );
    return classStart.difference(now).inMinutes;
  }
}

/// Course statistics
class CourseStatistics {
  final String courseId;
  final int totalCredits;
  final Duration totalClassHours;
  final double averageAttendance;

  CourseStatistics({
    required this.courseId,
    required this.totalCredits,
    required this.totalClassHours,
    required this.averageAttendance,
  });
}
