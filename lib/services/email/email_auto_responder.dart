import '../../core/utils/logger.dart';
import '../gmail/gmail_service.dart';
import '../ai/advanced_ai.dart';
import '../autonomous/autonomous_actions.dart';
import '../../data/user_profile.dart';

/// Email Auto-Responder with intelligent automation
///
/// Automatically responds to emails based on:
/// - Email sentiment and urgency
/// - User's availability and schedule
/// - Permission settings
/// - Response patterns learned over time
class EmailAutoResponder {
  static final EmailAutoResponder _instance = EmailAutoResponder._internal();
  static EmailAutoResponder get instance => _instance;

  EmailAutoResponder._internal();

  // Response templates by category
  final Map<EmailCategory, List<String>> _templates = {
    EmailCategory.meetingRequest: [
      "Thanks for reaching out! I'll check my calendar and get back to you shortly.",
      "I appreciate the meeting request. Let me review my schedule and propose some times.",
      "Thank you! I'll coordinate with my calendar and send you some available slots.",
    ],
    EmailCategory.quickQuestion: [
      "Thanks for your question! I'll get back to you soon with details.",
      "Good question! Let me gather the information and respond shortly.",
      "I've received your question and will provide a thorough response soon.",
    ],
    EmailCategory.taskRequest: [
      "I've noted your request and will prioritize it accordingly.",
      "Thanks for sending this over. I'll review and provide an update soon.",
      "Request received! I'll work on this and keep you posted.",
    ],
    EmailCategory.information: [
      "Thanks for the update! I've noted the information.",
      "Received, thanks for keeping me in the loop!",
      "Thank you for sharing this information.",
    ],
    EmailCategory.urgent: [
      "I've received your urgent message and will prioritize this immediately.",
      "Thanks for flagging this as urgent. I'm on it and will respond ASAP.",
      "Urgent message received. I'll address this right away.",
    ],
  };

  /// Analyze email and determine if auto-response is appropriate
  Future<AutoResponseDecision> shouldAutoRespond(EmailMessage email) async {
    try {
      AppLogger.info('Analyzing email for auto-response: ${email.subject}');

      // 1. Check if sender is VIP (never auto-respond to VIPs without asking)
      if (UserProfile.instance.isVIPContact(email.from ?? '')) {
        return AutoResponseDecision(
          shouldRespond: false,
          reason: 'VIP contact - requires personal attention',
        );
      }

      // 2. Analyze sentiment and urgency
      final sentiment = await AdvancedAI.instance.analyzeSentiment(email.body);

      // 3. Check if it's a routine email
      final category = await _categorizeEmail(email);

      // 4. Check user's current availability
      final isAvailable = UserProfile.instance.isWorkHours;

      // 5. Determine if auto-response is appropriate
      bool shouldRespond = false;
      String reason = '';
      EmailCategory? responseCategory;

      if (sentiment.urgency > 0.8) {
        // Urgent emails should be flagged, not auto-responded
        return AutoResponseDecision(
          shouldRespond: false,
          reason: 'Urgent email - requires immediate personal attention',
          notifyUser: true,
        );
      }

      if (!isAvailable && category != EmailCategory.urgent) {
        // Outside work hours, auto-respond to non-urgent emails
        shouldRespond = true;
        reason = 'Outside work hours - auto-acknowledging receipt';
        responseCategory = category;
      }

      if (category == EmailCategory.meetingRequest ||
          category == EmailCategory.quickQuestion ||
          category == EmailCategory.taskRequest) {
        // These categories are good candidates for auto-response
        shouldRespond = true;
        reason = 'Routine ${category.name} - auto-acknowledging';
        responseCategory = category;
      }

      return AutoResponseDecision(
        shouldRespond: shouldRespond,
        reason: reason,
        category: responseCategory,
        suggestedResponse: shouldRespond
            ? await _generateResponse(email, responseCategory!)
            : null,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error analyzing email for auto-response', e, stackTrace);
      return AutoResponseDecision(
        shouldRespond: false,
        reason: 'Error analyzing email',
      );
    }
  }

  /// Categorize email by content
  Future<EmailCategory> _categorizeEmail(EmailMessage email) async {
    final content = '${email.subject} ${email.body}'.toLowerCase();

    // Simple keyword-based categorization
    if (content.contains('meeting') ||
        content.contains('schedule') ||
        content.contains('appointment')) {
      return EmailCategory.meetingRequest;
    }

    if (content.contains('quick question') ||
        content.contains('can you') ||
        content.contains('?') && email.body.length < 200) {
      return EmailCategory.quickQuestion;
    }

    if (content.contains('please') ||
        content.contains('could you') ||
        content.contains('need') ||
        content.contains('request')) {
      return EmailCategory.taskRequest;
    }

    if (content.contains('urgent') ||
        content.contains('asap') ||
        content.contains('immediate')) {
      return EmailCategory.urgent;
    }

    return EmailCategory.information;
  }

  /// Generate appropriate response based on category
  Future<String> _generateResponse(
    EmailMessage email,
    EmailCategory category,
  ) async {
    try {
      // Get template for category
      final templates = _templates[category] ?? _templates[EmailCategory.information]!;
      final baseTemplate = templates[DateTime.now().millisecond % templates.length];

      // Use AI to personalize the response
      final prompt = '''
Generate a professional auto-response email based on this template: "$baseTemplate"

Original email subject: ${email.subject}
From: ${email.from}
Category: ${category.name}

Requirements:
- Keep it brief (2-3 sentences max)
- Professional but warm tone
- Acknowledge their message
- Set expectation for when they'll hear back
- Don't make specific commitments
- Match the formality of their email

Generate only the email body, no subject line.
''';

      final aiResponse = await AdvancedAI.instance.composeEmail(
        points: [baseTemplate],
        tone: 'professional',
        recipient: email.from ?? 'recipient',
      );

      return aiResponse;
    } catch (e) {
      AppLogger.error('Error generating response', e);
      // Fallback to template
      final templates = _templates[category] ?? _templates[EmailCategory.information]!;
      return templates.first;
    }
  }

  /// Execute auto-response with permission check
  Future<bool> sendAutoResponse(EmailMessage originalEmail, String response) async {
    try {
      AppLogger.info('Attempting to send auto-response');

      // Create autonomous action for sending email
      final action = AutonomousAction(
        id: 'auto_respond_${originalEmail.id}',
        type: ActionType.respondToEmail,
        description: 'Auto-respond to email from ${originalEmail.from}',
        parameters: {
          'originalEmail': originalEmail,
          'response': response,
        },
        suggestedResponse: response,
      );

      // Execute with permission system
      final result = await AutonomousActions.instance.executeAction(action);

      if (result.success) {
        // Send the email
        final replyEmail = EmailMessage(
          to: [originalEmail.from ?? ''],
          subject: 'Re: ${originalEmail.subject}',
          body: response,
        );

        final sent = await GmailService.instance.sendEmail(replyEmail);

        if (sent != null) {
          AppLogger.info('Auto-response sent successfully');

          // Mark original as read
          if (originalEmail.id != null) {
            await GmailService.instance.markAsRead(originalEmail.id!);
          }

          return true;
        }
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error sending auto-response', e, stackTrace);
      return false;
    }
  }

  /// Process inbox and auto-respond where appropriate
  Future<AutoResponseSummary> processInbox({int maxEmails = 20}) async {
    try {
      AppLogger.info('Processing inbox for auto-responses');

      if (!GmailService.instance.isAuthenticated) {
        AppLogger.warning('Not authenticated with Gmail');
        return AutoResponseSummary(
          processed: 0,
          responded: 0,
          flagged: 0,
        );
      }

      // Get unread messages
      final messages = await GmailService.instance.getInboxMessages(maxResults: maxEmails);
      final unreadMessages = messages.where((m) => !(m.isRead ?? true)).toList();

      int responded = 0;
      int flagged = 0;

      for (final email in unreadMessages) {
        // Analyze each email
        final decision = await shouldAutoRespond(email);

        if (decision.notifyUser) {
          // Urgent email - notify user
          AppLogger.info('Urgent email flagged: ${email.subject}');
          flagged++;
          // In production, send notification to user
          continue;
        }

        if (decision.shouldRespond && decision.suggestedResponse != null) {
          // Attempt auto-response
          final sent = await sendAutoResponse(email, decision.suggestedResponse!);
          if (sent) {
            responded++;
          }
        }
      }

      return AutoResponseSummary(
        processed: unreadMessages.length,
        responded: responded,
        flagged: flagged,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error processing inbox', e, stackTrace);
      return AutoResponseSummary(
        processed: 0,
        responded: 0,
        flagged: 0,
      );
    }
  }
}

/// Decision on whether to auto-respond to an email
class AutoResponseDecision {
  final bool shouldRespond;
  final String reason;
  final EmailCategory? category;
  final String? suggestedResponse;
  final bool notifyUser;

  AutoResponseDecision({
    required this.shouldRespond,
    required this.reason,
    this.category,
    this.suggestedResponse,
    this.notifyUser = false,
  });
}

/// Email categories for auto-response
enum EmailCategory {
  meetingRequest,
  quickQuestion,
  taskRequest,
  information,
  urgent,
  other,
}

/// Summary of auto-response processing
class AutoResponseSummary {
  final int processed;
  final int responded;
  final int flagged;

  AutoResponseSummary({
    required this.processed,
    required this.responded,
    required this.flagged,
  });

  @override
  String toString() {
    return 'Processed $processed emails: $responded auto-responses sent, $flagged flagged for attention';
  }
}
