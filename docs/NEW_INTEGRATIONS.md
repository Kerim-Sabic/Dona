# 🚀 New API Integrations Guide

This document provides detailed information about the newly integrated APIs in Dona AI.

---

## 📧 Gmail API

### Overview
The Gmail API integration allows Dona to read, send, and manage emails on behalf of users.

### Features
- ✅ Read inbox messages
- ✅ Send emails
- ✅ Mark messages as read/unread
- ✅ Search emails
- ✅ OAuth 2.0 authentication

### Usage Example

```dart
import 'package:dona_ai/services/gmail/gmail_service.dart';

// Initialize
await GmailService.instance.init();

// Authenticate (opens browser for OAuth)
await GmailService.instance.authenticate();

// Or set token manually
await GmailService.instance.setAccessToken('your-token');

// Get inbox messages
final messages = await GmailService.instance.getInboxMessages(maxResults: 20);

// Send an email
final email = EmailMessage(
  to: ['recipient@example.com'],
  subject: 'Hello from Dona AI',
  body: 'This is a test email from Dona AI!',
);
await GmailService.instance.sendEmail(email);

// Mark as read
await GmailService.instance.markAsRead(messageId);
```

### Setup
1. Enable Gmail API in Google Cloud Console
2. Add the required scopes to your OAuth consent screen
3. Obtain OAuth 2.0 credentials (already configured in api_keys.dart)

---

## ✅ Google Tasks API

### Overview
Manage tasks and to-do lists with Google Tasks integration.

### Features
- ✅ Get all task lists
- ✅ Get tasks from a specific list
- ✅ Create new tasks
- ✅ Update tasks
- ✅ Complete tasks
- ✅ Delete tasks
- ✅ Support for subtasks

### Usage Example

```dart
import 'package:dona_ai/services/google_tasks/google_tasks_service.dart';

// Initialize
await GoogleTasksService.instance.init();

// Get all task lists
final taskLists = await GoogleTasksService.instance.getTaskLists();

// Get tasks from a list
final tasks = await GoogleTasksService.instance.getTasks(
  taskLists.first.id,
  showCompleted: false,
);

// Create a task
final newTask = GoogleTask(
  title: 'Buy groceries',
  notes: 'Milk, bread, eggs',
  due: DateTime.now().add(Duration(days: 1)),
);
await GoogleTasksService.instance.createTask(taskLists.first.id, newTask);

// Complete a task
await GoogleTasksService.instance.completeTask(taskListId, taskId);
```

### Setup
1. Enable Google Tasks API in Google Cloud Console
2. Add the required scopes to your OAuth consent screen

---

## 📁 Google Drive API

### Overview
Access and manage files in Google Drive.

### Features
- ✅ List files
- ✅ Search files
- ✅ Upload files
- ✅ Download files
- ✅ Create folders
- ✅ Delete files
- ✅ Get recent files
- ✅ Get starred files

### Usage Example

```dart
import 'package:dona_ai/services/google_drive/google_drive_service.dart';
import 'dart:typed_data';

// Initialize
await GoogleDriveService.instance.init();

// List recent files
final files = await GoogleDriveService.instance.getRecentFiles(limit: 20);

// Search files
final searchResults = await GoogleDriveService.instance.searchFiles('project');

// Upload a file
final fileContent = Uint8List.fromList([...]); // Your file bytes
final uploadedFile = await GoogleDriveService.instance.uploadFile(
  fileName: 'document.pdf',
  fileContent: fileContent,
  mimeType: 'application/pdf',
);

// Download a file
final downloadedBytes = await GoogleDriveService.instance.downloadFile(fileId);

// Create a folder
final folder = await GoogleDriveService.instance.createFolder('My Folder');
```

### Setup
1. Enable Google Drive API in Google Cloud Console
2. Add the required scopes to your OAuth consent screen

---

## 🗺️ Google Maps API

### Overview
Comprehensive Google Maps integration with multiple services.

### Enabled Services
- ✅ Directions API - Get routes between locations
- ✅ Places API - Search for nearby places
- ✅ Geocoding API - Convert addresses to coordinates and vice versa
- ✅ Distance Matrix API - Calculate distances between multiple points
- ✅ Roads API - Snap GPS points to roads
- ✅ Air Quality API - Get air quality data (placeholder)
- ✅ Pollen API - Get pollen data (coming soon)

### Usage Example

```dart
import 'package:dona_ai/services/google_maps/google_maps_service.dart';

// Initialize
await GoogleMapsService.instance.init();

// Get directions
final route = await GoogleMapsService.instance.getDirections(
  origin: 'Sarajevo, Bosnia',
  destination: 'Mostar, Bosnia',
  travelMode: 'driving',
);
print('Distance: ${route?.distanceFormatted}');
print('Duration: ${route?.durationFormatted}');

// Search nearby places
final places = await GoogleMapsService.instance.searchNearbyPlaces(
  latitude: 43.8563,
  longitude: 18.4131,
  type: 'restaurant',
  radius: 1500,
);

// Geocode an address
final location = await GoogleMapsService.instance.geocodeAddress(
  'Baščaršija, Sarajevo',
);

// Reverse geocode coordinates
final address = await GoogleMapsService.instance.reverseGeocode(
  43.8563,
  18.4131,
);

// Snap points to roads
final points = [
  PlaceLocation(lat: 43.856, lng: 18.413),
  PlaceLocation(lat: 43.857, lng: 18.414),
];
final snappedPoints = await GoogleMapsService.instance.snapToRoads(points);
```

### Setup
1. Get API key from Google Cloud Console
2. Enable the following APIs:
   - Directions API
   - Places API
   - Geocoding API
   - Distance Matrix API
   - Roads API
3. Configure API key in `lib/config/api_keys.dart`

### API Key Configuration
The same API key is used for all Google Maps services. Make sure to enable the required APIs in your Google Cloud project.

---

## 📱 Twilio API (Voice & SMS)

### Overview
Send SMS messages and make phone calls using Twilio.

### Features
- ✅ Send SMS messages
- ✅ Make phone calls
- ✅ Get message status
- ✅ Get call status
- ✅ Get recent messages
- ✅ Get recent calls
- ✅ TwiML generation for voice calls

### Usage Example

```dart
import 'package:dona_ai/services/twilio/twilio_service.dart';

// Initialize
await TwilioService.instance.init();

// Send SMS
final sms = await TwilioService.instance.sendSms(
  to: '+38761234567',
  message: 'Hello from Dona AI!',
);

// Check SMS status
if (sms?.isDelivered == true) {
  print('Message delivered!');
}

// Make a phone call (requires TwiML endpoint)
final call = await TwilioService.instance.makeCall(
  to: '+38761234567',
  twimlUrl: 'https://your-server.com/twiml',
);

// Get SMS status
final status = await TwilioService.instance.getSmsStatus(sms!.sid!);

// Get recent messages
final messages = await TwilioService.instance.getRecentMessages(limit: 20);

// Verify credentials
final isValid = await TwilioService.instance.verifyCredentials();
```

### TwiML for Voice Calls
To make voice calls with text-to-speech, you need to host TwiML (Twilio Markup Language) on your server:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="alice" language="en-US">Hello! This is Dona AI calling.</Say>
</Response>
```

Alternatively, use Twilio TwiML Bins to host your TwiML without a server.

### Setup
1. Create a Twilio account at https://www.twilio.com
2. Get your Account SID and Auth Token from the Twilio Console
3. Purchase a Twilio phone number
4. Configure credentials in `lib/config/api_keys.dart`

---

## 🔐 Security Best Practices

### API Keys Management

1. **Never commit api_keys.dart**
   - Already in .gitignore
   - Use api_keys.dart.template for reference

2. **Use environment variables in production**
   ```dart
   static const String apiKey = String.fromEnvironment('API_KEY');
   ```

3. **Rotate API keys regularly**
   - Google Cloud Console
   - Twilio Console

4. **Use OAuth 2.0 for Google services**
   - More secure than API keys
   - User can revoke access anytime
   - Limited scopes

### OAuth 2.0 Flow

For Google services (Gmail, Calendar, Tasks, Drive):

1. User clicks "Sign in with Google"
2. Browser opens OAuth consent screen
3. User grants permissions
4. Access token is returned
5. Token is stored securely (LocalStorage)
6. Token is refreshed when expired

---

## 📊 API Usage & Limits

### Google Cloud APIs
- **Gmail API**: 1 billion quota units/day (Free tier)
- **Google Tasks API**: Unlimited (Free)
- **Google Drive API**: 1 billion queries/day (Free tier)
- **Google Maps APIs**: Varies by service (Most have free tier)

### Twilio
- **Free Trial**: $15 credit
- **SMS**: ~$0.0075 per message
- **Voice**: ~$0.013 per minute
- **Paid plans available**

### Rate Limiting
All services implement automatic retry with exponential backoff for rate limit errors.

---

## 🧪 Testing

### Unit Tests
```bash
flutter test test/services/
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing
1. Copy api_keys.dart.template to api_keys.dart
2. Fill in your API keys
3. Run the app
4. Test each service independently

---

## 🐛 Troubleshooting

### Gmail API

**Error: "Access denied"**
- Check OAuth scopes in Google Cloud Console
- Re-authenticate user

**Error: "Quota exceeded"**
- Check quota limits in Google Cloud Console
- Implement caching to reduce API calls

### Google Maps API

**Error: "REQUEST_DENIED"**
- Check if API is enabled in Google Cloud Console
- Verify API key is correct
- Check if billing is enabled (required for some APIs)

**Error: "ZERO_RESULTS"**
- Check if location/address is valid
- Try different search parameters

### Twilio

**Error: "Authentication failed"**
- Verify Account SID and Auth Token
- Check if credentials are correct

**Error: "Phone number not verified"**
- Verify phone numbers in Twilio Console (trial accounts)
- Upgrade to paid account for unrestricted use

---

## 📚 Additional Resources

### Documentation
- [Gmail API Docs](https://developers.google.com/gmail/api)
- [Google Tasks API Docs](https://developers.google.com/tasks)
- [Google Drive API Docs](https://developers.google.com/drive)
- [Google Maps API Docs](https://developers.google.com/maps)
- [Twilio Docs](https://www.twilio.com/docs)

### Code Examples
- Check `lib/services/` for implementation details
- See inline comments for usage examples
- Review test files for comprehensive examples

---

## 🎯 Next Steps

1. **Implement UI screens** for each service
2. **Add AI integration** to control services via voice
3. **Create workflows** combining multiple services
4. **Add offline support** with local caching
5. **Implement push notifications** for new emails, tasks, etc.

---

**Happy coding! 🚀**
