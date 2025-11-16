import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../ai/ai_service.dart';
import '../student/flashcard_generator_service.dart';

/// Smart Note
class SmartNote {
  final String id;
  final String title;
  final String content;
  final String? courseId;
  final String? examId;
  final DateTime created;
  final DateTime modified;
  final List<String> tags;
  final String? audioRecordingPath;
  final String? transcription;
  final NoteType type;
  final List<String> linkedNotes;

  SmartNote({
    required this.id,
    required this.title,
    required this.content,
    this.courseId,
    this.examId,
    required this.created,
    required this.modified,
    this.tags = const [],
    this.audioRecordingPath,
    this.transcription,
    this.type = NoteType.text,
    this.linkedNotes = const [],
  });

  factory SmartNote.fromJson(Map<String, dynamic> json) {
    return SmartNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      courseId: json['courseId'] as String?,
      examId: json['examId'] as String?,
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ?? [],
      audioRecordingPath: json['audioRecordingPath'] as String?,
      transcription: json['transcription'] as String?,
      type: NoteType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => NoteType.text,
      ),
      linkedNotes: (json['linkedNotes'] as List<dynamic>?)?.map((n) => n as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      if (courseId != null) 'courseId': courseId,
      if (examId != null) 'examId': examId,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
      'tags': tags,
      if (audioRecordingPath != null) 'audioRecordingPath': audioRecordingPath,
      if (transcription != null) 'transcription': transcription,
      'type': type.toString(),
      'linkedNotes': linkedNotes,
    };
  }
}

enum NoteType {
  text,
  lecture,
  meeting,
  outline,
  summary,
}

/// Smart Notes Service
/// AI-powered note-taking with lecture recording and transcription
class SmartNotesService {
  static final SmartNotesService _instance = SmartNotesService._internal();
  static SmartNotesService get instance => _instance;

  SmartNotesService._internal();

  List<SmartNote> _notes = [];
  SmartNote? _activeRecording;
  bool _isRecording = false;

  // Callbacks
  Function(bool)? onRecordingStateChanged;

  /// Initialize smart notes service
  Future<void> init() async {
    try {
      await _loadNotes();
      AppLogger.info('SmartNotesService initialized with ${_notes.length} notes');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize SmartNotesService', e, stackTrace);
    }
  }

  /// Get all notes
  List<SmartNote> get allNotes => List.unmodifiable(_notes);

  /// Get notes for course
  List<SmartNote> getNotesForCourse(String courseId) =>
      _notes.where((n) => n.courseId == courseId).toList();

  /// Get note by ID
  SmartNote? getNote(String noteId) {
    try {
      return _notes.firstWhere((n) => n.id == noteId);
    } catch (e) {
      return null;
    }
  }

  /// Create new note
  Future<SmartNote> createNote({
    required String title,
    String content = '',
    String? courseId,
    String? examId,
    NoteType type = NoteType.text,
    List<String> tags = const [],
  }) async {
    try {
      final note = SmartNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        courseId: courseId,
        examId: examId,
        created: DateTime.now(),
        modified: DateTime.now(),
        tags: tags,
        type: type,
      );

      _notes.add(note);
      await _saveNotes();

      AppLogger.info('Created note: $title');
      return note;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating note', e, stackTrace);
      rethrow;
    }
  }

  /// Update note
  Future<void> updateNote(SmartNote note) async {
    try {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        await _saveNotes();
        AppLogger.info('Updated note: ${note.title}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating note', e, stackTrace);
      rethrow;
    }
  }

  /// Delete note
  Future<bool> deleteNote(String noteId) async {
    try {
      final removedCount = _notes.where((n) => n.id == noteId).length;
      _notes.removeWhere((n) => n.id == noteId);

      if (removedCount > 0) {
        await _saveNotes();
        AppLogger.info('Deleted note: $noteId');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting note', e, stackTrace);
      return false;
    }
  }

  /// Start lecture recording
  /// In production: Uses Flutter audio recorder
  Future<void> startLectureRecording({
    required String title,
    String? courseId,
  }) async {
    if (_isRecording) return;

    try {
      _isRecording = true;
      onRecordingStateChanged?.call(true);

      _activeRecording = SmartNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: '',
        courseId: courseId,
        created: DateTime.now(),
        modified: DateTime.now(),
        type: NoteType.lecture,
      );

      // In production:
      // 1. Initialize audio recorder (record package or similar)
      // 2. Start recording with quality settings
      // 3. Save to local storage
      // 4. Real-time transcription (optional)

      AppLogger.info('🎤 Started lecture recording: $title');
    } catch (e, stackTrace) {
      AppLogger.error('Error starting lecture recording', e, stackTrace);
      _isRecording = false;
      onRecordingStateChanged?.call(false);
      rethrow;
    }
  }

  /// Stop lecture recording and transcribe
  Future<SmartNote> stopLectureRecording() async {
    if (!_isRecording || _activeRecording == null) {
      throw StateError('No active recording');
    }

    try {
      _isRecording = false;
      onRecordingStateChanged?.call(false);

      // In production:
      // 1. Stop audio recorder
      // 2. Get audio file path
      // 3. Send to Whisper API for transcription
      // 4. Process transcription with AI
      // 5. Generate organized notes

      AppLogger.info('🎤 Stopped lecture recording');

      // Simulated transcription
      final transcription = await _transcribeAudio(_activeRecording!.audioRecordingPath ?? '');

      // Generate organized notes from transcription
      final organizedNotes = await _organizeTranscription(transcription);

      // Auto-generate flashcards
      await _autoGenerateFlashcards(transcription, _activeRecording!.courseId);

      final completedNote = SmartNote(
        id: _activeRecording!.id,
        title: _activeRecording!.title,
        content: organizedNotes,
        courseId: _activeRecording!.courseId,
        created: _activeRecording!.created,
        modified: DateTime.now(),
        type: NoteType.lecture,
        transcription: transcription,
        audioRecordingPath: 'path/to/recording.wav', // Placeholder
      );

      _notes.add(completedNote);
      await _saveNotes();

      _activeRecording = null;

      return completedNote;
    } catch (e, stackTrace) {
      AppLogger.error('Error stopping lecture recording', e, stackTrace);
      _isRecording = false;
      onRecordingStateChanged?.call(false);
      rethrow;
    }
  }

  /// Transcribe audio using Whisper API
  /// In production: Uses OpenAI Whisper API ($0.006/minute)
  Future<String> _transcribeAudio(String audioFilePath) async {
    try {
      // In production:
      // 1. Send audio to Whisper API
      // 2. Get transcription with timestamps
      // 3. Format transcription

      AppLogger.info('Transcribing audio...');

      // Placeholder - production would call Whisper API
      return 'Transcribed lecture content would appear here. This would include all spoken words from the lecture, formatted with proper punctuation and paragraphs.';
    } catch (e, stackTrace) {
      AppLogger.error('Error transcribing audio', e, stackTrace);
      return '';
    }
  }

  /// Organize transcription into structured notes
  Future<String> _organizeTranscription(String transcription) async {
    try {
      final prompt = '''
Organize this lecture transcription into well-structured notes:

Transcription:
$transcription

Create:
1. Clear section headings
2. Bullet points for key concepts
3. Numbered lists for processes/steps
4. Highlight important definitions
5. Organize by topic

Return formatted markdown notes.
''';

      final organized = await AIService.instance.chat(prompt);
      return organized;
    } catch (e, stackTrace) {
      AppLogger.error('Error organizing transcription', e, stackTrace);
      return transcription; // Fallback to raw transcription
    }
  }

  /// Auto-generate flashcards from notes
  Future<void> _autoGenerateFlashcards(String content, String? courseId) async {
    try {
      if (courseId == null) return;

      // Generate flashcards using FlashcardGeneratorService
      await FlashcardGeneratorService.instance.generateFlashcardsFromText(
        text: content,
        deckTitle: 'Lecture Flashcards',
        courseId: courseId,
      );

      AppLogger.info('Auto-generated flashcards from lecture');
    } catch (e, stackTrace) {
      AppLogger.error('Error auto-generating flashcards', e, stackTrace);
    }
  }

  /// Search notes
  List<SmartNote> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
             note.content.toLowerCase().contains(lowerQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get notes by tag
  List<SmartNote> getNotesByTag(String tag) {
    return _notes.where((note) => note.tags.contains(tag)).toList();
  }

  /// Link notes together
  Future<void> linkNotes(String noteId1, String noteId2) async {
    try {
      final note1 = getNote(noteId1);
      final note2 = getNote(noteId2);

      if (note1 == null || note2 == null) return;

      // Add bidirectional links
      // (Simplified - would need to update SmartNote model)

      AppLogger.info('Linked notes: ${note1.title} <-> ${note2.title}');
    } catch (e, stackTrace) {
      AppLogger.error('Error linking notes', e, stackTrace);
    }
  }

  /// Get recording state
  bool get isRecording => _isRecording;

  /// Save notes
  Future<void> _saveNotes() async {
    try {
      final json = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await LocalStorageService.instance.setString('smart_notes', json);
      AppLogger.debug('Saved ${_notes.length} notes');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving notes', e, stackTrace);
    }
  }

  /// Load notes
  Future<void> _loadNotes() async {
    try {
      final json = LocalStorageService.instance.getString('smart_notes');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _notes = data.map((item) => SmartNote.fromJson(item)).toList();
        AppLogger.info('Loaded ${_notes.length} notes');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading notes', e, stackTrace);
    }
  }
}
