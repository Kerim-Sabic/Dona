# Privacy & Safety Design

## Overview

Dona AI prioritizes user privacy and data safety. All personal data is stored locally on the user's device with full user control over export and deletion.

## Data Storage

### What We Store

#### 1. Memory & Learning Data
- **Memories**: Facts and information learned about the user
  - Storage: SQLite database (`memories` table)
  - Categories: fact, preference, routine, relationship, goal, habit, event
  - Includes: key-value pairs, importance scores, timestamps

- **Preferences**: Learned user preferences
  - Storage: SQLite database (`preferences` table)
  - Types: food, communication, scheduling, notification, workspace, study style, exercise, sleep, music, weather
  - Includes: confidence scores, occurrence counts

- **Routines**: Detected patterns and habits
  - Storage: SQLite database (`routines` table)
  - Types: daily, weekly, monthly, location-based
  - Includes: patterns, time of day, day of week

#### 2. Student Data
- **Courses**: Registered courses and course materials
- **Exams**: Scheduled exams and test dates
- **Assignments**: Projects and homework with due dates
- **Flashcards**: Study flashcard decks
- **Study Sessions**: Focus session history

#### 3. Productivity Data
- **Tasks**: Google Tasks integration
- **Calendar Events**: Google Calendar integration
- **Queued Actions**: Offline actions pending execution
- **Focus Sessions**: Pomodoro and study session logs

#### 4. Communication Data (Temporary)
- **Conversation History**: Recent chat messages (session-only)
- **AI Interactions**: Prompts and responses (not persisted beyond session)

### What We DON'T Store

- Passwords or authentication credentials (OAuth tokens only, in secure storage)
- Full email content
- SMS message content (only metadata for queued actions)
- Location history (only current location for context, not persisted)
- Biometric data
- Payment information

## Data Location

### Local Storage
All data is stored **locally on the user's device**:
- SQLite database: `lib/services/storage/database/`
- Shared Preferences: App settings and configuration
- Secure Storage: OAuth tokens and sensitive credentials

### No Cloud Backup
Dona does **NOT** automatically sync or backup data to the cloud.

### External API Calls
- Google APIs (Calendar, Gmail, Tasks, Drive): Only when user explicitly triggers actions
- DeepSeek AI: Only for chat/AI features, no data retention on their end
- Weather API: Anonymous location-based requests
- News API: Anonymous requests
- Twilio: Only for SMS/calls initiated by user

## Privacy Controls

### User Rights

Users have full control over their data through the Privacy Settings screen (`/settings/privacy`):

1. **View**: See exactly what data is stored and how much
2. **Export**: Download all data as JSON
3. **Delete by Category**: Clear specific data types
4. **Reset Everything**: Nuclear option to delete all data

### Data Categories

Each category can be managed independently:

| Category | Export | Clear | Description |
|----------|--------|-------|-------------|
| Memory & Learning | ✅ | ✅ | Memories, preferences, routines |
| Student Data | ✅ | ✅ | Courses, exams, assignments |
| Productivity Data | ✅ | ✅ | Tasks, queued actions |

### Export Format

All exports are JSON with the following structure:
```json
{
  "memories": [...],
  "preferences": [...],
  "routines": [...],
  "exported_at": "2025-01-15T10:30:00Z"
}
```

## Safety Measures

### 1. Logging Safety

The `AppLogger` automatically sanitizes logs to prevent PII leakage:

```dart
- Emails: user@example.com → [EMAIL]
- Phone numbers: 555-123-4567 → [PHONE]
- API keys/tokens: abc123xyz789... → [TOKEN]
```

**Debug Mode**: Full logs with sensitive data (for development)
**Production Mode**: Sanitized logs only

### 2. Secure Storage

Sensitive data uses Flutter Secure Storage:
- OAuth tokens
- API keys
- User credentials

### 3. No External Transmission

Unless explicitly requested by the user:
- No analytics tracking
- No crash reporting with PII
- No telemetry data

### 4. Confirmation Dialogs

All destructive actions require explicit confirmation:
- Clear data category
- Reset all data
- Delete courses/exams/assignments

### 5. Offline-First Architecture

The Action Queue ensures:
- No automatic background uploads
- User approval before executing queued actions
- Transparent sync status

## Data Retention

### Automatic Cleanup

Memory decay algorithm ensures old, irrelevant data is automatically pruned:
- Formula: `importance * (0.95^days) * accessBonus`
- Relevance threshold: 0.1
- Garbage collection removes memories below threshold

### Manual Cleanup

Users can clear data at any time through Privacy Settings.

## Third-Party Services

### Google APIs
- **Authentication**: OAuth 2.0 (tokens stored locally)
- **Calendar**: Read/write events (user-initiated)
- **Gmail**: Read/send emails (user-initiated)
- **Tasks**: Read/write tasks (user-initiated)
- **Drive**: Upload/download files (user-initiated)

### DeepSeek AI
- **Usage**: Chat and AI features only
- **Data Sent**: User prompts and context
- **Data Retention**: Per DeepSeek's privacy policy (no long-term storage)
- **Opt-Out**: Disable AI features in settings

### Weather API
- **Usage**: Weather information
- **Data Sent**: Anonymous location (lat/lng)
- **No PII**: No user identification

### News API
- **Usage**: News headlines
- **Data Sent**: None (public API)
- **No PII**: Completely anonymous

### Twilio
- **Usage**: SMS and voice calls
- **Data Sent**: Phone numbers, message content (user-initiated)
- **Data Retention**: Per Twilio's policy
- **User Control**: Explicit approval for each action

## Future Enhancements

### Planned Privacy Features

1. **End-to-End Encryption**: Encrypt local database with user password
2. **Selective Sync**: Optional cloud backup with encryption
3. **Privacy Audit Log**: Track all data access and modifications
4. **GDPR Compliance**: Full data portability and right to erasure
5. **Anonymous Mode**: Operate without learning/storing preferences

## Compliance

### Current Status
- Local-only storage (GDPR-friendly)
- User control over data (GDPR Article 17: Right to erasure)
- Data portability (GDPR Article 20: Export functionality)

### Regulatory Considerations
- Not currently collecting data for commercial purposes
- No advertising or tracking
- No data sharing with third parties (except user-initiated API calls)

## Security Best Practices

1. **Never Log Sensitive Data**: Emails, passwords, tokens sanitized
2. **Secure Storage**: OAuth tokens in encrypted storage
3. **HTTPS Only**: All API calls over secure connections
4. **Input Validation**: Sanitize all user inputs
5. **Confirmation Dialogs**: Prevent accidental data loss

## User Communication

### Privacy Policy (To Be Created)
Will include:
- What data we collect
- How it's used
- How it's stored
- User rights
- Contact information

### In-App Transparency
- Privacy Settings screen shows exact data counts
- Clear explanations for each data category
- Export functionality for full transparency

## Contact & Support

For privacy concerns or data deletion requests:
- In-app: Settings → Privacy & Data → Contact Support
- Email: [To be determined]

---

**Last Updated**: 2025-01-15
**Version**: 1.0
**Status**: Active
