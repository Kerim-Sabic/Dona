# Dona AI - Testing Guide

## Quick Start Testing

All API keys have been configured and are ready to test!

### Configured APIs

✅ **DeepSeek AI** - Chat/Conversation AI
✅ **WorldNewsAPI** - Bosnia & international news
✅ **OpenWeatherMap** - Weather forecasts
✅ **Google Cloud** - Speech services (ready for integration)

---

## Running the App

### Prerequisites

Make sure you have Flutter installed:
```bash
flutter --version
```

### Run on Device/Emulator

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

Or for a specific platform:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (for quick testing)
flutter run -d chrome
```

---

## Testing Features

### 1. Chat/AI Integration (DeepSeek) ✅

**How to test:**
1. Launch the app
2. Tap the big blue "Tap to speak" button on home screen
3. Or tap the chat icon and type a message
4. Try these sample prompts:
   - "Hello, tell me about yourself"
   - "What can you help me with?"
   - "Tell me a joke"
   - "What's the weather like?" (tests intent extraction)

**Expected behavior:**
- User message appears in blue bubble on right
- "Processing..." status shows briefly
- Dona responds with personality (professional, witty, helpful)
- Conversation history is maintained

**Troubleshooting:**
- If you get an error, check internet connection
- Check console logs for API errors
- DeepSeek API key should be valid

---

### 2. News Feed (WorldNewsAPI) ✅

**How to test:**
1. From home screen, tap "News" card
2. Wait for news to load (Bosnia-focused content)
3. Scroll through articles
4. Tap an article to open in browser
5. Pull down to refresh

**Expected behavior:**
- Shows top 20 news articles
- Articles are from Bosnian and international sources
- Each card shows: source, title, description, date
- "Read more" button opens article in external browser
- Refresh icon reloads news

**Sample response:**
- News about Bosnia economy, politics, culture
- International tech/business news
- Articles with timestamps ("2h ago", "1d ago")

**Troubleshooting:**
- If no news loads, check API key
- Pull down to refresh manually
- Check console for API errors

---

### 3. Weather (OpenWeatherMap) ✅

**How to test:**
1. From home screen, tap "Weather" card
2. Default city is Sarajevo
3. View current weather and forecast
4. Tap search icon to change city
5. Try different cities: Banja Luka, Mostar, Tuzla

**Expected behavior:**
- Large temperature display with current conditions
- Weather details: humidity, wind, pressure, cloudiness
- Horizontal scrollable forecast (next 8 entries)
- Each forecast shows time, temp, description
- Search allows changing city

**Sample data:**
```
Sarajevo
22°C
PARTLY CLOUDY
Feels like 21°C

Details:
Min/Max: 18° / 25°
Humidity: 65%
Wind: 3.5 m/s N
Pressure: 1013 hPa
```

**Troubleshooting:**
- If weather doesn't load, check internet
- Try refreshing with refresh icon
- Verify city name spelling

---

### 4. Home Screen

**How to test:**
1. Launch app
2. Check greeting changes based on time:
   - Before 12pm: "Good Morning"
   - 12pm-5pm: "Good Afternoon"
   - After 5pm: "Good Evening"
3. Test all Quick Action cards:
   - News → Opens news screen ✅
   - Weather → Opens weather screen ✅
   - Calendar → Shows "coming soon" message
   - Food Ordering → Shows "coming soon" message

---

## API Testing from Code

### Test AI Service Directly

Create a test file or use Dart console:

```dart
import 'package:dona_ai/services/ai/ai_service.dart';

void testAI() async {
  final aiService = AIService.instance;

  final response = await aiService.chat('Hello Dona!');
  print('AI Response: $response');
}
```

### Test News Service

```dart
import 'package:dona_ai/services/news/news_service.dart';

void testNews() async {
  final newsService = NewsService.instance;

  final articles = await newsService.getTopNews();
  print('Fetched ${articles.length} articles');

  if (articles.isNotEmpty) {
    print('First article: ${articles.first.title}');
  }
}
```

### Test Weather Service

```dart
import 'package:dona_ai/services/weather/weather_service.dart';

void testWeather() async {
  final weatherService = WeatherService.instance;

  final weather = await weatherService.getCurrentWeather(city: 'Sarajevo');
  if (weather != null) {
    print('${weather.cityName}: ${weather.temperature}°C');
    print('Conditions: ${weather.description}');
  }
}
```

---

## Common Issues & Solutions

### Issue: "Failed to fetch..."

**Solution:**
- Check internet connection
- Verify API keys are correct in `lib/config/api_keys.dart`
- Check API service status (DeepSeek, WorldNewsAPI, OpenWeatherMap)
- Look at console logs for specific error messages

### Issue: App won't build

**Solution:**
```bash
# Clean build
flutter clean

# Get dependencies again
flutter pub get

# Rebuild
flutter run
```

### Issue: API returns 401/403 errors

**Solution:**
- API key is invalid or expired
- Check API key format
- Verify API key has proper permissions
- Check API rate limits

### Issue: News/Weather shows mock data

**Solution:**
- This is expected behavior when API fails
- Check logs to see actual error
- Verify API endpoints are reachable
- Check API documentation for changes

---

## Expected Log Output

### Successful AI Chat
```
[INFO] AIService initialized with DeepSeek API
[DEBUG] Sending message to DeepSeek AI: Hello
[INFO] Received AI response
```

### Successful News Fetch
```
[INFO] NewsService initialized with WorldNewsAPI
[DEBUG] Fetching top news for country: ba
[INFO] Fetched 20 news articles
```

### Successful Weather Fetch
```
[INFO] WeatherService initialized with OpenWeatherMap API
[DEBUG] Fetching current weather for: Sarajevo
[INFO] Fetched weather for Sarajevo
```

---

## Testing Checklist

Before considering the app fully tested:

- [ ] AI Chat responds correctly
- [ ] Conversation history is maintained
- [ ] News loads from Bosnia region
- [ ] News articles open in browser
- [ ] Weather shows current conditions
- [ ] Weather forecast displays
- [ ] City search works in weather
- [ ] All navigation works (home ↔ chat ↔ news ↔ weather)
- [ ] Settings screen opens
- [ ] App handles errors gracefully
- [ ] Pull-to-refresh works
- [ ] Loading indicators show properly

---

## Next Steps After Testing

Once basic features are tested and working:

1. **Add Speech Integration**
   - Implement Google Cloud Speech-to-Text
   - Add Text-to-Speech for voice responses
   - Test with Bosnian language

2. **Calendar Integration**
   - Implement Google Calendar API
   - OAuth authentication
   - Event creation/management

3. **Enhanced AI Features**
   - Intent-based routing (news/weather commands)
   - Proactive suggestions
   - Multi-turn conversations

4. **UI/UX Polish**
   - Add animations
   - Improve error messages
   - Better loading states
   - Voice waveform visualizations

5. **Offline Support**
   - Cache recent data
   - Queue failed requests
   - Better offline indicators

---

## Performance Testing

### Memory Usage
```bash
flutter run --profile
# Use DevTools to monitor memory
```

### Network Requests
- Monitor API call frequency
- Check for unnecessary requests
- Verify caching works

### Battery Impact
- Test on real device
- Monitor background activity
- Check wake locks

---

## API Rate Limits

Be aware of API limits during testing:

| API | Free Tier Limit |
|-----|----------------|
| DeepSeek | Check account |
| WorldNewsAPI | 100 requests/day |
| OpenWeatherMap | 1000 requests/day |

**Tip:** If you hit rate limits during testing, the app will show mock data instead of crashing.

---

## Feedback & Issues

If you encounter any issues:

1. Check console logs first
2. Verify API keys are correct
3. Check internet connection
4. Review this guide's troubleshooting section
5. Check API service status pages

**Happy Testing! 🚀**
