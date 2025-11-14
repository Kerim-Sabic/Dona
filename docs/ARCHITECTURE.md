# Dona AI - Architecture Documentation

## Overview

Dona AI follows a clean architecture pattern with clear separation of concerns across three main layers:

1. **Presentation Layer** - UI and user interactions
2. **Domain Layer** - Business logic and use cases
3. **Data Layer** - Data management and external services

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Screens │  │  Widgets │  │   BLoC   │  │   UI     │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────┐  │
│  │ Entities │  │ Use Cases│  │ Repository Interfaces    │  │
│  └──────────┘  └──────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Models  │  │Repository│  │DataSource│  │ Services │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Layer Details

### 1. Presentation Layer

**Location:** `lib/presentation/`

**Responsibilities:**
- Display UI to users
- Handle user interactions
- Manage UI state with BLoC
- Navigate between screens

**Components:**
- **Screens:** Full-page views (Home, Chat, Settings, etc.)
- **Widgets:** Reusable UI components
- **BLoC:** State management using the BLoC pattern

**Key Screens:**
- `HomeScreen` - Main dashboard with quick actions
- `ChatScreen` - Conversational interface
- `SettingsScreen` - App configuration
- `OnboardingScreen` - First-time user experience

### 2. Domain Layer

**Location:** `lib/domain/`

**Responsibilities:**
- Define business entities
- Implement business logic
- Define repository contracts (interfaces)
- Contain use cases (single-responsibility business operations)

**Components:**
- **Entities:** Pure business objects (e.g., Message, CalendarEvent, NewsItem)
- **Use Cases:** Specific business operations (e.g., SendMessage, ScheduleEvent)
- **Repositories (Interfaces):** Contracts for data access

**Example Use Cases:**
- `SendMessageUseCase` - Send a message to the AI
- `ScheduleEventUseCase` - Create a calendar event
- `GetWeatherUseCase` - Fetch weather information
- `OrderFoodUseCase` - Place a food order

### 3. Data Layer

**Location:** `lib/data/`

**Responsibilities:**
- Implement repository interfaces
- Manage data sources (local and remote)
- Handle data transformations (models ↔ entities)
- Cache and persist data

**Components:**
- **Models:** Data transfer objects with JSON serialization
- **Repositories (Implementations):** Concrete implementations of domain repositories
- **DataSources:** Local (SQLite, SharedPreferences) and Remote (API clients)

## Services Layer

**Location:** `lib/services/`

**Purpose:** External integrations and platform-specific functionality

**Services:**

### AI Service (`ai/`)
- AI/LLM integration (Claude, GPT-4)
- Natural language understanding
- Intent extraction
- Context management

### Speech Service (`speech/`)
- Speech-to-text (Google Cloud Speech API)
- Text-to-speech (Google Cloud TTS)
- Voice input handling
- Audio playback

### Calendar Service (`calendar/`)
- Google Calendar API integration
- Event CRUD operations
- OAuth authentication
- Sync management

### News Service (`news/`)
- News API integration (WorldNewsAPI)
- Bosnia-specific news filtering
- Article parsing and summarization

### Weather Service (`weather/`)
- Weather API integration (Google Weather / OpenWeatherMap)
- Location-based forecasts
- Weather alerts

### Location Service (`location/`)
- GPS location tracking
- Geocoding and reverse geocoding
- Google Maps integration
- Navigation and directions

### Notification Service (`notifications/`)
- Firebase Cloud Messaging
- Local notifications
- Push notification handling
- Notification scheduling

### Storage Service (`storage/`)
- Local data persistence (SharedPreferences, SQLite, Hive)
- Secure storage for sensitive data
- Cache management

## State Management

**Pattern:** BLoC (Business Logic Component)

**Libraries:**
- `flutter_bloc` - Core BLoC implementation
- `provider` - Dependency injection

**BLoC Structure:**
```dart
// Event
abstract class ChatEvent {}
class SendMessage extends ChatEvent {
  final String message;
  SendMessage(this.message);
}

// State
abstract class ChatState {}
class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final List<Message> messages;
  ChatLoaded(this.messages);
}
class ChatError extends ChatState {
  final String error;
  ChatError(this.error);
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AIService aiService;

  ChatBloc(this.aiService) : super(ChatInitial()) {
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    // Business logic here
  }
}
```

## Data Flow

### Example: Sending a Chat Message

1. **User Action** → User types and sends a message
2. **Presentation Layer** → `ChatScreen` captures input
3. **BLoC Event** → Dispatches `SendMessage` event to `ChatBloc`
4. **Use Case** → `ChatBloc` calls `SendMessageUseCase`
5. **Repository** → Use case calls `MessageRepository`
6. **Data Source** → Repository uses `AIService` to send message
7. **API Call** → `AIService` calls Claude/GPT API
8. **Response** → API response flows back through layers
9. **State Update** → `ChatBloc` emits new `ChatLoaded` state
10. **UI Update** → `ChatScreen` rebuilds with new messages

```
User Input → ChatScreen → ChatBloc → SendMessageUseCase
    ↓
MessageRepository → AIService → Claude API
    ↓
Response ← Response ← Response ← Response
    ↓
ChatBloc (new state) → ChatScreen (rebuild)
```

## Key Design Patterns

### 1. Repository Pattern
- Abstracts data sources
- Allows easy swapping of implementations
- Testable with mock repositories

### 2. Dependency Injection
- Services injected via constructors
- Managed by `provider` package
- Enables testing with mocks

### 3. Singleton Pattern
- Used for service instances
- Ensures single instance of services (e.g., `AIService.instance`)

### 4. Observer Pattern
- BLoC uses streams for state changes
- UI observes state and rebuilds reactively

## API Integration Strategy

### Authentication
- OAuth 2.0 for Google Calendar
- API keys for third-party services (stored securely)
- Token refresh handling

### Error Handling
- Try-catch blocks in service layers
- Custom exceptions for business logic errors
- User-friendly error messages in UI

### Offline Support
- Local caching of recent data
- Queue for pending operations
- Sync when connection restored

### Rate Limiting
- Respect API rate limits
- Implement request throttling
- Cache frequently accessed data

## Security Considerations

### Data Encryption
- Sensitive data encrypted at rest (using `flutter_secure_storage`)
- HTTPS for all network requests
- API keys not committed to version control

### Permissions
- Request permissions only when needed
- Explain why permissions are required
- Handle permission denials gracefully

### Privacy
- GDPR compliance
- User consent for data collection
- Data deletion on user request
- Local processing where possible

## Testing Strategy

### Unit Tests
- Test business logic in isolation
- Mock dependencies
- High coverage for use cases

### Widget Tests
- Test individual widgets
- Verify UI behavior
- Test user interactions

### Integration Tests
- End-to-end workflows
- Test API integrations
- Test state management flow

### Mocking
```dart
class MockAIService extends Mock implements AIService {}

void main() {
  late ChatBloc chatBloc;
  late MockAIService mockAIService;

  setUp(() {
    mockAIService = MockAIService();
    chatBloc = ChatBloc(mockAIService);
  });

  test('should emit ChatLoaded when message is sent', () async {
    // Test implementation
  });
}
```

## Performance Optimization

### Lazy Loading
- Load data on demand
- Paginate large lists
- Defer heavy operations

### Caching
- Cache API responses
- Cache images and assets
- Invalidate stale cache

### Code Splitting
- Lazy import heavy packages
- Use deferred loading for rarely used features

### Build Optimization
- Use `const` constructors
- Minimize rebuilds with `keys`
- Profile with Flutter DevTools

## Future Enhancements

1. **Machine Learning Integration**
   - On-device personalization with TensorFlow Lite
   - User habit prediction
   - Smart suggestions

2. **Advanced Voice**
   - Wake word detection ("Hey Dona")
   - Continuous conversation mode
   - Voice biometrics

3. **Multi-Device Sync**
   - Cloud sync across devices
   - Real-time synchronization
   - Conflict resolution

4. **Plugin Architecture**
   - Extensible with custom plugins
   - Third-party integrations
   - Community contributions

---

## References

- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Repository Pattern](https://docs.flutter.dev/data-and-backend/state-mgmt/options#repository-pattern)
