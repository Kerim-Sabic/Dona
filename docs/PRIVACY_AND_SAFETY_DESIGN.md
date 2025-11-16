# Dona Pro - Privacy & Safety Design

## Core Privacy Principles

1. **Local-First**: All data stored locally on user's device
2. **User Control**: Full transparency and control over stored data
3. **Minimal Collection**: Collect only what's necessary for functionality
4. **No Surveillance**: No tracking, analytics, or telemetry without consent
5. **Clear Communication**: Explicit about what's collected and why

## Data Storage

### What We Store

**Memory & Learning**:
- User preferences (e.g., "prefers morning meetings")
- Learned routines (e.g., "works best 9am-11am")
- Facts about user (e.g., "enrolled in CS 101")
- **Storage**: Local database, `MemoryEngine`

**Student Data**:
- Courses, exams, assignments (user-entered)
- Due dates, grades (optional)
- **Storage**: Local database, managers (`CourseManager`, `ExamManager`, `AssignmentManager`)

**Autopilot History**:
- Autopilot type (e.g., "Plan My Day", "Weekly Review")
- Execution summary (e.g., "Planned day with 5 focus blocks")
- Action counts (total vs executed)
- Status (success, partial, failed, cancelled)
- Timestamp
- **NO raw email content, message text, or personal details**
- **Storage**: Local JSON via `AutopilotHistoryService` (max 100 entries)

**Usage Statistics**:
- Daily feature usage counts (for limit enforcement)
- App mode (Free/Premium/Trial)
- **Storage**: In-memory with 7-day cleanup, `FeatureUsageTracker`

**Logs**:
- App events (info, warnings, errors)
- Sanitized in production (no PII)
- **Storage**: Ring buffer (max 100 entries), `AppLogger`

### What We DON'T Store

- ❌ Raw email content or message bodies
- ❌ Full calendar event details (only metadata like "meeting at 2pm")
- ❌ Passwords or API keys (OAuth tokens stored securely by OS)
- ❌ Location history (current location used transiently for context)
- ❌ Browsing history
- ❌ Contacts' personal information (only names/dates for reminders)

## Feedback Snapshots

### What's Included

When users submit feedback via the in-app Feedback & Support screen:

**App Environment**:
- App name: "Dona Pro"
- Version: e.g., "1.0.0"
- Build number: e.g., "42"

**Platform Info**:
- OS: "android", "ios", "macos", "windows", "linux"
- OS version: e.g., "iOS 17.1", "Android 13"
- Locale: e.g., "en_US"

**App State**:
- Current mode: "free", "premiumTrial", "premium"

**Usage Statistics** (High-level, non-identifying):
- Total autopilots run: e.g., 127
- Successful executions: e.g., 115
- Failed executions: e.g., 5
- Partial executions: e.g., 7
- Success rate: e.g., "90.5%"
- Autopilot types used: e.g., `{"plan_my_day": 45, "study_autopilot": 30, ...}`

**Sanitized Logs** (Last 30 entries):
- Timestamp (ISO 8601)
- Log level (debug, info, warning, error)
- Message with PII stripped (see Sanitization below)
- **NO stack traces** (excluded for privacy)

### What's NOT Included

- ❌ Raw email content
- ❌ Message bodies from any service
- ❌ Personal names (sanitized to `[NAME_REDACTED]`)
- ❌ Email addresses (sanitized to `[EMAIL_REDACTED]`)
- ❌ Phone numbers (sanitized to `[PHONE_REDACTED]`)
- ❌ API keys/tokens (sanitized to `[TOKEN_REDACTED]`)
- ❌ File paths with usernames (sanitized to `/Users/[USER]/...`)
- ❌ AI prompts or responses containing personal info
- ❌ Full memory database contents

### PII Sanitization

**Regex Patterns Applied**:
```dart
// Emails
r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b' → '[EMAIL_REDACTED]'

// Phone numbers
r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b' → '[PHONE_REDACTED]'

// Names (capitalized words in pairs)
r'\b([A-Z][a-z]+ [A-Z][a-z]+)\b' → '[NAME_REDACTED]'

// Long tokens/API keys (32+ alphanumeric)
r'\b[A-Za-z0-9]{32,}\b' → '[TOKEN_REDACTED]'

// macOS paths
r'/Users/[^/\s]+' → '/Users/[USER]'

// Windows paths
r'C:\\Users\\[^\\\s]+' → 'C:\\Users\\[USER]'
```

**Example Sanitization**:
```
Before: "Contact John Smith at john@example.com or 123-456-7890"
After:  "Contact [NAME_REDACTED] at [EMAIL_REDACTED] or [PHONE_REDACTED]"
```

## Demo Mode

### Purpose

Generate realistic sample data for:
- App screenshots
- Product demos
- Investor presentations
- Beta testing onboarding

### How It Works

**Enter Demo Mode**:
1. User navigates to Settings → Demo & Testing → Enter Demo Mode
2. Confirmation dialog explains demo data will be generated
3. `DemoDataService.enterDemoMode()` called
4. Generates 13 autopilot history entries spanning 7 days
5. All entries tagged with `metadata: {'demo': true, 'generated_at': timestamp}`
6. Demo mode flag set to true in local storage

**Demo Data Characteristics**:
- **Realistic**: Varied autopilot types, different statuses (success, partial, cancelled)
- **Clearly Marked**: `metadata['demo'] == true` on all generated entries
- **Isolated**: Real user data unaffected (unless user manually created data before demo mode)
- **Reversible**: Exit demo mode removes all demo-tagged entries

**Exit Demo Mode**:
1. User clicks "Exit Demo Mode" in Settings
2. Confirmation dialog warns demo data will be deleted
3. `DemoDataService.exitDemoMode()` called
4. Clears all autopilot history (currently clears ALL - future: filter by demo tag)
5. Demo mode flag set to false

**Privacy Guarantee**: Demo data is local-only and never transmitted. It contains no real user information.

### Demo Data Inventory

**Currently Generated**:
- Autopilot history entries (13 entries across 7 days)

**Placeholders** (for future implementation):
- Tasks (student assignments, founder to-dos)
- Courses (CS 101, MATH 201, BUS 301)
- Calendar events (meetings, study sessions)

## Autopilot History & Analytics

### What's Tracked

**Per Autopilot Execution**:
- `id`: Unique identifier
- `timestamp`: When executed
- `type`: Autopilot type enum (planMyDay, studyAutopilot, weeklyReview, etc.)
- `summary`: User-facing summary (e.g., "Planned day with 5 focus blocks")
- `totalActions`: Number of actions in plan
- `executedActions`: How many succeeded
- `status`: success | partial | failed | cancelled
- `errorMessage`: Optional high-level error (NOT raw exceptions)
- `createdItemIds`: Optional list of IDs for tasks/events created
- `metadata`: Optional key-value pairs (e.g., `{'demo': true}`)

### What's NOT Tracked

- ❌ Full action descriptions (only counts)
- ❌ Raw AI prompts or responses
- ❌ Email/message content referenced in actions
- ❌ Personal details from context (only high-level summaries)

**Example Entry**:
```json
{
  "id": "uuid-1234",
  "timestamp": "2025-11-16T14:30:00Z",
  "type": "planMyDay",
  "summary": "Planned day with 5 focus blocks and break reminders",
  "totalActions": 7,
  "executedActions": 7,
  "status": "success",
  "errorMessage": null,
  "createdItemIds": ["task-1", "task-2", "event-1"],
  "metadata": {}
}
```

### Statistics

**Aggregated Stats** (No PII):
- Total executions
- Success count, failed count, partial count
- Success rate (percentage)
- Most-used autopilot types

**Used For**:
- User's personal progress tracking
- Feedback snapshots (high-level counts only)
- In-app analytics (local only, not transmitted)

## User Data Control

### Export Data

Users can export their data from Privacy & Data settings:

**Memory & Learning Export**:
- Memories, preferences, routines → JSON format
- Copied to clipboard (user pastes into file/document)

**Student Data Export**:
- Courses, exams, assignments → JSON format

**Productivity Data Export**:
- Queued offline actions → JSON format

**Format**: Pretty-printed JSON with `exported_at` timestamp

### Clear Data

Users can selectively clear data:

**Clear Memory Data**:
- Confirmation dialog: "Dona will forget everything she learned about you"
- Deletes all memories, preferences, routines

**Clear Student Data**:
- Confirmation dialog: "This will delete all courses, exams, and assignments"
- Removes all student-specific data

**Clear Productivity Data**:
- Confirmation dialog: "This will delete all queued offline actions"
- Clears action queue

**Reset All Data** (DANGER ZONE):
- Requires typing "DELETE" to confirm
- Deletes EVERYTHING:
  - All memories and learned preferences
  - All student data
  - All productivity data
  - All autopilot history
  - All settings
- **Cannot be undone**

### Data Retention

- **Local Storage**: Indefinite until user deletes or resets
- **Logs**: Rolling buffer (max 100 entries, oldest removed first)
- **Autopilot History**: Max 100 entries (oldest removed first)
- **Usage Stats**: 7-day rolling window (auto-cleanup)

## Safety Guardrails

### Dangerous Operations

**Reset All Data**:
- Red "Danger Zone" card
- Clear warning text
- Requires typing "DELETE" (case-insensitive)
- Button disabled until correct text entered

**Demo Mode Entry**:
- Orange warning icon
- Explains demo data generation
- Confirms user wants sample data

**Demo Mode Exit**:
- Red warning icon
- Explains demo data will be deleted
- Confirms real data will remain intact

### Feature Gating

**Upgrade Prompts**:
- Show lock icon on premium features
- Clear benefit explanation (1-2 bullet points)
- "Upgrade Now" or "Maybe Later" options
- **Never spam**: Only shown when user attempts locked feature
- Friendly copy: "Upgrade to unlock..." not "You can't access..."

### Confirmation Dialogs

**Pattern**:
1. Clear title with icon (⚠️ for warnings, 🔒 for locks, ℹ️ for info)
2. Explanation of what will happen
3. "Cancel" (always available)
4. "Confirm" (red for danger, blue for safe actions)

**No Dark Patterns**:
- Cancel is never hidden
- Destructive actions use red color
- Text is never misleading
- Users can always back out

## Compliance Notes

**GDPR**: User has full control over their data (export, delete)

**CCPA**: Transparent data collection, user can request deletion

**Children**: Not designed for users under 13

**Third-Party Services**:
- Google Calendar: OAuth, no data stored on our servers
- Google Tasks: OAuth, no data stored on our servers
- Future integrations: Same principle (OAuth, minimal storage)

## Future Privacy Enhancements

- [ ] End-to-end encryption for cloud sync (when implemented)
- [ ] Differential privacy for aggregated analytics
- [ ] Zero-knowledge architecture exploration
- [ ] User-controlled data retention periods
- [ ] Automated PII detection and masking
- [ ] Privacy-preserving federated learning
