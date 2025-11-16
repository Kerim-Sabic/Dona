import 'persona_profiles.dart';
import '../core/utils/logger.dart';
import '../services/storage/local_storage_service.dart';

/// Manages persona selection and switching for Dona
class PersonaManager {
  static final PersonaManager _instance = PersonaManager._internal();
  static PersonaManager get instance => _instance;

  PersonaManager._internal();

  static const String _storageKey = 'active_persona_id';

  PersonaProfile _currentPersona = PersonaProfiles.defaultDona;

  /// Get the currently active persona
  PersonaProfile get currentPersona => _currentPersona;

  /// Initialize persona manager and load saved persona
  Future<void> init() async {
    try {
      final savedPersonaId =
          LocalStorageService.instance.getString(_storageKey);

      if (savedPersonaId != null) {
        final persona = PersonaProfiles.getById(savedPersonaId);
        if (persona != null) {
          _currentPersona = persona;
          AppLogger.info(
              'PersonaManager initialized with saved persona: ${persona.name}');
        } else {
          AppLogger.warning(
              'Saved persona ID "$savedPersonaId" not found, using default');
          _currentPersona = PersonaProfiles.defaultDona;
        }
      } else {
        AppLogger.info('PersonaManager initialized with default persona');
        _currentPersona = PersonaProfiles.defaultDona;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize PersonaManager', e, stackTrace);
      _currentPersona = PersonaProfiles.defaultDona;
    }
  }

  /// Switch to a different persona
  Future<bool> switchPersona(String personaId) async {
    try {
      final persona = PersonaProfiles.getById(personaId);

      if (persona == null) {
        AppLogger.warning('Persona with ID "$personaId" not found');
        return false;
      }

      _currentPersona = persona;
      await LocalStorageService.instance.setString(_storageKey, personaId);

      AppLogger.info('Switched to persona: ${persona.name}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to switch persona', e, stackTrace);
      return false;
    }
  }

  /// Get all available personas
  List<PersonaProfile> getAllPersonas() {
    return PersonaProfiles.allPersonas;
  }

  /// Get a specific persona by ID without switching
  PersonaProfile? getPersona(String id) {
    return PersonaProfiles.getById(id);
  }

  /// Reset to default persona
  Future<void> resetToDefault() async {
    await switchPersona(PersonaProfiles.defaultDona.id);
  }

  /// Get persona characteristics for current mode
  Map<String, dynamic> getCurrentCharacteristics() {
    return {
      'id': _currentPersona.id,
      'name': _currentPersona.name,
      'witLevel': _currentPersona.witLevel,
      'formalityLevel': _currentPersona.formalityLevel,
      'style': _currentPersona.conversationStyle,
    };
  }

  /// Check if current persona should use emoji
  bool get shouldUseEmoji {
    return _currentPersona.conversationStyle['useEmoji'] == true;
  }

  /// Get response length preference
  String get responseLength {
    return _currentPersona.conversationStyle['responseLength'] ?? 'medium';
  }

  /// Get suggestion frequency
  String get suggestionFrequency {
    return _currentPersona.conversationStyle['suggestionFrequency'] ?? 'moderate';
  }

  /// Get humor level
  String get humorLevel {
    return _currentPersona.conversationStyle['humorLevel'] ?? 'moderate';
  }

  /// Check if current persona is professional mode
  bool get isProfessionalMode {
    return _currentPersona.id == PersonaProfiles.professionalMode.id;
  }

  /// Check if current persona is study coach
  bool get isStudyCoach {
    return _currentPersona.id == PersonaProfiles.studyCoach.id;
  }

  /// Check if current persona is life advisor
  bool get isLifeAdvisor {
    return _currentPersona.id == PersonaProfiles.lifeAdvisor.id;
  }

  /// Check if current persona is founder/CEO mode
  bool get isFounderMode {
    return _currentPersona.id == PersonaProfiles.founderMode.id;
  }

  /// Get system prompt for current persona
  String getSystemPrompt() {
    return _currentPersona.systemPrompt;
  }

  /// Get system prompt with context injection
  String getSystemPromptWithContext({
    String? userContext,
    Map<String, dynamic>? additionalContext,
  }) {
    final basePrompt = _currentPersona.systemPrompt;
    final contextParts = <String>[];

    if (userContext != null && userContext.isNotEmpty) {
      contextParts.add('Current context: $userContext');
    }

    if (additionalContext != null && additionalContext.isNotEmpty) {
      final contextInfo = additionalContext.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      contextParts.add('Additional info: $contextInfo');
    }

    if (contextParts.isEmpty) {
      return basePrompt;
    }

    return '$basePrompt\n\n${contextParts.join('\n')}';
  }
}
