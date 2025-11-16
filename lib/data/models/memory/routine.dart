/// User routine model for recurring patterns and behaviors
class UserRoutine {
  final String id;
  final String routineType; // 'daily', 'weekly', 'monthly', 'location_based'
  final String pattern; // Description of the pattern
  final String? timeOfDay; // 'morning', 'afternoon', 'evening', 'night'
  final String? dayOfWeek; // For weekly patterns
  final String? location; // For location-based routines
  final double confidence; // 0.0 - 1.0 (how consistent is this?)
  final DateTime firstObserved;
  final DateTime lastObserved;
  final int occurrenceCount;
  final Map<String, dynamic>? metadata;

  UserRoutine({
    required this.id,
    required this.routineType,
    required this.pattern,
    this.timeOfDay,
    this.dayOfWeek,
    this.location,
    required this.confidence,
    required this.firstObserved,
    required this.lastObserved,
    this.occurrenceCount = 1,
    this.metadata,
  });

  UserRoutine copyWith({
    String? id,
    String? routineType,
    String? pattern,
    String? timeOfDay,
    String? dayOfWeek,
    String? location,
    double? confidence,
    DateTime? firstObserved,
    DateTime? lastObserved,
    int? occurrenceCount,
    Map<String, dynamic>? metadata,
  }) {
    return UserRoutine(
      id: id ?? this.id,
      routineType: routineType ?? this.routineType,
      pattern: pattern ?? this.pattern,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      location: location ?? this.location,
      confidence: confidence ?? this.confidence,
      firstObserved: firstObserved ?? this.firstObserved,
      lastObserved: lastObserved ?? this.lastObserved,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Reinforce routine (observed again)
  UserRoutine reinforced() {
    final newConfidence = (confidence + 0.05).clamp(0.0, 1.0);
    return copyWith(
      confidence: newConfidence,
      lastObserved: DateTime.now(),
      occurrenceCount: occurrenceCount + 1,
    );
  }

  /// Check if routine is currently active (should be happening now)
  bool isActiveNow({DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();

    if (routineType == RoutineType.daily && timeOfDay != null) {
      return _matchesTimeOfDay(now, timeOfDay!);
    }

    if (routineType == RoutineType.weekly && dayOfWeek != null) {
      return _matchesDayOfWeek(now, dayOfWeek!);
    }

    return false;
  }

  bool _matchesTimeOfDay(DateTime time, String expectedTimeOfDay) {
    final hour = time.hour;

    switch (expectedTimeOfDay) {
      case 'morning':
        return hour >= 6 && hour < 12;
      case 'afternoon':
        return hour >= 12 && hour < 17;
      case 'evening':
        return hour >= 17 && hour < 21;
      case 'night':
        return hour >= 21 || hour < 6;
      default:
        return false;
    }
  }

  bool _matchesDayOfWeek(DateTime time, String expectedDay) {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final currentDay = days[time.weekday - 1];
    return currentDay == expectedDay.toLowerCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineType': routineType,
      'pattern': pattern,
      'timeOfDay': timeOfDay,
      'dayOfWeek': dayOfWeek,
      'location': location,
      'confidence': confidence,
      'firstObserved': firstObserved.millisecondsSinceEpoch,
      'lastObserved': lastObserved.millisecondsSinceEpoch,
      'occurrenceCount': occurrenceCount,
      'metadata': metadata,
    };
  }

  factory UserRoutine.fromJson(Map<String, dynamic> json) {
    return UserRoutine(
      id: json['id'] as String,
      routineType: json['routineType'] as String,
      pattern: json['pattern'] as String,
      timeOfDay: json['timeOfDay'] as String?,
      dayOfWeek: json['dayOfWeek'] as String?,
      location: json['location'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      firstObserved:
          DateTime.fromMillisecondsSinceEpoch(json['firstObserved'] as int),
      lastObserved:
          DateTime.fromMillisecondsSinceEpoch(json['lastObserved'] as int),
      occurrenceCount: json['occurrenceCount'] as int? ?? 1,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Routine types
class RoutineType {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String locationBased = 'location_based';
  static const String eventBased = 'event_based';
}

/// Common routine patterns
class RoutinePattern {
  static const String wakeUp = 'wake_up';
  static const String sleep = 'sleep';
  static const String exercise = 'exercise';
  static const String study = 'study';
  static const String work = 'work';
  static const String meals = 'meals';
  static const String commute = 'commute';
  static const String leisure = 'leisure';
}
