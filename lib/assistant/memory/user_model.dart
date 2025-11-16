import 'memory_engine.dart';
import 'package:uuid/uuid.dart';
import '../persona_manager.dart';
import '../persona_profiles.dart';
import '../../core/utils/logger.dart';
import '../../data/models/memory/memory.dart';
import '../../data/models/memory/preference.dart';
import '../../data/models/memory/routine.dart';
import '../../services/storage/local_storage_service.dart';

/// User Model Service - Aggregated view of user profile, preferences, and routines
class UserModelService {
  static final UserModelService _instance = UserModelService._internal();
  static UserModelService get instance => _instance;

  UserModelService._internal();

  static const String _profileKey = 'user_profile';
  static const String _usageProfileKey = 'usage_profile';
  final _uuid = const Uuid();

  UsageProfile _cachedUsageProfile = UsageProfile.mixed;

  /// Initialize user model service
  Future<void> init() async {
    try {
      await MemoryEngine.instance.init();
      _cachedUsageProfile = await getUsageProfile();
      AppLogger.info('UserModelService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize UserModelService', e, stackTrace);
    }
  }

  /// Get complete user snapshot
  Future<UserSnapshot> getUserSnapshot() async {
    try {
      final profile = await _getUserProfile();
      final preferences = await _getKeyPreferences();
      final routines = await _getActiveRoutines();
      final persona = PersonaManager.instance.currentPersona;

      return UserSnapshot(
        profile: profile,
        keyPreferences: preferences,
        activeRoutines: routines,
        currentPersona: persona,
        timestamp: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user snapshot', e, stackTrace);
      return UserSnapshot.empty();
    }
  }

  /// Get user profile
  Future<UserProfile> _getUserProfile() async {
    try {
      // Try to load from storage first
      final stored = LocalStorageService.instance.getString(_profileKey);
      if (stored != null) {
        // TODO: Deserialize from JSON
        // For now, return default
      }

      // Try to build from memories
      final nameMemory = await MemoryEngine.instance.searchMemories('user_name', limit: 1);
      final timezoneMemory = await MemoryEngine.instance.searchMemories('timezone', limit: 1);

      return UserProfile(
        name: nameMemory.isNotEmpty ? nameMemory.first.value.toString() : null,
        timezone: timezoneMemory.isNotEmpty ? timezoneMemory.first.value.toString() : null,
        locale: 'en_US', // Default
        role: _inferUserRole(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user profile', e, stackTrace);
      return UserProfile.empty();
    }
  }

  /// Infer user role from preferences and routines
  UserRole _inferUserRole() {
    // TODO: Implement role inference logic based on:
    // - Student features usage (courses, exams, flashcards)
    // - Work features usage (meetings, professional tone)
    // - Mixed usage
    return UserRole.mixed;
  }

  /// Get key preferences
  Future<Map<String, String>> _getKeyPreferences() async {
    try {
      final prefs = await MemoryEngine.instance.getTopPreferences(limit: 20);

      final Map<String, String> keyPrefs = {};
      for (final pref in prefs) {
        keyPrefs[pref.preferenceType] = pref.preferenceValue;
      }

      return keyPrefs;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get key preferences', e, stackTrace);
      return {};
    }
  }

  /// Get active routines
  Future<List<UserRoutine>> _getActiveRoutines() async {
    try {
      return await MemoryEngine.instance.getActiveRoutines();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get active routines', e, stackTrace);
      return [];
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfileUpdate update) async {
    try {
      if (update.name != null) {
        await MemoryEngine.instance.rememberFact(
          key: 'user_name',
          value: update.name!,
          importance: 1.0,
          source: MemorySource.user,
        );
      }

      if (update.timezone != null) {
        await MemoryEngine.instance.rememberFact(
          key: 'timezone',
          value: update.timezone!,
          importance: 0.9,
          source: MemorySource.user,
        );
      }

      if (update.locale != null) {
        await MemoryEngine.instance.rememberFact(
          key: 'locale',
          value: update.locale!,
          importance: 0.8,
          source: MemorySource.user,
        );
      }

      AppLogger.info('User profile updated');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
    }
  }

  /// Learn from user behavior
  Future<void> learnFromAction({
    required String actionType,
    required bool userAccepted,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final importance = userAccepted ? 0.7 : 0.3;

      await MemoryEngine.instance.rememberFact(
        key: 'action_$actionType',
        value: userAccepted ? 'accepted' : 'rejected',
        importance: importance,
        source: MemorySource.observed,
        category: MemoryCategory.preference,
      );

      AppLogger.debug('Learned from action: $actionType (accepted: $userAccepted)');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to learn from action', e, stackTrace);
    }
  }

  /// Record a user preference
  Future<void> recordPreference({
    required String type,
    required String value,
    String source = 'observed',
  }) async {
    try {
      await MemoryEngine.instance.recordPreference(
        preferenceType: type,
        preferenceValue: value,
        learnedFrom: source,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to record preference', e, stackTrace);
    }
  }

  /// Record a routine event
  Future<void> recordRoutine({
    required String pattern,
    required String type,
    String? timeOfDay,
    String? location,
  }) async {
    try {
      await MemoryEngine.instance.recordRoutineEvent(
        pattern: pattern,
        routineType: type,
        timeOfDay: timeOfDay,
        location: location,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to record routine', e, stackTrace);
    }
  }

  /// Get user mode (study-heavy, work-heavy, or mixed)
  Future<UserMode> getUserMode() async {
    try {
      final studyPrefs = await MemoryEngine.instance.getTopPreferences(
        preferenceType: PreferenceType.studyStyle,
      );

      final workPrefs = await MemoryEngine.instance.getTopPreferences(
        preferenceType: PreferenceType.workspace,
      );

      if (studyPrefs.length > workPrefs.length * 2) {
        return UserMode.studyHeavy;
      } else if (workPrefs.length > studyPrefs.length * 2) {
        return UserMode.workHeavy;
      } else {
        return UserMode.mixed;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user mode', e, stackTrace);
      return UserMode.mixed;
    }
  }

  /// Get usage profile (determines which features are highlighted)
  Future<UsageProfile> getUsageProfile() async {
    try {
      final stored = LocalStorageService.instance.getString(_usageProfileKey);
      if (stored != null) {
        return UsageProfile.values.firstWhere(
          (e) => e.name == stored,
          orElse: () => UsageProfile.mixed,
        );
      }
      return _cachedUsageProfile;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get usage profile', e, stackTrace);
      return UsageProfile.mixed;
    }
  }

  /// Set usage profile
  Future<void> setUsageProfile(UsageProfile profile) async {
    try {
      await LocalStorageService.instance.setString(_usageProfileKey, profile.name);
      _cachedUsageProfile = profile;
      AppLogger.info('Usage profile set to: ${profile.displayName}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set usage profile', e, stackTrace);
    }
  }

  /// Get cached usage profile (synchronous, no await needed)
  UsageProfile get currentUsageProfile => _cachedUsageProfile;
}

/// Complete user snapshot
class UserSnapshot {
  final UserProfile profile;
  final Map<String, String> keyPreferences;
  final List<UserRoutine> activeRoutines;
  final PersonaProfile currentPersona;
  final DateTime timestamp;

  const UserSnapshot({
    required this.profile,
    required this.keyPreferences,
    required this.activeRoutines,
    required this.currentPersona,
    required this.timestamp,
  });

  factory UserSnapshot.empty() {
    return UserSnapshot(
      profile: UserProfile.empty(),
      keyPreferences: {},
      activeRoutines: [],
      currentPersona: PersonaProfiles.defaultDona,
      timestamp: DateTime.now(),
    );
  }

  /// Get brief summary for AI context
  String toBriefSummary() {
    final parts = <String>[];

    if (profile.name != null) {
      parts.add('User: ${profile.name}');
    }

    if (keyPreferences.isNotEmpty) {
      final topPrefs = keyPreferences.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ');
      parts.add('Preferences: $topPrefs');
    }

    if (activeRoutines.isNotEmpty) {
      parts.add('Active routines: ${activeRoutines.length}');
    }

    parts.add('Persona: ${currentPersona.name}');

    return parts.join(' | ');
  }
}

/// User profile
class UserProfile {
  final String? name;
  final String? timezone;
  final String? locale;
  final UserRole role;

  const UserProfile({
    this.name,
    this.timezone,
    this.locale,
    required this.role,
  });

  factory UserProfile.empty() {
    return const UserProfile(role: UserRole.mixed);
  }
}

/// User profile update
class UserProfileUpdate {
  final String? name;
  final String? timezone;
  final String? locale;

  const UserProfileUpdate({
    this.name,
    this.timezone,
    this.locale,
  });
}

/// User role
enum UserRole {
  student,
  professional,
  mixed,
}

/// Usage profile - determines which features/autopilots are highlighted
enum UsageProfile {
  student,     // Highlights study features
  founder,     // Highlights founder/executive features
  professional, // Highlights work/productivity features
  mixed,       // Balanced mix
}

extension UsageProfileExtension on UsageProfile {
  String get displayName {
    switch (this) {
      case UsageProfile.student:
        return 'Student';
      case UsageProfile.founder:
        return 'Founder / CEO';
      case UsageProfile.professional:
        return 'Professional';
      case UsageProfile.mixed:
        return 'Mixed';
    }
  }

  String get description {
    switch (this) {
      case UsageProfile.student:
        return 'Optimized for academic success with study tools and exam prep';
      case UsageProfile.founder:
        return 'Optimized for founders and executives with strategic planning and decision support';
      case UsageProfile.professional:
        return 'Optimized for professionals with productivity and task management';
      case UsageProfile.mixed:
        return 'Balanced experience with all features available';
    }
  }
}

/// User mode based on usage patterns
enum UserMode {
  studyHeavy,
  workHeavy,
  mixed,
}
