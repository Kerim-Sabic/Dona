import 'dart:convert';

/// Grade model for tracking grades on assignments and courses
class Grade {
  final String id;
  final String? assignmentId;  // If null, this is a course grade
  final String courseId;
  final double earnedPoints;
  final double totalPoints;
  final String? letterGrade;
  final double? gpaValue;  // On 4.0 or 5.0 scale
  final DateTime date;
  final String? notes;
  final GradeType type;

  Grade({
    required this.id,
    this.assignmentId,
    required this.courseId,
    required this.earnedPoints,
    required this.totalPoints,
    this.letterGrade,
    this.gpaValue,
    required this.date,
    this.notes,
    this.type = GradeType.assignment,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as String,
      assignmentId: json['assignmentId'] as String?,
      courseId: json['courseId'] as String,
      earnedPoints: (json['earnedPoints'] as num).toDouble(),
      totalPoints: (json['totalPoints'] as num).toDouble(),
      letterGrade: json['letterGrade'] as String?,
      gpaValue: (json['gpaValue'] as num?)?.toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      type: GradeType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => GradeType.assignment,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (assignmentId != null) 'assignmentId': assignmentId,
      'courseId': courseId,
      'earnedPoints': earnedPoints,
      'totalPoints': totalPoints,
      if (letterGrade != null) 'letterGrade': letterGrade,
      if (gpaValue != null) 'gpaValue': gpaValue,
      'date': date.toIso8601String(),
      if (notes != null) 'notes': notes,
      'type': type.toString(),
    };
  }

  /// Calculate percentage
  double get percentage {
    if (totalPoints == 0) return 0;
    return (earnedPoints / totalPoints) * 100;
  }

  /// Check if passing (>= 60%)
  bool get isPassing => percentage >= 60;

  Grade copyWith({
    double? earnedPoints,
    double? totalPoints,
    String? letterGrade,
    double? gpaValue,
    String? notes,
  }) {
    return Grade(
      id: id,
      assignmentId: assignmentId,
      courseId: courseId,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      letterGrade: letterGrade ?? this.letterGrade,
      gpaValue: gpaValue ?? this.gpaValue,
      date: date,
      notes: notes ?? this.notes,
      type: type,
    );
  }
}

/// Grade type
enum GradeType {
  assignment,
  exam,
  midterm,
  final_exam,
  course,  // Final course grade
}

/// Course grade summary
class CourseGrade {
  final String courseId;
  final List<Grade> grades;
  final Map<String, double> categoryWeights;  // e.g., {'homework': 0.3, 'exams': 0.5, 'final': 0.2}
  final double currentGrade;
  final String currentLetterGrade;
  final double currentGPA;

  CourseGrade({
    required this.courseId,
    required this.grades,
    this.categoryWeights = const {},
    required this.currentGrade,
    required this.currentLetterGrade,
    required this.currentGPA,
  });

  /// Calculate what grade is needed on remaining work to achieve target
  WhatIfResult calculateWhatIfGrade({
    required double targetGrade,
    required double remainingWeight,
  }) {
    // Current grade contribution
    final currentContribution = currentGrade * (1 - remainingWeight);

    // Grade needed on remaining work
    final neededOnRemaining = (targetGrade - currentContribution) / remainingWeight;

    return WhatIfResult(
      targetGrade: targetGrade,
      currentGrade: currentGrade,
      neededGrade: neededOnRemaining,
      isAchievable: neededOnRemaining <= 100 && neededOnRemaining >= 0,
      message: _generateWhatIfMessage(targetGrade, neededOnRemaining),
    );
  }

  String _generateWhatIfMessage(double target, double needed) {
    if (needed > 100) {
      return 'Target of ${target.toStringAsFixed(1)}% is not achievable. Even with 100% on remaining work, you\'ll fall short.';
    } else if (needed < 0) {
      return 'You\'ve already achieved ${target.toStringAsFixed(1)}%! Great work!';
    } else if (needed >= 95) {
      return 'You need ${needed.toStringAsFixed(1)}% on remaining work to get ${target.toStringAsFixed(1)}%. Very challenging but possible!';
    } else if (needed >= 80) {
      return 'You need ${needed.toStringAsFixed(1)}% on remaining work to get ${target.toStringAsFixed(1)}%. Study hard!';
    } else {
      return 'You need ${needed.toStringAsFixed(1)}% on remaining work to get ${target.toStringAsFixed(1)}%. Very achievable!';
    }
  }
}

/// What-if calculation result
class WhatIfResult {
  final double targetGrade;
  final double currentGrade;
  final double neededGrade;
  final bool isAchievable;
  final String message;

  WhatIfResult({
    required this.targetGrade,
    required this.currentGrade,
    required this.neededGrade,
    required this.isAchievable,
    required this.message,
  });
}

/// GPA Calculator
class GPACalculator {
  final GPAScale scale;

  GPACalculator({this.scale = GPAScale.scale_4_0});

  /// Convert percentage to letter grade
  String percentageToLetter(double percentage) {
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 63) return 'D';
    if (percentage >= 60) return 'D-';
    return 'F';
  }

  /// Convert letter grade to GPA value
  double letterToGPA(String letter) {
    switch (scale) {
      case GPAScale.scale_4_0:
        return _letterToGPA4_0(letter);
      case GPAScale.scale_5_0:
        return _letterToGPA5_0(letter);
      case GPAScale.pass_fail:
        return letter == 'P' ? 4.0 : 0.0;
    }
  }

  double _letterToGPA4_0(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
      case 'A+':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'D-':
        return 0.7;
      default:
        return 0.0;  // F
    }
  }

  double _letterToGPA5_0(String letter) {
    // Weighted/honors scale
    switch (letter.toUpperCase()) {
      case 'A':
      case 'A+':
        return 5.0;
      case 'A-':
        return 4.7;
      case 'B+':
        return 4.3;
      case 'B':
        return 4.0;
      case 'B-':
        return 3.7;
      case 'C+':
        return 3.3;
      case 'C':
        return 3.0;
      case 'C-':
        return 2.7;
      case 'D+':
        return 2.3;
      case 'D':
        return 2.0;
      case 'D-':
        return 1.7;
      default:
        return 0.0;  // F
    }
  }

  /// Convert percentage to GPA
  double percentageToGPA(double percentage) {
    final letter = percentageToLetter(percentage);
    return letterToGPA(letter);
  }

  /// Calculate semester GPA
  double calculateSemesterGPA(List<CourseGrade> courseGrades, Map<String, int> credits) {
    double totalPoints = 0;
    int totalCredits = 0;

    for (final courseGrade in courseGrades) {
      final courseCredits = credits[courseGrade.courseId] ?? 3;
      totalPoints += courseGrade.currentGPA * courseCredits;
      totalCredits += courseCredits;
    }

    if (totalCredits == 0) return 0.0;
    return totalPoints / totalCredits;
  }

  /// Calculate cumulative GPA
  double calculateCumulativeGPA(List<SemesterGPA> semesters) {
    double totalPoints = 0;
    int totalCredits = 0;

    for (final semester in semesters) {
      totalPoints += semester.gpa * semester.credits;
      totalCredits += semester.credits;
    }

    if (totalCredits == 0) return 0.0;
    return totalPoints / totalCredits;
  }
}

/// GPA Scale types
enum GPAScale {
  scale_4_0,   // Standard 4.0 scale
  scale_5_0,   // Weighted/honors 5.0 scale
  pass_fail,   // Pass/Fail system
}

/// Semester GPA summary
class SemesterGPA {
  final String semester;
  final double gpa;
  final int credits;
  final List<CourseGrade> courses;

  SemesterGPA({
    required this.semester,
    required this.gpa,
    required this.credits,
    required this.courses,
  });
}

/// GPA Trend
class GPATrend {
  final List<SemesterGPA> semesters;
  final double cumulativeGPA;
  final double highestSemester;
  final double lowestSemester;
  final String trend;  // 'improving', 'declining', 'stable'

  GPATrend({
    required this.semesters,
    required this.cumulativeGPA,
    required this.highestSemester,
    required this.lowestSemester,
    required this.trend,
  });

  factory GPATrend.fromSemesters(List<SemesterGPA> semesters) {
    if (semesters.isEmpty) {
      return GPATrend(
        semesters: [],
        cumulativeGPA: 0.0,
        highestSemester: 0.0,
        lowestSemester: 0.0,
        trend: 'stable',
      );
    }

    final calculator = GPACalculator();
    final cumulative = calculator.calculateCumulativeGPA(semesters);
    final highest = semesters.map((s) => s.gpa).reduce((a, b) => a > b ? a : b);
    final lowest = semesters.map((s) => s.gpa).reduce((a, b) => a < b ? a : b);

    // Determine trend
    String trend = 'stable';
    if (semesters.length >= 2) {
      final recent = semesters.sublist(semesters.length - 2);
      if (recent[1].gpa > recent[0].gpa + 0.1) {
        trend = 'improving';
      } else if (recent[1].gpa < recent[0].gpa - 0.1) {
        trend = 'declining';
      }
    }

    return GPATrend(
      semesters: semesters,
      cumulativeGPA: cumulative,
      highestSemester: highest,
      lowestSemester: lowest,
      trend: trend,
    );
  }
}
