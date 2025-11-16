/// User preference model for learned behaviors and choices
class UserPreference {
  final String id;
  final String preferenceType; // 'food', 'communication', 'scheduling', etc.
  final String preferenceValue;
  final double confidence; // 0.0 - 1.0 (how sure are we?)
  final String learnedFrom; // How we learned this
  final DateTime createdAt;
  final DateTime updatedAt;
  final int occurrenceCount; // How many times we've seen this preference
  final Map<String, dynamic>? context; // Additional context

  UserPreference({
    required this.id,
    required this.preferenceType,
    required this.preferenceValue,
    required this.confidence,
    required this.learnedFrom,
    required this.createdAt,
    required this.updatedAt,
    this.occurrenceCount = 1,
    this.context,
  });

  UserPreference copyWith({
    String? id,
    String? preferenceType,
    String? preferenceValue,
    double? confidence,
    String? learnedFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? occurrenceCount,
    Map<String, dynamic>? context,
  }) {
    return UserPreference(
      id: id ?? this.id,
      preferenceType: preferenceType ?? this.preferenceType,
      preferenceValue: preferenceValue ?? this.preferenceValue,
      confidence: confidence ?? this.confidence,
      learnedFrom: learnedFrom ?? this.learnedFrom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      context: context ?? this.context,
    );
  }

  /// Reinforce this preference (seen again)
  UserPreference reinforced() {
    final newConfidence = (confidence + 0.05).clamp(0.0, 1.0);
    return copyWith(
      confidence: newConfidence,
      updatedAt: DateTime.now(),
      occurrenceCount: occurrenceCount + 1,
    );
  }

  /// Weaken this preference (contradicted)
  UserPreference weakened() {
    final newConfidence = (confidence - 0.1).clamp(0.0, 1.0);
    return copyWith(
      confidence: newConfidence,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'preferenceType': preferenceType,
      'preferenceValue': preferenceValue,
      'confidence': confidence,
      'learnedFrom': learnedFrom,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'occurrenceCount': occurrenceCount,
      'context': context,
    };
  }

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'] as String,
      preferenceType: json['preferenceType'] as String,
      preferenceValue: json['preferenceValue'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      learnedFrom: json['learnedFrom'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      occurrenceCount: json['occurrenceCount'] as int? ?? 1,
      context: json['context'] as Map<String, dynamic>?,
    );
  }
}

/// Preference types
class PreferenceType {
  static const String food = 'food';
  static const String communication = 'communication';
  static const String scheduling = 'scheduling';
  static const String notification = 'notification';
  static const String workspace = 'workspace';
  static const String studyStyle = 'study_style';
  static const String exercise = 'exercise';
  static const String sleep = 'sleep';
  static const String music = 'music';
  static const String weather = 'weather';
}
