import '../../core/utils/logger.dart';
import '../../data/models/student/course.dart';
import '../../data/models/student/assignment.dart';
import '../../data/models/student/exam.dart';
import 'course_manager.dart';
import 'assignment_manager.dart';
import 'exam_manager.dart';
import 'gpa_calculator_service.dart';

/// Student Analytics Dashboard Service
/// Aggregates data from all student services to provide comprehensive analytics
class StudentAnalyticsService {
  static final StudentAnalyticsService _instance = StudentAnalyticsService._internal();
  static StudentAnalyticsService get instance => _instance;

  StudentAnalyticsService._internal();

  /// Initialize analytics service
  Future<void> init() async {
    try {
      AppLogger.info('StudentAnalyticsService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize StudentAnalyticsService', e, stackTrace);
    }
  }

  /// Get comprehensive dashboard overview
  Future<DashboardOverview> getDashboardOverview() async {
    try {
      // Gather data from all services
      final courses = CourseManager.instance.allCourses;
      final assignments = AssignmentManager.instance.allAssignments;
      final exams = ExamManager.instance.allExams;
      final gradeStats = GPACalculatorService.instance.getStatistics();

      // Assignment statistics
      final assignmentStats = AssignmentManager.instance.getStatistics();

      // Exam statistics
      final examStats = ExamManager.instance.getStatistics();

      // Today's schedule
      final todaysClasses = CourseManager.instance.getTodaysClasses();
      final todaysAssignments = AssignmentManager.instance.todaysAssignments;
      final todaysExams = ExamManager.instance.todaysExams;

      // Upcoming items
      final nextClass = CourseManager.instance.getNextClass();
      final dueSoonAssignments = AssignmentManager.instance.dueSoonAssignments;
      final upcomingExams = ExamManager.instance.upcomingExams.take(5).toList();

      // Warnings and alerts
      final overdueAssignments = AssignmentManager.instance.overdueAssignments;
      final failingCourses = await _getFailingCourses();

      return DashboardOverview(
        // Overview stats
        totalCourses: courses.length,
        totalAssignments: assignments.length,
        totalExams: exams.length,
        cumulativeGPA: gradeStats.cumulativeGPA,

        // Assignment stats
        incompleteAssignments: assignmentStats.incomplete,
        overdueAssignments: overdueAssignments.length,
        assignmentCompletionRate: assignmentStats.completionRate,

        // Exam stats
        upcomingExamsCount: examStats.upcomingExams,
        examsThisWeek: examStats.examsThisWeek,
        totalStudyTime: examStats.totalStudyTime,
        averageStudyProductivity: examStats.averageProductivity,

        // Today's schedule
        todaysClassesCount: todaysClasses.length,
        todaysAssignmentsCount: todaysAssignments.length,
        todaysExamsCount: todaysExams.length,
        nextClass: nextClass,

        // Upcoming items
        dueSoonCount: dueSoonAssignments.length,
        nextAssignment: dueSoonAssignments.isNotEmpty ? dueSoonAssignments.first : null,
        nextExam: upcomingExams.isNotEmpty ? upcomingExams.first : null,

        // Warnings
        hasOverdueAssignments: overdueAssignments.isNotEmpty,
        hasFailingGrades: failingCourses.isNotEmpty,
        failingCoursesCount: failingCourses.length,

        // Time
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting dashboard overview', e, stackTrace);
      rethrow;
    }
  }

  /// Get detailed academic performance report
  Future<AcademicPerformanceReport> getAcademicPerformance() async {
    try {
      final courses = CourseManager.instance.allCourses;
      final coursePerformances = <CoursePerformanceDetail>[];

      for (final course in courses) {
        final performance = await _analyzeCoursePerformance(course);
        coursePerformances.add(performance);
      }

      // Calculate overall metrics
      final avgPerformance = coursePerformances.isEmpty ? 0.0 :
        coursePerformances.fold<double>(0.0, (sum, p) => sum + p.currentGrade) / coursePerformances.length;

      final strongestCourse = coursePerformances.isEmpty ? null :
        coursePerformances.reduce((a, b) => a.currentGrade > b.currentGrade ? a : b);

      final weakestCourse = coursePerformances.isEmpty ? null :
        coursePerformances.reduce((a, b) => a.currentGrade < b.currentGrade ? a : b);

      // GPA trend
      final gpaTrend = GPACalculatorService.instance.getGPATrend();

      // Grade distribution
      final gradeDistribution = GPACalculatorService.instance.getGradeDistribution();

      return AcademicPerformanceReport(
        coursePerformances: coursePerformances,
        averagePerformance: avgPerformance,
        strongestCourse: strongestCourse,
        weakestCourse: weakestCourse,
        gpaTrend: gpaTrend.trend,
        cumulativeGPA: gpaTrend.cumulativeGPA,
        semesterGPAs: gpaTrend.semesters,
        gradeDistribution: gradeDistribution,
        generated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting academic performance', e, stackTrace);
      rethrow;
    }
  }

  /// Analyze performance for a specific course
  Future<CoursePerformanceDetail> _analyzeCoursePerformance(Course course) async {
    try {
      final courseGrade = await GPACalculatorService.instance.calculateCourseGrade(course.id);
      final assignments = AssignmentManager.instance.getAssignmentsForCourse(course.id);
      final exams = ExamManager.instance.getExamsForCourse(course.id);

      // Calculate assignment completion rate
      final completedAssignments = assignments.where((a) => a.isCompleted).length;
      final assignmentCompletionRate = assignments.isEmpty ? 0.0 :
        (completedAssignments / assignments.length) * 100;

      // Calculate average assignment grade
      final gradedAssignments = assignments.where((a) => a.earnedPoints != null).toList();
      final avgAssignmentGrade = gradedAssignments.isEmpty ? 0.0 :
        gradedAssignments.fold<double>(0.0, (sum, a) => sum + (a.percentageGrade ?? 0.0)) / gradedAssignments.length;

      // Calculate exam performance
      final gradedExams = exams.where((e) => e.earnedScore != null).toList();
      final avgExamGrade = gradedExams.isEmpty ? 0.0 :
        gradedExams.fold<double>(0.0, (sum, e) => sum + (e.percentageScore ?? 0.0)) / gradedExams.length;

      // Identify struggling areas
      final strugglingAssignments = assignments.where((a) =>
        a.earnedPoints != null && (a.percentageGrade ?? 0.0) < 70.0
      ).toList();

      // Predict final grade
      final prediction = await GPACalculatorService.instance.predictFinalGrade(course.id);

      return CoursePerformanceDetail(
        course: course,
        currentGrade: courseGrade.currentGrade,
        letterGrade: courseGrade.currentLetterGrade,
        gpa: courseGrade.currentGPA,
        assignmentCount: assignments.length,
        completedAssignments: completedAssignments,
        assignmentCompletionRate: assignmentCompletionRate,
        averageAssignmentGrade: avgAssignmentGrade,
        examCount: exams.length,
        completedExams: gradedExams.length,
        averageExamGrade: avgExamGrade,
        strugglingAreasCount: strugglingAssignments.length,
        prediction: prediction,
        trend: prediction.trend ?? 0.0,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error analyzing course performance', e, stackTrace);
      rethrow;
    }
  }

  /// Get study time analytics
  Future<StudyTimeAnalytics> getStudyTimeAnalytics() async {
    try {
      final examStats = ExamManager.instance.getStatistics();
      final courses = CourseManager.instance.allCourses;

      // Calculate time per course
      final timePerCourse = <String, Duration>{};
      for (final course in courses) {
        final exams = ExamManager.instance.getExamsForCourse(course.id);
        final totalTime = exams.fold<Duration>(
          Duration.zero,
          (total, exam) => total + ExamManager.instance.getTotalStudyTime(exam.id),
        );
        timePerCourse[course.id] = totalTime;
      }

      // Find most studied course
      String? mostStudiedCourseId;
      Duration maxTime = Duration.zero;
      timePerCourse.forEach((courseId, time) {
        if (time > maxTime) {
          maxTime = time;
          mostStudiedCourseId = courseId;
        }
      });

      final mostStudiedCourse = mostStudiedCourseId != null
        ? CourseManager.instance.getCourse(mostStudiedCourseId!)
        : null;

      // Calculate daily average
      final totalDays = 30; // Last 30 days
      final avgDailyTime = Duration(
        minutes: examStats.totalStudyTime.inMinutes ~/ totalDays,
      );

      // Study session trends
      final allExams = ExamManager.instance.allExams;
      final recentSessions = <ExamStudySession>[];
      for (final exam in allExams) {
        recentSessions.addAll(ExamManager.instance.getStudySessionsForExam(exam.id));
      }

      // Get last 7 days
      final now = DateTime.now();
      final last7Days = recentSessions.where((s) =>
        s.startTime.isAfter(now.subtract(const Duration(days: 7)))
      ).toList();

      return StudyTimeAnalytics(
        totalStudyTime: examStats.totalStudyTime,
        totalStudySessions: examStats.totalStudySessions,
        averageSessionDuration: examStats.totalStudySessions > 0
          ? Duration(minutes: examStats.totalStudyTime.inMinutes ~/ examStats.totalStudySessions)
          : Duration.zero,
        averageDailyStudyTime: avgDailyTime,
        averageProductivity: examStats.averageProductivity,
        timePerCourse: timePerCourse,
        mostStudiedCourse: mostStudiedCourse,
        sessionsLast7Days: last7Days.length,
        generated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting study time analytics', e, stackTrace);
      rethrow;
    }
  }

  /// Get productivity insights
  Future<ProductivityInsights> getProductivityInsights() async {
    try {
      final assignmentStats = AssignmentManager.instance.getStatistics();
      final examStats = ExamManager.instance.getStatistics();

      // Assignment productivity
      final onTimeRate = assignmentStats.total > 0
        ? ((assignmentStats.completed - AssignmentManager.instance.overdueAssignments.length) / assignmentStats.total) * 100
        : 0.0;

      // Study productivity
      final studyProductivity = examStats.averageProductivity;

      // Identify peak productivity times (would need more detailed tracking)
      // For now, provide general insights

      // Calculate workload balance
      final courses = CourseManager.instance.allCourses;
      final workloadPerCourse = <String, int>{};
      for (final course in courses) {
        final assignments = AssignmentManager.instance.getAssignmentsForCourse(course.id);
        final incompleteCount = assignments.where((a) => !a.isCompleted).length;
        workloadPerCourse[course.id] = incompleteCount;
      }

      // Find overloaded course
      String? overloadedCourseId;
      int maxWorkload = 0;
      workloadPerCourse.forEach((courseId, count) {
        if (count > maxWorkload) {
          maxWorkload = count;
          overloadedCourseId = courseId;
        }
      });

      final overloadedCourse = overloadedCourseId != null
        ? CourseManager.instance.getCourse(overloadedCourseId!)
        : null;

      // Generate recommendations
      final recommendations = <String>[];

      if (assignmentStats.overdue > 0) {
        recommendations.add('You have ${assignmentStats.overdue} overdue assignments. Prioritize completing them!');
      }

      if (assignmentStats.completionRate < 50) {
        recommendations.add('Your assignment completion rate is low (${assignmentStats.completionRate.toStringAsFixed(0)}%). Try breaking tasks into smaller subtasks.');
      }

      if (studyProductivity < 50) {
        recommendations.add('Your study productivity is below average. Consider using Pomodoro technique or eliminating distractions.');
      }

      if (examStats.examsThisWeek > 0) {
        recommendations.add('You have ${examStats.examsThisWeek} exam(s) this week. Make sure to follow your study plan!');
      }

      if (overloadedCourse != null && maxWorkload > 5) {
        recommendations.add('${overloadedCourse.code} has $maxWorkload pending assignments. Consider dedicating extra time to this course.');
      }

      if (assignmentStats.dueSoon > 3) {
        recommendations.add('${assignmentStats.dueSoon} assignments due soon. Start working on them now to avoid last-minute stress.');
      }

      // Study recommendations based on exam performance
      final completedExams = ExamManager.instance.completedExams;
      if (completedExams.isNotEmpty) {
        final avgScore = completedExams.fold<double>(0.0, (sum, e) => sum + (e.percentageScore ?? 0.0)) / completedExams.length;
        if (avgScore < 70) {
          recommendations.add('Your average exam score is ${avgScore.toStringAsFixed(0)}%. Consider using AI flashcards and quiz generators to improve.');
        }
      }

      return ProductivityInsights(
        assignmentCompletionRate: assignmentStats.completionRate,
        onTimeSubmissionRate: onTimeRate,
        studyProductivity: studyProductivity,
        workloadBalance: workloadPerCourse,
        overloadedCourse: overloadedCourse,
        recommendations: recommendations,
        generated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting productivity insights', e, stackTrace);
      rethrow;
    }
  }

  /// Get courses that are failing or at risk
  Future<List<Course>> _getFailingCourses() async {
    try {
      final courses = CourseManager.instance.allCourses;
      final failingCourses = <Course>[];

      for (final course in courses) {
        final courseGrade = await GPACalculatorService.instance.calculateCourseGrade(course.id);
        if (courseGrade.currentGrade < 60.0) {
          failingCourses.add(course);
        }
      }

      return failingCourses;
    } catch (e) {
      AppLogger.warning('Error getting failing courses', e);
      return [];
    }
  }

  /// Get achievement summary
  Future<AchievementSummary> getAchievements() async {
    try {
      final achievements = <Achievement>[];
      final gradeStats = GPACalculatorService.instance.getStatistics();
      final assignmentStats = AssignmentManager.instance.getStatistics();
      final examStats = ExamManager.instance.getStatistics();

      // GPA achievements
      if (gradeStats.cumulativeGPA >= 4.0) {
        achievements.add(Achievement(
          id: 'perfect_gpa',
          title: '🎓 Perfect GPA',
          description: 'Maintained a 4.0 GPA!',
          unlockedDate: DateTime.now(),
        ));
      } else if (gradeStats.cumulativeGPA >= 3.5) {
        achievements.add(Achievement(
          id: 'deans_list',
          title: '⭐ Dean\'s List',
          description: 'GPA above 3.5!',
          unlockedDate: DateTime.now(),
        ));
      }

      // Assignment achievements
      if (assignmentStats.completionRate == 100) {
        achievements.add(Achievement(
          id: 'perfect_completion',
          title: '✅ Perfect Completion',
          description: 'Completed all assignments!',
          unlockedDate: DateTime.now(),
        ));
      }

      if (assignmentStats.completed >= 50) {
        achievements.add(Achievement(
          id: 'assignment_master',
          title: '📚 Assignment Master',
          description: 'Completed 50+ assignments!',
          unlockedDate: DateTime.now(),
        ));
      }

      // Study time achievements
      if (examStats.totalStudyTime.inHours >= 100) {
        achievements.add(Achievement(
          id: 'dedicated_student',
          title: '💪 Dedicated Student',
          description: 'Studied for 100+ hours!',
          unlockedDate: DateTime.now(),
        ));
      }

      if (examStats.totalStudySessions >= 50) {
        achievements.add(Achievement(
          id: 'study_warrior',
          title: '⚡ Study Warrior',
          description: 'Completed 50+ study sessions!',
          unlockedDate: DateTime.now(),
        ));
      }

      // Exam achievements
      final completedExams = ExamManager.instance.completedExams;
      final perfectExams = completedExams.where((e) => (e.percentageScore ?? 0.0) >= 95.0).length;
      if (perfectExams >= 5) {
        achievements.add(Achievement(
          id: 'exam_ace',
          title: '🏆 Exam Ace',
          description: 'Scored 95%+ on 5 exams!',
          unlockedDate: DateTime.now(),
        ));
      }

      // Streak achievements
      // (Would need more detailed tracking for actual streaks)
      if (assignmentStats.overdue == 0 && assignmentStats.total > 10) {
        achievements.add(Achievement(
          id: 'on_time_streak',
          title: '⏰ On-Time Streak',
          description: 'No overdue assignments!',
          unlockedDate: DateTime.now(),
        ));
      }

      return AchievementSummary(
        achievements: achievements,
        totalPoints: achievements.length * 100,
        level: _calculateLevel(achievements.length),
        generated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error getting achievements', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate user level based on achievements
  int _calculateLevel(int achievementCount) {
    // Simple level calculation: 1 level per 3 achievements
    return 1 + (achievementCount ~/ 3);
  }
}

/// Dashboard overview model
class DashboardOverview {
  final int totalCourses;
  final int totalAssignments;
  final int totalExams;
  final double cumulativeGPA;

  final int incompleteAssignments;
  final int overdueAssignments;
  final double assignmentCompletionRate;

  final int upcomingExamsCount;
  final int examsThisWeek;
  final Duration totalStudyTime;
  final double averageStudyProductivity;

  final int todaysClassesCount;
  final int todaysAssignmentsCount;
  final int todaysExamsCount;
  final dynamic nextClass;

  final int dueSoonCount;
  final Assignment? nextAssignment;
  final Exam? nextExam;

  final bool hasOverdueAssignments;
  final bool hasFailingGrades;
  final int failingCoursesCount;

  final DateTime lastUpdated;

  DashboardOverview({
    required this.totalCourses,
    required this.totalAssignments,
    required this.totalExams,
    required this.cumulativeGPA,
    required this.incompleteAssignments,
    required this.overdueAssignments,
    required this.assignmentCompletionRate,
    required this.upcomingExamsCount,
    required this.examsThisWeek,
    required this.totalStudyTime,
    required this.averageStudyProductivity,
    required this.todaysClassesCount,
    required this.todaysAssignmentsCount,
    required this.todaysExamsCount,
    this.nextClass,
    required this.dueSoonCount,
    this.nextAssignment,
    this.nextExam,
    required this.hasOverdueAssignments,
    required this.hasFailingGrades,
    required this.failingCoursesCount,
    required this.lastUpdated,
  });
}

/// Academic performance report
class AcademicPerformanceReport {
  final List<CoursePerformanceDetail> coursePerformances;
  final double averagePerformance;
  final CoursePerformanceDetail? strongestCourse;
  final CoursePerformanceDetail? weakestCourse;
  final String gpaTrend;
  final double cumulativeGPA;
  final List<dynamic> semesterGPAs;
  final Map<String, int> gradeDistribution;
  final DateTime generated;

  AcademicPerformanceReport({
    required this.coursePerformances,
    required this.averagePerformance,
    this.strongestCourse,
    this.weakestCourse,
    required this.gpaTrend,
    required this.cumulativeGPA,
    required this.semesterGPAs,
    required this.gradeDistribution,
    required this.generated,
  });
}

/// Course performance detail
class CoursePerformanceDetail {
  final Course course;
  final double currentGrade;
  final String letterGrade;
  final double gpa;
  final int assignmentCount;
  final int completedAssignments;
  final double assignmentCompletionRate;
  final double averageAssignmentGrade;
  final int examCount;
  final int completedExams;
  final double averageExamGrade;
  final int strugglingAreasCount;
  final dynamic prediction;
  final double trend;

  CoursePerformanceDetail({
    required this.course,
    required this.currentGrade,
    required this.letterGrade,
    required this.gpa,
    required this.assignmentCount,
    required this.completedAssignments,
    required this.assignmentCompletionRate,
    required this.averageAssignmentGrade,
    required this.examCount,
    required this.completedExams,
    required this.averageExamGrade,
    required this.strugglingAreasCount,
    required this.prediction,
    required this.trend,
  });
}

/// Study time analytics
class StudyTimeAnalytics {
  final Duration totalStudyTime;
  final int totalStudySessions;
  final Duration averageSessionDuration;
  final Duration averageDailyStudyTime;
  final double averageProductivity;
  final Map<String, Duration> timePerCourse;
  final Course? mostStudiedCourse;
  final int sessionsLast7Days;
  final DateTime generated;

  StudyTimeAnalytics({
    required this.totalStudyTime,
    required this.totalStudySessions,
    required this.averageSessionDuration,
    required this.averageDailyStudyTime,
    required this.averageProductivity,
    required this.timePerCourse,
    this.mostStudiedCourse,
    required this.sessionsLast7Days,
    required this.generated,
  });
}

/// Productivity insights
class ProductivityInsights {
  final double assignmentCompletionRate;
  final double onTimeSubmissionRate;
  final double studyProductivity;
  final Map<String, int> workloadBalance;
  final Course? overloadedCourse;
  final List<String> recommendations;
  final DateTime generated;

  ProductivityInsights({
    required this.assignmentCompletionRate,
    required this.onTimeSubmissionRate,
    required this.studyProductivity,
    required this.workloadBalance,
    this.overloadedCourse,
    required this.recommendations,
    required this.generated,
  });
}

/// Achievement
class Achievement {
  final String id;
  final String title;
  final String description;
  final DateTime unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockedDate,
  });
}

/// Achievement summary
class AchievementSummary {
  final List<Achievement> achievements;
  final int totalPoints;
  final int level;
  final DateTime generated;

  AchievementSummary({
    required this.achievements,
    required this.totalPoints,
    required this.level,
    required this.generated,
  });
}
