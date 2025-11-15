# 🚀 Quick Implementation Guide

## Transforming Dona into Your Perfect Assistant

This guide shows you how to implement the intelligent features that make Dona proactive, learning, and truly helpful.

---

## ✅ What's Already Built

### 1. **Proactive Assistant** ✨
Location: `lib/services/proactive/proactive_assistant.dart`

**What it does:**
- Monitors your calendar 24/7
- Sends smart notifications before meetings
- Calculates travel time and suggests when to leave
- Morning briefings and end-of-day wrap-ups
- Weather alerts based on your schedule

**How to use:**
```dart
// In your main app initialization (lib/main.dart)
import 'package:dona_ai/services/proactive/proactive_assistant.dart';

void main() async {
  // Initialize services
  await ProactiveAssistant.instance.init();

  // Set notification callback
  ProactiveAssistant.instance.onNotification = (notification) {
    // Show to user
    _showNotificationToUser(notification);
  };

  // Start monitoring
  ProactiveAssistant.instance.startMonitoring();

  runApp(MyApp());
}
```

### 2. **User Profile & Learning** 🧠
Location: `lib/data/user_profile.dart`

**What it does:**
- Learns your meeting patterns
- Remembers frequent contacts
- Tracks preferred locations
- Analyzes your communication style
- Respects privacy with full control

**How to use:**
```dart
// Initialize
await UserProfile.instance.init();

// Learn from calendar event (automatic)
await UserProfile.instance.learnFromCalendarEvent(event);

// Learn from location visit
await UserProfile.instance.learnFromLocationVisit(location, 'Restaurant Name');

// Get insights
final preferredHour = UserProfile.instance.preferredMeetingHour;
final topContacts = UserProfile.instance.topContacts;
final isWorkTime = UserProfile.instance.isWorkHours;

// Privacy controls
UserProfile.instance.setLearning(false); // Pause learning
await UserProfile.instance.clearAllData(); // Clear everything
final privacyReport = UserProfile.instance.getPrivacyReport();
```

### 3. **Intent Recognition** 💬
Location: `lib/services/ai/intent_recognition.dart`

**What it does:**
- Understands natural language commands
- Extracts structured data (who, what, when, where)
- Detects urgency and context
- Supports multi-turn conversations

**How to use:**
```dart
// Parse user input
final intent = await IntentRecognizer.instance.parseIntent(
  "Schedule a meeting with John tomorrow at 2pm"
);

// Check what user wants
if (intent.type == IntentType.scheduleEvent) {
  final who = intent.entities['who']; // "John"
  final when = intent.entities['when']; // "tomorrow at 2pm"

  // Execute action
  await _scheduleEvent(who, when);
}

// Generate contextual response
final response = IntentRecognizer.instance.generateResponse(intent);
// "I'll schedule a meeting with John for tomorrow at 2pm. Let me check your calendar..."

// Multi-turn conversation
final context = ConversationContext();
context.addUserMessage("What's the weather?");
context.addAssistantMessage("It's 22°C and sunny in Sarajevo");
context.addUserMessage("How about tomorrow?"); // Follow-up
```

---

## 📝 Implementation Steps

### Step 1: Initialize Services (5 minutes)

**Edit `lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'services/proactive/proactive_assistant.dart';
import 'services/ai/intent_recognition.dart';
import 'data/user_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize intelligent services
  await _initIntelligentServices();

  runApp(const DonaApp());
}

Future<void> _initIntelligentServices() async {
  // 1. User Profile (learns preferences)
  await UserProfile.instance.init();

  // 2. Proactive Assistant (monitors and alerts)
  ProactiveAssistant.instance.onNotification = (notification) {
    _handleProactiveNotification(notification);
  };
  ProactiveAssistant.instance.startMonitoring();

  print('✅ Intelligent services initialized');
}

void _handleProactiveNotification(ProactiveNotification notification) {
  // Show notification to user
  // You can use flutter_local_notifications or show in-app

  print('📢 ${notification.title}: ${notification.message}');

  // If notification has actions, present them to user
  if (notification.actions != null) {
    for (final action in notification.actions!) {
      print('  → ${action.label}');
    }
  }
}
```

### Step 2: Enhance Chat Screen (10 minutes)

**Edit `lib/presentation/screens/chat/chat_screen.dart`:**

```dart
import '../../../services/ai/intent_recognition.dart';
import '../../../data/user_profile.dart';

class ChatScreen extends StatefulWidget {
  // ... existing code
}

class _ChatScreenState extends State<ChatScreen> {
  final ConversationContext _context = ConversationContext();

  Future<void> _handleUserMessage(String message) async {
    // 1. Add to conversation context
    _context.addUserMessage(message);

    // 2. Learn from interaction
    await UserProfile.instance.learnFromInteraction(message, null);

    // 3. Parse intent
    final intent = await IntentRecognizer.instance.parseIntent(message);

    // 4. Execute appropriate action
    String response;
    switch (intent.type) {
      case IntentType.scheduleEvent:
        response = await _handleScheduleEvent(intent);
        break;

      case IntentType.checkWeather:
        response = await _handleCheckWeather(intent);
        break;

      case IntentType.navigate:
        response = await _handleNavigation(intent);
        break;

      default:
        // Use AI for general conversation
        response = await AIService.instance.chat(message);
    }

    // 5. Add assistant response to context
    _context.addAssistantMessage(response);

    // 6. Update UI
    setState(() {
      _messages.add(Message(text: response, isUser: false));
    });
  }

  Future<String> _handleScheduleEvent(Intent intent) async {
    final who = intent.entities['who'];
    final when = intent.entities['when'];
    final what = intent.entities['what'];

    if (who == null || when == null) {
      return 'I need more details. Who should I schedule with and when?';
    }

    // Create calendar event
    // ... (use CalendarService)

    return 'Perfect! I\'ve scheduled a meeting with $who for $when.';
  }

  Future<String> _handleCheckWeather(Intent intent) async {
    final city = intent.entities['city'] ??
                 intent.entities['where'] ??
                 'Sarajevo';

    final weather = await WeatherService.instance.getCurrentWeather(city: city);

    if (weather != null) {
      return 'It\'s ${weather.temperature.toInt()}°C and ${weather.description} in ${weather.cityName}';
    }

    return 'Sorry, I couldn\'t fetch the weather right now.';
  }
}
```

### Step 3: Add Proactive Notification UI (15 minutes)

**Create `lib/presentation/widgets/proactive_notification_banner.dart`:**

```dart
import 'package:flutter/material.dart';
import '../../services/proactive/proactive_assistant.dart';

class ProactiveNotificationBanner extends StatefulWidget {
  const ProactiveNotificationBanner({Key? key}) : super(key: key);

  @override
  State<ProactiveNotificationBanner> createState() =>
      _ProactiveNotificationBannerState();
}

class _ProactiveNotificationBannerState
    extends State<ProactiveNotificationBanner> {
  ProactiveNotification? _currentNotification;

  @override
  void initState() {
    super.initState();

    // Listen for notifications
    ProactiveAssistant.instance.onNotification = (notification) {
      setState(() {
        _currentNotification = notification;
      });

      // Auto-dismiss after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _currentNotification?.id == notification.id) {
          setState(() {
            _currentNotification = null;
          });
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_currentNotification == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getPriorityColor(_currentNotification!.priority),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            _currentNotification!.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            _currentNotification!.message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),

          // Actions
          if (_currentNotification!.actions != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _currentNotification!.actions!.map((action) {
                return ElevatedButton(
                  onPressed: () {
                    action.onTap();
                    setState(() {
                      _currentNotification = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(action.label),
                );
              }).toList(),
            ),
          ],

          // Dismiss button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _currentNotification = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.low:
        return Colors.grey;
    }
  }
}
```

**Add to your home screen:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Your existing home content
        _buildHomeContent(),

        // Proactive notifications overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: ProactiveNotificationBanner(),
          ),
        ),
      ],
    ),
  );
}
```

---

## 🎯 Testing the Features

### Test 1: Proactive Calendar Notifications

```dart
// Add a calendar event for 1 hour from now
final event = CalendarEvent(
  id: 'test-1',
  title: 'Test Meeting',
  startTime: DateTime.now().add(Duration(hours: 1)),
  endTime: DateTime.now().add(Duration(hours: 2)),
  location: 'Office',
);

await CalendarService.instance.createEvent(event);

// Wait a few minutes, you should see notification:
// "Meeting in 60 minutes - Test Meeting"
```

### Test 2: Intent Recognition

```dart
// Test various commands
final testCommands = [
  "Schedule a meeting with Sarah tomorrow at 3pm",
  "What's the weather in Mostar?",
  "Navigate to Baščaršija",
  "Send an email to john@example.com",
  "What's on my calendar today?",
];

for (final command in testCommands) {
  final intent = await IntentRecognizer.instance.parseIntent(command);
  print('Command: $command');
  print('Intent: ${intent.type.name}');
  print('Entities: ${intent.entities}');
  print('---');
}
```

### Test 3: User Learning

```dart
// Simulate some activity
for (int i = 0; i < 5; i++) {
  final event = CalendarEvent(
    id: 'meeting-$i',
    title: 'Team Meeting',
    startTime: DateTime(2024, 1, i + 1, 10, 0), // All at 10 AM
    endTime: DateTime(2024, 1, i + 1, 11, 0), // 1 hour duration
    attendees: ['john@example.com', 'sarah@example.com'],
  );

  await UserProfile.instance.learnFromCalendarEvent(event);
}

// Check learned patterns
print('Preferred meeting hour: ${UserProfile.instance.preferredMeetingHour}');
// Should show: 10

print('Top contacts: ${UserProfile.instance.topContacts}');
// Should show: john@example.com, sarah@example.com
```

---

## 🚀 Next Features to Implement

Based on the [Perfect Assistant Roadmap](PERFECT_ASSISTANT_ROADMAP.md):

### Priority 1 (This Week):
1. **Voice Interface with Context**
   - Enhance speech service with conversation memory
   - Add wake word detection
   - Implement hands-free mode

2. **Smart Scheduling Assistant**
   - Auto-suggest meeting times based on preferences
   - Check both participants' availability
   - Smart conflict resolution

3. **Morning Briefing Screen**
   - Weather + Calendar + News in one view
   - Personalized based on user habits
   - Quick actions for common tasks

### Priority 2 (Next Week):
1. **Autonomous Actions**
   - Auto-respond to routine emails
   - Auto-schedule recurring meetings
   - Permission system for autonomous tasks

2. **Cross-Service Workflows**
   - Meeting prep: Search emails + Drive docs
   - Trip planning: Calendar + Maps + Weather
   - Daily recap: Generate summary, save to Drive

### Priority 3 (Month 2):
1. **Personality Engine**
   - Consistent Donna Paulsen personality
   - Emotional intelligence
   - Contextual responses

2. **Wellness Features**
   - Smart break suggestions
   - Work-life balance monitoring
   - Healthy habit reminders

---

## 📚 Resources

- **Full Roadmap:** [PERFECT_ASSISTANT_ROADMAP.md](PERFECT_ASSISTANT_ROADMAP.md)
- **API Integration:** [NEW_INTEGRATIONS.md](NEW_INTEGRATIONS.md)
- **Quick Start:** [../QUICK_START.md](../QUICK_START.md)

---

## 💡 Tips for Success

1. **Start Small:** Implement one feature at a time
2. **Test Continuously:** Use real-world scenarios
3. **Get Feedback:** See what users actually need
4. **Iterate:** Improve based on usage patterns
5. **Privacy First:** Always respect user data

---

## 🎉 You're Ready!

You now have the foundation for a truly intelligent personal assistant. The key differentiators are:

✅ **Proactive** - Dona acts before you ask
✅ **Learning** - Gets better with every interaction
✅ **Contextual** - Understands your situation
✅ **Natural** - Communicates like a human assistant

**Let's make Dona the best assistant ever! 🚀**
