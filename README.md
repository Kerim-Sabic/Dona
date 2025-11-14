# Dona AI - The Ultimate Personal Assistant

<div align="center">
  <h3>Your AI concierge, inspired by Donna from Suits</h3>
  <p>A full-featured conversational assistant for Android and iOS</p>
</div>

---

## Overview

Dona AI is a sophisticated personal assistant app that leverages modern AI (Claude, GPT-4) to understand natural language and perform tasks on your behalf. The app proactively informs users about news, weather, calendar events, and more, while dynamically executing commands like scheduling meetings or ordering food.

### Key Features

- 🗣️ **Natural Voice & Chat Interface** - Seamless conversation using speech-to-text and text-to-speech
- 🌍 **Multilingual Support** - Fluent in Bosnian (Latin) and English
- 📅 **Smart Scheduling** - Automated calendar management and reminders
- 📰 **Daily Briefings** - Morning updates with news, weather, and calendar events
- 🍕 **Task Automation** - Order food, make calls, send messages, and more
- 🧠 **Learning & Personalization** - Adapts to your habits and anticipates needs
- 🔒 **Privacy-First** - GDPR compliant with local data encryption

---

## Architecture

### Tech Stack

- **Framework**: Flutter (Dart) for cross-platform development
- **AI Engine**: Claude API / OpenAI GPT-4 for NLP and conversation
- **Speech**: Google Cloud Speech-to-Text & Text-to-Speech
- **Backend**: Node.js/Python server for heavy AI tasks
- **Database**: SQLite (local) + Cloud sync for user data
- **State Management**: BLoC pattern with Provider

### Project Structure

```
dona_ai/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # App widget & routing
│   │
│   ├── core/                     # Core utilities
│   │   ├── constants/           # App constants
│   │   ├── theme/               # App theme
│   │   ├── utils/               # Helper functions
│   │   └── config/              # Configuration
│   │
│   ├── data/                     # Data layer
│   │   ├── models/              # Data models
│   │   ├── repositories/        # Repository implementations
│   │   └── datasources/         # Local & remote data sources
│   │
│   ├── domain/                   # Business logic
│   │   ├── entities/            # Business entities
│   │   ├── repositories/        # Repository interfaces
│   │   └── usecases/            # Business use cases
│   │
│   ├── presentation/             # UI layer
│   │   ├── screens/             # App screens
│   │   ├── widgets/             # Reusable widgets
│   │   └── bloc/                # State management
│   │
│   └── services/                 # External services
│       ├── ai/                  # AI/LLM integration
│       ├── speech/              # Speech services
│       ├── calendar/            # Calendar API
│       ├── news/                # News API
│       ├── weather/             # Weather API
│       ├── location/            # Location services
│       └── notifications/       # Push notifications
│
├── assets/                       # Static assets
│   ├── images/
│   ├── icons/
│   └── audio/
│
├── test/                         # Unit & widget tests
├── integration_test/             # Integration tests
└── docs/                         # Additional documentation
```

---

## API Integrations

### Core APIs

- **AI/NLP**: Anthropic Claude or OpenAI GPT-4
- **Speech Recognition**: Google Cloud Speech-to-Text
- **Text-to-Speech**: Google Cloud TTS
- **Calendar**: Google Calendar API (OAuth 2.0)
- **News**: WorldNewsAPI (Bosnia region)
- **Weather**: Google Weather API / OpenWeatherMap
- **Maps**: Google Maps API (Directions, Geocoding)
- **Food Delivery**: Glovo API, Wolt (local Bosnia services)
- **Calls/SMS**: Twilio Voice & SMS APIs
- **Notifications**: Firebase Cloud Messaging (FCM)

### Regional Support

Dona AI is optimized for Bosnia and Herzegovina with:
- Local news sources (WorldNewsAPI country code: `ba`)
- Weather data for Bosnian cities
- Integration with regional food delivery services (Glovo, Donesi)
- Native Bosnian language support with proper speech recognition

---

## Getting Started

### Prerequisites

- Flutter SDK (≥3.0.0)
- Dart SDK (≥3.0.0)
- Android Studio / Xcode for mobile development
- API keys for third-party services

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Dona
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API keys**
   Create `lib/config/api_keys.dart`:
   ```dart
   class ApiKeys {
     static const String claudeApiKey = 'your-claude-key';
     static const String openAiApiKey = 'your-openai-key';
     static const String googleCloudApiKey = 'your-google-key';
     static const String newsApiKey = 'your-news-api-key';
     static const String weatherApiKey = 'your-weather-key';
     // Add other API keys
   }
   ```

4. **Set up Firebase**
   - Add `google-services.json` (Android)
   - Add `GoogleService-Info.plist` (iOS)

5. **Run the app**
   ```bash
   flutter run
   ```

---

## Features in Detail

### 1. Conversational Interface

Dona uses natural language processing to understand commands:

```
User: "Schedule a meeting with John tomorrow at 3pm"
Dona: "I've scheduled a meeting with John for tomorrow at 3:00 PM."

User: "What's the weather like?"
Dona: "It's currently 22°C and sunny in Sarajevo. Perfect day!"

User: "Order pizza for dinner"
Dona: "I'll order your usual pizza from Pizza Place. Confirm?"
```

### 2. Proactive Morning Briefing

Every morning, Dona provides:
- Weather forecast
- Calendar events for the day
- Top news headlines (Bosnia & international)
- Personalized reminders

### 3. Task Automation

- **Calendar Management**: Create, update, delete events
- **Reminders**: Set time-based or location-based reminders
- **Calls & Messages**: Initiate calls or send SMS via voice
- **Food Ordering**: Place orders with local delivery services
- **Navigation**: Get directions and ETAs

### 4. Learning & Personalization

Dona learns from your interactions:
- Recognizes daily routines
- Suggests actions based on habits
- Remembers preferences (favorite restaurants, meeting patterns)
- Adapts conversation style to your tone

---

## Development Roadmap

### Phase 1: MVP (Current)
- ✅ Flutter project setup
- ✅ Basic UI/UX design
- 🔄 LLM integration (Claude/GPT-4)
- 🔄 Speech-to-text & text-to-speech
- 🔄 Calendar API integration
- 🔄 News & Weather APIs

### Phase 2: Core Features
- Voice command processing
- Task automation (scheduling, reminders)
- Push notifications
- Local data storage

### Phase 3: Advanced Features
- Food ordering integration
- Learning & personalization ML
- Multi-language refinement
- Voice customization

### Phase 4: Polish & Launch
- Comprehensive testing (Bosnian & English)
- Performance optimization
- Security audit
- Google Play & App Store release

---

## Privacy & Security

Dona AI takes privacy seriously:

- ✅ **GDPR Compliant**: Full compliance with EU data protection regulations
- ✅ **Encrypted Storage**: All local data encrypted at rest
- ✅ **Secure Communication**: HTTPS for all API calls
- ✅ **Permission-Based**: Explicit user consent for sensitive operations
- ✅ **Data Control**: Users can delete all data at any time
- ✅ **On-Device Processing**: Voice processing done locally when possible

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

[License TBD]

---

## Contact & Support

For questions or support:
- Create an issue in this repository
- Email: [contact email]

---

**Built with ❤️ using Flutter and AI**
