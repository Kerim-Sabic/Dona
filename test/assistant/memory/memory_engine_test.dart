import 'package:flutter_test/flutter_test.dart';
import 'package:dona/data/models/memory/memory.dart';
import 'package:dona/data/models/memory/preference.dart';

/// Unit tests for Memory Engine - Importance Decay & Relevance
///
/// Tests the critical memory decay formula: importance * (0.95^days) * accessBonus
void main() {
  group('Memory - Importance Decay', () {
    test('Fresh memory (0 days) maintains full importance', () {
      final now = DateTime.now();
      final memory = Memory(
        id: 'test-1',
        category: MemoryCategory.fact,
        key: 'user_name',
        value: 'John',
        importance: 0.9,
        source: MemorySource.user,
        createdAt: now,
        lastAccessed: now,
        accessCount: 0,
      );

      // Fresh memory should have close to original importance
      expect(memory.currentImportance, greaterThan(0.85));
      expect(memory.currentImportance, lessThanOrEqualTo(1.0));
    });

    test('Memory decays over time (7 days)', () {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final memory = Memory(
        id: 'test-2',
        category: MemoryCategory.fact,
        key: 'old_fact',
        value: 'Some fact',
        importance: 1.0,
        source: MemorySource.observed,
        createdAt: sevenDaysAgo,
        lastAccessed: sevenDaysAgo,
        accessCount: 0,
      );

      // After 7 days without access, importance should decay
      // Formula: 1.0 * (0.95 * 7) * 1.0 = 6.65
      // But it's clamped to [0.0, 1.0]
      expect(memory.currentImportance, lessThan(1.0));
      expect(memory.currentImportance, greaterThanOrEqualTo(0.0));
    });

    test('Memory decays significantly over 30 days', () {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final memory = Memory(
        id: 'test-3',
        category: MemoryCategory.preference,
        key: 'old_preference',
        value: 'coffee',
        importance: 0.8,
        source: MemorySource.inferred,
        createdAt: thirtyDaysAgo,
        lastAccessed: thirtyDaysAgo,
        accessCount: 0,
      );

      // After 30 days without access, should be significantly decayed
      expect(memory.currentImportance, lessThan(0.5));
    });

    test('Frequently accessed memory resists decay', () {
      final now = DateTime.now();
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      final memory = Memory(
        id: 'test-4',
        category: MemoryCategory.fact,
        key: 'frequent_fact',
        value: 'Important info',
        importance: 0.7,
        source: MemorySource.user,
        createdAt: fourteenDaysAgo,
        lastAccessed: now, // Accessed recently
        accessCount: 10, // Accessed many times
      );

      // High access count should provide bonus that resists decay
      // accessBonus = 1.0 + (10 * 0.05).clamp(0.0, 0.5) = 1.5
      expect(memory.currentImportance, greaterThan(0.5));
    });

    test('Memory with zero importance stays zero', () {
      final now = DateTime.now();

      final memory = Memory(
        id: 'test-5',
        category: MemoryCategory.note,
        key: 'trivial',
        value: 'xyz',
        importance: 0.0,
        source: MemorySource.inferred,
        createdAt: now,
        lastAccessed: now,
        accessCount: 0,
      );

      expect(memory.currentImportance, equals(0.0));
      expect(memory.isRelevant, isFalse); // Below 0.1 threshold
    });

    test('Memory relevance threshold (0.1)', () {
      final now = DateTime.now();

      // Memory above threshold
      final relevantMemory = Memory(
        id: 'test-6a',
        category: MemoryCategory.fact,
        key: 'relevant',
        value: 'important',
        importance: 0.5,
        source: MemorySource.user,
        createdAt: now,
        lastAccessed: now,
        accessCount: 0,
      );

      // Memory below threshold (simulated with very old + low importance)
      final irrelevantMemory = Memory(
        id: 'test-6b',
        category: MemoryCategory.note,
        key: 'irrelevant',
        value: 'trivial',
        importance: 0.1,
        source: MemorySource.inferred,
        createdAt: now.subtract(const Duration(days: 60)),
        lastAccessed: now.subtract(const Duration(days: 60)),
        accessCount: 0,
      );

      expect(relevantMemory.isRelevant, isTrue);
      expect(irrelevantMemory.isRelevant, isFalse);
    });

    test('Memory access tracking updates correctly', () {
      final now = DateTime.now();

      final memory = Memory(
        id: 'test-7',
        category: MemoryCategory.fact,
        key: 'test',
        value: 'value',
        importance: 0.8,
        source: MemorySource.user,
        createdAt: now,
        lastAccessed: now,
        accessCount: 5,
      );

      final accessedMemory = memory.accessed();

      expect(accessedMemory.accessCount, equals(6));
      expect(accessedMemory.lastAccessed.isAfter(memory.lastAccessed) ||
             accessedMemory.lastAccessed.isAtSameMomentAs(memory.lastAccessed), isTrue);
    });
  });

  group('UserPreference - Confidence Reinforcement', () {
    test('Preference reinforcement increases confidence', () {
      final now = DateTime.now();

      final pref = UserPreference(
        id: 'pref-1',
        preferenceType: PreferenceType.food,
        preferenceValue: 'pizza',
        confidence: 0.5,
        learnedFrom: 'observed',
        createdAt: now,
        updatedAt: now,
        occurrenceCount: 1,
      );

      final reinforced = pref.reinforced();

      expect(reinforced.confidence, equals(0.55)); // +0.05
      expect(reinforced.occurrenceCount, equals(2));
      expect(reinforced.updatedAt.isAfter(pref.updatedAt), isTrue);
    });

    test('Preference confidence caps at 1.0', () {
      final now = DateTime.now();

      final pref = UserPreference(
        id: 'pref-2',
        preferenceType: PreferenceType.communication,
        preferenceValue: 'email',
        confidence: 0.98,
        learnedFrom: 'user',
        createdAt: now,
        updatedAt: now,
      );

      final reinforced = pref.reinforced();

      expect(reinforced.confidence, equals(1.0)); // Clamped
    });

    test('Preference weakening decreases confidence', () {
      final now = DateTime.now();

      final pref = UserPreference(
        id: 'pref-3',
        preferenceType: PreferenceType.scheduling,
        preferenceValue: 'morning',
        confidence: 0.7,
        learnedFrom: 'observed',
        createdAt: now,
        updatedAt: now,
        occurrenceCount: 5,
      );

      final weakened = pref.weakened();

      expect(weakened.confidence, equals(0.6)); // -0.1
      expect(weakened.updatedAt.isAfter(pref.updatedAt), isTrue);
    });

    test('Preference confidence floors at 0.0', () {
      final now = DateTime.now();

      final pref = UserPreference(
        id: 'pref-4',
        preferenceType: PreferenceType.music,
        preferenceValue: 'jazz',
        confidence: 0.05,
        learnedFrom: 'inferred',
        createdAt: now,
        updatedAt: now,
      );

      final weakened = pref.weakened();

      expect(weakened.confidence, equals(0.0)); // Floored
    });
  });

  group('Memory - JSON Serialization', () {
    test('Memory serializes to JSON correctly', () {
      final now = DateTime.now();

      final memory = Memory(
        id: 'test-json-1',
        category: MemoryCategory.fact,
        key: 'test_key',
        value: 'test_value',
        importance: 0.8,
        source: MemorySource.user,
        createdAt: now,
        lastAccessed: now,
        accessCount: 3,
        metadata: {'extra': 'data'},
      );

      final json = memory.toJson();

      expect(json['id'], equals('test-json-1'));
      expect(json['category'], equals(MemoryCategory.fact));
      expect(json['key'], equals('test_key'));
      expect(json['value'], equals('test_value'));
      expect(json['importance'], equals(0.8));
      expect(json['accessCount'], equals(3));
      expect(json['metadata'], isNotNull);
    });

    test('Memory deserializes from JSON correctly', () {
      final now = DateTime.now();

      final json = {
        'id': 'test-json-2',
        'category': MemoryCategory.preference,
        'key': 'color',
        'value': 'blue',
        'importance': 0.6,
        'source': MemorySource.observed,
        'createdAt': now.millisecondsSinceEpoch,
        'lastAccessed': now.millisecondsSinceEpoch,
        'accessCount': 2,
        'metadata': {'context': 'test'},
      };

      final memory = Memory.fromJson(json);

      expect(memory.id, equals('test-json-2'));
      expect(memory.category, equals(MemoryCategory.preference));
      expect(memory.key, equals('color'));
      expect(memory.value, equals('blue'));
      expect(memory.importance, equals(0.6));
      expect(memory.accessCount, equals(2));
    });
  });
}
