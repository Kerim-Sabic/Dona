# API Integrations Guide

## Overview

This document outlines all third-party API integrations required for Dona AI.

## Required APIs

### 1. AI/LLM Services

#### Anthropic Claude API
- **Purpose**: Natural language understanding and conversation
- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Authentication**: API Key
- **Setup**:
  ```bash
  # Add to lib/config/api_keys.dart
  static const String claudeApiKey = 'sk-ant-...';
  ```
- **Documentation**: https://docs.anthropic.com/

#### OpenAI API (Alternative)
- **Purpose**: GPT-4 for conversation
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Authentication**: Bearer token
- **Documentation**: https://platform.openai.com/docs/api-reference

---

### 2. Speech Services

#### Google Cloud Speech-to-Text
- **Purpose**: Convert voice to text (Bosnian & English)
- **Endpoint**: `https://speech.googleapis.com/v1/speech:recognize`
- **Authentication**: OAuth 2.0 / API Key
- **Languages**: `en-US`, `bs-BA`
- **Setup**:
  ```bash
  # Enable in Google Cloud Console
  # Add service account JSON to project
  ```
- **Documentation**: https://cloud.google.com/speech-to-text/docs

#### Google Cloud Text-to-Speech
- **Purpose**: Convert text to natural speech
- **Endpoint**: `https://texttospeech.googleapis.com/v1/text:synthesize`
- **Authentication**: OAuth 2.0 / API Key
- **Voices**: Standard, WaveNet, Neural2
- **Documentation**: https://cloud.google.com/text-to-speech/docs

---

### 3. Calendar Integration

#### Google Calendar API
- **Purpose**: Manage user calendar events
- **Endpoint**: `https://www.googleapis.com/calendar/v3/`
- **Authentication**: OAuth 2.0
- **Scopes**:
  - `https://www.googleapis.com/auth/calendar` (Full access)
  - `https://www.googleapis.com/auth/calendar.events` (Events only)
- **Setup**:
  ```dart
  // 1. Enable Google Calendar API in Cloud Console
  // 2. Configure OAuth consent screen
  // 3. Add credentials (OAuth 2.0 Client ID)
  // 4. Use googleapis package
  import 'package:googleapis/calendar/v3.dart';
  ```
- **Documentation**: https://developers.google.com/calendar/api/guides/overview

---

### 4. News API

#### WorldNewsAPI
- **Purpose**: Fetch Bosnia & international news
- **Endpoint**: `https://api.worldnewsapi.com/`
- **Authentication**: API Key (X-Api-Key header)
- **Bosnia Filter**: `source-country=ba`
- **Features**:
  - Top headlines
  - Search news
  - Category filtering
- **Example Request**:
  ```bash
  GET https://api.worldnewsapi.com/top-news?source-country=ba&language=en
  Headers: X-Api-Key: YOUR_API_KEY
  ```
- **Pricing**: Free tier available
- **Documentation**: https://worldnewsapi.com/docs

---

### 5. Weather API

#### Google Weather API (Maps Platform)
- **Purpose**: Get weather forecasts for Bosnia
- **Endpoint**: Part of Google Maps Platform
- **Authentication**: API Key
- **Coverage**: Bosnia and Herzegovina supported
- **Documentation**: https://developers.google.com/maps/documentation/weather

#### OpenWeatherMap API (Alternative)
- **Purpose**: Weather data and forecasts
- **Endpoint**: `https://api.openweathermap.org/data/2.5/`
- **Authentication**: API Key (appid parameter)
- **Endpoints**:
  - Current weather: `/weather`
  - 5-day forecast: `/forecast`
  - Weather alerts: `/onecall`
- **Example Request**:
  ```bash
  GET https://api.openweathermap.org/data/2.5/weather?q=Sarajevo&appid=YOUR_API_KEY&units=metric
  ```
- **Pricing**: Free tier (1000 calls/day)
- **Documentation**: https://openweathermap.org/api

---

### 6. Maps & Location

#### Google Maps API
- **Purpose**: Geocoding, directions, navigation
- **APIs Needed**:
  - **Geocoding API**: Address ↔ Coordinates
  - **Directions API**: Routes and ETAs
  - **Places API**: POI search
- **Authentication**: API Key
- **Setup**:
  ```yaml
  # In pubspec.yaml
  dependencies:
    google_maps_flutter: ^2.5.3
  ```
- **Documentation**: https://developers.google.com/maps/documentation

---

### 7. Food Delivery

#### Glovo API (Bosnia)
- **Purpose**: Order food from Glovo
- **Type**: Partner API (requires business account)
- **Coverage**: Sarajevo, Banja Luka, other cities
- **Authentication**: API Key / OAuth
- **Features**:
  - Browse restaurants
  - Place orders
  - Track delivery
- **Setup**: Contact Glovo for partner API access
- **Documentation**: https://glovoapp.com/en/partners

#### Wolt API (Alternative)
- **Purpose**: Food delivery
- **Coverage**: Bosnia region
- **Note**: May require deep links if API not available

---

### 8. Communications

#### Twilio Voice & SMS API
- **Purpose**: Make calls and send SMS programmatically
- **Endpoints**:
  - Voice: `https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Calls.json`
  - SMS: `https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json`
- **Authentication**: Account SID + Auth Token (Basic Auth)
- **Features**:
  - Outbound calls
  - SMS sending
  - Voice recordings
  - Call tracking
- **Pricing**: Pay-as-you-go
- **Documentation**: https://www.twilio.com/docs/usage/api

---

### 9. Push Notifications

#### Firebase Cloud Messaging (FCM)
- **Purpose**: Send push notifications
- **Platform**: Android & iOS
- **Authentication**: Service account JSON
- **Setup**:
  ```bash
  # 1. Create Firebase project
  # 2. Add Android app (download google-services.json)
  # 3. Add iOS app (download GoogleService-Info.plist)
  # 4. Enable Cloud Messaging in Firebase Console
  ```
- **Documentation**: https://firebase.google.com/docs/cloud-messaging

---

### 10. Translation (Optional)

#### Google Cloud Translation API
- **Purpose**: Translate between Bosnian and English
- **Endpoint**: `https://translation.googleapis.com/language/translate/v2`
- **Authentication**: API Key
- **Languages**: `bs` (Bosnian), `en` (English)
- **Documentation**: https://cloud.google.com/translate/docs

---

## API Keys Configuration

### Development Setup

1. Create `lib/config/api_keys.dart`:

```dart
class ApiKeys {
  // AI/LLM
  static const String claudeApiKey = 'YOUR_CLAUDE_KEY';
  static const String openAiApiKey = 'YOUR_OPENAI_KEY';

  // Google Cloud
  static const String googleCloudApiKey = 'YOUR_GOOGLE_CLOUD_KEY';

  // News
  static const String newsApiKey = 'YOUR_WORLDNEWS_KEY';

  // Weather
  static const String weatherApiKey = 'YOUR_WEATHER_KEY';

  // Maps
  static const String googleMapsApiKey = 'YOUR_MAPS_KEY';

  // Communications
  static const String twilioAccountSid = 'YOUR_TWILIO_SID';
  static const String twilioAuthToken = 'YOUR_TWILIO_TOKEN';

  // Food Delivery
  static const String glovoApiKey = 'YOUR_GLOVO_KEY';
}
```

2. **Important**: Add `lib/config/api_keys.dart` to `.gitignore`

### Production Setup

Use environment variables or secure secret management:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get claudeApiKey => dotenv.env['CLAUDE_API_KEY']!;
  static String get googleCloudApiKey => dotenv.env['GOOGLE_CLOUD_API_KEY']!;
  // ...
}
```

---

## Rate Limits & Quotas

| API | Free Tier | Rate Limit |
|-----|-----------|------------|
| Claude API | Trial credits | TBD |
| OpenAI GPT-4 | Pay-as-you-go | 10k TPM |
| Google Cloud Speech | 60 min/month | 1 req/sec |
| Google Calendar | Free | 1M req/day |
| WorldNewsAPI | 100 req/day | TBD |
| OpenWeatherMap | 1000 req/day | 60 req/min |
| Twilio | Trial credit | TBD |

---

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for sensitive data
3. **Rotate keys regularly**
4. **Implement rate limiting** on client side
5. **Use HTTPS** for all API calls
6. **Validate API responses** before processing
7. **Handle errors gracefully**
8. **Log API usage** for monitoring

---

## Testing APIs

### Using Postman/cURL

Example: Test WorldNewsAPI
```bash
curl -X GET "https://api.worldnewsapi.com/top-news?source-country=ba&language=en" \
  -H "X-Api-Key: YOUR_API_KEY"
```

### Mock Responses for Development

Create mock services for offline development:

```dart
class MockNewsService implements NewsService {
  @override
  Future<List<NewsArticle>> getTopNews() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      NewsArticle(
        title: 'Sample News',
        description: 'This is a mock news article',
        // ...
      ),
    ];
  }
}
```

---

## Troubleshooting

### Common Issues

1. **401 Unauthorized**: Check API key is correct
2. **403 Forbidden**: Check API is enabled in console
3. **429 Too Many Requests**: Rate limit exceeded
4. **500 Server Error**: API service issue, retry with backoff

### Debug Logging

Enable detailed API logging:

```dart
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

---

## Next Steps

1. ✅ Register for required API keys
2. ✅ Set up Google Cloud project
3. ✅ Enable necessary APIs in Cloud Console
4. ✅ Configure OAuth 2.0 credentials
5. ✅ Test each API integration
6. ✅ Implement error handling
7. ✅ Set up monitoring and alerts
