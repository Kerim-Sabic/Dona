import 'dart:convert';
import '../../core/utils/logger.dart';
import '../storage/local_storage_service.dart';
import '../gmail/gmail_service.dart';
import '../calendar/calendar_service.dart';
import '../ai/ai_service.dart';

/// Relationship Manager
/// Tracks and nurtures professional and personal relationships
/// - Reminds you to follow up with contacts
/// - Tracks last interaction dates
/// - Suggests when to reach out
/// - Analyzes communication patterns
class RelationshipManager {
  static final RelationshipManager _instance = RelationshipManager._internal();
  static RelationshipManager get instance => _instance;

  RelationshipManager._internal();

  final Map<String, Contact> _contacts = {};
  final List<Interaction> _interactions = [];

  /// Initialize relationship manager
  Future<void> init() async {
    try {
      await _loadContacts();
      await _loadInteractions();
      AppLogger.info('RelationshipManager initialized with ${_contacts.length} contacts');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize RelationshipManager', e, stackTrace);
    }
  }

  /// Track email interaction
  Future<void> trackEmailInteraction(EmailMessage email) async {
    try {
      final contactEmail = email.from ?? email.to.first;

      // Get or create contact
      final contact = await _getOrCreateContact(contactEmail);

      // Record interaction
      final interaction = Interaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactEmail: contactEmail,
        type: InteractionType.email,
        timestamp: DateTime.now(),
        subject: email.subject,
        sentiment: await _analyzeSentiment(email.body),
      );

      _interactions.add(interaction);
      contact.lastInteraction = DateTime.now();
      contact.interactionCount++;

      await _saveContacts();
      await _saveInteractions();

      AppLogger.debug('Tracked email interaction with $contactEmail');
    } catch (e, stackTrace) {
      AppLogger.error('Error tracking email interaction', e, stackTrace);
    }
  }

  /// Track meeting interaction
  Future<void> trackMeetingInteraction(String contactEmail, String meetingTitle) async {
    try {
      final contact = await _getOrCreateContact(contactEmail);

      final interaction = Interaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactEmail: contactEmail,
        type: InteractionType.meeting,
        timestamp: DateTime.now(),
        subject: meetingTitle,
      );

      _interactions.add(interaction);
      contact.lastInteraction = DateTime.now();
      contact.interactionCount++;
      contact.lastMeetingDate = DateTime.now();

      await _saveContacts();
      await _saveInteractions();

      AppLogger.debug('Tracked meeting interaction with $contactEmail');
    } catch (e, stackTrace) {
      AppLogger.error('Error tracking meeting interaction', e, stackTrace);
    }
  }

  /// Get or create contact
  Future<Contact> _getOrCreateContact(String email) async {
    if (_contacts.containsKey(email)) {
      return _contacts[email]!;
    }

    final contact = Contact(
      email: email,
      name: _extractNameFromEmail(email),
      firstInteraction: DateTime.now(),
      lastInteraction: DateTime.now(),
      interactionCount: 0,
      relationship: RelationshipStrength.acquaintance,
    );

    _contacts[email] = contact;
    return contact;
  }

  /// Get contacts needing follow-up
  List<Contact> getContactsNeedingFollowUp({int daysSinceContact = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceContact));

    return _contacts.values.where((contact) {
      // Skip VIP contacts (handled separately)
      if (contact.isVIP) return false;

      // Check if last interaction was before cutoff
      if (contact.lastInteraction.isBefore(cutoffDate)) {
        // Only suggest for important relationships
        return contact.relationship == RelationshipStrength.close ||
               contact.relationship == RelationshipStrength.important;
      }

      return false;
    }).toList()
      ..sort((a, b) => a.lastInteraction.compareTo(b.lastInteraction));
  }

  /// Get relationship insights
  Future<RelationshipInsights> getInsights() async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));

      // Count interactions in last 30 days
      final recentInteractions = _interactions.where(
        (i) => i.timestamp.isAfter(last30Days),
      ).toList();

      // Group by contact
      final Map<String, int> interactionsByContact = {};
      for (final interaction in recentInteractions) {
        interactionsByContact[interaction.contactEmail] =
          (interactionsByContact[interaction.contactEmail] ?? 0) + 1;
      }

      // Find most contacted
      final sortedContacts = interactionsByContact.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topContacts = sortedContacts.take(5)
        .map((e) => _contacts[e.key])
        .whereType<Contact>()
        .toList();

      // Get contacts needing follow-up
      final needsFollowUp = await getContactsNeedingFollowUp();

      // Calculate relationship distribution
      final relationshipDist = <RelationshipStrength, int>{};
      for (final contact in _contacts.values) {
        relationshipDist[contact.relationship] =
          (relationshipDist[contact.relationship] ?? 0) + 1;
      }

      // Generate AI insights
      final aiInsights = await _generateAIInsights(
        topContacts: topContacts,
        needsFollowUp: needsFollowUp,
        totalContacts: _contacts.length,
        recentInteractions: recentInteractions.length,
      );

      return RelationshipInsights(
        totalContacts: _contacts.length,
        recentInteractions: recentInteractions.length,
        topContacts: topContacts,
        needsFollowUp: needsFollowUp,
        relationshipDistribution: relationshipDist,
        aiInsights: aiInsights,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error generating relationship insights', e, stackTrace);
      rethrow;
    }
  }

  /// Generate AI insights
  Future<String> _generateAIInsights({
    required List<Contact> topContacts,
    required List<Contact> needsFollowUp,
    required int totalContacts,
    required int recentInteractions,
  }) async {
    try {
      final prompt = '''
Generate relationship insights based on this data:

Total contacts: $totalContacts
Recent interactions (30 days): $recentInteractions

Top 5 contacts:
${topContacts.map((c) => '- ${c.name} (${c.interactionCount} interactions)').join('\n')}

Contacts needing follow-up:
${needsFollowUp.take(3).map((c) => '- ${c.name} (last contact: ${_daysAgo(c.lastInteraction)} days ago)').join('\n')}

Requirements:
- Be concise (3-4 sentences)
- Highlight strong relationships
- Suggest who to follow up with
- Give actionable advice
- Be encouraging and professional

Example: "You're maintaining strong connections with your top 5 contacts. Consider reaching out to Sarah - it's been 45 days since your last meeting. A quick check-in email could strengthen that relationship."
''';

      return await AIService.instance.chat(prompt);
    } catch (e) {
      AppLogger.error('Error generating AI insights', e);
      return 'Continue building strong professional relationships!';
    }
  }

  /// Analyze sentiment of text
  Future<double> _analyzeSentiment(String text) async {
    // Simplified sentiment analysis
    // In production, use AdvancedAI.instance.analyzeSentiment
    return 0.5; // Neutral
  }

  /// Extract name from email
  String _extractNameFromEmail(String email) {
    // Try to extract name from email address
    final localPart = email.split('@').first;
    final parts = localPart.split('.');

    if (parts.length >= 2) {
      return '${_capitalize(parts[0])} ${_capitalize(parts[1])}';
    }

    return _capitalize(localPart);
  }

  /// Capitalize string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Days ago
  int _daysAgo(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }

  /// Mark contact as VIP
  Future<void> markAsVIP(String email) async {
    final contact = _contacts[email];
    if (contact != null) {
      contact.isVIP = true;
      contact.relationship = RelationshipStrength.important;
      await _saveContacts();
      AppLogger.info('Marked $email as VIP');
    }
  }

  /// Update relationship strength
  Future<void> updateRelationship(String email, RelationshipStrength strength) async {
    final contact = _contacts[email];
    if (contact != null) {
      contact.relationship = strength;
      await _saveContacts();
      AppLogger.info('Updated relationship for $email to ${strength.name}');
    }
  }

  /// Add note to contact
  Future<void> addNote(String email, String note) async {
    final contact = _contacts[email];
    if (contact != null) {
      contact.notes.add(ContactNote(
        text: note,
        timestamp: DateTime.now(),
      ));
      await _saveContacts();
      AppLogger.info('Added note to $email');
    }
  }

  /// Get contact
  Contact? getContact(String email) {
    return _contacts[email];
  }

  /// Get all contacts
  List<Contact> get allContacts => _contacts.values.toList();

  /// Load contacts from storage
  Future<void> _loadContacts() async {
    try {
      final json = LocalStorageService.instance.getString('relationship_contacts');
      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        _contacts.clear();
        data.forEach((email, contactData) {
          _contacts[email] = Contact.fromJson(contactData);
        });
        AppLogger.info('Loaded ${_contacts.length} contacts');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading contacts', e, stackTrace);
    }
  }

  /// Save contacts to storage
  Future<void> _saveContacts() async {
    try {
      final data = _contacts.map((email, contact) =>
        MapEntry(email, contact.toJson())
      );
      final json = jsonEncode(data);
      await LocalStorageService.instance.setString('relationship_contacts', json);
      AppLogger.debug('Saved ${_contacts.length} contacts');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving contacts', e, stackTrace);
    }
  }

  /// Load interactions from storage
  Future<void> _loadInteractions() async {
    try {
      final json = LocalStorageService.instance.getString('relationship_interactions');
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _interactions.clear();
        _interactions.addAll(
          data.map((item) => Interaction.fromJson(item)),
        );
        AppLogger.info('Loaded ${_interactions.length} interactions');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading interactions', e, stackTrace);
    }
  }

  /// Save interactions to storage
  Future<void> _saveInteractions() async {
    try {
      final json = jsonEncode(_interactions.map((i) => i.toJson()).toList());
      await LocalStorageService.instance.setString('relationship_interactions', json);
      AppLogger.debug('Saved ${_interactions.length} interactions');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving interactions', e, stackTrace);
    }
  }
}

/// Contact model
class Contact {
  final String email;
  String name;
  DateTime firstInteraction;
  DateTime lastInteraction;
  DateTime? lastMeetingDate;
  int interactionCount;
  RelationshipStrength relationship;
  bool isVIP;
  final List<ContactNote> notes;
  Map<String, dynamic> metadata;

  Contact({
    required this.email,
    required this.name,
    required this.firstInteraction,
    required this.lastInteraction,
    this.lastMeetingDate,
    required this.interactionCount,
    required this.relationship,
    this.isVIP = false,
    List<ContactNote>? notes,
    Map<String, dynamic>? metadata,
  }) : notes = notes ?? [],
       metadata = metadata ?? {};

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      email: json['email'] as String,
      name: json['name'] as String,
      firstInteraction: DateTime.parse(json['firstInteraction'] as String),
      lastInteraction: DateTime.parse(json['lastInteraction'] as String),
      lastMeetingDate: json['lastMeetingDate'] != null
        ? DateTime.parse(json['lastMeetingDate'] as String)
        : null,
      interactionCount: json['interactionCount'] as int,
      relationship: RelationshipStrength.values.firstWhere(
        (e) => e.toString() == json['relationship'],
        orElse: () => RelationshipStrength.acquaintance,
      ),
      isVIP: json['isVIP'] as bool? ?? false,
      notes: (json['notes'] as List<dynamic>?)
        ?.map((n) => ContactNote.fromJson(n))
        .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'firstInteraction': firstInteraction.toIso8601String(),
      'lastInteraction': lastInteraction.toIso8601String(),
      if (lastMeetingDate != null) 'lastMeetingDate': lastMeetingDate!.toIso8601String(),
      'interactionCount': interactionCount,
      'relationship': relationship.toString(),
      'isVIP': isVIP,
      'notes': notes.map((n) => n.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

/// Contact note
class ContactNote {
  final String text;
  final DateTime timestamp;

  ContactNote({required this.text, required this.timestamp});

  factory ContactNote.fromJson(Map<String, dynamic> json) {
    return ContactNote(
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Interaction model
class Interaction {
  final String id;
  final String contactEmail;
  final InteractionType type;
  final DateTime timestamp;
  final String? subject;
  final double? sentiment;

  Interaction({
    required this.id,
    required this.contactEmail,
    required this.type,
    required this.timestamp,
    this.subject,
    this.sentiment,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      id: json['id'] as String,
      contactEmail: json['contactEmail'] as String,
      type: InteractionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => InteractionType.other,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      subject: json['subject'] as String?,
      sentiment: (json['sentiment'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactEmail': contactEmail,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      if (subject != null) 'subject': subject,
      if (sentiment != null) 'sentiment': sentiment,
    };
  }
}

/// Interaction type
enum InteractionType {
  email,
  meeting,
  call,
  message,
  other,
}

/// Relationship strength
enum RelationshipStrength {
  acquaintance,  // Just met or infrequent contact
  regular,       // Regular professional contact
  close,         // Close professional relationship
  important,     // Key stakeholder or mentor
}

/// Relationship insights
class RelationshipInsights {
  final int totalContacts;
  final int recentInteractions;
  final List<Contact> topContacts;
  final List<Contact> needsFollowUp;
  final Map<RelationshipStrength, int> relationshipDistribution;
  final String aiInsights;

  RelationshipInsights({
    required this.totalContacts,
    required this.recentInteractions,
    required this.topContacts,
    required this.needsFollowUp,
    required this.relationshipDistribution,
    required this.aiInsights,
  });

  @override
  String toString() {
    return '''
Relationship Insights:
  Total contacts: $totalContacts
  Recent interactions (30 days): $recentInteractions
  Top contacts: ${topContacts.length}
  Needs follow-up: ${needsFollowUp.length}

AI Insights:
  $aiInsights
''';
  }
}
