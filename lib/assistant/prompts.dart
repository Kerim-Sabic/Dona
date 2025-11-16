/// Centralized AI prompts for Dona AI Assistant
///
/// This file contains all prompt templates used across the app
/// for consistency and easy maintenance.

class DonaPrompts {
  /// Intent extraction prompt
  static String intentExtractionPrompt(String userMessage) {
    return '''
Analyze this user message and extract the intent and entities.
Return ONLY a JSON object with this exact structure:
{
  "intent": "intent_name",
  "entities": {},
  "confidence": 0.0
}

Possible intents:
- get_news: User wants news/headlines
- get_weather: User wants weather information
- schedule_event: User wants to create/modify calendar event
- check_schedule: User wants to see their calendar
- manage_task: User wants to create/complete/modify a task
- email_action: User wants to send/read/manage email
- make_call: User wants to make a phone call
- send_message: User wants to send SMS
- get_directions: User wants navigation/directions
- study_help: User wants academic assistance
- start_focus: User wants to start focus session
- general_chat: General conversation
- unknown: Cannot determine intent

User message: "$userMessage"

Return only the JSON object, no explanation.
''';
  }

  /// Flashcard generation prompt
  static String flashcardGenerationPrompt({
    required String text,
    required int count,
  }) {
    return '''
Generate $count flashcards from the following text.
Return ONLY a JSON array with this structure:
[
  {
    "question": "Clear, specific question",
    "answer": "Concise answer",
    "hint": "Optional hint (or null)"
  }
]

Guidelines:
- Focus on key concepts and facts
- Make questions clear and specific
- Keep answers concise but complete
- Include hints for difficult concepts
- Use active recall principles
- Prioritize important information

Text to analyze:
$text

Return only the JSON array, no explanation.
''';
  }

  /// Quiz generation prompt
  static String quizGenerationPrompt({
    required String text,
    required int questionCount,
    required String difficulty,
  }) {
    return '''
Generate a $difficulty difficulty quiz with $questionCount questions from the following text.

Return ONLY a JSON array with this structure:
[
  {
    "type": "multiple_choice",
    "question": "Question text",
    "options": ["A", "B", "C", "D"],
    "correctAnswer": "C",
    "explanation": "Why this is correct"
  }
]

Question types to use:
- multiple_choice: 4 options
- true_false: True or False
- short_answer: Brief answer expected

Difficulty levels:
- easy: Straightforward recall
- medium: Application and understanding
- hard: Analysis and synthesis
- expert: Critical thinking and evaluation

Guidelines:
- Mix question types
- Ensure all options are plausible
- Provide clear explanations
- Cover main concepts evenly
- Use clear, unambiguous language

Text to analyze:
$text

Return only the JSON array, no explanation.
''';
  }

  /// Document summarization prompt
  static String documentSummaryPrompt({
    required String text,
    required String summaryLength,
  }) {
    return '''
Summarize the following text into a $summaryLength summary.

Length options:
- brief: 2-3 sentences, main point only
- medium: 1-2 paragraphs, key points
- detailed: Multiple paragraphs, comprehensive

Guidelines:
- Capture main ideas and key points
- Maintain logical flow
- Use clear, concise language
- Include important details for medium/detailed
- Preserve critical information

Text to summarize:
$text

Provide only the summary, no preamble.
''';
  }

  /// Homework help prompt
  static String homeworkHelpPrompt({
    required String subject,
    required String question,
    required String gradeLevel,
  }) {
    return '''
Help a $gradeLevel student with this $subject question.

Guidelines:
- Provide step-by-step explanation
- Don't just give the answer - teach the concept
- Use age-appropriate language
- Include examples if helpful
- Encourage understanding over memorization
- If it's a problem-solving question, show the steps
- If it's a concept question, explain clearly

Subject: $subject
Grade Level: $gradeLevel
Question: $question

Provide your helpful explanation:
''';
  }

  /// Proactive suggestion prompt
  static String proactiveSuggestionPrompt({
    required String context,
    required String timeOfDay,
    required String location,
  }) {
    return '''
Based on the user's current context, suggest 2-3 helpful actions.

Current Context:
Time: $timeOfDay
Location: $location
Details: $context

Guidelines:
- Be genuinely helpful, not annoying
- Suggest actions that save time or add value
- Consider the time of day (don't suggest meetings at night)
- Be context-aware (don't suggest study if user is at gym)
- Keep suggestions brief and actionable

Return ONLY a JSON array:
[
  {
    "suggestion": "Brief description of action",
    "reason": "Why this would be helpful now",
    "priority": "high|medium|low"
  }
]

Return only the JSON array, no explanation.
''';
  }

  /// Email drafting prompt
  static String emailDraftPrompt({
    required String recipient,
    required String purpose,
    required String context,
    required String tone,
  }) {
    return '''
Draft an email for the following scenario.

Recipient: $recipient
Purpose: $purpose
Tone: $tone (professional, casual, formal, friendly)
Context: $context

Guidelines:
- Match the requested tone
- Be clear and concise
- Include appropriate greeting and closing
- Stay focused on the purpose
- Proofread for errors

Provide the email draft:
''';
  }

  /// Meeting notes summarization
  static String meetingNotesSummaryPrompt(String notes) {
    return '''
Summarize these meeting notes into a structured format.

Meeting notes:
$notes

Provide a summary with:
1. Key decisions made
2. Action items (who does what by when)
3. Important discussions
4. Next steps

Keep it concise and actionable.
''';
  }

  /// Relationship reminder prompt
  static String relationshipReminderPrompt({
    required String personName,
    required int daysSinceContact,
    required String relationship,
  }) {
    return '''
Generate a warm, personal reminder to reach out to someone.

Person: $personName
Relationship: $relationship
Last contact: $daysSinceContact days ago

Guidelines:
- Be warm and genuine
- Suggest specific conversation starters
- Acknowledge the relationship type
- Keep it brief and actionable

Provide the reminder message:
''';
  }

  /// Study session planning prompt
  static String studySessionPlanPrompt({
    required String subject,
    required int availableMinutes,
    required String examDate,
  }) {
    return '''
Create an effective study session plan.

Subject: $subject
Available time: $availableMinutes minutes
Exam date: $examDate

Guidelines:
- Use proven study techniques (Pomodoro, active recall, spaced repetition)
- Include breaks
- Prioritize high-impact topics
- Mix different study activities
- Be realistic about time

Provide a structured study plan with:
1. Breakdown by time blocks
2. Specific activities
3. Break schedule
4. Priority topics

Return the study plan:
''';
  }

  /// Habit tracking motivation prompt
  static String habitMotivationPrompt({
    required String habitName,
    required int currentStreak,
    required int targetStreak,
  }) {
    return '''
Generate an encouraging message for habit tracking.

Habit: $habitName
Current streak: $currentStreak days
Target: $targetStreak days

Guidelines:
- Be genuinely encouraging, not patronizing
- Acknowledge progress (even small wins)
- Provide specific motivation
- If streak is broken, be supportive not judgmental
- Keep it brief and inspiring

Provide the motivation message:
''';
  }

  /// Context-aware conversation starter
  static String contextAwareStarterPrompt({
    required String userContext,
    required String recentActivity,
  }) {
    return '''
Generate a helpful, context-aware conversation starter.

Current context: $userContext
Recent activity: $recentActivity

Guidelines:
- Reference their current context naturally
- Offer specific help based on what they're doing
- Don't be intrusive - be helpful
- Keep it conversational and warm
- Suggest 1-2 actionable things

Provide the conversation starter:
''';
  }

  /// Smart scheduling conflict resolution
  static String scheduleConflictPrompt({
    required String event1,
    required String event2,
    required String userPreferences,
  }) {
    return '''
Help resolve a scheduling conflict.

Conflicting events:
1. $event1
2. $event2

User preferences: $userPreferences

Guidelines:
- Consider event priority and flexibility
- Suggest concrete solutions
- Respect user's preferences
- Offer alternatives
- Explain your reasoning

Provide conflict resolution suggestions:
''';
  }

  /// News personalization prompt
  static String personalizedNewsPrompt({
    required List<String> interests,
    required String location,
  }) {
    return '''
Generate a personalized news briefing summary.

User interests: ${interests.join(', ')}
Location: $location

Guidelines:
- Prioritize topics matching interests
- Include local news if relevant
- Mix importance with interest
- Keep summaries concise
- Highlight actionable insights

Provide a structured news briefing:
''';
  }

  /// Wellness check-in prompt
  static String wellnessCheckInPrompt({
    required String mood,
    required String sleepQuality,
    required String energyLevel,
  }) {
    return '''
Provide a thoughtful wellness check-in response.

Current state:
- Mood: $mood
- Sleep quality: $sleepQuality
- Energy level: $energyLevel

Guidelines:
- Be empathetic and supportive
- Offer specific, actionable suggestions
- Don't be preachy or judgmental
- Consider the whole picture
- Keep it caring and genuine

Provide the check-in response:
''';
  }
}
