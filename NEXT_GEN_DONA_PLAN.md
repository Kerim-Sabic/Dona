# Next-Gen Dona: Personal OS Upgrade Plan

**Project:** Dona AI Assistant → Dona Personal OS
**Version:** 1.0.0 → 2.0.0
**Date:** 2025-11-16
**Status:** Planning & Implementation

---

## 🎯 Vision

Transform Dona from a capable personal assistant into a **world-class Personal OS** - Donna Paulsen from Suits, but **100000000000x better**. The goal is to create an AI-powered life orchestrator that:

- **Knows your life** through deep context and memory
- **Anticipates your needs** with proactive intelligence
- **Executes automatically** with intelligent autopilot
- **Delights with UX** that feels like magic
- **Works everywhere** with bulletproof offline support
- **Protects privacy** with encryption and safety rails

---

## 📋 Current State Assessment

### ✅ Strong Foundation (Grade: A-)

**Architecture:**
- Clean Architecture + BLoC/Provider
- 80 Dart files, ~27,000 LOC
- 46 services across 30 domains
- Triple storage (SharedPreferences, SQLite, Hive)
- 8 verified API integrations

**Current Capabilities:**
- ✅ AI conversation (DeepSeek LLM)
- ✅ Voice assistant (speech-to-text/TTS)
- ✅ 11-service student academic suite
- ✅ Productivity tools (focus, habits, analytics)
- ✅ Google ecosystem (Calendar, Gmail, Drive, Tasks, Maps)
- ✅ Communication (Twilio SMS/calls)
- ✅ Information (news, weather, briefing)
- ✅ Gamification & wellness
- ✅ Offline-first architecture
- ✅ Secure API configuration
- ✅ 7 null safety bugs fixed

**Recent Audit Results:**
- Security: A
- Null Safety: A
- API Integration: A
- Error Handling: A
- Code Quality: A-
- Production Ready: ✅

---

## 🚨 Current Limitations (Gaps for "Personal OS")

### 1. **No Unified Brain**
- Personality is scattered across services
- No centralized memory system
- Limited context awareness
- Prompts hardcoded in multiple places
- Can't learn from user behavior

### 2. **Reactive, Not Proactive**
- User must initiate most actions
- Limited anticipatory intelligence
- No autopilot execution framework
- Suggestions exist but aren't actionable

### 3. **Fragmented UX**
- No central "command center" dashboard
- Separate screens for each feature
- No global command palette
- Conversation UI is basic
- No contextual quick actions

### 4. **Single AI Model**
- Locked to DeepSeek only
- No free vs premium tiers
- Can't route tasks to optimal models
- No fallback providers

### 5. **Offline/Online Gaps**
- Works offline but sync is basic
- No action queue for pending operations
- No clear offline indicators
- Limited conflict resolution

### 6. **Privacy & Safety Needs**
- No encryption at rest
- Limited data export
- No safety rails for sensitive actions
- Missing privacy dashboard

### 7. **Limited Observability**
- Basic logging only
- No usage analytics
- No feature adoption tracking
- Limited diagnostics

### 8. **Testing Coverage**
- No comprehensive test suite
- No integration tests
- No widget tests
- No CI/CD

---

## 🗺️ Donna from Suits → Dona Personal OS Mapping

| Donna's Capability | Current Dona | Next-Gen Dona |
|-------------------|--------------|---------------|
| **Knows everything about Harvey** | ❌ No persistent memory | ✅ Long-term memory & user model |
| **Anticipates needs before asking** | ⚠️ Limited proactive | ✅ Context engine + autopilot |
| **Executes complex tasks autonomously** | ❌ No autopilot | ✅ Autopilot framework |
| **Manages relationships** | ✅ Basic tracking | ✅ Deep relationship intelligence |
| **Handles scheduling conflicts** | ⚠️ Basic calendar | ✅ Smart conflict resolution |
| **Witty, professional personality** | ✅ Personality service | ✅ Configurable personas |
| **Manages communication** | ✅ Email/SMS | ✅ + Autopilot drafting & sending |
| **Orders food, books, arrangements** | ❌ Not implemented | ✅ Abstract service layer |
| **Remembers preferences** | ⚠️ Limited | ✅ Comprehensive preferences |
| **Works seamlessly** | ⚠️ Good UX | ✅ World-class UX |

---

## 🏗️ Phased Upgrade Plan

## **Phase 1: Core Brain System** 🧠

**Objective:** Build the intelligent foundation that makes Dona "think"

### 1.1 Persona & Conversation Brain
**New Modules:**
- `lib/assistant/persona_manager.dart`
- `lib/assistant/persona_profiles.dart`
- `lib/assistant/prompts.dart`
- `lib/assistant/assistant_brain.dart`

**Implementation:**
```dart
// Centralized persona system
class PersonaProfile {
  String id;
  String name;
  String systemPrompt;
  double witLevel;      // 0.0 - 1.0
  double formalityLevel;
  Map<String, dynamic> conversationStyle;
}

class PersonaManager {
  PersonaProfile defaultDona;
  PersonaProfile professionalMode;
  PersonaProfile studyCoach;
  PersonaProfile lifeAdvisor;

  PersonaProfile getCurrentPersona();
  void switchPersona(String personaId);
}

class AssistantBrain {
  Future<String> generateReply({
    required String userMessage,
    required ConversationContext context,
    PersonaProfile? persona,
  });
}
```

**Files to Modify:**
- `lib/services/ai/ai_service.dart` - Use AssistantBrain
- `lib/services/personality/donna_personality.dart` - Migrate to PersonaManager
- `lib/services/proactive/proactive_assistant.dart` - Integrate AssistantBrain

**Risk Mitigation:**
- Keep existing AI service as fallback
- Gradual migration of prompts
- A/B test persona responses

---

### 1.2 Long-Term Memory & User Model
**New Modules:**
- `lib/assistant/memory/memory_engine.dart`
- `lib/assistant/memory/user_model.dart`
- `lib/assistant/memory/memory_store.dart`
- `lib/data/models/memory/` (fact, preference, routine, relationship)

**Implementation:**
```dart
class UserModel {
  UserProfile profile;          // Name, timezone, language
  UserPreferences preferences;  // Food, sleep, notifications
  UserRoutines routines;        // Wake/sleep, locations, patterns
  RelationshipGraph relationships;
}

class MemoryEngine {
  Future<void> rememberFact({
    required String key,
    required dynamic value,
    required double importance,  // 0.0 - 1.0
    required String source,
    String? category,
  });

  Future<List<Memory>> queryMemories({
    DateTimeRange? timeRange,
    String? category,
    double? minImportance,
    int limit = 10,
  });

  Future<void> learnFromAction({
    required String actionType,
    required bool userAccepted,
    Map<String, dynamic>? metadata,
  });
}

class MemoryStore {
  // SQLite for structured memories
  // Importance scoring and decay over time
}
```

**Database Schema:**
```sql
CREATE TABLE memories (
  id TEXT PRIMARY KEY,
  category TEXT,
  key TEXT,
  value TEXT,
  importance REAL,
  source TEXT,
  created_at INTEGER,
  last_accessed INTEGER,
  access_count INTEGER
);

CREATE TABLE user_preferences (
  id TEXT PRIMARY KEY,
  preference_type TEXT,
  preference_value TEXT,
  confidence REAL,
  learned_from TEXT,
  updated_at INTEGER
);

CREATE TABLE routines (
  id TEXT PRIMARY KEY,
  routine_type TEXT,
  pattern TEXT,
  frequency TEXT,
  last_occurrence INTEGER
);
```

**Files to Modify:**
- `lib/services/storage/local_storage_service.dart` - Add memory database
- `lib/services/relationships/relationship_manager.dart` - Integrate with memory
- `lib/services/habits/habit_tracker.dart` - Feed into routine learning

**Risk Mitigation:**
- Start with small memory footprint
- Implement memory pruning/archival
- Allow user to view/edit memories

---

### 1.3 Context Engine
**New Modules:**
- `lib/assistant/context/context_engine.dart`
- `lib/assistant/context/context_aggregator.dart`
- `lib/assistant/context/context_models.dart`

**Implementation:**
```dart
class LifeContext {
  DateTime timestamp;

  // Time context
  TimeOfDay timeOfDay;
  DayOfWeek dayOfWeek;
  bool isWeekend;
  bool isHoliday;

  // Calendar context
  List<CalendarEvent> todayEvents;
  CalendarEvent? currentEvent;
  CalendarEvent? nextEvent;
  List<CalendarEvent> thisWeekEvents;

  // Task context
  List<Task> dueTasks;
  List<Task> overdneTasks;
  int pendingTaskCount;

  // Location context
  String? currentLocation;
  bool isAtHome;
  bool isAtWork;
  String? estimatedLocation;

  // Communication context
  int unreadEmails;
  List<EmailSummary> importantEmails;
  int unreadMessages;

  // Work/Study context
  FocusSession? activeFocusSession;
  List<Exam> upcomingExams;
  List<Assignment> dueAssignments;

  // Wellness context
  double todayActivityLevel;
  int hoursSlept;
  String moodToday;

  // Weather context
  WeatherData currentWeather;
  WeatherData forecastToday;
}

class ContextEngine {
  Future<LifeContext> getTodayContext();
  Future<LifeContext> getThisWeekContext();
  Future<LifeContext> getImportantNowContext();
  Future<LifeContext> getContextForTime(DateTime time);

  Stream<LifeContext> contextStream(); // Real-time updates
}
```

**Files to Integrate:**
- ✅ `lib/services/calendar/calendar_service.dart`
- ✅ `lib/services/gmail/gmail_service.dart`
- ✅ `lib/services/google_tasks/google_tasks_service.dart`
- ✅ `lib/services/weather/weather_service.dart`
- ✅ `lib/services/focus/focus_mode_service.dart`
- ✅ `lib/services/student/*` (all student services)
- ✅ `lib/services/wellness/wellness_manager.dart`
- ✅ `lib/services/google_maps/google_maps_service.dart`

**Risk Mitigation:**
- Lazy loading of context data
- Cache context for performance
- Graceful degradation if services unavailable

---

## **Phase 2: Life OS & Autopilot** 🚀

**Objective:** Enable Dona to orchestrate and execute complex life tasks

### 2.1 Command Center / "Today" Screen
**New Files:**
- `lib/presentation/screens/command_center/command_center_screen.dart`
- `lib/presentation/widgets/command_center/priority_card.dart`
- `lib/presentation/widgets/command_center/dona_recommends.dart`
- `lib/presentation/widgets/command_center/quick_actions_grid.dart`
- `lib/presentation/widgets/command_center/focus_timer_widget.dart`

**Features:**
```
┌─────────────────────────────────────────┐
│  Command Center - Saturday, Nov 16     │
├─────────────────────────────────────────┤
│  ☀️ Morning Briefing                    │
│  • Top 3 priorities for today          │
│  • 4 meetings, next at 2:00 PM        │
│  • Weather: 22°C, Partly cloudy        │
│  • 3 important emails                  │
├─────────────────────────────────────────┤
│  🎯 Dona Recommends                     │
│  • Start focus session for Project X   │
│  • Review flashcards (15 due)          │
│  • Call Mom (haven't talked in 5 days) │
│  • Prepare for Monday's exam          │
├─────────────────────────────────────────┤
│  ⚡ Quick Actions                       │
│  [Ask Dona] [Focus] [Add Task] [Note] │
│  [Call...] [Message...] [Schedule]    │
├─────────────────────────────────────────┤
│  ⏱️ Active Focus Session                │
│  Deep Work • 23:45 remaining           │
│  [Pause] [End]                         │
└─────────────────────────────────────────┘
```

**Implementation:**
- Use `ContextEngine` for real-time data
- Integrate with `MemoryEngine` for recommendations
- Beautiful cards with smooth animations
- Pull-to-refresh for latest context

**Files to Modify:**
- `lib/app.dart` - Add route
- `lib/presentation/screens/home/home_screen.dart` - Link to Command Center

---

### 2.2 Autopilot Framework
**New Modules:**
- `lib/assistant/autopilot/autopilot_engine.dart`
- `lib/assistant/autopilot/autopilot_action.dart`
- `lib/assistant/autopilot/autopilot_executor.dart`
- `lib/assistant/autopilot/action_registry.dart`
- `lib/data/models/autopilot/` (action, execution_plan, result)

**Implementation:**
```dart
class AutopilotAction {
  String id;
  String intent;              // "Book dentist appointment"
  AutopilotActionType type;   // schedule, communicate, order, etc.
  Map<String, dynamic> parameters;
  List<String> requiredServices;
  List<String> requiredPermissions;
  AutopilotStatus status;
}

enum AutopilotStatus {
  pending,        // Waiting for approval
  approved,       // User approved
  executing,      // In progress
  completed,      // Success
  failed,         // Error occurred
  cancelled,      // User cancelled
}

class AutopilotEngine {
  Future<AutopilotAction> parseIntent(String userMessage);

  Future<ExecutionPlan> createPlan(AutopilotAction action);

  Future<void> requestApproval({
    required AutopilotAction action,
    required ExecutionPlan plan,
  });

  Future<AutopilotResult> execute(AutopilotAction action);

  Future<List<AutopilotAction>> getPendingApprovals();
  Future<List<AutopilotAction>> getRecentExecutions({int limit = 20});
}

class ExecutionPlan {
  List<AutopilotStep> steps;
  String summary;
  List<String> risks;
  bool requiresApproval;
}

class AutopilotStep {
  String description;
  String service;
  String action;
  Map<String, dynamic> parameters;
  bool isReversible;
}
```

**UI Components:**
- `lib/presentation/screens/autopilot/autopilot_approval_screen.dart`
- `lib/presentation/screens/autopilot/autopilot_history_screen.dart`
- `lib/presentation/widgets/autopilot/action_preview_card.dart`

**Preview Card Example:**
```
┌─────────────────────────────────────────┐
│  🤖 Autopilot Action                    │
├─────────────────────────────────────────┤
│  Intent: Schedule dentist appointment  │
│                                         │
│  Dona will:                            │
│  1. Search your calendar for next week │
│  2. Find a 1-hour slot on Tue/Wed     │
│  3. Create event: "Dentist - Dr. Smith"│
│  4. Send confirmation SMS             │
│                                         │
│  ⚠️  This will send an SMS              │
│                                         │
│  [✅ Approve] [✏️ Edit] [❌ Cancel]      │
└─────────────────────────────────────────┘
```

**Risk Mitigation:**
- All actions require explicit approval initially
- Simulation mode before execution
- Clear undo/rollback for reversible actions
- Detailed logging

---

### 2.3 Abstract Service Layers
**New Modules:**
- `lib/services/integrations/food_ordering_service.dart`
- `lib/services/integrations/transport_service.dart`
- `lib/services/integrations/booking_service.dart`
- `lib/services/integrations/payment_service.dart`

**Implementation:**
```dart
// Abstract interface - can be wired to real APIs later
abstract class FoodOrderingService {
  Future<List<Restaurant>> searchRestaurants({
    String? cuisine,
    String? location,
    double? maxPrice,
  });

  Future<Menu> getMenu(String restaurantId);

  Future<OrderDraft> createOrder({
    required String restaurantId,
    required List<MenuItem> items,
  });

  Future<Order> placeOrder(OrderDraft draft);

  Future<OrderStatus> getOrderStatus(String orderId);
}

// Stub implementation for now
class FoodOrderingServiceStub implements FoodOrderingService {
  // Returns mock data, doesn't make real orders
  // Clear UI indication: "Food ordering is in preview mode"
}

abstract class TransportService {
  Future<List<RideOption>> getRideOptions({
    required Location from,
    required Location to,
  });

  Future<RideDraft> createRideRequest(RideOption option);

  Future<Ride> requestRide(RideDraft draft);

  Future<RideStatus> getRideStatus(String rideId);
}

class TransportServiceStub implements TransportService {
  // Stub for future Uber/Lyft/taxi integration
}
```

**Legal Safety:**
- All stubs clearly marked as "preview"
- No hardcoded third-party brand names
- User must provide own API keys for real services
- Documentation on how to wire real services

**Files to Modify:**
- `lib/assistant/autopilot/action_registry.dart` - Register new services
- Settings screen - Add integration configuration

---

## **Phase 3: World-Class UX** ✨

**Objective:** Make using Dona feel magical

### 3.1 Enhanced Conversation Screen
**New/Modified Files:**
- `lib/presentation/screens/chat/chat_screen_v2.dart`
- `lib/presentation/widgets/chat/message_bubble.dart`
- `lib/presentation/widgets/chat/quick_reply_chips.dart`
- `lib/presentation/widgets/chat/action_card.dart`
- `lib/presentation/widgets/chat/context_pills.dart`
- `lib/presentation/widgets/chat/thinking_indicator.dart`

**Features:**
```
┌─────────────────────────────────────────┐
│  [Today] [Calendar] [Email] [Tasks] [Study]  │ ← Context pills
├─────────────────────────────────────────┤
│                                         │
│  👤 You (10:30 AM)                      │
│  What's my schedule today?             │
│                                         │
│  🤖 Dona (10:30 AM)                     │
│  You have 4 meetings today:            │
│  • 2:00 PM - Team Sync (1h)           │
│  • 3:30 PM - Client Call (30m)        │
│  • 5:00 PM - Project Review (1h)      │
│  • 7:00 PM - Dinner with Sarah        │
│                                         │
│  ┌─────────────────────────────┐       │ ← Action card
│  │ 📅 Would you like me to:    │       │
│  │ • Prepare notes for 2PM?   │       │
│  │ • Set focus time before 2PM?│       │
│  │ • Find restaurant for 7PM? │       │
│  └─────────────────────────────┘       │
│                                         │
│  [Yes, all] [Just notes] [No thanks]  │ ← Quick replies
│                                         │
│  🎤 [Hold to talk]  💬 Type message... │
└─────────────────────────────────────────┘
```

**Implementation:**
- Rich message types (text, cards, actions, images)
- Voice recording with waveform animation
- "Dona is thinking..." with elegant spinner
- Context pills filter conversation focus
- Inline action buttons
- Smooth scroll and animations

---

### 3.2 Global Command Palette
**New Files:**
- `lib/presentation/widgets/command_palette/command_palette.dart`
- `lib/presentation/widgets/command_palette/command_item.dart`
- `lib/assistant/command_registry.dart`

**Features:**
```
┌─────────────────────────────────────────┐
│  🔍 Search or type a command...        │
├─────────────────────────────────────────┤
│  Suggested:                            │
│  ⚡ Start focus session                │
│  📧 Check email                        │
│  📅 Add event to calendar              │
│  🎓 Review flashcards                 │
│                                         │
│  Recent:                               │
│  📝 Add task: "Finish report"          │
│  📞 Call Mom                           │
│  ☀️ Check weather                      │
│                                         │
│  All Actions:                          │
│  🗓️ Calendar • 📧 Email • 📝 Tasks    │
│  🎓 Study • 🎯 Focus • 📞 Calls       │
└─────────────────────────────────────────┘
```

**Access:**
- FAB button (always visible)
- Swipe down from top
- Long press home button
- Keyboard shortcut (web/desktop)

**Implementation:**
```dart
class Command {
  String id;
  String title;
  String icon;
  List<String> keywords;
  Function action;
  bool needsContext;
}

class CommandRegistry {
  List<Command> allCommands;

  List<Command> search(String query);
  List<Command> getSuggested(LifeContext context);
  List<Command> getRecent();

  Future<void> execute(Command command);
}
```

---

### 3.3 Visual Polish & Onboarding
**Theme Enhancements:**
- Consistent Material Design 3
- Smooth transitions (Hero animations)
- Subtle micro-interactions
- Dark/light theme refinement
- Custom color palettes for personas

**New Onboarding Flow:**
```
Screen 1: Welcome
  "Meet Dona, your AI personal OS"

Screen 2: What can Dona do?
  Quick feature highlights with animations

Screen 3: Choose Your Style
  [Default Dona] [Professional] [Study Coach]

Screen 4: Priorities
  [✓] Study & Academics
  [✓] Work & Productivity
  [ ] Life & Relationships
  [ ] Health & Wellness

Screen 5: Permissions
  Explain why each permission is needed
  [Allow Calendar] [Allow Notifications] [Allow Location]

Screen 6: Let's Go!
  "I'm ready to make your life easier."
```

**Files:**
- `lib/presentation/screens/onboarding/onboarding_flow.dart`
- `lib/core/theme/app_theme_v2.dart`
- `lib/presentation/widgets/animations/` (new directory)

---

## **Phase 4: AI Orchestration & Infrastructure** 🤖

### 4.1 Multi-Model AI Router
**New Modules:**
- `lib/assistant/ai_router/ai_router.dart`
- `lib/assistant/ai_router/model_provider.dart`
- `lib/assistant/ai_router/routing_policy.dart`

**Implementation:**
```dart
enum ModelProvider {
  deepseek,
  anthropic,
  openai,
  local,
}

enum TaskComplexity {
  lightweight,  // Simple queries, quick responses
  medium,       // Planning, analysis
  complex,      // Life orchestration, reasoning
}

class ModelConfig {
  ModelProvider provider;
  String modelName;
  double cost;           // Per 1K tokens
  int maxTokens;
  double latency;        // Avg response time
  List<String> capabilities;
}

class AiRouter {
  List<ModelConfig> availableModels;
  RoutingPolicy policy;

  Future<ModelConfig> selectModel({
    required TaskComplexity complexity,
    required UserTier userTier,
    String? preferredProvider,
  });

  Future<String> generate({
    required String prompt,
    required TaskComplexity complexity,
    UserTier? tier,
  });
}

enum UserTier {
  free,     // Rate limited, cheaper models
  premium,  // Full access, best models
}

class RoutingPolicy {
  ModelConfig routeTask({
    required TaskComplexity complexity,
    required UserTier tier,
    required List<ModelConfig> available,
  }) {
    if (tier == UserTier.free) {
      // Use cheaper/faster models
      if (complexity == TaskComplexity.lightweight) {
        return cheapestModel;
      }
    } else {
      // Premium: route to best model for task
      return mostCapableModel;
    }
  }
}
```

**Configuration (.env):**
```env
# DeepSeek (current)
DEEPSEEK_API_KEY=sk-...

# Optional: Anthropic Claude
ANTHROPIC_API_KEY=sk-ant-...

# Optional: OpenAI
OPENAI_API_KEY=sk-...

# Routing preferences
AI_ROUTER_DEFAULT_PROVIDER=deepseek
AI_ROUTER_FALLBACK_PROVIDER=openai
```

**Files to Modify:**
- `lib/services/ai/ai_service.dart` - Use AiRouter
- `lib/assistant/assistant_brain.dart` - Route via AiRouter
- Settings screen - Add AI provider settings

**Free vs Premium:**
```
Free Tier:
- DeepSeek only
- 50 messages/day
- Standard context length
- 1 active focus session

Premium Tier ($9.99/month):
- All AI models
- Unlimited messages
- Extended context
- Multiple focus sessions
- Priority autopilot
- Advanced analytics
```

---

### 4.2 Robust Offline/Online
**New Modules:**
- `lib/assistant/sync/action_queue.dart`
- `lib/assistant/sync/sync_manager.dart`
- `lib/presentation/screens/sync/sync_status_screen.dart`

**Implementation:**
```dart
class QueuedAction {
  String id;
  ActionType type;
  Map<String, dynamic> data;
  DateTime queuedAt;
  int retryCount;
  ActionStatus status;
}

enum ActionStatus {
  pending,
  executing,
  succeeded,
  failed,
  cancelled,
}

class ActionQueue {
  Future<void> enqueue(QueuedAction action);

  Future<void> processQueue();

  Future<List<QueuedAction>> getPending();
  Future<List<QueuedAction>> getFailed();

  Future<void> retry(String actionId);
  Future<void> cancel(String actionId);
}

class SyncManager {
  Stream<ConnectivityStatus> connectivityStream;

  Future<void> syncWhenOnline();

  Future<void> syncNow();

  Future<SyncStatus> getSyncStatus();
}
```

**UI Indicators:**
- Subtle badge on nav bar when offline
- Toast notification when back online
- Sync progress indicator
- Failed actions list with retry button

**Files to Modify:**
- `lib/services/offline/offline_manager.dart` - Integrate ActionQueue
- All API services - Enqueue on failure
- `lib/app.dart` - Add connectivity listener

---

### 4.3 Privacy & Security
**New Modules:**
- `lib/core/security/encryption_service.dart`
- `lib/core/security/data_export_service.dart`
- `lib/core/security/safety_rails.dart`
- `lib/presentation/screens/privacy/privacy_dashboard_screen.dart`

**Implementation:**
```dart
class EncryptionService {
  Future<void> encryptSensitiveData(String key, String data);
  Future<String> decryptSensitiveData(String key);

  // Encrypt Hive boxes with sensitive data
  Future<void> encryptMemories();
  Future<void> encryptRelationships();
  Future<void> encryptHealthData();
}

class DataExportService {
  Future<Map<String, dynamic>> exportAllData();

  Future<String> exportMemories({String format = 'json'});
  Future<String> exportTasks({String format = 'csv'});
  Future<String> exportStudentData({String format = 'json'});
}

class SafetyRails {
  // Prevent sending sensitive data without approval
  Future<bool> checkSensitiveAction(AutopilotAction action);

  // Require confirmation for actions involving others
  Future<bool> requiresExplicitConsent(ActionType type);

  // Redact sensitive content in logs
  String redactSensitiveInfo(String text);
}
```

**Privacy Dashboard:**
```
┌─────────────────────────────────────────┐
│  Data & Privacy                        │
├─────────────────────────────────────────┤
│  📊 Storage Overview                   │
│  • Memories: 2.3 MB                   │
│  • Tasks & Events: 1.1 MB            │
│  • Student Data: 5.7 MB              │
│  • Relationships: 0.8 MB             │
│  • Analytics: 0.4 MB                 │
│  • Total: 10.3 MB                    │
├─────────────────────────────────────────┤
│  🔒 Security                           │
│  • Encryption: [✓] Enabled           │
│  • Data at rest: Encrypted           │
│  • API keys: Environment variables   │
├─────────────────────────────────────────┤
│  📤 Export Data                        │
│  [Export All] [Export Specific]      │
├─────────────────────────────────────────┤
│  🗑️ Clear Data                         │
│  [Clear Memories] [Clear Habits]     │
│  [Clear Relationships] [Clear All]   │
└─────────────────────────────────────────┘
```

**New File:**
- `PRIVACY_AND_SAFETY_DESIGN.md`

---

## **Phase 5: Analytics, Logging & Quality** 📊

### 5.1 Privacy-Respectful Analytics
**New Modules:**
- `lib/analytics/analytics_service.dart`
- `lib/analytics/event_tracker.dart`

**Implementation:**
```dart
class AnalyticsService {
  // NO raw content, only aggregated events
  Future<void> trackFeatureUse(String featureName);

  Future<void> trackIntentCategory(String category);

  Future<void> trackSuggestionAccepted(String suggestionType);

  Future<void> trackAutopilotAction({
    required String actionType,
    required bool accepted,
  });

  Future<Map<String, int>> getFeatureUsage({int days = 30});
  Future<Map<String, int>> getIntentDistribution();
  Future<double> getSuggestionAcceptanceRate();
}
```

**What's Tracked:**
- Feature usage counts (no content)
- Intent categories (study/work/life)
- Suggestion acceptance rates
- Autopilot approval rates
- App crashes (stack traces only)

**What's NOT Tracked:**
- Message content
- Personal information
- Contacts or names
- Calendar event details
- Any PII

---

### 5.2 Enhanced Logging & Diagnostics
**New Modules:**
- `lib/core/diagnostics/diagnostic_service.dart`
- `lib/core/diagnostics/log_viewer.dart`
- `lib/presentation/screens/diagnostics/diagnostics_screen.dart`

**Implementation:**
```dart
class DiagnosticService {
  Future<DiagnosticReport> generateReport();

  Future<List<LogEntry>> getRecentLogs({int limit = 100});

  Future<Map<String, ServiceHealth>> checkServicesHealth();

  Future<StorageReport> getStorageReport();

  Future<SyncStatus> getSyncStatus();
}

class ServiceHealth {
  String serviceName;
  bool isInitialized;
  bool isHealthy;
  DateTime lastCheck;
  String? errorMessage;
}
```

**Diagnostics Screen** (dev builds only):
```
┌─────────────────────────────────────────┐
│  🔧 Diagnostics                        │
├─────────────────────────────────────────┤
│  Services Status:                      │
│  ✅ AIService (healthy)               │
│  ✅ Calendar (healthy)                │
│  ⚠️  Gmail (token expired)             │
│  ✅ Storage (healthy)                 │
├─────────────────────────────────────────┤
│  Recent Logs: (last 50)               │
│  [INFO] 10:30 - Context refreshed     │
│  [WARN] 10:25 - Gmail token expired   │
│  [ERROR] 10:20 - API timeout         │
├─────────────────────────────────────────┤
│  Storage:                              │
│  • Database: 10.3 MB                  │
│  • Cache: 5.2 MB                      │
│  • Logs: 1.1 MB                       │
├─────────────────────────────────────────┤
│  [Export Logs] [Clear Cache]          │
└─────────────────────────────────────────┘
```

---

### 5.3 Comprehensive Testing
**New Test Files:**
```
test/
├── assistant/
│   ├── persona_manager_test.dart
│   ├── memory_engine_test.dart
│   ├── context_engine_test.dart
│   └── autopilot_engine_test.dart
├── ai_router/
│   └── routing_policy_test.dart
├── sync/
│   ├── action_queue_test.dart
│   └── sync_manager_test.dart
├── widgets/
│   ├── command_center_test.dart
│   ├── command_palette_test.dart
│   └── chat_screen_test.dart
└── integration/
    ├── autopilot_flow_test.dart
    ├── memory_learning_test.dart
    └── context_refresh_test.dart
```

**Test Coverage Goals:**
- Core brain: 90%+
- Autopilot: 85%+
- UI widgets: 70%+
- Services: 80%+

**CI/CD:**
- GitHub Actions workflow
- Run tests on every push
- Static analysis
- Build checks

---

## 📦 New File Structure

```
lib/
├── assistant/                    # NEW - Core brain
│   ├── persona_manager.dart
│   ├── persona_profiles.dart
│   ├── prompts.dart
│   ├── assistant_brain.dart
│   ├── memory/
│   │   ├── memory_engine.dart
│   │   ├── user_model.dart
│   │   └── memory_store.dart
│   ├── context/
│   │   ├── context_engine.dart
│   │   ├── context_aggregator.dart
│   │   └── context_models.dart
│   ├── autopilot/
│   │   ├── autopilot_engine.dart
│   │   ├── autopilot_action.dart
│   │   ├── autopilot_executor.dart
│   │   └── action_registry.dart
│   ├── ai_router/
│   │   ├── ai_router.dart
│   │   ├── model_provider.dart
│   │   └── routing_policy.dart
│   ├── sync/
│   │   ├── action_queue.dart
│   │   └── sync_manager.dart
│   └── command_registry.dart
│
├── analytics/                    # NEW - Analytics
│   ├── analytics_service.dart
│   └── event_tracker.dart
│
├── core/
│   ├── security/                 # NEW - Security
│   │   ├── encryption_service.dart
│   │   ├── data_export_service.dart
│   │   └── safety_rails.dart
│   ├── diagnostics/              # NEW - Diagnostics
│   │   ├── diagnostic_service.dart
│   │   └── log_viewer.dart
│   └── ...
│
├── data/
│   └── models/
│       ├── memory/               # NEW - Memory models
│       │   ├── memory.dart
│       │   ├── preference.dart
│       │   ├── routine.dart
│       │   └── relationship.dart
│       ├── autopilot/            # NEW - Autopilot models
│       │   ├── autopilot_action.dart
│       │   ├── execution_plan.dart
│       │   └── autopilot_result.dart
│       └── ...
│
├── presentation/
│   ├── screens/
│   │   ├── command_center/       # NEW - Command Center
│   │   │   └── command_center_screen.dart
│   │   ├── autopilot/            # NEW - Autopilot screens
│   │   │   ├── autopilot_approval_screen.dart
│   │   │   └── autopilot_history_screen.dart
│   │   ├── privacy/              # NEW - Privacy
│   │   │   └── privacy_dashboard_screen.dart
│   │   ├── sync/                 # NEW - Sync
│   │   │   └── sync_status_screen.dart
│   │   ├── diagnostics/          # NEW - Diagnostics
│   │   │   └── diagnostics_screen.dart
│   │   └── ...
│   └── widgets/
│       ├── command_center/       # NEW - Command Center widgets
│       ├── command_palette/      # NEW - Command Palette
│       ├── chat/                 # ENHANCED - Chat widgets
│       ├── autopilot/            # NEW - Autopilot widgets
│       └── animations/           # NEW - Animations
│
├── services/
│   └── integrations/             # NEW - Abstract services
│       ├── food_ordering_service.dart
│       ├── transport_service.dart
│       ├── booking_service.dart
│       └── payment_service.dart
│
└── ...
```

---

## 🎯 Success Criteria

### Must-Have (Required for 2.0 launch)
- ✅ Persona system with 3+ profiles
- ✅ Memory engine storing 1000+ facts
- ✅ Context engine aggregating all services
- ✅ Autopilot framework with approval flow
- ✅ Command Center screen
- ✅ Enhanced conversation UI
- ✅ Command palette
- ✅ Multi-model AI router
- ✅ Action queue for offline
- ✅ Privacy dashboard
- ✅ Data export
- ✅ 80%+ test coverage
- ✅ All existing features still work

### Nice-to-Have (Can be post-launch)
- Integration with real food ordering APIs
- Integration with ride-sharing APIs
- Advanced conflict resolution in sync
- Voice-only mode
- Desktop app (Windows/Mac/Linux)
- Team/family sharing features

---

## 📊 Estimated Impact

### Development
- **New Files:** ~60
- **Modified Files:** ~25
- **New Lines:** ~15,000
- **Test Files:** ~30
- **Duration:** 4-6 weeks (with testing)

### User Experience
- **Onboarding Time:** 2 min → 5 min (better, clearer)
- **Daily Actions:** 50% reduction (autopilot)
- **Response Accuracy:** +30% (context + memory)
- **User Delight:** Significantly improved

### Technical
- **Performance:** Maintained or better (caching, optimization)
- **Stability:** Higher (more tests)
- **Security:** Significantly improved (encryption, safety rails)
- **Scalability:** Better (modular architecture)

---

## 🚨 Risk Areas & Mitigation

| Risk | Mitigation |
|------|------------|
| **Breaking existing features** | Comprehensive testing, gradual rollout |
| **Performance degradation** | Profiling, lazy loading, caching |
| **User confusion** | Clear onboarding, contextual help |
| **Privacy concerns** | Transparent privacy dashboard, user control |
| **AI cost explosion** | Free tier limits, smart routing |
| **Offline sync conflicts** | Clear conflict resolution UI |
| **Too much complexity** | Progressive disclosure, sensible defaults |

---

## 📅 Development Phases

### Phase 1: Core Brain (Week 1-2)
- Days 1-3: Persona system
- Days 4-7: Memory engine
- Days 8-10: Context engine
- Days 11-14: Integration & testing

### Phase 2: Autopilot (Week 3)
- Days 15-17: Autopilot framework
- Days 18-19: Abstract services
- Days 20-21: Approval UI

### Phase 3: UX Enhancement (Week 4)
- Days 22-24: Command Center
- Days 25-26: Enhanced chat
- Days 27-28: Command palette & polish

### Phase 4: Infrastructure (Week 5)
- Days 29-30: AI router
- Days 31-32: Offline queue
- Days 33-35: Privacy & security

### Phase 5: Quality & Launch (Week 6)
- Days 36-38: Testing
- Days 39-40: Analytics & diagnostics
- Days 41-42: Documentation & final polish

---

## ✅ Definition of Done

Each phase is complete when:
- ✅ All code implemented
- ✅ Unit tests written and passing
- ✅ Integration tests passing
- ✅ Static analysis clean
- ✅ Documentation updated
- ✅ Git commits pushed
- ✅ No regression in existing features
- ✅ Performance acceptable

---

## 📝 Next Steps

1. ✅ **Approval:** Review and approve this plan
2. **Implementation:** Execute phases 1-5 in order
3. **Testing:** Comprehensive test coverage
4. **Documentation:** Update all docs
5. **Beta:** Deploy to beta testers
6. **Feedback:** Iterate based on feedback
7. **Launch:** Production release v2.0

---

**Status:** ✅ PLAN COMPLETE - READY FOR IMPLEMENTATION

**Created:** 2025-11-16
**Version:** 1.0
**Next:** Begin Phase 1 - Core Brain System
