import 'dart:convert';

/// Exam model for tracking exams and preparation
class Exam {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final ExamType type;
  final DateTime dateTime;
  final Duration duration;
  final String? location;
  final String? room;
  final List<String> topicsCovered;
  final List<String> studyMaterials;
  final ExamFormat format;
  final double? totalPoints;
  final double? weight;  // Percentage of final grade (0-100)
  final bool allowsCheatSheet;
  final String? cheatSheetRules;
  final String? additionalNotes;
  final ExamStatus status;
  final double? earnedScore;
  final String? letterGrade;
  final DateTime created;

  Exam({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    required this.dateTime,
    this.duration = const Duration(hours: 2),
    this.location,
    this.room,
    this.topicsCovered = const [],
    this.studyMaterials = const [],
    this.format = ExamFormat.mixed,
    this.totalPoints,
    this.weight,
    this.allowsCheatSheet = false,
    this.cheatSheetRules,
    this.additionalNotes,
    this.status = ExamStatus.upcoming,
    this.earnedScore,
    this.letterGrade,
    required this.created,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: ExamType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ExamType.exam,
      ),
      dateTime: DateTime.parse(json['dateTime'] as String),
      duration: Duration(minutes: json['durationMinutes'] as int? ?? 120),
      location: json['location'] as String?,
      room: json['room'] as String?,
      topicsCovered: (json['topicsCovered'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      studyMaterials: (json['studyMaterials'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      format: ExamFormat.values.firstWhere(
        (e) => e.toString() == json['format'],
        orElse: () => ExamFormat.mixed,
      ),
      totalPoints: (json['totalPoints'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      allowsCheatSheet: json['allowsCheatSheet'] as bool? ?? false,
      cheatSheetRules: json['cheatSheetRules'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
      status: ExamStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ExamStatus.upcoming,
      ),
      earnedScore: (json['earnedScore'] as num?)?.toDouble(),
      letterGrade: json['letterGrade'] as String?,
      created: DateTime.parse(json['created'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      if (description != null) 'description': description,
      'type': type.toString(),
      'dateTime': dateTime.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      if (location != null) 'location': location,
      if (room != null) 'room': room,
      'topicsCovered': topicsCovered,
      'studyMaterials': studyMaterials,
      'format': format.toString(),
      if (totalPoints != null) 'totalPoints': totalPoints,
      if (weight != null) 'weight': weight,
      'allowsCheatSheet': allowsCheatSheet,
      if (cheatSheetRules != null) 'cheatSheetRules': cheatSheetRules,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      'status': status.toString(),
      if (earnedScore != null) 'earnedScore': earnedScore,
      if (letterGrade != null) 'letterGrade': letterGrade,
      'created': created.toIso8601String(),
    };
  }

  /// Get days until exam
  int get daysUntil => dateTime.difference(DateTime.now()).inDays;

  /// Get hours until exam
  int get hoursUntil => dateTime.difference(DateTime.now()).inHours;

  /// Check if exam is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  /// Check if exam is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
           dateTime.month == tomorrow.month &&
           dateTime.day == tomorrow.day;
  }

  /// Check if exam is in the past
  bool get isPast => DateTime.now().isAfter(dateTime);

  /// Get percentage score if available
  double? get percentageScore {
    if (earnedScore == null || totalPoints == null || totalPoints == 0) {
      return null;
    }
    return (earnedScore! / totalPoints!) * 100;
  }

  /// Get study progress (topics covered vs total topics)
  double get studyProgress {
    if (topicsCovered.isEmpty) return 0;
    // This would be calculated based on actual study sessions
    // For now, return 0
    return 0;
  }

  Exam copyWith({
    String? title,
    String? description,
    ExamType? type,
    DateTime? dateTime,
    Duration? duration,
    String? location,
    String? room,
    List<String>? topicsCovered,
    List<String>? studyMaterials,
    ExamFormat? format,
    double? totalPoints,
    double? weight,
    bool? allowsCheatSheet,
    String? cheatSheetRules,
    String? additionalNotes,
    ExamStatus? status,
    double? earnedScore,
    String? letterGrade,
  }) {
    return Exam(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      room: room ?? this.room,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      studyMaterials: studyMaterials ?? this.studyMaterials,
      format: format ?? this.format,
      totalPoints: totalPoints ?? this.totalPoints,
      weight: weight ?? this.weight,
      allowsCheatSheet: allowsCheatSheet ?? this.allowsCheatSheet,
      cheatSheetRules: cheatSheetRules ?? this.cheatSheetRules,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      earnedScore: earnedScore ?? this.earnedScore,
      letterGrade: letterGrade ?? this.letterGrade,
      created: created,
    );
  }
}

/// Exam types
enum ExamType {
  quiz,
  exam,
  midterm,
  final_exam,
  practical,
  oral,
  comprehensive,
}

/// Exam formats
enum ExamFormat {
  multiple_choice,
  true_false,
  short_answer,
  essay,
  mixed,
  practical,
  oral,
  open_book,
  take_home,
}

/// Exam status
enum ExamStatus {
  upcoming,
  in_progress,
  completed,
  graded,
}

/// Study session for exam prep
class ExamStudySession {
  final String id;
  final String examId;
  final String? topicCovered;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final int productivityScore;  // 0-100
  final String? notes;
  final List<String> resourcesUsed;

  ExamStudySession({
    required this.id,
    required this.examId,
    this.topicCovered,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.productivityScore = 0,
    this.notes,
    this.resourcesUsed = const [],
  });

  factory ExamStudySession.fromJson(Map<String, dynamic> json) {
    return ExamStudySession(
      id: json['id'] as String,
      examId: json['examId'] as String,
      topicCovered: json['topicCovered'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      duration: Duration(minutes: json['durationMinutes'] as int),
      productivityScore: json['productivityScore'] as int? ?? 0,
      notes: json['notes'] as String?,
      resourcesUsed: (json['resourcesUsed'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      if (topicCovered != null) 'topicCovered': topicCovered,
      'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'productivityScore': productivityScore,
      if (notes != null) 'notes': notes,
      'resourcesUsed': resourcesUsed,
    };
  }
}

/// Exam preparation plan
class ExamPrepPlan {
  final String examId;
  final List<StudyTopic> topics;
  final Map<DateTime, List<StudyTopic>> schedule;
  final int totalHoursNeeded;
  final int hoursCompleted;
  final double completionPercentage;

  ExamPrepPlan({
    required this.examId,
    required this.topics,
    required this.schedule,
    required this.totalHoursNeeded,
    this.hoursCompleted = 0,
    this.completionPercentage = 0,
  });

  bool get isComplete => completionPercentage >= 100;
  int get hoursRemaining => totalHoursNeeded - hoursCompleted;
}

/// Study topic for exam
class StudyTopic {
  final String id;
  final String name;
  final int estimatedHours;
  final Priority priority;
  final bool isCompleted;
  final List<String> resources;

  StudyTopic({
    required this.id,
    required this.name,
    required this.estimatedHours,
    this.priority = Priority.medium,
    this.isCompleted = false,
    this.resources = const [],
  });
}

/// Priority levels (reuse from assignment)
enum Priority {
  low,
  medium,
  high,
  urgent,
}

/// Extension for ExamType display
extension ExamTypeExtension on ExamType {
  String get displayName {
    switch (this) {
      case ExamType.quiz:
        return 'Quiz';
      case ExamType.exam:
        return 'Exam';
      case ExamType.midterm:
        return 'Midterm';
      case ExamType.final_exam:
        return 'Final Exam';
      case ExamType.practical:
        return 'Practical';
      case ExamType.oral:
        return 'Oral Exam';
      case ExamType.comprehensive:
        return 'Comprehensive Exam';
    }
  }

  String get emoji {
    switch (this) {
      case ExamType.quiz:
        return '📋';
      case ExamType.exam:
        return '📄';
      case ExamType.midterm:
        return '📚';
      case ExamType.final_exam:
        return '🎓';
      case ExamType.practical:
        return '🔬';
      case ExamType.oral:
        return '🎤';
      case ExamType.comprehensive:
        return '📖';
    }
  }
}
