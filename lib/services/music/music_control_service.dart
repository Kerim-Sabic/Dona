import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/input_sanitizer.dart';

/// Music track model
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? duration; // in seconds
  final String? coverUrl;
  final String? previewUrl;
  final bool isPlaying;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.coverUrl,
    this.previewUrl,
    this.isPlaying = false,
  });

  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Playlist model
class MusicPlaylist {
  final String id;
  final String name;
  final String? description;
  final int trackCount;
  final String? coverUrl;

  MusicPlaylist({
    required this.id,
    required this.name,
    this.description,
    required this.trackCount,
    this.coverUrl,
  });
}

/// Music player state
enum PlayerState {
  playing,
  paused,
  stopped,
}

/// Music Control Service
/// Provides music playback control and streaming service integration
/// Supports Spotify, Apple Music, and local playback
class MusicControlService {
  static final MusicControlService _instance = MusicControlService._internal();
  static MusicControlService get instance => _instance;

  MusicControlService._internal();

  PlayerState _playerState = PlayerState.stopped;
  MusicTrack? _currentTrack;
  int _volume = 50; // 0-100
  bool _shuffle = false;
  bool _repeat = false;

  PlayerState get playerState => _playerState;
  MusicTrack? get currentTrack => _currentTrack;
  int get volume => _volume;
  bool get shuffle => _shuffle;
  bool get repeat => _repeat;

  Future<void> init() async {
    AppLogger.info('MusicControlService initialized');
  }

  /// Play a track by name/artist
  Future<String> play({String? query, String? service}) async {
    try {
      if (query == null || query.isEmpty) {
        // Resume current track
        if (_currentTrack != null) {
          _playerState = PlayerState.playing;
          return '▶️ Resumed: ${_currentTrack!.title} by ${_currentTrack!.artist}';
        }
        return 'No track to play. Try: "Play Bohemian Rhapsody"';
      }

      final sanitizedQuery = InputSanitizer.sanitizeSearchQuery(query);

      // For demonstration, create a mock track
      _currentTrack = MusicTrack(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: sanitizedQuery.split(' by ').first,
        artist: sanitizedQuery.contains(' by ')
            ? sanitizedQuery.split(' by ').last
            : 'Various Artists',
      );

      _playerState = PlayerState.playing;

      // Try to open in Spotify
      if (service == null || service.toLowerCase() == 'spotify') {
        final spotifySearch = Uri.encodeComponent(sanitizedQuery);
        final spotifyUrl = 'spotify:search:$spotifySearch';

        try {
          final uri = Uri.parse(spotifyUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return '🎵 Opening in Spotify: ${_currentTrack!.title}';
          }
        } catch (e) {
          AppLogger.debug('Spotify not available: $e');
        }

        // Fallback to web
        final webUrl = 'https://open.spotify.com/search/$spotifySearch';
        final webUri = Uri.parse(webUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          return '🎵 Opening in Spotify (Web): ${_currentTrack!.title}';
        }
      }

      // Apple Music fallback
      if (service != null && service.toLowerCase() == 'apple') {
        final appleSearch = Uri.encodeComponent(sanitizedQuery);
        final appleUrl = 'https://music.apple.com/search?term=$appleSearch';
        final uri = Uri.parse(appleUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return '🎵 Opening in Apple Music: ${_currentTrack!.title}';
        }
      }

      return '🎵 Playing: ${_currentTrack!.title}\n'
          'Note: Install Spotify or Apple Music app for full playback control.';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to play music', e, stackTrace);
      return 'Unable to play music. Please try again.';
    }
  }

  /// Pause playback
  Future<String> pause() async {
    if (_playerState == PlayerState.playing && _currentTrack != null) {
      _playerState = PlayerState.paused;
      return '⏸️ Paused: ${_currentTrack!.title}';
    }
    return 'Nothing is currently playing.';
  }

  /// Resume playback
  Future<String> resume() async {
    if (_playerState == PlayerState.paused && _currentTrack != null) {
      _playerState = PlayerState.playing;
      return '▶️ Resumed: ${_currentTrack!.title}';
    }
    return 'Nothing to resume.';
  }

  /// Stop playback
  Future<String> stop() async {
    if (_currentTrack != null) {
      final track = _currentTrack!;
      _currentTrack = null;
      _playerState = PlayerState.stopped;
      return '⏹️ Stopped: ${track.title}';
    }
    return 'Nothing is currently playing.';
  }

  /// Skip to next track
  Future<String> next() async {
    if (_currentTrack != null) {
      return '⏭️ Skipped to next track\n'
          'Note: This requires Spotify/Apple Music app for actual control.';
    }
    return 'Nothing is currently playing.';
  }

  /// Go to previous track
  Future<String> previous() async {
    if (_currentTrack != null) {
      return '⏮️ Went to previous track\n'
          'Note: This requires Spotify/Apple Music app for actual control.';
    }
    return 'Nothing is currently playing.';
  }

  /// Set volume (0-100)
  Future<String> setVolume(int level) async {
    if (level < 0 || level > 100) {
      return 'Volume must be between 0 and 100.';
    }

    _volume = level;

    String emoji;
    if (level == 0) {
      emoji = '🔇';
    } else if (level < 30) {
      emoji = '🔈';
    } else if (level < 70) {
      emoji = '🔉';
    } else {
      emoji = '🔊';
    }

    return '$emoji Volume set to $_volume%';
  }

  /// Toggle shuffle
  Future<String> toggleShuffle() async {
    _shuffle = !_shuffle;
    return _shuffle ? '🔀 Shuffle enabled' : '🔁 Shuffle disabled';
  }

  /// Toggle repeat
  Future<String> toggleRepeat() async {
    _repeat = !_repeat;
    return _repeat ? '🔂 Repeat enabled' : '➡️ Repeat disabled';
  }

  /// Search for music
  Future<List<MusicTrack>> search(String query) async {
    try {
      final sanitizedQuery = InputSanitizer.sanitizeSearchQuery(query);

      // For demonstration, return mock results
      return [
        MusicTrack(
          id: '1',
          title: sanitizedQuery,
          artist: 'Search Result 1',
          album: 'Album',
          duration: 180,
        ),
        MusicTrack(
          id: '2',
          title: '$sanitizedQuery (Remix)',
          artist: 'Search Result 2',
          album: 'Album',
          duration: 200,
        ),
      ];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search music', e, stackTrace);
      return [];
    }
  }

  /// Get current playback status
  String getStatus() {
    if (_currentTrack == null) {
      return '⏹️ No music playing\n'
          'Try: "Play Bohemian Rhapsody" or "Play jazz music"';
    }

    String statusIcon;
    switch (_playerState) {
      case PlayerState.playing:
        statusIcon = '▶️';
        break;
      case PlayerState.paused:
        statusIcon = '⏸️';
        break;
      case PlayerState.stopped:
        statusIcon = '⏹️';
        break;
    }

    final buffer = StringBuffer();
    buffer.writeln('$statusIcon Now Playing:');
    buffer.writeln('🎵 ${_currentTrack!.title}');
    buffer.writeln('🎤 ${_currentTrack!.artist}');

    if (_currentTrack!.album != null) {
      buffer.writeln('💿 ${_currentTrack!.album}');
    }

    if (_currentTrack!.duration != null) {
      buffer.writeln('⏱️ ${_currentTrack!.formattedDuration}');
    }

    buffer.writeln('\n🔊 Volume: $_volume%');
    if (_shuffle) buffer.writeln('🔀 Shuffle: ON');
    if (_repeat) buffer.writeln('🔂 Repeat: ON');

    return buffer.toString();
  }

  /// Get playlists (mock data)
  Future<List<MusicPlaylist>> getPlaylists() async {
    return [
      MusicPlaylist(
        id: '1',
        name: 'Liked Songs',
        description: 'Your favorite tracks',
        trackCount: 150,
      ),
      MusicPlaylist(
        id: '2',
        name: 'Daily Mix',
        description: 'Your daily music mix',
        trackCount: 50,
      ),
      MusicPlaylist(
        id: '3',
        name: 'Workout',
        description: 'High energy tracks',
        trackCount: 75,
      ),
    ];
  }

  /// Play playlist by name
  Future<String> playPlaylist(String playlistName) async {
    try {
      final sanitizedName = InputSanitizer.sanitizeText(playlistName);

      // For demonstration
      _playerState = PlayerState.playing;
      _currentTrack = MusicTrack(
        id: 'playlist-track',
        title: 'Track from $sanitizedName',
        artist: 'Playlist Artist',
      );

      return '🎵 Playing playlist: $sanitizedName\n'
          'Note: Full playlist control requires Spotify/Apple Music app.';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to play playlist', e, stackTrace);
      return 'Unable to play playlist. Please try again.';
    }
  }

  /// Get music recommendations
  Future<String> getRecommendations({String? genre, String? mood}) async {
    final buffer = StringBuffer('🎵 Music Recommendations:\n\n');

    if (genre != null) {
      buffer.writeln('Genre: ${genre.toUpperCase()}\n');
      buffer.writeln('Recommended tracks:');
      buffer.writeln('1. Track 1 - Artist 1');
      buffer.writeln('2. Track 2 - Artist 2');
      buffer.writeln('3. Track 3 - Artist 3');
    } else if (mood != null) {
      buffer.writeln('Mood: ${mood.toUpperCase()}\n');
      buffer.writeln('Recommended playlists:');
      buffer.writeln('1. ${mood.capitalize()} Vibes');
      buffer.writeln('2. ${mood.capitalize()} Mix');
      buffer.writeln('3. ${mood.capitalize()} Essentials');
    } else {
      buffer.writeln('Popular right now:');
      buffer.writeln('1. Top Hits 2025');
      buffer.writeln('2. New Music Friday');
      buffer.writeln('3. Today\'s Top Hits');
    }

    buffer.writeln('\nSay "Play [track name]" to start listening!');
    return buffer.toString();
  }

  /// Get help message
  String getHelp() {
    return '''
🎵 Music Control Help:

Playback:
• "Play Bohemian Rhapsody"
• "Play jazz music"
• "Pause"
• "Resume"
• "Stop"
• "Next track"
• "Previous track"

Volume:
• "Set volume to 50"
• "Volume up"
• "Volume down"
• "Mute"

Playlists:
• "Play my workout playlist"
• "Show my playlists"

Discovery:
• "Music recommendations"
• "Play happy music"
• "Play rock genre"

Status:
• "What's playing?"
• "Music status"

Note: Full playback control requires Spotify or Apple Music app.
For best experience, install the mobile app.
''';
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
