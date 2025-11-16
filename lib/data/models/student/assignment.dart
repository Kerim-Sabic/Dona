import 'dart:convert';

/// Assignment model for tracking coursework
class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final AssignmentType type;
  final DateTime dueDate;
  final Priority priority;
  final Duration? estimatedTime;
  final int completionPercentage;
  final List<Subtask> subtasks;
  final bool isCompleted;
  final DateTime? completedDate;
  final double? earnedPoints;
  final double? totalPoints;
  final String? notes;
  final List<String> attachments;
  final DateTime created;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    required this.dueDate,
    this.priority = Priority.medium,
    this.estimatedTime,
    this.completionPercentage = 0,
    this.subtasks = const [],
    this.isCompleted = false,
    this.completedDate,
    this.earnedPoints,
    this.totalPoints,
    this.notes,
    this.attachments = const [],
    required this.created,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: AssignmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AssignmentType.homework,
      ),
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: Priority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => Priority.medium,
      ),
      estimatedTime: json['estimatedMinutes'] != null
          ? Duration(minutes: json['estimatedMinutes'] as int)
          : null,
      completionPercentage: json['completionPercentage'] as int? ?? 0,
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      earnedPoints: (json['earnedPoints'] as num?)?.toDouble(),
      totalPoints: (json['totalPoints'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
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
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.toString(),
      if (estimatedTime != null) 'estimatedMinutes': estimatedTime!.inMinutes,
      'completionPercentage': completionPercentage,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
      if (completedDate != null) 'completedDate': completedDate!.toIso8601String(),
      if (earnedPoints != null) 'earnedPoints': earnedPoints,
      if (totalPoints != null) 'totalPoints': totalPoints,
      if (notes != null) 'notes': notes,
      'attachments': attachments,
      'created': created.toIso8601String(),
    };
  }

  /// Check if assignment is overdue
  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dueDate);

  /// Check if due soon (within 24 hours)
  bool get isDueSoon {
    if (isCompleted) return false;
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    return diff.inHours > 0 && diff.inHours <= 24;
  }

  /// Get days until due
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Get percentage grade if points available
  double? get percentageGrade {
    if (earnedPoints == null || totalPoints == null || totalPoints == 0) {
      return null;
    }
    return (earnedPoints! / totalPoints!) * 100;
  }

  Assignment copyWith({
    String? title,
    String? description,
    AssignmentType? type,
    DateTime? dueDate,
    Priority? priority,
    Duration? estimatedTime,
    int? completionPercentage,
    List<Subtask>? subtasks,
    bool? isCompleted,
    DateTime? completedDate,
    double? earnedPoints,
    double? totalPoints,
    String? notes,
    List<String>? attachments,
  }) {
    return Assignment(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      created: created,
    );
  }
}

/// Subtask for breaking down large assignments
class Subtask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedDate;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedDate,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      if (completedDate != null) 'completedDate': completedDate!.toIso8601String(),
    };
  }

  Subtask copyWith({
    String? title,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return Subtask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}

/// Assignment types
enum AssignmentType {
  homework,
  project,
  quiz,
  exam,
  midterm,
  final_exam,
  lab,
  presentation,
  paper,
  reading,
  discussion,
  other,
}

/// Priority levels
enum Priority {
  low,
  medium,
  high,
  urgent,
}

/// Extension for AssignmentType display
extension AssignmentTypeExtension on AssignmentType {
  String get displayName {
    switch (this) {
      case AssignmentType.homework:
        return 'Homework';
      case AssignmentType.project:
        return 'Project';
      case AssignmentType.quiz:
        return 'Quiz';
      case AssignmentType.exam:
        return 'Exam';
      case AssignmentType.midterm:
        return 'Midterm';
      case AssignmentType.final_exam:
        return 'Final Exam';
      case AssignmentType.lab:
        return 'Lab';
      case AssignmentType.presentation:
        return 'Presentation';
      case AssignmentType.paper:
        return 'Paper';
      case AssignmentType.reading:
        return 'Reading';
      case AssignmentType.discussion:
        return 'Discussion';
      case AssignmentType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case AssignmentType.homework:
        return '📝';
      case AssignmentType.project:
        return '🎯';
      case AssignmentType.quiz:
        return '📋';
      case AssignmentType.exam:
        return '📄';
      case AssignmentType.midterm:
        return '📚';
      case AssignmentType.final_exam:
        return '🎓';
      case AssignmentType.lab:
        return '🔬';
      case AssignmentType.presentation:
        return '📊';
      case AssignmentType.paper:
        return '📃';
      case AssignmentType.reading:
        return '📖';
      case AssignmentType.discussion:
        return '💬';
      case AssignmentType.other:
        return '📌';
    }
  }
}
