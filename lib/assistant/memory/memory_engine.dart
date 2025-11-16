import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../../data/models/memory/memory.dart';
import '../../data/models/memory/preference.dart';
import '../../data/models/memory/routine.dart';

/// Memory Engine - Persistent storage and retrieval of user memories, preferences, and routines
class MemoryEngine {
  static final MemoryEngine _instance = MemoryEngine._internal();
  static MemoryEngine get instance => _instance;

  MemoryEngine._internal();

  static const String _dbName = 'dona_memory.db';
  static const int _dbVersion = 1;

  Database? _database;
  final _uuid = const Uuid();

  /// Initialize the memory engine and create database
  Future<void> init() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);

      _database = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      AppLogger.info('MemoryEngine initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize MemoryEngine', e, stackTrace);
      rethrow;
    }
  }

  /// Create database schema
  Future<void> _createDatabase(Database db, int version) async {
    // Memories table
    await db.execute('''
      CREATE TABLE memories (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        importance REAL NOT NULL,
        source TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        access_count INTEGER NOT NULL DEFAULT 0,
        metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_memories_category ON memories(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_memories_importance ON memories(importance DESC)
    ''');

    // Preferences table
    await db.execute('''
      CREATE TABLE preferences (
        id TEXT PRIMARY KEY,
        preference_type TEXT NOT NULL,
        preference_value TEXT NOT NULL,
        confidence REAL NOT NULL,
        learned_from TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        occurrence_count INTEGER NOT NULL DEFAULT 1,
        context TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_preferences_type ON preferences(preference_type)
    ''');

    // Routines table
    await db.execute('''
      CREATE TABLE routines (
        id TEXT PRIMARY KEY,
        routine_type TEXT NOT NULL,
        pattern TEXT NOT NULL,
        time_of_day TEXT,
        day_of_week TEXT,
        location TEXT,
        confidence REAL NOT NULL,
        first_observed INTEGER NOT NULL,
        last_observed INTEGER NOT NULL,
        occurrence_count INTEGER NOT NULL DEFAULT 1,
        metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_routines_type ON routines(routine_type)
    ''');

    AppLogger.info('Memory database schema created');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations here in future versions
    AppLogger.info('Upgrading memory database from $oldVersion to $newVersion');
  }

  /// Ensure database is initialized
  Database get _db {
    if (_database == null) {
      throw StateError('MemoryEngine not initialized. Call init() first.');
    }
    return _database!;
  }

  // ==================== MEMORY OPERATIONS ====================

  /// Save or update a memory
  Future<void> saveMemory(Memory memory) async {
    try {
      await _db.insert(
        'memories',
        {
          'id': memory.id,
          'category': memory.category,
          'key': memory.key,
          'value': memory.value.toString(),
          'importance': memory.importance,
          'source': memory.source,
          'created_at': memory.createdAt.millisecondsSinceEpoch,
          'last_accessed': memory.lastAccessed.millisecondsSinceEpoch,
          'access_count': memory.accessCount,
          'metadata': memory.metadata != null ? memory.metadata.toString() : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('Saved memory: ${memory.key}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save memory', e, stackTrace);
      rethrow;
    }
  }

  /// Remember a new fact
  Future<void> rememberFact({
    required String key,
    required dynamic value,
    required double importance,
    required String source,
    String? category,
  }) async {
    final memory = Memory(
      id: _uuid.v4(),
      category: category ?? MemoryCategory.fact,
      key: key,
      value: value,
      importance: importance.clamp(0.0, 1.0),
      source: source,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );

    await saveMemory(memory);
  }

  /// Get memories by category
  Future<List<Memory>> getMemoriesByCategory(String category, {int? limit}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'memories',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'importance DESC, last_accessed DESC',
        limit: limit,
      );

      return maps.map((map) => _memoryFromDb(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get memories by category', e, stackTrace);
      return [];
    }
  }

  /// Get top relevant memories
  Future<List<Memory>> getTopRelevantMemories({
    String? category,
    double minImportance = 0.1,
    int limit = 10,
  }) async {
    try {
      String whereClause = 'importance >= ?';
      List<dynamic> whereArgs = [minImportance];

      if (category != null) {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        'memories',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'importance DESC, last_accessed DESC',
        limit: limit,
      );

      final memories = maps.map((map) => _memoryFromDb(map)).toList();

      // Sort by current importance (with decay)
      memories.sort((a, b) => b.currentImportance.compareTo(a.currentImportance));

      return memories.take(limit).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get top relevant memories', e, stackTrace);
      return [];
    }
  }

  /// Search memories by key pattern
  Future<List<Memory>> searchMemories(String searchTerm, {int? limit}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'memories',
        where: 'key LIKE ? OR value LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
        orderBy: 'importance DESC',
        limit: limit,
      );

      return maps.map((map) => _memoryFromDb(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search memories', e, stackTrace);
      return [];
    }
  }

  /// Mark memory as accessed
  Future<void> markMemoryAccessed(String memoryId) async {
    try {
      final memory = await _getMemoryById(memoryId);
      if (memory != null) {
        await saveMemory(memory.accessed());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark memory as accessed', e, stackTrace);
    }
  }

  /// Get memory by ID
  Future<Memory?> _getMemoryById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'memories',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _memoryFromDb(maps.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get memory by ID', e, stackTrace);
      return null;
    }
  }

  /// Delete memory
  Future<void> deleteMemory(String memoryId) async {
    try {
      await _db.delete(
        'memories',
        where: 'id = ?',
        whereArgs: [memoryId],
      );
      AppLogger.debug('Deleted memory: $memoryId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete memory', e, stackTrace);
    }
  }

  /// Clear old irrelevant memories (garbage collection)
  Future<int> pruneOldMemories({double minRelevance = 0.05}) async {
    try {
      // Get all memories and check current importance
      final allMemories = await _db.query('memories');
      int pruned = 0;

      for (final map in allMemories) {
        final memory = _memoryFromDb(map);
        if (memory.currentImportance < minRelevance) {
          await deleteMemory(memory.id);
          pruned++;
        }
      }

      AppLogger.info('Pruned $pruned irrelevant memories');
      return pruned;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to prune memories', e, stackTrace);
      return 0;
    }
  }

  // ==================== PREFERENCE OPERATIONS ====================

  /// Save or update a preference
  Future<void> savePreference(UserPreference preference) async {
    try {
      await _db.insert(
        'preferences',
        {
          'id': preference.id,
          'preference_type': preference.preferenceType,
          'preference_value': preference.preferenceValue,
          'confidence': preference.confidence,
          'learned_from': preference.learnedFrom,
          'created_at': preference.createdAt.millisecondsSinceEpoch,
          'updated_at': preference.updatedAt.millisecondsSinceEpoch,
          'occurrence_count': preference.occurrenceCount,
          'context': preference.context?.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('Saved preference: ${preference.preferenceType}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save preference', e, stackTrace);
      rethrow;
    }
  }

  /// Record or reinforce a preference
  Future<void> recordPreference({
    required String preferenceType,
    required String preferenceValue,
    required String learnedFrom,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Check if preference already exists
      final existing = await getPreferenceByType(preferenceType, preferenceValue);

      if (existing != null) {
        // Reinforce existing preference
        await savePreference(existing.reinforced());
      } else {
        // Create new preference
        final preference = UserPreference(
          id: _uuid.v4(),
          preferenceType: preferenceType,
          preferenceValue: preferenceValue,
          confidence: 0.5, // Start with medium confidence
          learnedFrom: learnedFrom,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          context: context,
        );
        await savePreference(preference);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to record preference', e, stackTrace);
    }
  }

  /// Get preference by type and value
  Future<UserPreference?> getPreferenceByType(String type, String value) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'preferences',
        where: 'preference_type = ? AND preference_value = ?',
        whereArgs: [type, value],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _preferenceFromDb(maps.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get preference', e, stackTrace);
      return null;
    }
  }

  /// Get top preferences by type
  Future<List<UserPreference>> getTopPreferences({
    String? preferenceType,
    int limit = 10,
  }) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'preferences',
        where: preferenceType != null ? 'preference_type = ?' : null,
        whereArgs: preferenceType != null ? [preferenceType] : null,
        orderBy: 'confidence DESC, occurrence_count DESC',
        limit: limit,
      );

      return maps.map((map) => _preferenceFromDb(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get top preferences', e, stackTrace);
      return [];
    }
  }

  // ==================== ROUTINE OPERATIONS ====================

  /// Save or update a routine
  Future<void> saveRoutine(UserRoutine routine) async {
    try {
      await _db.insert(
        'routines',
        {
          'id': routine.id,
          'routine_type': routine.routineType,
          'pattern': routine.pattern,
          'time_of_day': routine.timeOfDay,
          'day_of_week': routine.dayOfWeek,
          'location': routine.location,
          'confidence': routine.confidence,
          'first_observed': routine.firstObserved.millisecondsSinceEpoch,
          'last_observed': routine.lastObserved.millisecondsSinceEpoch,
          'occurrence_count': routine.occurrenceCount,
          'metadata': routine.metadata?.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.debug('Saved routine: ${routine.pattern}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save routine', e, stackTrace);
      rethrow;
    }
  }

  /// Record a routine occurrence
  Future<void> recordRoutineEvent({
    required String pattern,
    required String routineType,
    String? timeOfDay,
    String? dayOfWeek,
    String? location,
  }) async {
    try {
      // Check if routine exists
      final existing = await _getRoutineByPattern(pattern);

      if (existing != null) {
        // Reinforce existing routine
        await saveRoutine(existing.reinforced());
      } else {
        // Create new routine
        final routine = UserRoutine(
          id: _uuid.v4(),
          routineType: routineType,
          pattern: pattern,
          timeOfDay: timeOfDay,
          dayOfWeek: dayOfWeek,
          location: location,
          confidence: 0.5,
          firstObserved: DateTime.now(),
          lastObserved: DateTime.now(),
        );
        await saveRoutine(routine);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to record routine event', e, stackTrace);
    }
  }

  /// Get routine by pattern
  Future<UserRoutine?> _getRoutineByPattern(String pattern) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'routines',
        where: 'pattern = ?',
        whereArgs: [pattern],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _routineFromDb(maps.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get routine', e, stackTrace);
      return null;
    }
  }

  /// Get active routines for current time
  Future<List<UserRoutine>> getActiveRoutines({DateTime? referenceTime}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'routines',
        orderBy: 'confidence DESC',
      );

      final routines = maps.map((map) => _routineFromDb(map)).toList();

      // Filter to active routines
      return routines
          .where((r) => r.isActiveNow(referenceTime: referenceTime))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get active routines', e, stackTrace);
      return [];
    }
  }

  /// Get all routines by type
  Future<List<UserRoutine>> getRoutinesByType(String routineType) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'routines',
        where: 'routine_type = ?',
        whereArgs: [routineType],
        orderBy: 'confidence DESC',
      );

      return maps.map((map) => _routineFromDb(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get routines by type', e, stackTrace);
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  Memory _memoryFromDb(Map<String, dynamic> map) {
    return Memory(
      id: map['id'] as String,
      category: map['category'] as String,
      key: map['key'] as String,
      value: map['value'],
      importance: (map['importance'] as num).toDouble(),
      source: map['source'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['last_accessed'] as int),
      accessCount: map['access_count'] as int,
      metadata: map['metadata'] != null ? {} : null, // TODO: Parse JSON
    );
  }

  UserPreference _preferenceFromDb(Map<String, dynamic> map) {
    return UserPreference(
      id: map['id'] as String,
      preferenceType: map['preference_type'] as String,
      preferenceValue: map['preference_value'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      learnedFrom: map['learned_from'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      occurrenceCount: map['occurrence_count'] as int,
      context: map['context'] != null ? {} : null, // TODO: Parse JSON
    );
  }

  UserRoutine _routineFromDb(Map<String, dynamic> map) {
    return UserRoutine(
      id: map['id'] as String,
      routineType: map['routine_type'] as String,
      pattern: map['pattern'] as String,
      timeOfDay: map['time_of_day'] as String?,
      dayOfWeek: map['day_of_week'] as String?,
      location: map['location'] as String?,
      confidence: (map['confidence'] as num).toDouble(),
      firstObserved: DateTime.fromMillisecondsSinceEpoch(map['first_observed'] as int),
      lastObserved: DateTime.fromMillisecondsSinceEpoch(map['last_observed'] as int),
      occurrenceCount: map['occurrence_count'] as int,
      metadata: map['metadata'] != null ? {} : null, // TODO: Parse JSON
    );
  }

  /// Get statistics about stored memories
  Future<Map<String, int>> getMemoryStatistics() async {
    try {
      final memories = await _db.rawQuery('SELECT COUNT(*) as count FROM memories');
      final preferences = await _db.rawQuery('SELECT COUNT(*) as count FROM preferences');
      final routines = await _db.rawQuery('SELECT COUNT(*) as count FROM routines');

      return {
        'memories': memories.first['count'] as int,
        'preferences': preferences.first['count'] as int,
        'routines': routines.first['count'] as int,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get memory statistics', e, stackTrace);
      return {'memories': 0, 'preferences': 0, 'routines': 0};
    }
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
    AppLogger.info('MemoryEngine database closed');
  }
}
