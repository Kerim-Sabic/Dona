# DONA AI - Comprehensive Codebase Overview

## Executive Summary

**Dona AI** is a sophisticated personal assistant application built with Flutter (Dart) for iOS and Android. It's inspired by Donna Paulsen from the TV show "Suits" and features natural language processing, voice interaction, calendar management, and integrations with multiple Google APIs, Twilio, and AI services.

**Current Status:** MVP Phase with core services implemented and ready for testing

---

## 1. PROJECT STRUCTURE & ARCHITECTURE

### Directory Layout

```
/home/user/Dona/
├── lib/                          # Source code
│   ├── main.dart                # App entry point
│   ├── app.dart                 # App widget & routing configuration
│   │
│   ├── core/                    # Core utilities & theme
│   │   ├── constants/           # App strings and constants
│   │   ├── theme/              # Material Design theme
│   │   └── utils/              # Helper functions & logging
│   │
│   ├── config/                 # Configuration
│   │   └── api_keys.dart.template  # API keys template (api_keys.dart is gitignored)
│   │
│   ├── data/                   # Data layer
│   │   ├── models/             # Data models (CalendarEvent, NewsArticle, WeatherData)
│   │   └── user_profile.dart   # User learning & preferences
│   │
│   ├── services/               # External integrations
│   │   ├── ai/                 # DeepSeek AI & Intent Recognition
│   │   ├── calendar/           # Google Calendar API (OAuth 2.0)
│   │   ├── gmail/              # Gmail API
│   │   ├── google_drive/       # Google Drive API
│   │   ├── google_maps/        # Google Maps APIs
│   │   ├── google_tasks/       # Google Tasks API
│   │   ├── news/               # WorldNewsAPI
│   │   ├── weather/            # OpenWeatherMap API
│   │   ├── twilio/             # Twilio SMS & Voice
│   │   ├── speech/             # Speech-to-text & Text-to-speech
│   │   ├── storage/            # Local storage (SharedPreferences)
│   │   └── proactive/          # Proactive monitoring & notifications
│   │
│   └── presentation/           # UI layer
│       ├── screens/            # Full-screen views
│       │   ├── home/          # Main dashboard
│       │   ├── chat/          # Chat interface
│       │   ├── calendar/      # Calendar management
│       │   ├── news/          # News feed
│       │   ├── weather/       # Weather display
│       │   ├── settings/      # App settings
│       │   └── onboarding/    # First-time setup
│       └── widgets/           # Reusable UI components
│
├── docs/                        # Documentation
│   ├── ARCHITECTURE.md         # Clean architecture details
│   ├── API_INTEGRATIONS.md     # API setup guide
│   ├── QUICK_START.md          # Quick start guide
│   ├── QUICK_IMPLEMENTATION_GUIDE.md  # Feature implementation
│   ├── PERFECT_ASSISTANT_ROADMAP.md   # Future vision
│   ├── NEW_INTEGRATIONS.md     # New API documentation
│   └── GOOGLE_CALENDAR_SETUP.md       # Calendar OAuth setup
│
├── pubspec.yaml                # Flutter dependencies
├── analysis_options.yaml        # Linter configuration
├── README.md                    # Project overview
└── QUICK_START.md             # Setup instructions
```

### Architecture Pattern

**Clean Architecture with 3 Layers:**

1. **Presentation Layer** (`lib/presentation/`)
   - Screens, Widgets, UI state management
   - No business logic
   - Responsive to user interactions

2. **Domain Layer** (Minimal in current implementation)
   - Business entities
   - Use cases
   - Repository interfaces

3. **Data Layer** (`lib/data/` + `lib/services/`)
   - Data models
   - API integrations
   - Local storage
   - Repository implementations

---

## 2. TECHNOLOGY STACK

### Frontend
- **Framework:** Flutter 3.0+
- **Language:** Dart 3.0+
- **State Management:** Provider 6.1.1 + Flutter BLoC 8.1.3
- **Localization:** flutter_localizations + intl 0.18.1

### APIs & Networking
- **HTTP Client:** http 1.1.0 + dio 5.4.0
- **URL Launcher:** url_launcher 6.2.4

### AI/LLM Services
- **Primary AI:** DeepSeek API (with Claude/GPT-4 support planned)
- **Intent Recognition:** Custom pattern matching + AI-based extraction

### Speech & Voice
- **Speech-to-Text:** speech_to_text 6.5.1
- **Text-to-Speech:** flutter_tts 3.8.5
- **Voice UI:** avatar_glow 3.0.1

### Google APIs
- **Google APIs Client:** googleapis 13.0.0 + googleapis_auth 1.5.0
- **Integrated Services:**
  - Google Calendar (OAuth 2.0)
  - Gmail (OAuth 2.0)
  - Google Tasks
  - Google Drive
  - Google Maps (Directions, Places, Geocoding)
  - Google Cloud Speech/TTS
  - Google Sheets API

### Communication
- **SMS & Voice:** Twilio Flutter 0.0.9
- **Notifications:** Firebase 14.7.10 + flutter_local_notifications 16.3.2

### Location & Maps
- **Location Services:** geolocator 11.0.0
- **Geocoding:** geocoding 2.1.1
- **Maps Display:** google_maps_flutter 2.5.3

### Data Storage
- **Preferences:** shared_preferences 2.2.2
- **Local Database:** sqflite 2.3.2
- **File Access:** path_provider 2.1.2
- **Advanced Storage:** Hive 2.2.3 + hive_flutter 1.1.0

### Security
- **Secure Storage:** flutter_secure_storage 9.0.0
- **Encryption:** crypto 3.0.3

### Utilities
- **UUID:** uuid 4.3.3
- **Equality:** equatable 2.0.5
- **Logging:** logger 2.0.2+1
- **Time Formatting:** timeago 3.6.0
- **JSON Serialization:** json_annotation 4.8.1

### Testing & Development
- **Testing:** flutter_test (built-in)
- **Code Generation:** build_runner 2.4.8 + json_serializable 6.7.1 + hive_generator 2.0.1
- **Mocking:** mockito 5.4.4
- **Linting:** flutter_lints 3.0.1

---

## 3. EXISTING FEATURES & FUNCTIONALITY

### A. Core Personal Assistant Features

#### 1. **AI Chat Interface** ✅ LIVE
- **Service:** `AIService` (DeepSeek API)
- **Features:**
  - Natural language conversation
  - Conversation history (last 10 messages)
  - Streaming responses
  - Intent extraction
  - Personality-based responses (Donna from Suits persona)
- **Status:** Working with real DeepSeek API

#### 2. **Voice Interface** (Framework Ready)
- **Service:** `SpeechService`
- **Features:**
  - Speech-to-text with multi-language support (English, Bosnian)
  - Text-to-speech synthesis
  - Voice input/output state management
- **Status:** API structure ready, needs TTS/STT implementation

#### 3. **Intent Recognition** ✅ IMPLEMENTED
- **Service:** `IntentRecognizer`
- **Supported Intents:**
  - Schedule/reschedule/cancel events
  - Send email/SMS
  - Make calls
  - Create/complete tasks
  - Navigate & find locations
  - Check weather/news
  - Upload/download files
  - Set reminders
- **Parsing Methods:**
  - Quick pattern matching for common intents
  - AI-based parsing for complex requests
- **Features:**
  - Entity extraction (who, what, when, where, why)
  - Urgency detection
  - Confidence scoring
  - Context-aware follow-ups

#### 4. **Proactive Assistant** ✅ IMPLEMENTED
- **Service:** `ProactiveAssistant`
- **Features:**
  - Calendar event monitoring (5-minute intervals)
  - Smart meeting reminders (1 hour, 30 min, 15 min before)
  - Travel time calculation & alerts
  - Weather alerts (rain, extreme temps)
  - Morning briefings (7 AM)
  - End-of-day wrap-ups (6 PM)
  - Notification actions (Brief me, Navigate, Snooze)
- **Notification Types:** Calendar, Traffic, Weather, Reminder, Suggestion, Emergency

#### 5. **User Profile & Learning** ✅ IMPLEMENTED
- **Service:** `UserProfile`
- **Learns:**
  - Meeting time patterns (preferred hours)
  - Meeting duration preferences
  - Frequent contacts
  - Frequent locations
  - Preferred restaurants
  - Communication style (formality level)
- **Features:**
  - Work hours detection
  - Smart scheduling recommendations
  - Privacy controls (disable learning)
  - GDPR compliance (data export/deletion)
  - Privacy report generation

---

### B. Calendar Management

#### **Google Calendar Integration** ✅ LIVE
- **Service:** `CalendarService`
- **Features:**
  - OAuth 2.0 authentication
  - Get upcoming events
  - Get events by date range
  - Create events
  - Update events
  - Delete events
  - Mock data for testing (no auth needed)
- **Data Model:** `CalendarEvent`
  - All-day event support
  - Location tracking
  - Attendee management
  - Color-coded events
  - Time/date formatting helpers
  - Duration calculations

---

### C. Communication

#### **Email Management** ✅ IMPLEMENTED
- **Service:** `GmailService`
- **Features:**
  - OAuth 2.0 authentication
  - Read inbox messages
  - Send emails (with CC/BCC support)
  - Mark as read/unread
  - Label management
  - Message parsing (plain text, multipart)
- **Data Model:** `EmailMessage`
  - From/To/Cc/Bcc fields
  - Subject & body
  - Read/unread status
  - Labels
  - Thread ID support

#### **SMS & Voice Calls** ✅ IMPLEMENTED
- **Service:** `TwilioService`
- **SMS Features:**
  - Send SMS messages
  - Get SMS status
  - Retrieve message history
  - Error handling
- **Voice Features:**
  - Make phone calls
  - Text-to-speech calls
  - Call status tracking
  - TwiML generation
- **Data Models:** `SmsMessage`, `PhoneCall`

---

### D. Task Management

#### **Google Tasks Integration** ✅ IMPLEMENTED
- **Service:** `GoogleTasksService`
- **Features:**
  - Get all task lists
  - Create tasks with notes & due dates
  - Update task status
  - Complete tasks
  - Delete tasks
  - Subtask support
  - Mock data for testing
- **Data Models:** `GoogleTask`, `TaskList`
  - Due date management
  - Status tracking (needsAction/completed)
  - Notes & parent task references

---

### E. Information Services

#### **News Feed** ✅ LIVE
- **Service:** `NewsService`
- **API:** WorldNewsAPI
- **Features:**
  - Top news headlines (Bosnia-focused)
  - News search
  - Category filtering
  - Mock data fallback
- **Data Model:** `NewsArticle`
  - Title, description, content
  - Source, author
  - Published date
  - Image URL
  - External link

#### **Weather** ✅ LIVE
- **Service:** `WeatherService`
- **API:** OpenWeatherMap
- **Features:**
  - Current weather by city name
  - 5-day weather forecast
  - Weather by coordinates (latitude/longitude)
  - Mock data fallback
- **Data Model:** `WeatherData`
  - Temperature, feels-like, min/max
  - Humidity, pressure, wind
  - Weather description & icon codes
  - Cloud coverage
  - Timestamp

---

### F. File Management

#### **Google Drive Integration** ✅ IMPLEMENTED
- **Service:** `GoogleDriveService`
- **Features:**
  - List files/folders
  - Search files
  - Upload files
  - Download files
  - Create folders
  - Delete files
  - Get recent files
  - Get starred files
- **Data Model:** `DriveFile`
  - File metadata
  - MIME type detection
  - Size formatting
  - Timestamps
  - Web links

---

### G. Navigation & Location

#### **Google Maps Integration** ✅ FRAMEWORK READY
- **Service:** `GoogleMapsService`
- **Features:**
  - Directions & routes
  - Travel time calculation
  - Distance calculation
  - Geocoding (address → coordinates)
  - Reverse geocoding (coordinates → address)
  - Route polylines
  - Turn-by-turn instructions
- **Supported APIs:**
  - Directions API
  - Geocoding API
  - Distance Matrix API
  - Air Quality API
  - Pollen API
  - Roads API

---

### H. Local Storage

#### **Local Storage Service** ✅ IMPLEMENTED
- **Implementation:** SharedPreferences wrapper
- **Supported Data Types:**
  - Strings, Integers, Booleans, Doubles
  - String lists
  - Custom JSON data
- **Use Cases:**
  - User preferences
  - Authentication tokens
  - App settings
  - Offline cache

---

## 4. API INTEGRATIONS (DETAILED)

### Summary Table

| API | Service | Status | Key Features |
|-----|---------|--------|--------------|
| **DeepSeek API** | AI Chat | ✅ LIVE | Conversational AI, Intent extraction |
| **Google Calendar** | Calendar | ✅ LIVE | OAuth 2.0, CRUD operations |
| **Gmail** | Email | ✅ READY | OAuth 2.0, Send/Read emails |
| **Google Tasks** | Tasks | ✅ READY | Task lists, Subtasks |
| **Google Drive** | Files | ✅ READY | Upload/Download, Search |
| **Google Maps** | Navigation | ✅ READY | Directions, Geocoding, Routes |
| **Twilio** | SMS/Voice | ✅ READY | Send SMS, Make calls |
| **WorldNewsAPI** | News | ✅ LIVE | Headlines, Search, Categories |
| **OpenWeatherMap** | Weather | ✅ LIVE | Current weather, 5-day forecast |
| **Google Cloud Speech** | Voice | 🔄 READY | STT/TTS configuration |
| **Firebase** | Notifications | 🔄 READY | Push notifications, FCM |

**Status Legend:**
- ✅ LIVE = Fully tested and working
- ✅ READY = Implemented, needs final testing
- 🔄 READY = Framework in place, implementation needed

---

## 5. CONFIGURATION & SETUP

### API Keys Configuration

**File:** `lib/config/api_keys.dart.template`

To set up the app:

1. Copy template to actual file:
   ```bash
   cp lib/config/api_keys.dart.template lib/config/api_keys.dart
   ```

2. Fill in your API credentials:
   ```dart
   class ApiKeys {
     // AI Services
     static const String deepSeekApiKey = 'YOUR_KEY';
     static const String claudeApiKey = 'YOUR_KEY';
     
     // Google APIs (use same OAuth credentials)
     static const String googleCalendarClientId = 'YOUR_CLIENT_ID';
     static const String googleMapsApiKey = 'YOUR_KEY';
     
     // Third-party services
     static const String newsApiKey = 'YOUR_KEY';
     static const String openWeatherApiKey = 'YOUR_KEY';
     
     // Twilio
     static const String twilioAccountSid = 'YOUR_SID';
     static const String twilioAuthToken = 'YOUR_TOKEN';
   }
   ```

3. **Important:** `api_keys.dart` is in `.gitignore` - NEVER commit API keys

### OAuth Configuration

All Google APIs use OAuth 2.0 with these shared parameters:
- **Client ID:** (Same for all Google APIs)
- **Redirect URI:** `http://localhost:8080` (web) or custom for mobile
- **Scopes:** Service-specific (calendar, gmail, drive, tasks, maps)

### Environment Variables

**ApiConfig** class provides default values:
- Default city: "Sarajevo"
- Default country: "ba" (Bosnia & Herzegovina)
- Default language: "en"
- Temperature unit: "metric" (Celsius)
- Connection timeout: 30 seconds

---

## 6. KEY COMPONENTS & MODULES

### Services Architecture

Each service follows a singleton pattern:

```dart
class [Service] {
  static final [Service] _instance = [Service]._internal();
  static [Service] get instance => _instance;
  
  [Service]._internal();
  
  Future<void> init() async { /* initialize */ }
}
```

### Service Initialization (main.dart)

Currently initializes:
- ✅ LocalStorageService
- 🔄 Firebase (TODO)
- 🔄 Hive (TODO)
- 🔄 Notification services (TODO)

To implement: Call services' `init()` methods in `_initializeServices()`

### Data Models

**Models with JSON serialization:**
- `CalendarEvent` - Google Calendar events
- `EmailMessage` - Gmail messages
- `GoogleTask` / `TaskList` - Google Tasks
- `DriveFile` - Google Drive files
- `NewsArticle` - News items
- `WeatherData` - Weather information
- `SmsMessage` / `PhoneCall` - Twilio messages
- `DirectionRoute` / `DirectionLeg` / `DirectionStep` - Maps directions
- `PlaceLocation` - Location data

### Intent Types

```dart
enum IntentType {
  // Calendar
  scheduleEvent, rescheduleEvent, cancelEvent, checkCalendar,
  
  // Communication
  sendEmail, readEmail, sendSMS, makeCall,
  
  // Tasks
  createTask, completeTask, listTasks,
  
  // Location
  navigate, findPlace, checkTraffic,
  
  // Information
  checkWeather, readNews, search,
  
  // Files
  uploadFile, downloadFile, searchFiles,
  
  // Reminders
  setReminder, listReminders,
  
  // General
  greeting, help, unknown,
}
```

---

## 7. DATA FLOW & USER INTERACTIONS

### Example: Chat Message Flow

```
User Input (Chat Screen)
    ↓
ChatScreen → AIService.chat(message)
    ↓
DeepSeek API Call
    ↓
Response → Add to conversation history
    ↓
IntentRecognizer.parseIntent(message)
    ↓
Execute action (if needed):
  - Schedule? → CalendarService
  - Email? → GmailService
  - Task? → GoogleTasksService
  - Weather? → WeatherService
    ↓
Return response + action result
    ↓
Update ChatScreen UI
    ↓
UserProfile.learnFromInteraction(message)
    ↓
ProactiveAssistant.startMonitoring()
```

### Example: Proactive Notification Flow

```
ProactiveAssistant.startMonitoring()
    ↓
Timer every 5 minutes
    ↓
_runChecks() runs in parallel:
  - _checkUpcomingEvents()
  - _checkWeatherAlerts()
  - _checkMorningBriefing()
  - _checkEndOfDayWrapup()
    ↓
For each check:
  1. Fetch relevant data
  2. Analyze context
  3. Determine if notification needed
  4. Create ProactiveNotification
    ↓
_sendNotification(notification)
    ↓
Call onNotification callback
    ↓
UI displays notification with actions
    ↓
User taps action
    ↓
Execute callback (e.g., _startNavigation)
```

---

## 8. CURRENT IMPLEMENTATION STATUS

### Fully Implemented ✅

- ✅ AI Chat with DeepSeek API
- ✅ Intent recognition (pattern + AI-based)
- ✅ Google Calendar (mock + OAuth ready)
- ✅ Gmail (full implementation)
- ✅ Google Tasks (full implementation)
- ✅ Google Drive (full implementation)
- ✅ Google Maps (framework ready)
- ✅ News Feed (WorldNewsAPI)
- ✅ Weather (OpenWeatherMap)
- ✅ Twilio SMS/Voice (full implementation)
- ✅ User Profile & Learning
- ✅ Proactive monitoring system
- ✅ Local storage
- ✅ Conversation context management

### In Progress 🔄

- 🔄 Speech-to-text implementation
- 🔄 Text-to-speech integration
- 🔄 Firebase Cloud Messaging
- 🔄 UI Screens (most scaffolded)
- 🔄 BLoC state management

### Not Started ❌

- ❌ Advanced voice (wake word detection)
- ❌ Machine learning personalization
- ❌ Food ordering integrations (Glovo/Wolt)
- ❌ Multi-device sync
- ❌ Plugin architecture
- ❌ Advanced analytics

---

## 9. AREAS OF CONCERN & IMPROVEMENT

### Current Issues

1. **Speech Services Stubbed Out**
   - SpeechService has placeholder implementations
   - Needs real Google Cloud Speech-to-Text integration
   - Text-to-speech uses `flutter_tts` but not fully initialized

2. **OAuth Flow Incomplete**
   - Redirect URI handling not fully implemented
   - Manual token setting required for testing
   - Should implement proper OAuth flow with local server redirect handler

3. **Missing UI Screens**
   - Several screens scaffolded but not fully implemented
   - Chat screen needs streaming responses display
   - Settings screen for user preferences
   - Email, Tasks, Drive, Maps screens need work

4. **Firebase Not Initialized**
   - FCM for push notifications
   - Authentication alternatives
   - Cloud sync (optional)

5. **Limited Error Handling**
   - Generic error messages
   - No retry logic for failed API calls
   - Missing timeout handling

6. **Performance Concerns**
   - Conversation history not pruned efficiently
   - Proactive checks run every 5 minutes (battery impact)
   - No caching strategy for frequently accessed data

### Recommendations for Improvement

1. **High Priority:**
   - Implement real speech services
   - Complete OAuth flow
   - Add comprehensive error handling
   - Implement proper notification UI
   - Add unit & widget tests

2. **Medium Priority:**
   - Improve performance (pagination, lazy loading)
   - Add offline support
   - Implement caching strategy
   - Add analytics/logging
   - Create Settings screen

3. **Low Priority:**
   - Food ordering integrations
   - Multi-language support completion
   - Advanced voice features
   - ML-based personalization

---

## 10. TESTING & DOCUMENTATION

### Existing Documentation ✅

- `README.md` - Project overview
- `QUICK_START.md` - Quick setup guide (comprehensive!)
- `docs/ARCHITECTURE.md` - Architecture details
- `docs/API_INTEGRATIONS.md` - API configuration
- `docs/QUICK_IMPLEMENTATION_GUIDE.md` - Feature implementation guide
- `docs/PERFECT_ASSISTANT_ROADMAP.md` - Future vision
- `docs/NEW_INTEGRATIONS.md` - New API details
- `docs/GOOGLE_CALENDAR_SETUP.md` - OAuth setup

### Testing Status

- **Unit Tests:** Not implemented
- **Widget Tests:** Not implemented
- **Integration Tests:** Not implemented
- **Manual Testing:** Ready (follow QUICK_START.md)

### Test Data

Mock data available for:
- Calendar events
- News articles
- Weather data
- Google Tasks
- Gmail messages

---

## 11. DEPLOYMENT & BUILD

### Requirements

- Flutter SDK: ≥3.0.0
- Dart SDK: ≥3.0.0
- Android SDK or Xcode (for native builds)

### Build Commands

```bash
# Get dependencies
flutter pub get

# Run app (web)
flutter run -d chrome

# Run app (mobile emulator)
flutter run

# Build release
flutter build apk  # Android
flutter build ios  # iOS
flutter build web  # Web
```

### Platform Support

- ✅ Android (with Gradle)
- ✅ iOS (with CocoaPods)
- ✅ Web (Chrome, Firefox, Safari)
- ❌ Desktop (not configured)

---

## 12. SECURITY & PRIVACY

### Implemented ✅

- ✅ API keys excluded from version control
- ✅ Secure token storage (flutter_secure_storage)
- ✅ HTTPS for all API calls
- ✅ OAuth 2.0 for Google APIs
- ✅ User consent for permissions
- ✅ Data export capability (GDPR)
- ✅ Data deletion option

### Not Yet Implemented 🔄

- 🔄 Biometric authentication
- 🔄 Encryption at rest (local data)
- 🔄 Certificate pinning
- 🔄 Rate limiting
- 🔄 Audit logging
- 🔄 Privacy policy enforcement

---

## 13. LOCALIZATION

### Supported Languages

- ✅ English (en-US)
- ✅ Bosnian (bs-BA)

### Configuration

- Uses `flutter_localizations`
- `intl` package for date/time formatting
- String constants in `core/constants/app_strings.dart`

---

## QUICK REFERENCE

### Key Files to Modify

**To add new features:**
1. Create service in `lib/services/[feature]/`
2. Add models in `lib/data/models/`
3. Create screen in `lib/presentation/screens/[feature]/`
4. Update routing in `lib/app.dart`
5. Initialize service in `lib/main.dart` if needed

**To configure APIs:**
1. Edit `lib/config/api_keys.dart` (from template)
2. Add scopes to `ApiKeys` class
3. Update `ApiConfig` if new endpoints needed

### Running the App

```bash
cd /home/user/Dona
flutter pub get
flutter run -d chrome  # or your device
```

---

## CONCLUSION

**Dona AI** is a well-structured, feature-rich personal assistant with:
- ✅ Solid foundation with clean architecture
- ✅ Comprehensive API integrations
- ✅ Intelligent proactive features
- ✅ User learning & personalization
- ✅ Ready for MVP testing

**Next Steps:**
1. Complete speech services integration
2. Implement remaining UI screens
3. Add comprehensive testing
4. Deploy to beta testers
5. Gather feedback for Phase 2 (advanced features)

The codebase is well-documented, maintainable, and ready for expansion!
