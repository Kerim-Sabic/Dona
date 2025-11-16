# Dona Pro - Features & Architecture

## Overview

Dona Pro is an AI-powered life assistant that helps users plan their day, manage tasks, stay focused, and maintain relationships through intelligent autopilots and context-aware recommendations.

## Phase 5: Beta Launch & Real-World Pilot Readiness

### Onboarding Flow

**Welcome → Profile Selection → Persona Selection**

1. **Welcome Screen**
   - Value propositions: "Plan Your Day & Week", "Run Autopilots That Execute", "Founder & Student Modes"
   - Sets user expectations for what Dona can do

2. **Profile Selection**
   - Student: Focus on Study Coach persona, exam tracking, assignment management
   - Founder/CEO: Focus on Weekly Reviews, Focus Mode, strategic planning
   - Professional: Focus on Email/Task Triage, productivity optimization
   - Mixed: Flexible mode combining multiple personas

3. **Persona Selection**
   - Context-aware recommendations based on selected profile
   - Student → Study Coach, Default Dona
   - Founder → Founder/CEO, Professional  
   - Professional → Professional, Default Dona
   - Stored via `UserModelService` and `PersonaManager`

**Storage**: `OnboardingService` tracks completion state in local storage. Skip onboarding if `onboarding_completed` flag is true.

### Demo Mode

**Purpose**: Generate realistic sample data for showcases, screenshots, and presentations without using real user data.

**Features**:
- **Enter Demo Mode**: Generates 13 autopilot history entries spanning 7 days
- **Demo Data Marking**: All entries tagged with `metadata: {'demo': true, 'generated_at': timestamp}`
- **Exit Demo Mode**: Clears all demo data, preserves real user data
- **UI Indicator**: Amber banner in Settings when demo mode active

**Generated Data Types**:
- Autopilot history (Plan My Day, Study, Weekly Review, Focus Mode, Triage, Relationships)
- Placeholder support for tasks, courses, calendar events (to be implemented)

**Implementation**: `DemoDataService` singleton with `enterDemoMode()` and `exitDemoMode()` methods.

### In-App Feedback System

**Feedback Types**:
- Bug Report
- Feature Request
- General Feedback

**Privacy-Safe Snapshots**:
Collected data (NO personal content):
- App version, build number
- OS type and version
- App mode (Free/Premium/Trial)
- High-level usage stats (total autopilots run, success rate, types used)
- Last 30 log entries with PII stripped

**PII Sanitization**:
- Emails → `[EMAIL_REDACTED]`
- Phone numbers → `[PHONE_REDACTED]`
- Names → `[NAME_REDACTED]`
- API keys/tokens (32+ chars) → `[TOKEN_REDACTED]`
- File paths → `/Users/[USER]/...`

**Submission**: Copy to clipboard or email (via `FeedbackService.createFeedbackSnapshot()`)

### Command Palette

**Access**: Floating action button in Command Center (center-bottom) or `Cmd/Ctrl+K`

**Features**:
- Fuzzy search over all commands, autopilots, navigation actions
- 150ms debounced search for performance
- Keyboard shortcuts (↑↓ navigate, ↵ select, ESC close)
- Category grouping

**Performance**: Uses `ListView.builder` for efficiency, debounced search to avoid excessive filtering.

### End-to-End Flows

#### Student Profile Flow
1. **Onboarding**: Select "Student" → Choose "Study Coach" persona
2. **Add Course**: CS 101, Midterm on Nov 25
3. **Run Study Autopilot**: Generate study plan for midterm
4. **Check History**: View autopilot execution in Autopilot History screen
5. **Daily Use**: Plan My Day autopilot each morning (Free tier: 1/day)

#### Founder Profile Flow
1. **Onboarding**: Select "Founder/CEO" → Choose "Founder/CEO" persona
2. **Weekly Review**: Sunday evening review past week, plan upcoming week
3. **Focus Mode**: 2-hour deep work session with Pomodoro breaks (Premium)
4. **Triage**: Organize inbox and tasks (Premium)
5. **Relationship Maintenance**: Schedule check-ins with key contacts (Premium)

#### Busy Inbox Flow
1. **Morning**: Plan My Day autopilot
2. **Midday**: Triage autopilot to organize 23 tasks and 15 emails
3. **Afternoon**: Focus Mode for strategic planning
4. **Evening**: Check Autopilot History to review completed actions

### Performance Architecture

**Caching Strategy**:
- `ContextEngine`: Caches today's context to avoid redundant computation
- `AutopilotHistoryService`: Caps at 100 entries, auto-trims on new additions
- `CommandRegistry`: Pre-computes command list, lazy-loads heavy data

**List Performance**:
- All lists use `ListView.builder` for lazy loading
- History screen: Filters in-memory (max 100 entries)
- Command Palette: Debounced search (150ms)

**Async Operations**:
- `ActionQueue.processAll()`: Runs in background, not on UI thread
- `_loadCommandCenter()`: Parallel loading of context and priorities
- Autopilot generation: Shows loading dialog, doesn't block navigation

**Memory Management**:
- Log buffer: Max 100 entries (ring buffer)
- History: Max 100 entries (auto-trim)
- Usage tracker: Auto-cleans entries older than 7 days

### Free vs Premium Behavior

**Free Tier** (Client-side gating):
- Plan My Day: 1/day
- Study Autopilot: 2/day
- Total autopilots: 3/day
- AI requests: 50/day
- Weekly Review, Focus Mode, Triage, Relationship: Locked
- Autopilot History: Locked

**Premium Tier**:
- Plan My Day: Unlimited
- Study Autopilot: Unlimited
- All premium autopilots: Unlimited
- Total autopilots: 50/day
- AI requests: 1000/day
- Full Autopilot History access

**Premium Trial**:
- Reduced limits (10 autopilots/day, 200 AI requests/day)
- All features unlocked

**Enforcement**: `FeatureTiers.isFeatureAvailable()` checked before execution, `FeatureUsageTracker.recordUsage()` called after success, `UpgradeDialog` shown when limits hit.

### Security & Privacy

**No Raw Content Stored**:
- Autopilot history: Stores plan summary, action count, status only
- Feedback snapshots: NO email content, messages, or personal text
- Logs: PII automatically sanitized in production mode

**Local-First**:
- All data stored locally (SharedPreferences, local database)
- No cloud sync (yet)
- User has full control via Privacy & Data settings

**Guardrails**:
- Reset All Data: Requires typing "DELETE" to confirm
- Demo Mode: Clear warnings about data generation/cleanup
- Feature gating: Friendly upgrade prompts, never spammy

See also: [PRIVACY_AND_SAFETY_DESIGN.md](PRIVACY_AND_SAFETY_DESIGN.md)

## Testing

See: [BETA_TESTING_GUIDE.md](BETA_TESTING_GUIDE.md) for beta testing instructions.

Unit tests cover:
- Feature tier gating and usage limits
- PII sanitization patterns  
- Demo data generation behavior
- Command Palette performance

Widget tests (to be expanded):
- Onboarding flow navigation
- Autopilot History filtering
- Command Center autopilot buttons
- Feedback screen interactions

Run tests:
```bash
flutter test
```

## Architecture Highlights

**Singleton Services**: `DemoDataService`, `OnboardingService`, `FeedbackService`, `AutopilotHistoryService`, `ContextEngine`, `FeatureUsageTracker`

**State Management**: Flutter StatefulWidget with `setState()` for UI, services maintain internal state

**Navigation**: Named routes + MaterialPageRoute for modals

**Performance**: Lazy loading (builders), caching (context, history), debouncing (search), caps (history, logs)

## Future Enhancements

- Billing integration (currently client-side mode switching only)
- Cloud sync for cross-device access
- Real-time collaboration features
- Advanced analytics dashboards
- ML-based personalization
