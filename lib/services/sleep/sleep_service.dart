import 'dart:async';
import 'package:health/health.dart';
import '../../core/utils/logger.dart';

/// Sleep data model
class SleepData {
  final DateTime bedTime;
  final DateTime wakeTime;
  final Duration totalSleep;
  final int sleepQuality; // 0-100 score
  final int deepSleepMinutes;
  final int lightSleepMinutes;
  final int remSleepMinutes;
  final int awakeMinutes;

  SleepData({
    required this.bedTime,
    required this.wakeTime,
    required this.totalSleep,
    required this.sleepQuality,
    required this.deepSleepMinutes,
    required this.lightSleepMinutes,
    required this.remSleepMinutes,
    required this.awakeMinutes,
  });

  String get formattedDuration {
    final hours = totalSleep.inHours;
    final minutes = totalSleep.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

/// Smart alarm model
class SmartAlarm {
  final String id;
  final DateTime earliestWake;
  final DateTime latestWake;
  final DateTime? optimalWakeTime;
  final bool isActive;
  final String? label;
  final List<int> repeatDays; // 1=Mon, 7=Sun
  final String soundName;
  final int volumeLevel;

  SmartAlarm({
    required this.id,
    required this.earliestWake,
    required this.latestWake,
    this.optimalWakeTime,
    required this.isActive,
    this.label,
    required this.repeatDays,
    this.soundName = 'default',
    this.volumeLevel = 80,
  });

  factory SmartAlarm.fromJson(Map<String, dynamic> json) {
    return SmartAlarm(
      id: json['id'] ?? '',
      earliestWake: DateTime.parse(json['earliestWake']),
      latestWake: DateTime.parse(json['latestWake']),
      optimalWakeTime: json['optimalWakeTime'] != null
          ? DateTime.parse(json['optimalWakeTime'])
          : null,
      isActive: json['isActive'] ?? true,
      label: json['label'],
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
      soundName: json['soundName'] ?? 'default',
      volumeLevel: json['volumeLevel'] ?? 80,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'earliestWake': earliestWake.toIso8601String(),
      'latestWake': latestWake.toIso8601String(),
      'optimalWakeTime': optimalWakeTime?.toIso8601String(),
      'isActive': isActive,
      'label': label,
      'repeatDays': repeatDays,
      'soundName': soundName,
      'volumeLevel': volumeLevel,
    };
  }

  SmartAlarm copyWith({
    String? id,
    DateTime? earliestWake,
    DateTime? latestWake,
    DateTime? optimalWakeTime,
    bool? isActive,
    String? label,
    List<int>? repeatDays,
    String? soundName,
    int? volumeLevel,
  }) {
    return SmartAlarm(
      id: id ?? this.id,
      earliestWake: earliestWake ?? this.earliestWake,
      latestWake: latestWake ?? this.latestWake,
      optimalWakeTime: optimalWakeTime ?? this.optimalWakeTime,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      soundName: soundName ?? this.soundName,
      volumeLevel: volumeLevel ?? this.volumeLevel,
    );
  }
}

/// Sleep & Smart Wake Service
/// Integrates with HealthKit (iOS) and Google Fit (Android) for sleep tracking
/// Provides smart alarm functionality with optimal wake time calculation
class SleepService {
  static final SleepService _instance = SleepService._internal();
  static SleepService get instance => _instance;

  SleepService._internal();

  Health? _health;
  final List<SmartAlarm> _alarms = [];
  bool _isInitialized = false;
  bool _hasHealthPermissions = false;

  /// Health data types we want to access
  static final List<HealthDataType> _healthDataTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  Future<void> init() async {
    try {
      _health = Health();
      AppLogger.info('SleepService initialized');
      _isInitialized = true;

      // Request health permissions
      await _requestHealthPermissions();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize SleepService', e, stackTrace);
    }
  }

  /// Request health data permissions
  Future<bool> _requestHealthPermissions() async {
    if (_health == null) return false;

    try {
      final permissions = _healthDataTypes
          .map((type) => HealthDataAccess.READ)
          .toList();

      final requested = await _health!.requestAuthorization(
        _healthDataTypes,
        permissions: permissions,
      );

      _hasHealthPermissions = requested;
      if (requested) {
        AppLogger.info('Health permissions granted');
      } else {
        AppLogger.warning('Health permissions denied');
      }

      return requested;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to request health permissions', e, stackTrace);
      return false;
    }
  }

  /// Get sleep data for last night
  Future<SleepData?> getLastNightSleep() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return await getSleepData(
      startDate: DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 0),
      endDate: DateTime(now.year, now.month, now.day, 12, 0),
    );
  }

  /// Get sleep data for a specific date range
  Future<SleepData?> getSleepData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_hasHealthPermissions || _health == null) {
      AppLogger.warning('Health permissions not available, returning simulated data');
      return _getSimulatedSleepData();
    }

    try {
      final healthData = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        _healthDataTypes,
      );

      if (healthData.isEmpty) {
        AppLogger.info('No sleep data found for date range');
        return _getSimulatedSleepData();
      }

      // Process sleep data
      int deepSleepMinutes = 0;
      int lightSleepMinutes = 0;
      int remSleepMinutes = 0;
      int awakeMinutes = 0;
      DateTime? bedTime;
      DateTime? wakeTime;

      for (var data in healthData) {
        final minutes = data.value.toJson()['numericValue']?.toInt() ?? 0;

        switch (data.type) {
          case HealthDataType.SLEEP_DEEP:
            deepSleepMinutes += minutes;
            break;
          case HealthDataType.SLEEP_LIGHT:
            lightSleepMinutes += minutes;
            break;
          case HealthDataType.SLEEP_REM:
            remSleepMinutes += minutes;
            break;
          case HealthDataType.SLEEP_AWAKE:
            awakeMinutes += minutes;
            break;
          case HealthDataType.SLEEP_IN_BED:
            bedTime ??= data.dateFrom;
            wakeTime = data.dateTo;
            break;
          default:
            break;
        }
      }

      final totalSleepMinutes = deepSleepMinutes + lightSleepMinutes + remSleepMinutes;
      final totalSleep = Duration(minutes: totalSleepMinutes);

      // Calculate sleep quality score (0-100)
      final sleepQuality = _calculateSleepQuality(
        deepSleepMinutes: deepSleepMinutes,
        lightSleepMinutes: lightSleepMinutes,
        remSleepMinutes: remSleepMinutes,
        awakeMinutes: awakeMinutes,
      );

      return SleepData(
        bedTime: bedTime ?? startDate,
        wakeTime: wakeTime ?? endDate,
        totalSleep: totalSleep,
        sleepQuality: sleepQuality,
        deepSleepMinutes: deepSleepMinutes,
        lightSleepMinutes: lightSleepMinutes,
        remSleepMinutes: remSleepMinutes,
        awakeMinutes: awakeMinutes,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get sleep data', e, stackTrace);
      return _getSimulatedSleepData();
    }
  }

  /// Calculate sleep quality score (0-100)
  int _calculateSleepQuality({
    required int deepSleepMinutes,
    required int lightSleepMinutes,
    required int remSleepMinutes,
    required int awakeMinutes,
  }) {
    final totalSleep = deepSleepMinutes + lightSleepMinutes + remSleepMinutes;
    if (totalSleep == 0) return 0;

    // Ideal sleep composition (percentages)
    const idealDeepPercent = 20.0; // 15-25%
    const idealRemPercent = 25.0; // 20-25%
    const idealLightPercent = 55.0; // 50-60%

    final deepPercent = (deepSleepMinutes / totalSleep) * 100;
    final remPercent = (remSleepMinutes / totalSleep) * 100;
    final lightPercent = (lightSleepMinutes / totalSleep) * 100;

    // Calculate deviation from ideal
    final deepScore = 100 - ((deepPercent - idealDeepPercent).abs() * 2);
    final remScore = 100 - ((remPercent - idealRemPercent).abs() * 2);
    final lightScore = 100 - ((lightPercent - idealLightPercent).abs() * 2);

    // Penalize for too many awake minutes
    final awakePenalty = (awakeMinutes / totalSleep) * 100;

    // Calculate final score
    final score = ((deepScore + remScore + lightScore) / 3) - awakePenalty;

    return score.clamp(0, 100).round();
  }

  /// Get simulated sleep data for demo/fallback
  SleepData _getSimulatedSleepData() {
    final now = DateTime.now();
    final wakeTime = DateTime(now.year, now.month, now.day, 7, 15);
    final bedTime = wakeTime.subtract(const Duration(hours: 7, minutes: 45));

    return SleepData(
      bedTime: bedTime,
      wakeTime: wakeTime,
      totalSleep: const Duration(hours: 7, minutes: 20),
      sleepQuality: 78,
      deepSleepMinutes: 95,
      lightSleepMinutes: 245,
      remSleepMinutes: 100,
      awakeMinutes: 20,
    );
  }

  /// Create a smart alarm
  Future<SmartAlarm> createSmartAlarm({
    required DateTime earliestWake,
    required DateTime latestWake,
    String? label,
    List<int> repeatDays = const [],
    String soundName = 'default',
    int volumeLevel = 80,
  }) async {
    final alarm = SmartAlarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      earliestWake: earliestWake,
      latestWake: latestWake,
      isActive: true,
      label: label,
      repeatDays: repeatDays,
      soundName: soundName,
      volumeLevel: volumeLevel,
    );

    _alarms.add(alarm);
    AppLogger.info('Smart alarm created: ${alarm.id}');

    // Calculate optimal wake time
    final optimalAlarm = await _calculateOptimalWakeTime(alarm);
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = optimalAlarm;
    }

    return optimalAlarm;
  }

  /// Calculate optimal wake time based on sleep cycles
  Future<SmartAlarm> _calculateOptimalWakeTime(SmartAlarm alarm) async {
    // Sleep cycle is ~90 minutes
    // Optimal wake is at the end of a light sleep phase
    const sleepCycleDuration = Duration(minutes: 90);

    // Get user's typical bedtime from recent sleep data
    DateTime estimatedBedtime = alarm.earliestWake.subtract(const Duration(hours: 8));

    // Try to get actual bedtime from sleep data
    try {
      final recentSleep = await getLastNightSleep();
      if (recentSleep != null) {
        final avgBedtimeHour = recentSleep.bedTime.hour;
        estimatedBedtime = DateTime(
          alarm.earliestWake.year,
          alarm.earliestWake.month,
          alarm.earliestWake.day - 1,
          avgBedtimeHour,
          recentSleep.bedTime.minute,
        );
      }
    } catch (e) {
      AppLogger.debug('Could not get recent sleep data, using estimate');
    }

    // Calculate sleep cycles between bedtime and wake window
    final candidates = <DateTime>[];
    var currentTime = estimatedBedtime.add(sleepCycleDuration * 4); // Skip first 4 cycles (6 hours)

    while (currentTime.isBefore(alarm.latestWake)) {
      if (currentTime.isAfter(alarm.earliestWake) || currentTime.isAtSameMomentAs(alarm.earliestWake)) {
        candidates.add(currentTime);
      }
      currentTime = currentTime.add(sleepCycleDuration);
    }

    // Select optimal time (prefer earlier in the window)
    final optimalTime = candidates.isNotEmpty
        ? candidates.first
        : alarm.earliestWake.add(
            Duration(minutes: (alarm.latestWake.difference(alarm.earliestWake).inMinutes / 2).round()),
          );

    return alarm.copyWith(optimalWakeTime: optimalTime);
  }

  /// Get all alarms
  List<SmartAlarm> getAlarms() => List.unmodifiable(_alarms);

  /// Get active alarms
  List<SmartAlarm> getActiveAlarms() => _alarms.where((a) => a.isActive).toList();

  /// Toggle alarm on/off
  Future<void> toggleAlarm(String alarmId, bool isActive) async {
    final index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(isActive: isActive);
      AppLogger.info('Alarm ${isActive ? "enabled" : "disabled"}: $alarmId');
    }
  }

  /// Delete alarm
  Future<void> deleteAlarm(String alarmId) async {
    _alarms.removeWhere((a) => a.id == alarmId);
    AppLogger.info('Alarm deleted: $alarmId');
  }

  /// Format sleep data for display
  String formatSleepData(SleepData sleep) {
    final buffer = StringBuffer();
    buffer.writeln('😴 Sleep Summary:');
    buffer.writeln('🛏️ Bedtime: ${_formatTime(sleep.bedTime)}');
    buffer.writeln('⏰ Wake time: ${_formatTime(sleep.wakeTime)}');
    buffer.writeln('⏱️ Total sleep: ${sleep.formattedDuration}');
    buffer.writeln('⭐ Quality: ${sleep.sleepQuality}/100 ${_getQualityEmoji(sleep.sleepQuality)}');
    buffer.writeln();
    buffer.writeln('📊 Sleep Stages:');
    buffer.writeln('   🌑 Deep: ${sleep.deepSleepMinutes}min');
    buffer.writeln('   🌙 Light: ${sleep.lightSleepMinutes}min');
    buffer.writeln('   💭 REM: ${sleep.remSleepMinutes}min');
    if (sleep.awakeMinutes > 0) {
      buffer.writeln('   👁️ Awake: ${sleep.awakeMinutes}min');
    }

    return buffer.toString();
  }

  /// Format alarm for display
  String formatAlarm(SmartAlarm alarm) {
    final buffer = StringBuffer();
    buffer.writeln('⏰ Smart Alarm');
    if (alarm.label != null) {
      buffer.writeln('📝 ${alarm.label}');
    }
    buffer.writeln('⏱️ Window: ${_formatTime(alarm.earliestWake)} - ${_formatTime(alarm.latestWake)}');
    if (alarm.optimalWakeTime != null) {
      buffer.writeln('🎯 Optimal: ${_formatTime(alarm.optimalWakeTime!)}');
    }
    buffer.writeln('🔔 Status: ${alarm.isActive ? "Active" : "Inactive"}');

    return buffer.toString();
  }

  /// Get sleep analysis and recommendations
  Future<String> getSleepAnalysis() async {
    try {
      final sleep = await getLastNightSleep();

      if (sleep == null) {
        return 'No sleep data available. Make sure to grant health permissions.';
      }

      final buffer = StringBuffer();
      buffer.writeln(formatSleepData(sleep));
      buffer.writeln();
      buffer.writeln('💡 Insights:');

      // Quality assessment
      if (sleep.sleepQuality >= 80) {
        buffer.writeln('✅ Excellent sleep! You got great rest.');
      } else if (sleep.sleepQuality >= 60) {
        buffer.writeln('👍 Good sleep overall.');
      } else {
        buffer.writeln('⚠️ Sleep quality could be improved.');
      }

      // Duration assessment
      final totalHours = sleep.totalSleep.inMinutes / 60;
      if (totalHours < 6) {
        buffer.writeln('⚠️ You may need more sleep. Aim for 7-9 hours.');
      } else if (totalHours > 9) {
        buffer.writeln('💤 That\'s quite a lot! Most adults need 7-9 hours.');
      }

      // Deep sleep assessment
      final deepPercent = (sleep.deepSleepMinutes / sleep.totalSleep.inMinutes) * 100;
      if (deepPercent < 15) {
        buffer.writeln('🌑 Try to improve deep sleep: avoid screens before bed, keep room cool.');
      }

      buffer.writeln();
      buffer.writeln('🌟 Wellness Tips:');
      buffer.writeln('• Maintain consistent sleep schedule');
      buffer.writeln('• Avoid caffeine 6 hours before bed');
      buffer.writeln('• Keep bedroom cool (60-67°F)');
      buffer.writeln('• Limit screen time before sleep');

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get sleep analysis', e, stackTrace);
      return 'Unable to analyze sleep data.';
    }
  }

  /// Get wellness coaching tips (non-medical)
  String getWellnessTips() {
    return '''
😴 Sleep Wellness Tips:

🛏️ Sleep Hygiene:
• Stick to a consistent sleep schedule
• Create a relaxing bedtime routine
• Keep your bedroom dark, quiet, and cool
• Use your bed only for sleep

☕ Lifestyle:
• Avoid caffeine after 2 PM
• Limit alcohol before bed
• Exercise regularly (but not before bed)
• Get sunlight exposure during the day

📱 Technology:
• Enable night mode 2 hours before bed
• Avoid checking phone in bed
• Use smart alarm for gentle wake-up
• Track sleep patterns

🧘 Relaxation:
• Practice meditation or deep breathing
• Try progressive muscle relaxation
• Keep a journal to clear your mind
• Listen to calming music or sounds

💡 Remember: These are general wellness tips, not medical advice.
   Consult a healthcare professional for sleep disorders.
''';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getQualityEmoji(int quality) {
    if (quality >= 80) return '🌟';
    if (quality >= 60) return '👍';
    if (quality >= 40) return '😐';
    return '😴';
  }
}
