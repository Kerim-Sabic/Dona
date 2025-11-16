# AI Router & App Modes

## Overview

The AI Router is Dona's intelligent request routing system that manages model selection, tier enforcement, and usage tracking. It provides a clean abstraction between the application and AI backends, enabling flexible tier-based monetization.

## Architecture

```
┌─────────────────────────────────────────────┐
│           AssistantBrain                    │
│                                             │
│  generateReply() → AiRequest               │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│            AiRouter                          │
│                                             │
│  • Model Selection                          │
│  • Tier Enforcement                         │
│  • Usage Tracking                           │
│  • Statistics                               │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────┴─────────┬─────────────┐
         ▼                   ▼             ▼
    [Light Model]      [Standard]     [Premium]
         │                   │             │
         └───────────────────┴─────────────┘
                         │
                         ▼
                  [AIService]
                  (DeepSeek)
```

## App Modes

### Free Tier
**Target**: Casual users, trial experience

**Limits**:
- 50 AI requests per day
- 4,000 token context limit
- Light & Standard models only
- 2 autopilot executions per day
- No proactive suggestions

**Features Available**:
- ✅ Chat with Dona
- ✅ Study help (flashcards, quizzes)
- ✅ Calendar integration
- ✅ Basic autopilot (2/day)
- ❌ Premium models
- ❌ Proactive assistance
- ❌ Unlimited requests

### Premium Trial
**Target**: Testing premium features

**Limits**:
- 200 AI requests per day
- 8,000 token context limit
- All models available
- 10 autopilot executions per day
- Proactive suggestions enabled

**Features Available**:
- ✅ Everything in Free
- ✅ Premium models
- ✅ Proactive assistance
- ✅ More autopilot runs
- ✅ Higher quality responses

### Premium
**Target**: Power users, students, professionals

**Limits**:
- 1,000 AI requests per day
- 16,000 token context limit
- All models available
- 50 autopilot executions per day
- Proactive suggestions enabled

**Features Available**:
- ✅ Everything
- ✅ Highest quality AI
- ✅ Unlimited autopilot
- ✅ Priority support (future)

## Model Selection

### Light Model
**Use Cases**:
- Simple chat responses
- Quick lookups
- Basic formatting

**Characteristics**:
- Fast response time
- Lower cost (1x multiplier)
- 4K context window
- Good for straightforward tasks

**Routing Logic**:
```dart
if (context == simple_task && user.isFree) {
  return AiModel.light;
}
```

### Standard Model
**Use Cases**:
- General conversation
- Study help
- Email drafting
- Document summarization

**Characteristics**:
- Balanced speed/quality
- Moderate cost (2x multiplier)
- 8K context window
- Default for most tasks

**Routing Logic**:
```dart
if (context == chat || context == study_help) {
  return AiModel.standard;
}
```

### Premium Model
**Use Cases**:
- Autopilot planning
- Complex quiz generation
- Multi-step reasoning
- Advanced summarization

**Characteristics**:
- Highest quality
- Higher cost (5x multiplier)
- 16K context window
- Best for complex tasks

**Routing Logic**:
```dart
if (context == planning && user.isPremium) {
  return AiModel.premium;
}
```

## Routing Rules

### Request Types → Model Mapping

| Request Type | Free | Premium |
|--------------|------|---------|
| Chat | Standard | Standard |
| Planning (Autopilot) | Standard | **Premium** |
| Study Help | Standard | Standard |
| Quiz Generation | Light | **Premium** |
| Flashcard Generation | Light | Standard |
| Summarization | Light | **Premium** |
| Email Drafting | Standard | Standard |
| Proactive Suggestions | ❌ | Standard |

### Context Length Limits

```dart
Free:     4,000 tokens  (~3,000 words)
Premium:  16,000 tokens (~12,000 words)
```

If context exceeds limit:
1. Free: Truncate to fit
2. Premium: Use full context

### Daily Limits

```dart
Free:     50 requests
Premium:  1,000 requests
```

When limit reached:
1. Show "Upgrade to Premium" prompt
2. Block new requests until next day
3. Track reset time (midnight local)

## Usage Tracking

### Statistics Tracked

```dart
class UsageStats {
  DateTime date;
  int totalRequests;           // Total AI calls
  int autopilotUsed;          // Autopilot runs
  Map<AiModel, int> byModel;  // Per-model breakdown
  int estimatedCost;          // In cents
}
```

### Cost Estimation

Formula:
```dart
cost = (tokens / 1000) * model.costMultiplier
```

Example:
```
Request: 500 tokens
Model: Premium (5x multiplier)
Cost: (500 / 1000) * 5 = 2.5 cents
```

### Persistence

- Stats stored in local storage
- Keyed by date: `usage_stats_2025-01-15`
- Resets daily at midnight
- Historical stats kept for analytics

## API Reference

### AiRouter

```dart
// Initialize (call at app startup)
await AiRouter.instance.init();

// Send request
final request = AiRequest(
  prompt: 'Explain quantum physics',
  context: AiUsageContext.chat,
  conversationHistory: [...],
);

final response = await AiRouter.instance.send(request);

// Check limits
final remaining = AiRouter.instance.remainingRequests; // -1 if unlimited

// Check feature availability
final canUseAutopilot = AiRouter.instance.isFeatureAvailable('autopilot');

// Get current mode
final mode = AiRouter.instance.currentMode; // free, premiumTrial, premium

// Get tier limits
final limits = AiRouter.instance.currentLimits;

// Get today's stats
final stats = AiRouter.instance.todayStats;
```

### Mode Management

```dart
// Get current mode
final mode = AiRouter.instance.currentMode;

// Change mode (for testing/manual upgrade)
await AiRouter.instance.setMode(AppMode.premium);

// Check if premium
final isPremium = mode.isPremium; // true for premium or premiumTrial
```

### AiRequest

```dart
final request = AiRequest(
  prompt: 'User message',
  context: AiUsageContext.chat,        // Required
  conversationHistory: [...],          // Optional
  metadata: {...},                     // Optional
);

// Get estimated tokens
final tokens = request.estimatedTokens; // ~4 chars per token
```

### AiResponse

```dart
final response = await AiRouter.instance.send(request);

response.content;        // String: AI response
response.modelUsed;      // AiModel: Which model was used
response.tokensUsed;     // int: Actual token count
response.responseTime;   // Duration: How long it took
response.metadata;       // Map: Additional data
```

## Integration Guide

### 1. Replace Direct AI Calls

**Before**:
```dart
final response = await AIService.instance.chat(prompt);
```

**After**:
```dart
final request = AiRequest(
  prompt: prompt,
  context: AiUsageContext.chat,
);
final response = await AiRouter.instance.send(request);
final text = response.content;
```

### 2. Handle Limits

```dart
try {
  final response = await AiRouter.instance.send(request);
  // Use response
} on AiRouterException catch (e) {
  // Show upgrade prompt
  showUpgradeDialog(e.message);
}
```

### 3. Show Usage Stats

```dart
final stats = AiRouter.instance.todayStats;
if (stats != null) {
  print('Used ${stats.totalRequests} requests today');
  print('Estimated cost: \$${stats.estimatedCost / 100}');
}
```

### 4. Check Features Before Use

```dart
if (AiRouter.instance.isFeatureAvailable('autopilot')) {
  // Show autopilot button
} else {
  // Show locked with upgrade prompt
}
```

## Future Enhancements

### Planned Features

1. **Multi-Backend Support**
   - Map models to different AI providers
   - Fallback chains for reliability
   - Load balancing

2. **Dynamic Pricing**
   - Real-time cost tracking
   - Usage-based billing
   - Custom tier creation

3. **Caching Layer**
   - Cache common responses
   - Reduce duplicate requests
   - Save costs

4. **Rate Limiting**
   - Per-minute limits
   - Burst allowance
   - Cooldown periods

5. **Analytics Dashboard**
   - Usage graphs
   - Cost trends
   - Model performance

### Integration with Billing

When billing is implemented:

```dart
// Check subscription status
final subscription = await BillingService.instance.getSubscription();

// Upgrade flow
await BillingService.instance.subscribe(Tier.premium);
await AiRouter.instance.setMode(AppMode.premium);

// Downgrade flow
await BillingService.instance.cancel();
await AiRouter.instance.setMode(AppMode.free);
```

## Testing

### Manual Testing

```dart
// Set to free mode
await AiRouter.instance.setMode(AppMode.free);

// Make 50 requests
for (int i = 0; i < 50; i++) {
  await AiRouter.instance.send(...);
}

// 51st request should throw AiRouterException
```

### Mock for Unit Tests

```dart
class MockAiRouter implements AiRouter {
  @override
  Future<AiResponse> send(AiRequest request) async {
    return AiResponse(
      content: 'Mock response',
      modelUsed: AiModel.standard,
      responseTime: Duration.zero,
    );
  }
}
```

## Configuration

### Tier Limits (lib/assistant/ai_router/ai_models.dart)

```dart
// Adjust limits
const TierLimits.free = TierLimits(
  maxDailyRequests: 50,      // Change this
  maxContextLength: 4000,
  allowPremiumModels: false,
  allowProactive: false,
  allowAutopilot: true,
  maxAutopilotPerDay: 2,     // Change this
);
```

### Model Mapping (lib/assistant/ai_router/ai_router.dart)

```dart
AiModel _selectModel(AiUsageContext context, AppMode mode, TierLimits limits) {
  // Customize routing logic here
  if (context == AiUsageContext.planning && limits.allowPremiumModels) {
    return AiModel.premium;
  }
  return AiModel.standard;
}
```

## Monitoring

### Log Messages

```
INFO: AiRouter initialized: Mode=Free
DEBUG: Routing chat to Standard Model
WARNING: Daily request limit reached: 50/50
ERROR: AI request failed: Network error
```

### Diagnostics Screen

Navigate to `/diagnostics` (debug mode) to see:
- Current app mode
- Requests used today
- Requests remaining
- Model usage breakdown

---

**Version**: 1.0
**Last Updated**: 2025-01-15
**Status**: Production Ready (Architecture)
