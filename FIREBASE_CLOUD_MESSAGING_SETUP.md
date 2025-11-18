# 🔔 Firebase Cloud Messaging - Complete Setup Guide

## Where to Find Cloud Messaging in Firebase Console

Firebase has moved Cloud Messaging in recent updates. Here's where to find it:

### Location 1: Engage → Messaging
1. Open Firebase Console: https://console.firebase.google.com/
2. Select your `dona-ai` project
3. In left sidebar, click **"Engage"** (📢 icon)
4. Click **"Messaging"**
5. This is where you send manual notifications

### Location 2: Project Settings → Cloud Messaging Tab
1. Click **⚙️ Settings** icon (top-left)
2. Select **"Project settings"**
3. Click **"Cloud Messaging"** tab (at the top)
4. This shows your Server Key, Sender ID, and API configuration

---

## Do You Need to Configure Cloud Messaging?

### ✅ You DON'T Need Configuration If:
- You only want your app to receive notifications
- You're using Flutter's `firebase_messaging` package
- You have `google-services.json` and `GoogleService-Info.plist`

**You're already set up!** Just run `flutterfire configure` and you're done.

### ⚙️ You NEED Configuration If:
- You want to send notifications from a backend server
- You need the Server Key for API calls
- You want to set up iOS APNs certificates for production

---

## Enable Firebase Cloud Messaging API

If Cloud Messaging doesn't appear in Firebase Console:

### Step 1: Enable the API in Google Cloud Console
```bash
# Open in browser:
https://console.cloud.google.com/apis/library/fcm.googleapis.com
```

Or manually:
1. Go to: https://console.cloud.google.com/
2. Select your `dona-ai` project (top dropdown)
3. Click ☰ menu → **"APIs & Services"** → **"Library"**
4. Search: **"Firebase Cloud Messaging API"**
5. Click on **"Firebase Cloud Messaging API"**
6. Click **"Enable"** button
7. Wait 1-2 minutes for propagation

### Step 2: Verify in Firebase Console
1. Go back to Firebase Console
2. Refresh the page (Cmd/Ctrl + R)
3. Check **Engage → Messaging** (should now appear)

---

## Get Your Server Key & Sender ID

If you need to send notifications from a backend server:

### Option 1: Cloud Messaging Tab (Legacy)
1. Firebase Console → ⚙️ Settings → Project settings
2. Click **"Cloud Messaging"** tab
3. Scroll to **"Cloud Messaging API (Legacy)"**
4. Copy:
   - **Server key**: (for backend API calls)
   - **Sender ID**: (for frontend configuration)

### Option 2: Service Account Key (Recommended)
1. Firebase Console → ⚙️ Settings → Project settings
2. Click **"Service accounts"** tab
3. Click **"Generate new private key"**
4. Download JSON file (keep it secret!)
5. Use this for server-side Firebase Admin SDK

---

## iOS Push Notifications - APNs Configuration

For production iOS push notifications, you need Apple Push Notification service (APNs):

### Step 1: Create APNs Key in Apple Developer
1. Go to: https://developer.apple.com/account/
2. Click **"Certificates, Identifiers & Profiles"**
3. Click **"Keys"** (left sidebar)
4. Click **"+"** to create new key
5. Name it: `Dona AI APNs Key`
6. Check: ✅ **Apple Push Notifications service (APNs)**
7. Click **"Continue"** → **"Register"**
8. **Download the `.p8` file** (you can't download it again!)
9. Note your **Key ID** and **Team ID**

### Step 2: Upload APNs Key to Firebase
1. Firebase Console → ⚙️ Settings → Project settings
2. Click **"Cloud Messaging"** tab
3. Scroll to **"Apple app configuration"**
4. Click **"Upload"** under **"APNs Authentication Key"**
5. Upload your `.p8` file
6. Enter your **Key ID** and **Team ID**
7. Click **"Upload"**

### Step 3: Verify Configuration
1. Your iOS Bundle ID should show: `com.dona.ai`
2. APNs status should show: ✅ **Configured**

---

## Android Configuration (Already Done!)

Android is automatically configured when you added `google-services.json`. No extra steps needed!

✅ **Server Key**: Available in Cloud Messaging tab
✅ **Sender ID**: Available in Cloud Messaging tab
✅ **FCM Token**: Generated automatically by your app

---

## Testing Push Notifications

### Test from Firebase Console

1. **Go to Engage → Messaging**
2. Click **"New campaign"** or **"Send your first message"**
3. **Notification tab:**
   - Title: `Test Notification`
   - Text: `Dona AI is connected! 🚀`
4. Click **"Send test message"**
5. **Add FCM registration token:**
   - You'll need to get this from your app logs
   - Run your app first to generate the token
6. Click **"Test"**

### Get FCM Token from Your App

Add this temporarily to your `main.dart` to see the token:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get FCM token for testing
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();
  print('FCM Token: $token');  // Copy this token for testing

  runApp(DonaApp());
}
```

Run the app and check logs for `FCM Token: ...`

---

## Send Notifications from Code

If you want your app to schedule/send its own notifications:

### Local Notifications (No Server Needed)
Use `flutter_local_notifications` (already in your pubspec.yaml):

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings();
const InitializationSettings initializationSettings = InitializationSettings(
  android: initializationSettingsAndroid,
  iOS: initializationSettingsDarwin,
);

await flutterLocalNotificationsPlugin.initialize(initializationSettings);

// Show notification
const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
  'dona_channel',
  'Dona AI',
  channelDescription: 'Dona AI notifications',
  importance: Importance.max,
  priority: Priority.high,
);

const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

await flutterLocalNotificationsPlugin.show(
  0,
  'Task Reminder',
  'You have a meeting in 15 minutes',
  notificationDetails,
);
```

### Cloud Notifications from Backend
If you have a backend server (Node.js, Python, etc.):

**Using Firebase Admin SDK (Node.js example):**
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification
const message = {
  notification: {
    title: 'Task Reminder',
    body: 'You have a meeting in 15 minutes'
  },
  token: 'user_device_fcm_token_here'
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
  });
```

---

## Handle Incoming Notifications in Flutter

Add handlers in your `main.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Background handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission (iOS)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // Show local notification here
    }
  });

  // Handle when user taps notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!');
    // Navigate to relevant screen
  });

  runApp(DonaApp());
}
```

---

## Notification Channels (Android)

Define notification channels for Android (required for Android 8+):

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'dona_high_importance', // id
  'Dona AI Notifications', // name
  description: 'This channel is used for important Dona AI notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

---

## Troubleshooting

### "Cloud Messaging not found"
**Solution**: Enable Firebase Cloud Messaging API in Google Cloud Console

### "APNs certificate invalid" (iOS)
**Solution**:
1. Verify Bundle ID matches: `com.dona.ai`
2. Re-upload APNs `.p8` key
3. Verify Key ID and Team ID are correct

### "Notifications not received"
**Solution**:
1. Check app has notification permissions
2. Verify `google-services.json` / `GoogleService-Info.plist` are in correct locations
3. Check Firebase token is valid (print it in logs)
4. Ensure app is in foreground/background (not killed)

### "MissingPluginException"
**Solution**:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## Security Best Practices

### Don't Commit Sensitive Files
Verify `.gitignore` includes:
```gitignore
# Firebase
google-services.json
GoogleService-Info.plist
firebase_options.dart  # Sometimes
**/serviceAccountKey.json

# APNs
*.p8
*.p12
```

### Server Key Security
- **NEVER** expose Server Key in client code
- Only use Server Key on backend servers
- Use Firebase Admin SDK with service account JSON
- Rotate keys if exposed

### User Privacy
- Always request notification permissions
- Allow users to opt-out
- Don't send sensitive data in notification body (only in `data` payload)
- Use notification channels for user control (Android)

---

## Summary Checklist

- [ ] Firebase Cloud Messaging API enabled in Google Cloud Console
- [ ] Android: `google-services.json` in `android/app/`
- [ ] iOS: `GoogleService-Info.plist` in `ios/Runner/`
- [ ] iOS: APNs key uploaded to Firebase (for production)
- [ ] Code: `firebase_messaging` package installed
- [ ] Code: Background handler registered
- [ ] Code: Permission requested (iOS)
- [ ] Code: Message listeners set up
- [ ] Testing: FCM token printed in logs
- [ ] Testing: Test notification sent from Firebase Console
- [ ] Testing: App receives notification ✅

---

## Resources

- **Firebase Cloud Messaging Docs**: https://firebase.google.com/docs/cloud-messaging
- **FlutterFire Messaging**: https://firebase.flutter.dev/docs/messaging/overview
- **Apple APNs Guide**: https://developer.apple.com/documentation/usernotifications
- **Firebase Admin SDK**: https://firebase.google.com/docs/admin/setup
- **Notification Best Practices**: https://firebase.google.com/docs/cloud-messaging/best-practices

---

## Quick Commands

```bash
# Enable FCM API
gcloud services enable fcm.googleapis.com --project=dona-ai

# Test notification from command line (requires Server Key)
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Dona AI notification test"
    }
  }'

# Get FCM token from running app
adb logcat | grep "FCM Token"  # Android
# Or check Xcode console for iOS
```

---

**Need more help?** Check the Firebase documentation or run the setup script! 🚀
