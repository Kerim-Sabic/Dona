/// Memory model for storing facts, preferences, and user information
class Memory {
  final String id;
  final String category; // 'fact', 'preference', 'routine', 'relationship', etc.
  final String key;
  final dynamic value;
  final double importance; // 0.0 - 1.0
  final String source; // Where this memory came from
  final DateTime createdAt;
  final DateTime lastAccessed;
  final int accessCount;
  final Map<String, dynamic>? metadata;

  Memory({
    required this.id,
    required this.category,
    required this.key,
    required this.value,
    required this.importance,
    required this.source,
    required this.createdAt,
    required this.lastAccessed,
    this.accessCount = 0,
    this.metadata,
  });

  Memory copyWith({
    String? id,
    String? category,
    String? key,
    dynamic value,
    double? importance,
    String? source,
    DateTime? createdAt,
    DateTime? lastAccessed,
    int? accessCount,
    Map<String, dynamic>? metadata,
  }) {
    return Memory(
      id: id ?? this.id,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      importance: importance ?? this.importance,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create a Memory that was just accessed
  Memory accessed() {
    return copyWith(
      lastAccessed: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  /// Calculate importance decay over time
  double get currentImportance {
    final now = DateTime.now();
    final daysSinceCreated = now.difference(createdAt).inDays;
    final daysSinceAccessed = now.difference(lastAccessed).inDays;

    // Decay formula: importance * (0.95 ^ daysSinceAccessed) * accessBonus
    final timeDecay = importance * (0.95 * daysSinceAccessed);
    final accessBonus = 1.0 + (accessCount * 0.05).clamp(0.0, 0.5);

    return (timeDecay * accessBonus).clamp(0.0, 1.0);
  }

  /// Check if memory is still relevant (not too old)
  bool get isRelevant {
    return currentImportance > 0.1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'key': key,
      'value': value,
      'importance': importance,
      'source': source,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastAccessed': lastAccessed.millisecondsSinceEpoch,
      'accessCount': accessCount,
      'metadata': metadata,
    };
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      category: json['category'] as String,
      key: json['key'] as String,
      value: json['value'],
      importance: (json['importance'] as num).toDouble(),
      source: json['source'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastAccessed:
          DateTime.fromMillisecondsSinceEpoch(json['lastAccessed'] as int),
      accessCount: json['accessCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Memory categories for organization
class MemoryCategory {
  static const String fact = 'fact';
  static const String preference = 'preference';
  static const String routine = 'routine';
  static const String relationship = 'relationship';
  static const String goal = 'goal';
  static const String habit = 'habit';
  static const String event = 'event';
  static const String note = 'note';
}

/// Memory sources - where did we learn this?
class MemorySource {
  static const String user = 'user_told'; // User explicitly said
  static const String observed = 'observed'; // Learned from behavior
  static const String inferred = 'inferred'; // Deduced from context
  static const String imported = 'imported'; // From external source
}
