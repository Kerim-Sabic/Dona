import 'dart:convert';
import 'dart:async';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../focus/focus_mode_service.dart';

/// Enhanced Study Session Service
/// Smart Pomodoro timer with productivity tracking and analytics
class StudySessionService {
  static final StudySessionService _instance = StudySessionService._internal();
  static StudySessionService get instance => _instance;

  StudySessionService._internal();

  List<StudySession> _sessions = [];
  StudySession? _activeSession;
  Timer? _timer;
  int _secondsElapsed = 0;
  SessionPhase _currentPhase = SessionPhase.work;

  /// Initialize study session service
  Future<void> init() async {
    try {
      await _loadSessions();
      AppLogger.info('StudySessionService initialized with ${_sessions.length} past sessions');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize StudySessionService', e, stackTrace);
    }
  }

  /// Start a new study session
  Future<StudySession> startSession({
    String? courseId,
    String? examId,
    String? topic,
    String? goal,
    SessionType type = SessionType.pomodoro,
    Duration? customWorkDuration,
    Duration? customBreakDuration,
    bool enableFocusMode = true,
  }) async {
    try {
      // End any active session first
      if (_activeSession != null) {
        await endSession();
      }

      // Determine durations based on type
      Duration workDuration;
      Duration breakDuration;

      switch (type) {
        case SessionType.pomodoro:
          workDuration = const Duration(minutes: 25);
          breakDuration = const Duration(minutes: 5);
          break;
        case SessionType.short:
          workDuration = const Duration(minutes: 15);
          breakDuration = const Duration(minutes: 3);
          break;
        case SessionType.long:
          workDuration = const Duration(minutes: 50);
          breakDuration = const Duration(minutes: 10);
          break;
        case SessionType.custom:
          workDuration = customWorkDuration ?? const Duration(minutes: 25);
          breakDuration = customBreakDuration ?? const Duration(minutes: 5);
          break;
      }

      final session = StudySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        examId: examId,
        topic: topic,
        goal: goal,
        type: type,
        workDuration: workDuration,
        breakDuration: breakDuration,
        startTime: DateTime.now(),
        pomodorosCompleted: 0,
        distractions: 0,
      );

      _activeSession = session;
      _secondsElapsed = 0;
      _currentPhase = SessionPhase.work;

      // Enable focus mode if requested
      if (enableFocusMode) {
        await FocusModeService.instance.startFocusMode(duration: workDuration);
      }

      // Start timer
      _startTimer();

      AppLogger.info('Started study session: ${topic ?? 'Untitled'}');
      return session;
    } catch (e, stackTrace) {
      AppLogger.error('Error starting study session', e, stackTrace);
      rethrow;
    }
  }

  /// Start timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;

      // Check if current phase is complete
      final phaseDuration = _currentPhase == SessionPhase.work
        ? _activeSession!.workDuration
        : _activeSession!.breakDuration;

      if (_secondsElapsed >= phaseDuration.inSeconds) {
        _onPhaseComplete();
      }
    });
  }

  /// Handle phase completion
  void _onPhaseComplete() {
    if (_currentPhase == SessionPhase.work) {
      // Work phase complete - start break
      _currentPhase = SessionPhase.break_;
      _secondsElapsed = 0;

      // Update pomodoros completed
      _activeSession = StudySession(
        id: _activeSession!.id,
        courseId: _activeSession!.courseId,
        examId: _activeSession!.examId,
        topic: _activeSession!.topic,
        goal: _activeSession!.goal,
        type: _activeSession!.type,
        workDuration: _activeSession!.workDuration,
        breakDuration: _activeSession!.breakDuration,
        startTime: _activeSession!.startTime,
        endTime: _activeSession!.endTime,
        pomodorosCompleted: _activeSession!.pomodorosCompleted + 1,
        distractions: _activeSession!.distractions,
        notes: _activeSession!.notes,
        productivityScore: _activeSession!.productivityScore,
      );

      AppLogger.info('Work phase complete - starting break');
    } else {
      // Break complete - start new work phase
      _currentPhase = SessionPhase.work;
      _secondsElapsed = 0;

      AppLogger.info('Break complete - starting new work phase');
    }
  }

  /// Record a distraction
  Future<void> recordDistraction() async {
    if (_activeSession != null) {
      _activeSession = StudySession(
        id: _activeSession!.id,
        courseId: _activeSession!.courseId,
        examId: _activeSession!.examId,
        topic: _activeSession!.topic,
        goal: _activeSession!.goal,
        type: _activeSession!.type,
        workDuration: _activeSession!.workDuration,
        breakDuration: _activeSession!.breakDuration,
        startTime: _activeSession!.startTime,
        endTime: _activeSession!.endTime,
        pomodorosCompleted: _activeSession!.pomodorosCompleted,
        distractions: _activeSession!.distractions + 1,
        notes: _activeSession!.notes,
        productivityScore: _activeSession!.productivityScore,
      );

      AppLogger.debug('Recorded distraction');
    }
  }

  /// Pause current session
  void pauseSession() {
    _timer?.cancel();
    AppLogger.info('Session paused');
  }

  /// Resume paused session
  void resumeSession() {
    if (_activeSession != null) {
      _startTimer();
      AppLogger.info('Session resumed');
    }
  }

  /// End current session
  Future<StudySession?> endSession({String? notes, int? productivityScore}) async {
    try {
      if (_activeSession == null) return null;

      _timer?.cancel();

      // Disable focus mode
      if (FocusModeService.instance.isActive) {
        await FocusModeService.instance.stopFocusMode();
      }

      // Calculate final metrics
      final totalDuration = DateTime.now().difference(_activeSession!.startTime);
      final finalProductivityScore = productivityScore ?? _calculateProductivityScore();

      final completedSession = StudySession(
        id: _activeSession!.id,
        courseId: _activeSession!.courseId,
        examId: _activeSession!.examId,
        topic: _activeSession!.topic,
        goal: _activeSession!.goal,
        type: _activeSession!.type,
        workDuration: _activeSession!.workDuration,
        breakDuration: _activeSession!.breakDuration,
        startTime: _activeSession!.startTime,
        endTime: DateTime.now(),
        pomodorosCompleted: _activeSession!.pomodorosCompleted,
        distractions: _activeSession!.distractions,
        notes: notes ?? _activeSession!.notes,
        productivityScore: finalProductivityScore,
      );

      _sessions.add(completedSession);
      await _saveSessions();

      AppLogger.info('Ended study session - Duration: ${totalDuration.inMinutes}m, Pomodoros: ${completedSession.pomodorosCompleted}, Score: $finalProductivityScore');

      final result = _activeSession;
      _activeSession = null;
      _secondsElapsed = 0;

      return completedSession;
    } catch (e, stackTrace) {
      AppLogger.error('Error ending session', e, stackTrace);
      return null;
    }
  }

  /// Calculate productivity score based on session metrics
  int _calculateProductivityScore() {
    if (_activeSession == null) return 0;

    // Base score: 50
    int score = 50;

    // Pomodoros completed (up to +30 points)
    score += (_activeSession!.pomodorosCompleted * 6).clamp(0, 30);

    // Distractions penalty (up to -20 points)
    score -= (_activeSession!.distractions * 5).clamp(0, 20);

    // Duration bonus (for longer sessions)
    final minutes = DateTime.now().difference(_activeSession!.startTime).inMinutes;
    if (minutes >= 60) score += 15;
    else if (minutes >= 30) score += 10;
    else if (minutes >= 15) score += 5;

    return score.clamp(0, 100);
  }

  /// Get active session
  StudySession? get activeSession => _activeSession;

  /// Check if session is active
  bool get isSessionActive => _activeSession != null;

  /// Get current phase
  SessionPhase get currentPhase => _currentPhase;

  /// Get seconds elapsed in current phase
  int get secondsElapsed => _secondsElapsed;

  /// Get remaining time in current phase
  Duration get timeRemaining {
    if (_activeSession == null) return Duration.zero;

    final phaseDuration = _currentPhase == SessionPhase.work
      ? _activeSession!.workDuration
      : _activeSession!.breakDuration;

    final remaining = phaseDuration.inSeconds - _secondsElapsed;
    return Duration(seconds: remaining.clamp(0, phaseDuration.inSeconds));
  }

  /// Get all sessions
  List<StudySession> get allSessions => List.unmodifiable(_sessions);

  /// Get sessions for course
  List<StudySession> getSessionsForCourse(String courseId) =>
      _sessions.where((s) => s.courseId == courseId).toList();

  /// Get sessions for exam
  List<StudySession> getSessionsForExam(String examId) =>
      _sessions.where((s) => s.examId == examId).toList();

  /// Get recent sessions (last 7 days)
  List<StudySession> get recentSessions {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _sessions.where((s) => s.startTime.isAfter(weekAgo)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get today's sessions
  List<StudySession> get todaysSessions {
    final today = DateTime.now();
    return _sessions.where((s) {
      final start = s.startTime;
      return start.year == today.year &&
             start.month == today.month &&
             start.day == today.day;
    }).toList();
  }

  /// Get study statistics
  StudyStatistics getStatistics() {
    if (_sessions.isEmpty) {
      return StudyStatistics(
        totalSessions: 0,
        totalStudyTime: Duration.zero,
        totalPomodoros: 0,
        averageSessionDuration: Duration.zero,
        averageProductivity: 0.0,
        totalDistractions: 0,
        studyStreak: 0,
      );
    }

    final totalTime = _sessions.fold<Duration>(
      Duration.zero,
      (total, s) => total + (s.duration ?? Duration.zero),
    );

    final totalPomodoros = _sessions.fold<int>(
      0,
      (sum, s) => sum + s.pomodorosCompleted,
    );

    final avgDuration = Duration(
      seconds: totalTime.inSeconds ~/ _sessions.length,
    );

    final sessionsWithScores = _sessions.where((s) => s.productivityScore != null).toList();
    final avgProductivity = sessionsWithScores.isEmpty ? 0.0 :
      sessionsWithScores.fold<int>(0, (sum, s) => sum + s.productivityScore!) / sessionsWithScores.length;

    final totalDistractions = _sessions.fold<int>(
      0,
      (sum, s) => sum + s.distractions,
    );

    final streak = _calculateStudyStreak();

    return StudyStatistics(
      totalSessions: _sessions.length,
      totalStudyTime: totalTime,
      totalPomodoros: totalPomodoros,
      averageSessionDuration: avgDuration,
      averageProductivity: avgProductivity,
      totalDistractions: totalDistractions,
      studyStreak: streak,
      last7DaysSessions: recentSessions.length,
      todaysSessions: todaysSessions.length,
    );
  }

  /// Calculate study streak (consecutive days with sessions)
  int _calculateStudyStreak() {
    if (_sessions.isEmpty) return 0;

    final sortedSessions = List<StudySession>.from(_sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    DateTime? lastDate;

    for (final session in sortedSessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (lastDate == null) {
        // First session
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        // Only count if session was today
        if (sessionDate.isAtSameMomentAs(todayDate)) {
          streak = 1;
          lastDate = sessionDate;
        } else {
          break;
        }
      } else {
        // Check if this session is consecutive
        final expectedDate = lastDate.subtract(const Duration(days: 1));

        if (sessionDate.isAtSameMomentAs(expectedDate)) {
          streak++;
          lastDate = sessionDate;
        } else if (sessionDate.isBefore(expectedDate)) {
          // Gap in streak
          break;
        }
        // If same day, continue
      }
    }

    return streak;
  }

  /// Get break suggestions based on pomodoro count
  List<String> getBreakSuggestions() {
    final pomodorosCompleted = _activeSession?.pomodorosCompleted ?? 0;

    if (pomodorosCompleted % 4 == 0 && pomodorosCompleted > 0) {
      // Long break suggestions
      return [
        '🚶 Take a walk outside',
        '🧘 Do some stretching or yoga',
        '🍎 Have a healthy snack',
        '💤 Take a power nap (15-20 min)',
        '🎵 Listen to relaxing music',
      ];
    } else {
      // Short break suggestions
      return [
        '💧 Drink water',
        '👀 Look away from screen (20-20-20 rule)',
        '🧍 Stand up and stretch',
        '🪟 Look outside',
        '🫁 Deep breathing exercises',
      ];
    }
  }

  /// Dispose (cleanup)
  void dispose() {
    _timer?.cancel();
  }

  /// Save sessions
  Future<void> _saveSessions() async {
    try {
      final json = jsonEncode(_sessions.map((s) => {
        'id': s.id,
        'courseId': s.courseId,
        'examId': s.examId,
        'topic': s.topic,
        'goal': s.goal,
        'type': s.type.toString(),
        'workDuration': s.workDuration.inMinutes,
        'breakDuration': s.breakDuration.inMinutes,
        'startTime': s.startTime.toIso8601String(),
        'endTime': s.endTime?.toIso8601String(),
        'pomodorosCompleted': s.pomodorosCompleted,
        'distractions': s.distractions,
        'notes': s.notes,
        'productivityScore': s.productivityScore,
      }).toList());

      await LocalStorageService.instance.setString('study_sessions', json);
      AppLogger.debug('Saved ${_sessions.length} study sessions');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving study sessions', e, stackTrace);
    }
  }

  /// Load sessions
  Future<void> _loadSessions() async {
    try {
      final json = LocalStorageService.instance.getString('study_sessions');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _sessions = data.map((item) {
          return StudySession(
            id: item['id'] as String,
            courseId: item['courseId'] as String?,
            examId: item['examId'] as String?,
            topic: item['topic'] as String?,
            goal: item['goal'] as String?,
            type: SessionType.values.firstWhere(
              (t) => t.toString() == item['type'],
              orElse: () => SessionType.pomodoro,
            ),
            workDuration: Duration(minutes: item['workDuration'] as int),
            breakDuration: Duration(minutes: item['breakDuration'] as int),
            startTime: DateTime.parse(item['startTime'] as String),
            endTime: item['endTime'] != null
              ? DateTime.parse(item['endTime'] as String)
              : null,
            pomodorosCompleted: item['pomodorosCompleted'] as int,
            distractions: item['distractions'] as int,
            notes: item['notes'] as String?,
            productivityScore: item['productivityScore'] as int?,
          );
        }).toList();

        AppLogger.info('Loaded ${_sessions.length} study sessions');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading study sessions', e, stackTrace);
    }
  }
}

/// Study session model
class StudySession {
  final String id;
  final String? courseId;
  final String? examId;
  final String? topic;
  final String? goal;
  final SessionType type;
  final Duration workDuration;
  final Duration breakDuration;
  final DateTime startTime;
  final DateTime? endTime;
  final int pomodorosCompleted;
  final int distractions;
  final String? notes;
  final int? productivityScore;

  StudySession({
    required this.id,
    this.courseId,
    this.examId,
    this.topic,
    this.goal,
    required this.type,
    required this.workDuration,
    required this.breakDuration,
    required this.startTime,
    this.endTime,
    required this.pomodorosCompleted,
    required this.distractions,
    this.notes,
    this.productivityScore,
  });

  /// Get session duration
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Get focus percentage (time without distractions)
  double get focusPercentage {
    if (duration == null || duration!.inMinutes == 0) return 0.0;

    // Assume each distraction = 2 minutes lost
    final distractionMinutes = distractions * 2;
    final focusMinutes = duration!.inMinutes - distractionMinutes;

    return (focusMinutes / duration!.inMinutes * 100).clamp(0.0, 100.0);
  }
}

/// Session types
enum SessionType {
  pomodoro, // 25/5
  short,    // 15/3
  long,     // 50/10
  custom,   // User-defined
}

/// Session phase
enum SessionPhase {
  work,
  break_,
}

/// Study statistics
class StudyStatistics {
  final int totalSessions;
  final Duration totalStudyTime;
  final int totalPomodoros;
  final Duration averageSessionDuration;
  final double averageProductivity;
  final int totalDistractions;
  final int studyStreak;
  final int? last7DaysSessions;
  final int? todaysSessions;

  StudyStatistics({
    required this.totalSessions,
    required this.totalStudyTime,
    required this.totalPomodoros,
    required this.averageSessionDuration,
    required this.averageProductivity,
    required this.totalDistractions,
    required this.studyStreak,
    this.last7DaysSessions,
    this.todaysSessions,
  });

  @override
  String toString() {
    return '''
Study Statistics:
  Total Sessions: $totalSessions
  Total Study Time: ${totalStudyTime.inHours}h ${totalStudyTime.inMinutes % 60}m
  Total Pomodoros: $totalPomodoros
  Average Session: ${averageSessionDuration.inMinutes}min
  Average Productivity: ${averageProductivity.toStringAsFixed(1)}/100
  Study Streak: $studyStreak days 🔥
  ${last7DaysSessions != null ? 'Last 7 Days: $last7DaysSessions sessions' : ''}
  ${todaysSessions != null ? 'Today: $todaysSessions sessions' : ''}
''';
  }
}
