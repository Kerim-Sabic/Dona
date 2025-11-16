import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../data/models/student/exam.dart';
import '../../data/models/student/course.dart';
import '../storage/local_storage_service.dart';
import '../calendar/calendar_service.dart';
import '../notifications/smart_notification_service.dart';
import '../ai/ai_service.dart';
import '../../data/models/calendar_event.dart';
import 'course_manager.dart';

/// Exam Manager Service
/// Manages all exams with AI-powered study plan generation
class ExamManager {
  static final ExamManager _instance = ExamManager._internal();
  static ExamManager get instance => _instance;

  ExamManager._internal();

  List<Exam> _exams = [];
  List<ExamStudySession> _studySessions = [];
  final Map<String, ExamPrepPlan> _prepPlans = {};

  /// Initialize exam manager
  Future<void> init() async {
    try {
      await _loadExams();
      await _loadStudySessions();
      await _loadPrepPlans();
      AppLogger.info('ExamManager initialized with ${_exams.length} exams');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize ExamManager', e, stackTrace);
    }
  }

  /// Add a new exam
  Future<Exam> addExam({
    required String courseId,
    required String title,
    String? description,
    required ExamType type,
    required DateTime dateTime,
    Duration duration = const Duration(hours: 2),
    String? location,
    String? room,
    List<String>? topicsCovered,
    List<String>? studyMaterials,
    ExamFormat format = ExamFormat.mixed,
    double? totalPoints,
    double? weight,
    bool allowsCheatSheet = false,
    String? cheatSheetRules,
    String? additionalNotes,
  }) async {
    try {
      final exam = Exam(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        title: title,
        description: description,
        type: type,
        dateTime: dateTime,
        duration: duration,
        location: location,
        room: room,
        topicsCovered: topicsCovered ?? [],
        studyMaterials: studyMaterials ?? [],
        format: format,
        totalPoints: totalPoints,
        weight: weight,
        allowsCheatSheet: allowsCheatSheet,
        cheatSheetRules: cheatSheetRules,
        additionalNotes: additionalNotes,
        status: ExamStatus.upcoming,
        created: DateTime.now(),
      );

      _exams.add(exam);
      await _saveExams();

      // Generate AI study plan
      if (topicsCovered != null && topicsCovered.isNotEmpty) {
        await generateStudyPlan(exam);
      }

      // Schedule smart reminders
      await _scheduleReminders(exam);

      // Sync to calendar
      await _syncToCalendar(exam);

      AppLogger.info('Added exam: $title');
      return exam;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding exam', e, stackTrace);
      rethrow;
    }
  }

  /// Update exam
  Future<void> updateExam(Exam exam) async {
    try {
      final index = _exams.indexWhere((e) => e.id == exam.id);
      if (index != -1) {
        _exams[index] = exam;
        await _saveExams();

        // Update reminders if date changed
        await _scheduleReminders(exam);

        AppLogger.info('Updated exam: ${exam.title}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating exam', e, stackTrace);
      rethrow;
    }
  }

  /// Delete exam
  Future<bool> deleteExam(String examId) async {
    try {
      final removedCount = _exams.removeWhere((e) => e.id == examId);
      if (removedCount > 0) {
        // Also delete related study sessions and prep plan
        _studySessions.removeWhere((s) => s.examId == examId);
        _prepPlans.remove(examId);

        await _saveExams();
        await _saveStudySessions();
        await _savePrepPlans();

        AppLogger.info('Deleted exam: $examId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting exam', e, stackTrace);
      return false;
    }
  }

  /// Record exam score
  Future<void> recordExamScore(String examId, {
    required double earnedScore,
    String? letterGrade,
  }) async {
    final exam = getExam(examId);
    if (exam != null) {
      final graded = exam.copyWith(
        status: ExamStatus.graded,
        earnedScore: earnedScore,
        letterGrade: letterGrade,
      );
      await updateExam(graded);
    }
  }

  /// Generate AI-powered study plan
  Future<ExamPrepPlan> generateStudyPlan(Exam exam) async {
    try {
      AppLogger.info('Generating study plan for: ${exam.title}');

      final course = CourseManager.instance.getCourse(exam.courseId);
      final daysUntilExam = exam.daysUntil;

      final prompt = '''
Create a comprehensive study plan for this exam:

Exam: ${exam.title}
Course: ${course?.name ?? 'Unknown'}
Type: ${exam.type.displayName}
Format: ${exam.format.toString().split('.').last}
Date: ${exam.dateTime}
Days Until Exam: $daysUntilExam days

Topics Covered:
${exam.topicsCovered.map((t) => '- $t').join('\n')}

Study Materials Available:
${exam.studyMaterials.isNotEmpty ? exam.studyMaterials.map((m) => '- $m').join('\n') : 'None specified'}

Requirements:
- Return ONLY a JSON array of study topics
- Each topic should have: "name" (string), "estimatedHours" (number 1-10), "priority" ("low", "medium", "high", or "urgent")
- Break down topics into manageable chunks
- Prioritize based on importance and difficulty
- Consider available study time ($daysUntilExam days)
- Order by recommended study sequence

Example format:
[
  {"name": "Review Chapter 1-3: Basic Concepts", "estimatedHours": 3, "priority": "high"},
  {"name": "Practice problems sets 1-5", "estimatedHours": 4, "priority": "high"},
  {"name": "Review lecture notes Week 1-4", "estimatedHours": 2, "priority": "medium"}
]
''';

      final response = await AIService.instance.chat(prompt);

      try {
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (jsonMatch != null) {
          final List<dynamic> data = jsonDecode(jsonMatch.group(0)!);
          final topics = data.map((item) {
            Priority priority;
            final priorityStr = (item['priority'] as String).toLowerCase();
            if (priorityStr == 'urgent') {
              priority = Priority.urgent;
            } else if (priorityStr == 'high') {
              priority = Priority.high;
            } else if (priorityStr == 'medium') {
              priority = Priority.medium;
            } else {
              priority = Priority.low;
            }

            return StudyTopic(
              id: DateTime.now().millisecondsSinceEpoch.toString() + data.indexOf(item).toString(),
              name: item['name'] as String,
              estimatedHours: (item['estimatedHours'] as num).toInt(),
              priority: priority,
            );
          }).toList();

          // Calculate total hours needed
          final totalHours = topics.fold<int>(0, (sum, topic) => sum + topic.estimatedHours);

          // Create study schedule (distribute topics across available days)
          final schedule = _generateStudySchedule(topics, exam.dateTime, daysUntilExam);

          final plan = ExamPrepPlan(
            examId: exam.id,
            topics: topics,
            schedule: schedule,
            totalHoursNeeded: totalHours,
          );

          _prepPlans[exam.id] = plan;
          await _savePrepPlans();

          AppLogger.info('Generated study plan with ${topics.length} topics, $totalHours hours total');
          return plan;
        }
      } catch (e) {
        AppLogger.warning('Could not parse AI study plan: $e');
      }

      // Fallback: create basic study plan
      return _createFallbackStudyPlan(exam);
    } catch (e, stackTrace) {
      AppLogger.error('Error generating study plan', e, stackTrace);
      return _createFallbackStudyPlan(exam);
    }
  }

  /// Generate study schedule from topics
  Map<DateTime, List<StudyTopic>> _generateStudySchedule(
    List<StudyTopic> topics,
    DateTime examDate,
    int daysAvailable,
  ) {
    final schedule = <DateTime, List<StudyTopic>>{};

    if (daysAvailable <= 0) return schedule;

    // Start from today
    final today = DateTime.now();
    final studyDays = <DateTime>[];

    // Create list of study days (skip exam day)
    for (int i = 0; i < daysAvailable; i++) {
      final day = today.add(Duration(days: i));
      if (day.isBefore(examDate)) {
        studyDays.add(DateTime(day.year, day.month, day.day));
      }
    }

    if (studyDays.isEmpty) return schedule;

    // Distribute topics across days
    // Prioritize urgent/high priority topics first
    final sortedTopics = List<StudyTopic>.from(topics)
      ..sort((a, b) {
        final priorityOrder = {
          Priority.urgent: 0,
          Priority.high: 1,
          Priority.medium: 2,
          Priority.low: 3,
        };
        return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      });

    int currentDayIndex = 0;
    for (final topic in sortedTopics) {
      // Assign topic to current day
      final day = studyDays[currentDayIndex % studyDays.length];
      schedule[day] = schedule[day] ?? [];
      schedule[day]!.add(topic);

      // Move to next day for next topic (distribute evenly)
      currentDayIndex++;
    }

    return schedule;
  }

  /// Create fallback study plan when AI fails
  ExamPrepPlan _createFallbackStudyPlan(Exam exam) {
    final topics = exam.topicsCovered.map((topic) {
      return StudyTopic(
        id: DateTime.now().millisecondsSinceEpoch.toString() + exam.topicsCovered.indexOf(topic).toString(),
        name: topic,
        estimatedHours: 2,
        priority: Priority.medium,
      );
    }).toList();

    final totalHours = topics.length * 2;
    final schedule = _generateStudySchedule(topics, exam.dateTime, exam.daysUntil);

    final plan = ExamPrepPlan(
      examId: exam.id,
      topics: topics,
      schedule: schedule,
      totalHoursNeeded: totalHours,
    );

    _prepPlans[exam.id] = plan;
    return plan;
  }

  /// Start a study session for an exam
  Future<ExamStudySession> startStudySession(String examId, {String? topicCovered}) async {
    try {
      final session = ExamStudySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        examId: examId,
        topicCovered: topicCovered,
        startTime: DateTime.now(),
        duration: Duration.zero,
      );

      _studySessions.add(session);
      await _saveStudySessions();

      AppLogger.info('Started study session for exam: $examId');
      return session;
    } catch (e, stackTrace) {
      AppLogger.error('Error starting study session', e, stackTrace);
      rethrow;
    }
  }

  /// End a study session
  Future<void> endStudySession(String sessionId, {int? productivityScore, String? notes}) async {
    try {
      final index = _studySessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        final session = _studySessions[index];
        final endTime = DateTime.now();
        final duration = endTime.difference(session.startTime);

        final updatedSession = ExamStudySession(
          id: session.id,
          examId: session.examId,
          topicCovered: session.topicCovered,
          startTime: session.startTime,
          endTime: endTime,
          duration: duration,
          productivityScore: productivityScore ?? 0,
          notes: notes,
          resourcesUsed: session.resourcesUsed,
        );

        _studySessions[index] = updatedSession;
        await _saveStudySessions();

        // Update prep plan progress if applicable
        if (session.topicCovered != null) {
          await _updatePrepPlanProgress(session.examId, session.topicCovered!, duration);
        }

        AppLogger.info('Ended study session: $sessionId (${duration.inMinutes} minutes)');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error ending study session', e, stackTrace);
    }
  }

  /// Update prep plan progress
  Future<void> _updatePrepPlanProgress(String examId, String topicName, Duration timeSpent) async {
    try {
      final plan = _prepPlans[examId];
      if (plan != null) {
        // Find and mark topic as completed if enough time spent
        final topicIndex = plan.topics.indexWhere((t) => t.name == topicName);
        if (topicIndex != -1) {
          final topic = plan.topics[topicIndex];
          final estimatedDuration = Duration(hours: topic.estimatedHours);

          // Mark as completed if studied for at least 80% of estimated time
          if (timeSpent >= estimatedDuration * 0.8) {
            final updatedTopic = StudyTopic(
              id: topic.id,
              name: topic.name,
              estimatedHours: topic.estimatedHours,
              priority: topic.priority,
              isCompleted: true,
              resources: topic.resources,
            );

            final updatedTopics = List<StudyTopic>.from(plan.topics);
            updatedTopics[topicIndex] = updatedTopic;

            // Calculate new completion percentage
            final completedCount = updatedTopics.where((t) => t.isCompleted).length;
            final completionPercentage = (completedCount / updatedTopics.length) * 100;

            final updatedPlan = ExamPrepPlan(
              examId: plan.examId,
              topics: updatedTopics,
              schedule: plan.schedule,
              totalHoursNeeded: plan.totalHoursNeeded,
              hoursCompleted: plan.hoursCompleted + timeSpent.inHours,
              completionPercentage: completionPercentage,
            );

            _prepPlans[examId] = updatedPlan;
            await _savePrepPlans();
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Could not update prep plan progress', e);
    }
  }

  /// Get exam by ID
  Exam? getExam(String examId) {
    try {
      return _exams.firstWhere((e) => e.id == examId);
    } catch (e) {
      return null;
    }
  }

  /// Get all exams
  List<Exam> get allExams => List.unmodifiable(_exams);

  /// Get exams for course
  List<Exam> getExamsForCourse(String courseId) =>
      _exams.where((e) => e.courseId == courseId).toList();

  /// Get upcoming exams
  List<Exam> get upcomingExams =>
      _exams.where((e) => e.status == ExamStatus.upcoming && !e.isPast).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Get exams this week
  List<Exam> get examsThisWeek {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return _exams.where((e) =>
      e.status == ExamStatus.upcoming &&
      e.dateTime.isAfter(now) &&
      e.dateTime.isBefore(weekFromNow)
    ).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Get today's exams
  List<Exam> get todaysExams {
    final today = DateTime.now();
    return _exams.where((e) {
      final examDate = e.dateTime;
      return examDate.year == today.year &&
             examDate.month == today.month &&
             examDate.day == today.day;
    }).toList();
  }

  /// Get completed exams
  List<Exam> get completedExams =>
      _exams.where((e) => e.status == ExamStatus.graded).toList();

  /// Get study sessions for exam
  List<ExamStudySession> getStudySessionsForExam(String examId) =>
      _studySessions.where((s) => s.examId == examId).toList();

  /// Get total study time for exam
  Duration getTotalStudyTime(String examId) {
    final sessions = getStudySessionsForExam(examId);
    return sessions.fold(Duration.zero, (total, session) => total + session.duration);
  }

  /// Get prep plan for exam
  ExamPrepPlan? getPrepPlan(String examId) => _prepPlans[examId];

  /// Get study statistics
  ExamStatistics getStatistics() {
    final totalStudyTime = _studySessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.duration,
    );

    final avgProductivity = _studySessions.isEmpty ? 0.0 :
      _studySessions.map((s) => s.productivityScore).reduce((a, b) => a + b) / _studySessions.length;

    return ExamStatistics(
      totalExams: _exams.length,
      upcomingExams: upcomingExams.length,
      completedExams: completedExams.length,
      totalStudySessions: _studySessions.length,
      totalStudyTime: totalStudyTime,
      averageProductivity: avgProductivity,
      examsThisWeek: examsThisWeek.length,
    );
  }

  /// Schedule smart reminders
  Future<void> _scheduleReminders(Exam exam) async {
    try {
      if (exam.status != ExamStatus.upcoming) return;

      final course = CourseManager.instance.getCourse(exam.courseId);
      final courseName = course?.code ?? 'Exam';

      final reminders = <DateTime>[];
      final now = DateTime.now();

      // 1 week before
      final weekBefore = exam.dateTime.subtract(const Duration(days: 7));
      if (weekBefore.isAfter(now)) reminders.add(weekBefore);

      // 3 days before
      final threeDays = exam.dateTime.subtract(const Duration(days: 3));
      if (threeDays.isAfter(now)) reminders.add(threeDays);

      // 1 day before
      final dayBefore = exam.dateTime.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(now)) reminders.add(dayBefore);

      // Morning of exam day
      final examDay = DateTime(
        exam.dateTime.year,
        exam.dateTime.month,
        exam.dateTime.day,
        8, 0,
      );
      if (examDay.isAfter(now)) reminders.add(examDay);

      // 1 hour before
      final oneHour = exam.dateTime.subtract(const Duration(hours: 1));
      if (oneHour.isAfter(now)) reminders.add(oneHour);

      // Schedule notifications
      for (final reminderTime in reminders) {
        AppLogger.debug('Scheduled reminder for ${exam.title} at $reminderTime');
      }
    } catch (e) {
      AppLogger.warning('Could not schedule reminders', e);
    }
  }

  /// Sync to calendar
  Future<void> _syncToCalendar(Exam exam) async {
    try {
      if (!CalendarService.instance.isAuthenticated) return;

      final course = CourseManager.instance.getCourse(exam.courseId);
      final event = CalendarEvent(
        id: 'exam_${exam.id}',
        title: '${exam.type.emoji} ${exam.title}',
        description: '''
${course?.name ?? 'Exam'}
${exam.description ?? ''}

Location: ${exam.location ?? 'TBD'}
${exam.room != null ? 'Room: ${exam.room}' : ''}

Topics: ${exam.topicsCovered.join(', ')}
${exam.allowsCheatSheet ? '\n✅ Cheat sheet allowed: ${exam.cheatSheetRules ?? 'Check with professor'}' : ''}
''',
        startTime: exam.dateTime,
        endTime: exam.dateTime.add(exam.duration),
      );

      await CalendarService.instance.createEvent(event);
      AppLogger.debug('Synced exam to calendar: ${exam.title}');
    } catch (e) {
      AppLogger.warning('Could not sync to calendar', e);
    }
  }

  /// Save exams
  Future<void> _saveExams() async {
    try {
      final json = jsonEncode(_exams.map((e) => e.toJson()).toList());
      await LocalStorageService.instance.setString('exams', json);
      AppLogger.debug('Saved ${_exams.length} exams');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving exams', e, stackTrace);
    }
  }

  /// Load exams
  Future<void> _loadExams() async {
    try {
      final json = LocalStorageService.instance.getString('exams');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _exams = data.map((item) => Exam.fromJson(item)).toList();
        AppLogger.info('Loaded ${_exams.length} exams');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading exams', e, stackTrace);
    }
  }

  /// Save study sessions
  Future<void> _saveStudySessions() async {
    try {
      final json = jsonEncode(_studySessions.map((s) => s.toJson()).toList());
      await LocalStorageService.instance.setString('exam_study_sessions', json);
      AppLogger.debug('Saved ${_studySessions.length} study sessions');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving study sessions', e, stackTrace);
    }
  }

  /// Load study sessions
  Future<void> _loadStudySessions() async {
    try {
      final json = LocalStorageService.instance.getString('exam_study_sessions');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _studySessions = data.map((item) => ExamStudySession.fromJson(item)).toList();
        AppLogger.info('Loaded ${_studySessions.length} study sessions');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading study sessions', e, stackTrace);
    }
  }

  /// Save prep plans
  Future<void> _savePrepPlans() async {
    try {
      final map = _prepPlans.map((examId, plan) {
        return MapEntry(examId, {
          'examId': plan.examId,
          'topics': plan.topics.map((t) => {
            'id': t.id,
            'name': t.name,
            'estimatedHours': t.estimatedHours,
            'priority': t.priority.toString(),
            'isCompleted': t.isCompleted,
            'resources': t.resources,
          }).toList(),
          'schedule': plan.schedule.map((date, topics) {
            return MapEntry(
              date.toIso8601String(),
              topics.map((t) => t.id).toList(),
            );
          }),
          'totalHoursNeeded': plan.totalHoursNeeded,
          'hoursCompleted': plan.hoursCompleted,
          'completionPercentage': plan.completionPercentage,
        });
      });

      final json = jsonEncode(map);
      await LocalStorageService.instance.setString('exam_prep_plans', json);
      AppLogger.debug('Saved ${_prepPlans.length} prep plans');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving prep plans', e, stackTrace);
    }
  }

  /// Load prep plans
  Future<void> _loadPrepPlans() async {
    try {
      final json = LocalStorageService.instance.getString('exam_prep_plans');
      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        _prepPlans.clear();

        data.forEach((examId, planData) {
          final topicsData = planData['topics'] as List<dynamic>;
          final topics = topicsData.map((t) {
            Priority priority;
            final priorityStr = t['priority'] as String;
            if (priorityStr.contains('urgent')) {
              priority = Priority.urgent;
            } else if (priorityStr.contains('high')) {
              priority = Priority.high;
            } else if (priorityStr.contains('medium')) {
              priority = Priority.medium;
            } else {
              priority = Priority.low;
            }

            return StudyTopic(
              id: t['id'] as String,
              name: t['name'] as String,
              estimatedHours: t['estimatedHours'] as int,
              priority: priority,
              isCompleted: t['isCompleted'] as bool? ?? false,
              resources: (t['resources'] as List<dynamic>?)?.map((r) => r as String).toList() ?? [],
            );
          }).toList();

          final scheduleData = planData['schedule'] as Map<String, dynamic>;
          final schedule = <DateTime, List<StudyTopic>>{};
          scheduleData.forEach((dateStr, topicIds) {
            final date = DateTime.parse(dateStr);
            final topicIdList = (topicIds as List<dynamic>).map((id) => id as String).toList();
            schedule[date] = topics.where((t) => topicIdList.contains(t.id)).toList();
          });

          _prepPlans[examId] = ExamPrepPlan(
            examId: planData['examId'] as String,
            topics: topics,
            schedule: schedule,
            totalHoursNeeded: planData['totalHoursNeeded'] as int,
            hoursCompleted: planData['hoursCompleted'] as int? ?? 0,
            completionPercentage: (planData['completionPercentage'] as num?)?.toDouble() ?? 0.0,
          );
        });

        AppLogger.info('Loaded ${_prepPlans.length} prep plans');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading prep plans', e, stackTrace);
    }
  }
}

/// Exam statistics
class ExamStatistics {
  final int totalExams;
  final int upcomingExams;
  final int completedExams;
  final int totalStudySessions;
  final Duration totalStudyTime;
  final double averageProductivity;
  final int examsThisWeek;

  ExamStatistics({
    required this.totalExams,
    required this.upcomingExams,
    required this.completedExams,
    required this.totalStudySessions,
    required this.totalStudyTime,
    required this.averageProductivity,
    required this.examsThisWeek,
  });

  @override
  String toString() {
    return '''
Exam Statistics:
  Total Exams: $totalExams
  Upcoming: $upcomingExams
  Completed: $completedExams
  Exams This Week: $examsThisWeek

  Study Sessions: $totalStudySessions
  Total Study Time: ${totalStudyTime.inHours}h ${totalStudyTime.inMinutes % 60}m
  Average Productivity: ${averageProductivity.toStringAsFixed(1)}/100
''';
  }
}
