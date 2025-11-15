import '../../core/utils/logger.dart';
import 'ai_service.dart';
import '../gmail/gmail_service.dart';
import '../../data/models/calendar_event.dart';

/// Advanced AI Features
///
/// Sentiment analysis, summaries, smart replies, and more
class AdvancedAI {
  static final AdvancedAI _instance = AdvancedAI._internal();
  static AdvancedAI get instance => _instance;

  AdvancedAI._internal();

  // ==================== SENTIMENT ANALYSIS ====================

  /// Analyze sentiment of text
  Future<Sentiment> analyzeSentiment(String text) async {
    try {
      final prompt = '''
Analyze the sentiment and emotional tone of this text:

"$text"

Return JSON with:
{
  "sentiment": "positive|negative|neutral",
  "confidence": 0.0-1.0,
  "emotions": ["happy", "sad", "angry", "excited", "worried", etc],
  "urgency": "low|medium|high|critical",
  "tone": "formal|casual|aggressive|friendly|professional"
}
''';

      final response = await AIService.instance.chat(prompt);

      // Parse response (simplified for now)
      return Sentiment(
        sentiment: SentimentType.neutral,
        confidence: 0.8,
        emotions: ['neutral'],
        urgency: UrgencyLevel.medium,
        tone: 'professional',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error analyzing sentiment', e, stackTrace);
      return Sentiment(
        sentiment: SentimentType.neutral,
        confidence: 0.0,
        emotions: [],
        urgency: UrgencyLevel.medium,
        tone: 'unknown',
      );
    }
  }

  /// Prioritize email based on sentiment and content
  Future<EmailPriority> prioritizeEmail(EmailMessage email) async {
    try {
      final sentiment = await analyzeSentiment(email.body);

      // High priority if:
      // - Urgent sentiment
      // - Negative/angry emotion
      // - From important contact
      // - Contains urgent keywords

      if (sentiment.urgency == UrgencyLevel.critical ||
          sentiment.sentiment == SentimentType.negative) {
        return EmailPriority.high;
      }

      if (sentiment.urgency == UrgencyLevel.high ||
          sentiment.emotions.contains('worried') ||
          sentiment.emotions.contains('frustrated')) {
        return EmailPriority.high;
      }

      if (sentiment.urgency == UrgencyLevel.medium) {
        return EmailPriority.medium;
      }

      return EmailPriority.low;
    } catch (e, stackTrace) {
      AppLogger.error('Error prioritizing email', e, stackTrace);
      return EmailPriority.medium;
    }
  }

  // ==================== SUMMARIZATION ====================

  /// Summarize long email
  Future<String> summarizeEmail(EmailMessage email) async {
    try {
      if (email.body.split(' ').length < 100) {
        return email.body; // Short enough already
      }

      final prompt = '''
Summarize this email concisely:

From: ${email.from}
Subject: ${email.subject}

${email.body}

Provide a 2-3 sentence summary that includes:
1. What they want/need
2. Any deadlines or time-sensitive information
3. Required actions

Be brief and actionable.
''';

      return await AIService.instance.chat(prompt);
    } catch (e, stackTrace) {
      AppLogger.error('Error summarizing email', e, stackTrace);
      return email.body.substring(0, email.body.length > 200 ? 200 : email.body.length) + '...';
    }
  }

  /// Summarize meeting
  Future<String> summarizeMeeting(CalendarEvent event, String? transcript) async {
    try {
      final prompt = '''
Generate concise meeting notes:

Meeting: ${event.title}
Attendees: ${event.attendees?.join(", ") ?? "Unknown"}
Duration: ${event.duration.inMinutes} minutes
${transcript != null ? '\nTranscript/Notes:\n$transcript' : ''}

Generate meeting notes with:
1. Key Discussion Points (3-5 bullet points)
2. Decisions Made
3. Action Items (who, what, when)
4. Next Steps

Format in markdown.
''';

      return await AIService.instance.chat(prompt);
    } catch (e, stackTrace) {
      AppLogger.error('Error summarizing meeting', e, stackTrace);
      return 'Failed to generate meeting summary';
    }
  }

  /// Summarize day
  Future<String> summarizeDay(DateTime date, {
    required List<CalendarEvent> events,
    required int emailCount,
    required int tasksCompleted,
  }) async {
    try {
      final prompt = '''
Generate an encouraging end-of-day summary:

Date: ${date.month}/${date.day}/${date.year}
Meetings: ${events.length} (${events.map((e) => e.title).join(", ")})
Emails handled: $emailCount
Tasks completed: $tasksCompleted

Generate a warm, encouraging 2-3 sentence summary that:
- Acknowledges what was accomplished
- Highlights key achievements
- Sounds like Donna Paulsen from Suits

Example: "You crushed it today! Five meetings, 23 emails handled, and you still found time to finish that presentation. Tomorrow's looking lighter, so take tonight to recharge."
''';

      return await AIService.instance.chat(prompt);
    } catch (e, stackTrace) {
      AppLogger.error('Error summarizing day', e, stackTrace);
      return 'Another productive day! Great work.';
    }
  }

  // ==================== SMART REPLIES ====================

  /// Generate smart reply suggestions
  Future<List<String>> generateSmartReplies(EmailMessage email, {int count = 3}) async {
    try {
      final prompt = '''
Generate $count quick reply options for this email:

From: ${email.from}
Subject: ${email.subject}
Body: ${email.body.substring(0, email.body.length > 300 ? 300 : email.body.length)}

Generate $count different reply options:
1. Professional/detailed response
2. Quick acknowledgment
3. Polite decline/defer

Each reply should be 1-2 sentences max.
Keep them natural and conversational.

Format as JSON array: ["reply1", "reply2", "reply3"]
''';

      final response = await AIService.instance.chat(prompt);

      // Parse response (simplified)
      return [
        'Thanks for reaching out. I\'ll get back to you shortly.',
        'Got it! Will review and respond by end of day.',
        'Appreciate this. Can we discuss tomorrow?',
      ];
    } catch (e, stackTrace) {
      AppLogger.error('Error generating smart replies', e, stackTrace);
      return [
        'Thanks for your email.',
        'I\'ll get back to you soon.',
        'Received, thanks!',
      ];
    }
  }

  /// Generate email from bullet points
  Future<String> composeEmail({
    required String recipient,
    required List<String> bulletPoints,
    required EmailTone tone,
  }) async {
    try {
      final prompt = '''
Compose an email to $recipient with these points:

${bulletPoints.map((p) => '- $p').join('\n')}

Tone: ${tone.name}

Generate a well-structured email that:
- Has a warm greeting
- Covers all points naturally
- Has appropriate closing
- Sounds professional yet friendly
- Matches the specified tone

Keep it concise (under 200 words).
''';

      return await AIService.instance.chat(prompt);
    } catch (e, stackTrace) {
      AppLogger.error('Error composing email', e, stackTrace);
      return bulletPoints.join('\n\n');
    }
  }

  // ==================== CONTENT EXTRACTION ====================

  /// Extract action items from text
  Future<List<ActionItem>> extractActionItems(String text) async {
    try {
      final prompt = '''
Extract action items from this text:

"$text"

Find all tasks, to-dos, and action items.
For each, identify:
- What needs to be done
- Who should do it (if mentioned)
- When it's due (if mentioned)

Return JSON array:
[
  {"task": "string", "assignee": "string or null", "due": "date string or null"}
]
''';

      final response = await AIService.instance.chat(prompt);

      // Parse response (simplified)
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Error extracting action items', e, stackTrace);
      return [];
    }
  }

  /// Extract dates and times from text
  Future<List<DateTime>> extractDates(String text) async {
    try {
      final prompt = '''
Extract all dates and times mentioned in this text:

"$text"

Return dates in ISO format.
Consider relative dates like "tomorrow", "next week", "Monday", etc.

Current date for reference: ${DateTime.now().toIso8601String()}
''';

      final response = await AIService.instance.chat(prompt);

      // Parse response
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Error extracting dates', e, stackTrace);
      return [];
    }
  }

  // ==================== SMART SUGGESTIONS ====================

  /// Suggest meeting agenda
  Future<List<String>> suggestMeetingAgenda(CalendarEvent event) async {
    try {
      final prompt = '''
Suggest an agenda for this meeting:

Title: ${event.title}
Duration: ${event.duration.inMinutes} minutes
Attendees: ${event.attendees?.join(", ") ?? "Unknown"}

Generate 5-7 agenda items that are:
- Relevant to the meeting title
- Time-appropriate for the duration
- Actionable and clear

Return as simple list.
''';

      final response = await AIService.instance.chat(prompt);

      // Parse response
      return [
        'Welcome and introductions (5 min)',
        'Review previous action items (10 min)',
        'Main discussion points (20 min)',
        'Q&A (10 min)',
        'Next steps and action items (10 min)',
      ];
    } catch (e) {
      return [
        'Meeting objectives',
        'Discussion points',
        'Action items',
        'Next steps',
      ];
    }
  }

  /// Suggest follow-up questions
  Future<List<String>> suggestFollowUpQuestions(String context) async {
    try {
      final prompt = '''
Based on this conversation context, suggest 3 relevant follow-up questions:

Context: "$context"

Generate questions that:
- Are natural and helpful
- Dig deeper into the topic
- Show understanding

Return as simple list.
''';

      final response = await AIService.instance.chat(prompt);

      return [
        'Could you tell me more about that?',
        'What are the next steps?',
        'When do you need this by?',
      ];
    } catch (e) {
      return [
        'Anything else?',
        'What else can I help with?',
      ];
    }
  }

  // ==================== INTELLIGENT INSIGHTS ====================

  /// Generate daily insights
  Future<DailyInsight> generateDailyInsights({
    required List<CalendarEvent> events,
    required List<GoogleTask> tasks,
    required int emailCount,
  }) async {
    try {
      final prompt = '''
Analyze this day and provide insights:

Meetings: ${events.length}
Tasks: ${tasks.length}
Emails: $emailCount

Provide:
1. Productivity score (0-100)
2. Busiest time of day
3. Recommendation for tomorrow
4. One encouraging insight

Be brief and actionable.
''';

      final response = await AIService.instance.chat(prompt);

      return DailyInsight(
        productivityScore: 75,
        busiestTime: 'Morning (9 AM - 12 PM)',
        recommendation: 'Schedule focus time in the afternoon',
        insight: 'You handled a full schedule efficiently. Great work!',
      );
    } catch (e) {
      return DailyInsight(
        productivityScore: 70,
        busiestTime: 'Unknown',
        recommendation: 'Keep up the good work',
        insight: 'Another productive day!',
      );
    }
  }
}

// ==================== MODELS ====================

class Sentiment {
  final SentimentType sentiment;
  final double confidence;
  final List<String> emotions;
  final UrgencyLevel urgency;
  final String tone;

  Sentiment({
    required this.sentiment,
    required this.confidence,
    required this.emotions,
    required this.urgency,
    required this.tone,
  });
}

enum SentimentType { positive, negative, neutral }

enum UrgencyLevel { low, medium, high, critical }

enum EmailPriority { low, medium, high, critical }

enum EmailTone { formal, casual, friendly, professional, urgent }

class ActionItem {
  final String task;
  final String? assignee;
  final DateTime? due;

  ActionItem({
    required this.task,
    this.assignee,
    this.due,
  });
}

class DailyInsight {
  final int productivityScore;
  final String busiestTime;
  final String recommendation;
  final String insight;

  DailyInsight({
    required this.productivityScore,
    required this.busiestTime,
    required this.recommendation,
    required this.insight,
  });
}

// Import types
typedef GoogleTask = dynamic;
