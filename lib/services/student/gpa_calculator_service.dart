import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../data/models/student/grade.dart';
import '../../data/models/student/course.dart';
import '../../data/models/student/assignment.dart';
import '../storage/local_storage_service.dart';
import 'course_manager.dart';
import 'assignment_manager.dart';

/// GPA Calculator Service
/// Manages all grade calculations, GPA tracking, and "what if" scenarios
class GPACalculatorService {
  static final GPACalculatorService _instance = GPACalculatorService._internal();
  static GPACalculatorService get instance => _instance;

  GPACalculatorService._internal();

  List<Grade> _grades = [];
  List<SemesterGPA> _semesters = [];
  final GPACalculator _calculator = GPACalculator();

  /// Initialize GPA calculator service
  Future<void> init() async {
    try {
      await _loadGrades();
      await _loadSemesters();
      AppLogger.info('GPACalculatorService initialized with ${_grades.length} grades');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GPACalculatorService', e, stackTrace);
    }
  }

  /// Add a grade for an assignment
  Future<Grade> addGrade({
    required String courseId,
    String? assignmentId,
    required double earnedPoints,
    required double totalPoints,
    String? notes,
    GradeType type = GradeType.assignment,
  }) async {
    try {
      final percentage = (earnedPoints / totalPoints) * 100;
      final letterGrade = _calculator.percentageToLetter(percentage);
      final gpaValue = _calculator.percentageToGPA(percentage);

      final grade = Grade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        assignmentId: assignmentId,
        courseId: courseId,
        earnedPoints: earnedPoints,
        totalPoints: totalPoints,
        letterGrade: letterGrade,
        gpaValue: gpaValue,
        date: DateTime.now(),
        notes: notes,
        type: type,
      );

      _grades.add(grade);
      await _saveGrades();

      AppLogger.info('Added grade: $letterGrade (${percentage.toStringAsFixed(1)}%) for course $courseId');
      return grade;
    } catch (e, stackTrace) {
      AppLogger.error('Error adding grade', e, stackTrace);
      rethrow;
    }
  }

  /// Update a grade
  Future<void> updateGrade(Grade grade) async {
    try {
      final index = _grades.indexWhere((g) => g.id == grade.id);
      if (index != -1) {
        _grades[index] = grade;
        await _saveGrades();
        AppLogger.info('Updated grade: ${grade.id}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating grade', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a grade
  Future<bool> deleteGrade(String gradeId) async {
    try {
      final removedCount = _grades.removeWhere((g) => g.id == gradeId);
      if (removedCount > 0) {
        await _saveGrades();
        AppLogger.info('Deleted grade: $gradeId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting grade', e, stackTrace);
      return false;
    }
  }

  /// Get grade by ID
  Grade? getGrade(String gradeId) {
    try {
      return _grades.firstWhere((g) => g.id == gradeId);
    } catch (e) {
      return null;
    }
  }

  /// Get all grades
  List<Grade> get allGrades => List.unmodifiable(_grades);

  /// Get grades for a specific course
  List<Grade> getGradesForCourse(String courseId) =>
      _grades.where((g) => g.courseId == courseId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Get grades for a specific assignment
  Grade? getGradeForAssignment(String assignmentId) {
    try {
      return _grades.firstWhere((g) => g.assignmentId == assignmentId);
    } catch (e) {
      return null;
    }
  }

  /// Calculate current course grade
  CourseGrade calculateCourseGrade(String courseId, {Map<String, double>? categoryWeights}) async {
    try {
      final course = CourseManager.instance.getCourse(courseId);
      if (course == null) {
        throw Exception('Course not found: $courseId');
      }

      final courseGrades = getGradesForCourse(courseId);

      if (courseGrades.isEmpty) {
        return CourseGrade(
          courseId: courseId,
          grades: [],
          currentGrade: 0.0,
          currentLetterGrade: 'N/A',
          currentGPA: 0.0,
        );
      }

      // Calculate weighted average if category weights provided
      double totalGrade;
      if (categoryWeights != null && categoryWeights.isNotEmpty) {
        totalGrade = _calculateWeightedGrade(courseGrades, categoryWeights);
      } else {
        // Simple average
        final totalPercentage = courseGrades.fold<double>(
          0.0,
          (sum, grade) => sum + grade.percentage,
        );
        totalGrade = totalPercentage / courseGrades.length;
      }

      final letterGrade = _calculator.percentageToLetter(totalGrade);
      final gpaValue = _calculator.percentageToGPA(totalGrade);

      return CourseGrade(
        courseId: courseId,
        grades: courseGrades,
        categoryWeights: categoryWeights ?? {},
        currentGrade: totalGrade,
        currentLetterGrade: letterGrade,
        currentGPA: gpaValue,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating course grade', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate weighted grade from category weights
  double _calculateWeightedGrade(List<Grade> grades, Map<String, double> categoryWeights) {
    // Group grades by type
    final gradesByType = <GradeType, List<Grade>>{};
    for (final grade in grades) {
      gradesByType[grade.type] = gradesByType[grade.type] ?? [];
      gradesByType[grade.type]!.add(grade);
    }

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    // Calculate average for each category and apply weight
    gradesByType.forEach((type, typeGrades) {
      final categoryName = type.toString().split('.').last;
      final weight = categoryWeights[categoryName] ?? 0.0;

      if (weight > 0 && typeGrades.isNotEmpty) {
        final categoryAverage = typeGrades.fold<double>(
          0.0,
          (sum, grade) => sum + grade.percentage,
        ) / typeGrades.length;

        weightedSum += categoryAverage * weight;
        totalWeight += weight;
      }
    });

    if (totalWeight == 0) return 0.0;
    return weightedSum / totalWeight;
  }

  /// Calculate "What If" grade scenario
  WhatIfResult calculateWhatIfGrade({
    required String courseId,
    required double targetGrade,
    required double remainingWeight,
    Map<String, double>? categoryWeights,
  }) async {
    try {
      final courseGrade = await calculateCourseGrade(courseId, categoryWeights: categoryWeights);
      return courseGrade.calculateWhatIfGrade(
        targetGrade: targetGrade,
        remainingWeight: remainingWeight,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating what-if grade', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate semester GPA
  Future<double> calculateSemesterGPA(String semester) async {
    try {
      final courses = CourseManager.instance.getCoursesForSemester(semester);
      final courseGrades = <CourseGrade>[];
      final credits = <String, int>{};

      for (final course in courses) {
        final courseGrade = await calculateCourseGrade(course.id);
        courseGrades.add(courseGrade);
        credits[course.id] = course.credits;
      }

      return _calculator.calculateSemesterGPA(courseGrades, credits);
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating semester GPA', e, stackTrace);
      return 0.0;
    }
  }

  /// Calculate cumulative GPA
  double calculateCumulativeGPA() {
    if (_semesters.isEmpty) return 0.0;
    return _calculator.calculateCumulativeGPA(_semesters);
  }

  /// Save semester GPA
  Future<void> saveSemesterGPA(String semester) async {
    try {
      final courses = CourseManager.instance.getCoursesForSemester(semester);
      final courseGrades = <CourseGrade>[];
      int totalCredits = 0;

      for (final course in courses) {
        final courseGrade = await calculateCourseGrade(course.id);
        courseGrades.add(courseGrade);
        totalCredits += course.credits;
      }

      final credits = courses.fold<Map<String, int>>(
        {},
        (map, course) {
          map[course.id] = course.credits;
          return map;
        },
      );

      final gpa = _calculator.calculateSemesterGPA(courseGrades, credits);

      final semesterGPA = SemesterGPA(
        semester: semester,
        gpa: gpa,
        credits: totalCredits,
        courses: courseGrades,
      );

      // Remove old entry if exists
      _semesters.removeWhere((s) => s.semester == semester);
      _semesters.add(semesterGPA);

      await _saveSemesters();

      AppLogger.info('Saved semester GPA for $semester: ${gpa.toStringAsFixed(2)}');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving semester GPA', e, stackTrace);
    }
  }

  /// Get GPA trend analysis
  GPATrend getGPATrend() {
    return GPATrend.fromSemesters(_semesters);
  }

  /// Get semester by name
  SemesterGPA? getSemester(String semester) {
    try {
      return _semesters.firstWhere((s) => s.semester == semester);
    } catch (e) {
      return null;
    }
  }

  /// Get all semesters
  List<SemesterGPA> get allSemesters => List.unmodifiable(_semesters);

  /// Predict final grade based on current progress
  Future<GradePrediction> predictFinalGrade(String courseId) async {
    try {
      final courseGrade = await calculateCourseGrade(courseId);
      final assignments = AssignmentManager.instance.getAssignmentsForCourse(courseId);

      // Calculate completed weight
      final completedAssignments = assignments.where((a) => a.isCompleted).toList();
      final totalAssignments = assignments.length;

      if (totalAssignments == 0 || completedAssignments.isEmpty) {
        return GradePrediction(
          courseId: courseId,
          currentGrade: 0.0,
          predictedGrade: 0.0,
          confidence: 0.0,
          remainingWeight: 100.0,
          message: 'Not enough data for prediction',
        );
      }

      // Simple prediction: assume same performance continues
      final completionRate = completedAssignments.length / totalAssignments;
      final remainingWeight = (1 - completionRate) * 100;

      // Conservative prediction: current grade continues
      final predictedGrade = courseGrade.currentGrade;

      // Optimistic prediction: improvement trend
      final recentGrades = courseGrade.grades.take(5).toList();
      double trend = 0.0;
      if (recentGrades.length >= 2) {
        final oldAvg = recentGrades.sublist(recentGrades.length ~/ 2).fold<double>(
          0.0, (sum, g) => sum + g.percentage) / (recentGrades.length ~/ 2);
        final newAvg = recentGrades.take(recentGrades.length ~/ 2).fold<double>(
          0.0, (sum, g) => sum + g.percentage) / (recentGrades.length ~/ 2);
        trend = newAvg - oldAvg;
      }

      final optimisticGrade = predictedGrade + (trend * 0.5);
      final confidence = completionRate * 100;

      String message;
      if (predictedGrade >= 90) {
        message = 'Excellent! You\'re on track for an A';
      } else if (predictedGrade >= 80) {
        message = 'Great work! Predicted grade: B range';
      } else if (predictedGrade >= 70) {
        message = 'Good progress. Predicted grade: C range';
      } else if (predictedGrade >= 60) {
        message = 'Keep working! You\'re passing but can improve';
      } else {
        message = 'Warning: Current trend shows failing grade. Seek help!';
      }

      return GradePrediction(
        courseId: courseId,
        currentGrade: courseGrade.currentGrade,
        predictedGrade: predictedGrade,
        optimisticGrade: optimisticGrade,
        confidence: confidence,
        remainingWeight: remainingWeight,
        trend: trend,
        message: message,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error predicting final grade', e, stackTrace);
      rethrow;
    }
  }

  /// Get grade statistics
  GradeStatistics getStatistics() {
    if (_grades.isEmpty) {
      return GradeStatistics(
        totalGrades: 0,
        averageGrade: 0.0,
        highestGrade: 0.0,
        lowestGrade: 0.0,
        passingRate: 0.0,
        cumulativeGPA: 0.0,
      );
    }

    final percentages = _grades.map((g) => g.percentage).toList();
    final avgGrade = percentages.reduce((a, b) => a + b) / percentages.length;
    final highest = percentages.reduce((a, b) => a > b ? a : b);
    final lowest = percentages.reduce((a, b) => a < b ? a : b);
    final passingCount = _grades.where((g) => g.isPassing).length;
    final passingRate = (passingCount / _grades.length) * 100;

    return GradeStatistics(
      totalGrades: _grades.length,
      averageGrade: avgGrade,
      highestGrade: highest,
      lowestGrade: lowest,
      passingRate: passingRate,
      cumulativeGPA: calculateCumulativeGPA(),
      semesterCount: _semesters.length,
    );
  }

  /// Get visualization data for grade distribution
  Map<String, int> getGradeDistribution() {
    final distribution = <String, int>{
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };

    for (final grade in _grades) {
      final letter = grade.letterGrade ?? 'F';
      final baseGrade = letter.substring(0, 1);
      distribution[baseGrade] = (distribution[baseGrade] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get visualization data for GPA trend over time
  List<GPATrendPoint> getGPATrendData() {
    return _semesters.map((semester) {
      return GPATrendPoint(
        semester: semester.semester,
        gpa: semester.gpa,
        credits: semester.credits,
      );
    }).toList();
  }

  /// Get visualization data for course performance
  List<CoursePerformance> getCoursePerformanceData() async {
    final courses = CourseManager.instance.allCourses;
    final performanceData = <CoursePerformance>[];

    for (final course in courses) {
      final courseGrade = await calculateCourseGrade(course.id);
      if (courseGrade.grades.isNotEmpty) {
        performanceData.add(CoursePerformance(
          courseId: course.id,
          courseName: course.name,
          courseCode: course.code,
          currentGrade: courseGrade.currentGrade,
          letterGrade: courseGrade.currentLetterGrade,
          gpa: courseGrade.currentGPA,
          gradeCount: courseGrade.grades.length,
        ));
      }
    }

    return performanceData..sort((a, b) => b.currentGrade.compareTo(a.currentGrade));
  }

  /// Save grades
  Future<void> _saveGrades() async {
    try {
      final json = jsonEncode(_grades.map((g) => g.toJson()).toList());
      await LocalStorageService.instance.setString('grades', json);
      AppLogger.debug('Saved ${_grades.length} grades');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving grades', e, stackTrace);
    }
  }

  /// Load grades
  Future<void> _loadGrades() async {
    try {
      final json = LocalStorageService.instance.getString('grades');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _grades = data.map((item) => Grade.fromJson(item)).toList();
        AppLogger.info('Loaded ${_grades.length} grades');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading grades', e, stackTrace);
    }
  }

  /// Save semesters
  Future<void> _saveSemesters() async {
    try {
      final json = jsonEncode(_semesters.map((s) => {
        'semester': s.semester,
        'gpa': s.gpa,
        'credits': s.credits,
        'courses': s.courses.map((c) => {
          'courseId': c.courseId,
          'currentGrade': c.currentGrade,
          'currentLetterGrade': c.currentLetterGrade,
          'currentGPA': c.currentGPA,
        }).toList(),
      }).toList());

      await LocalStorageService.instance.setString('semesters', json);
      AppLogger.debug('Saved ${_semesters.length} semesters');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving semesters', e, stackTrace);
    }
  }

  /// Load semesters
  Future<void> _loadSemesters() async {
    try {
      final json = LocalStorageService.instance.getString('semesters');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _semesters = data.map((item) {
          final courses = (item['courses'] as List<dynamic>).map((c) {
            return CourseGrade(
              courseId: c['courseId'] as String,
              grades: [], // Grades are loaded separately
              currentGrade: (c['currentGrade'] as num).toDouble(),
              currentLetterGrade: c['currentLetterGrade'] as String,
              currentGPA: (c['currentGPA'] as num).toDouble(),
            );
          }).toList();

          return SemesterGPA(
            semester: item['semester'] as String,
            gpa: (item['gpa'] as num).toDouble(),
            credits: item['credits'] as int,
            courses: courses,
          );
        }).toList();

        AppLogger.info('Loaded ${_semesters.length} semesters');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading semesters', e, stackTrace);
    }
  }
}

/// Grade prediction result
class GradePrediction {
  final String courseId;
  final double currentGrade;
  final double predictedGrade;
  final double? optimisticGrade;
  final double confidence;
  final double remainingWeight;
  final double? trend;
  final String message;

  GradePrediction({
    required this.courseId,
    required this.currentGrade,
    required this.predictedGrade,
    this.optimisticGrade,
    required this.confidence,
    required this.remainingWeight,
    this.trend,
    required this.message,
  });

  @override
  String toString() {
    return '''
Grade Prediction:
  Current: ${currentGrade.toStringAsFixed(1)}%
  Predicted: ${predictedGrade.toStringAsFixed(1)}%
  ${optimisticGrade != null ? 'Optimistic: ${optimisticGrade!.toStringAsFixed(1)}%' : ''}
  Confidence: ${confidence.toStringAsFixed(0)}%
  Remaining: ${remainingWeight.toStringAsFixed(1)}%

  $message
''';
  }
}

/// Grade statistics
class GradeStatistics {
  final int totalGrades;
  final double averageGrade;
  final double highestGrade;
  final double lowestGrade;
  final double passingRate;
  final double cumulativeGPA;
  final int? semesterCount;

  GradeStatistics({
    required this.totalGrades,
    required this.averageGrade,
    required this.highestGrade,
    required this.lowestGrade,
    required this.passingRate,
    required this.cumulativeGPA,
    this.semesterCount,
  });

  @override
  String toString() {
    return '''
Grade Statistics:
  Total Grades: $totalGrades
  Average: ${averageGrade.toStringAsFixed(1)}%
  Highest: ${highestGrade.toStringAsFixed(1)}%
  Lowest: ${lowestGrade.toStringAsFixed(1)}%
  Passing Rate: ${passingRate.toStringAsFixed(1)}%
  Cumulative GPA: ${cumulativeGPA.toStringAsFixed(2)}
  ${semesterCount != null ? 'Semesters: $semesterCount' : ''}
''';
  }
}

/// GPA trend point for visualization
class GPATrendPoint {
  final String semester;
  final double gpa;
  final int credits;

  GPATrendPoint({
    required this.semester,
    required this.gpa,
    required this.credits,
  });
}

/// Course performance data for visualization
class CoursePerformance {
  final String courseId;
  final String courseName;
  final String courseCode;
  final double currentGrade;
  final String letterGrade;
  final double gpa;
  final int gradeCount;

  CoursePerformance({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.currentGrade,
    required this.letterGrade,
    required this.gpa,
    required this.gradeCount,
  });
}
