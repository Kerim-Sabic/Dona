# 🔥 Firebase Setup Guide for Dona AI

## Prerequisites
- Flutter SDK installed on your machine
- Google account for Firebase Console
- Dona AI project cloned locally

---

## Part 1: Create Platform Directories (One-Time Setup)

### Run on your local machine:
```bash
# Navigate to your Dona project
cd /path/to/Dona

# Run the blocker fix script (creates android/, ios/, test/, assets/)
chmod +x FIX_CRITICAL_BLOCKER.sh
./FIX_CRITICAL_BLOCKER.sh
```

**What this does:**
- Creates `android/` and `ios/` platform directories
- Creates `test/` directory structure
- Creates `assets/` directories for images/fonts/audio
- Runs `flutter pub get`
- Runs `flutter analyze`

---

## Part 2: Create Firebase Project

### 1. Go to Firebase Console
- Visit: https://console.firebase.google.com/
- Sign in with your Google account

### 2. Create New Project
1. Click **"Add project"** or **"Create a project"**
2. **Project name**: `dona-ai` (or your preferred name)
3. Click **Continue**
4. **Google Analytics**: Toggle OFF (optional - can enable later)
5. Click **Create project**
6. Wait for project creation (~30 seconds)
7. Click **Continue** when done

---

## Part 3: Add Android App to Firebase

### 1. Register Android App
1. In Firebase Console dashboard, click the **Android icon** (robot)
2. Fill in the registration form:
   - **Android package name**: `com.dona.ai` ⚠️ **CRITICAL** - Must match exactly!
   - **App nickname** (optional): `Dona AI Android`
   - **Debug signing certificate SHA-1** (optional): Leave blank for now
3. Click **Register app**

### 2. Download Configuration File
1. Click **Download google-services.json**
2. Save the file

### 3. Place Configuration File
```bash
# On your local machine, place the file here:
Dona/android/app/google-services.json

# The path should be:
# android/
#   app/
#     google-services.json  ← HERE
#     build.gradle
```

### 4. Verify Android Package Name
Open `android/app/build.gradle` and verify:
```gradle
android {
    namespace = "com.dona.ai"
    defaultConfig {
        applicationId = "com.dona.ai"  // Must match Firebase!
        ...
    }
}
```

### 5. Firebase Console - Continue
1. Click **Next** (Skip SDK setup - already in pubspec.yaml)
2. Click **Next** (Skip initialization - we'll do it manually)
3. Click **Continue to console**

---

## Part 4: Add iOS App to Firebase

### 1. Register iOS App
1. In Firebase Console dashboard, click the **iOS icon** (apple)
2. Fill in the registration form:
   - **iOS bundle ID**: `com.dona.ai` ⚠️ **CRITICAL** - Must match exactly!
   - **App nickname** (optional): `Dona AI iOS`
   - **App Store ID** (optional): Leave blank
   - **Team ID** (optional): Leave blank
3. Click **Register app**

### 2. Download Configuration File
1. Click **Download GoogleService-Info.plist**
2. Save the file

### 3. Place Configuration File

**Option A: Using Xcode (Recommended)**
```bash
# 1. Open iOS project in Xcode
cd Dona/ios
open Runner.xcworkspace

# 2. In Xcode:
#    - Right-click on "Runner" folder (blue icon)
#    - Select "Add Files to Runner..."
#    - Select your downloaded GoogleService-Info.plist
#    - ✅ Check "Copy items if needed"
#    - ✅ Check "Runner" target
#    - Click "Add"
```

**Option B: Manual Placement**
```bash
# Place the file here:
Dona/ios/Runner/GoogleService-Info.plist

# The path should be:
# ios/
#   Runner/
#     GoogleService-Info.plist  ← HERE
#     Info.plist
#     AppDelegate.swift
```

### 4. Verify iOS Bundle ID
Open `ios/Runner.xcodeproj` in Xcode and verify:
- **General** tab → **Bundle Identifier**: `com.dona.ai`

### 5. Firebase Console - Continue
1. Click **Next** (Skip SDK setup)
2. Click **Next** (Skip initialization)
3. Click **Continue to console**

---

## Part 5: Enable Firebase Cloud Messaging (FCM)

### 1. Enable FCM in Firebase Console
1. In Firebase Console, go to **Build** → **Cloud Messaging**
2. Click **Get started** (if shown)
3. Note: iOS push notifications require APNs configuration (can do later)

### 2. Get Server Key (For Reference)
1. Go to **Project Settings** (⚙️ icon) → **Cloud Messaging** tab
2. Under **Cloud Messaging API (Legacy)**, you'll see:
   - **Server key**: (copy if needed for backend)
   - **Sender ID**: (copy if needed)

---

## Part 6: Update Dona AI Code

### 1. Uncomment Firebase Initialization

Open `lib/main.dart` and find this line (around line 232):

**Before:**
```dart
// await Firebase.initializeApp(
```

**After:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 2. Install FlutterFire CLI (One-Time)
```bash
# On your local machine
dart pub global activate flutterfire_cli
```

### 3. Generate Firebase Options File
```bash
# Navigate to Dona project
cd /path/to/Dona

# Run FlutterFire configure
flutterfire configure

# This will:
# 1. Detect your Firebase project
# 2. Auto-generate lib/firebase_options.dart
# 3. Configure iOS and Android apps
```

**Follow the prompts:**
```
? Select a Firebase project to configure your Flutter application with:
  → dona-ai (or your project name)

? Which platforms should your configuration support?
  ✅ android
  ✅ ios
  ⬜ macos (optional)
  ⬜ web (optional)
```

### 4. Import Firebase Options

Update `lib/main.dart` to import the generated file:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ... rest of your code
}
```

---

## Part 7: Test Firebase Connection

### 1. Run the App
```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

### 2. Check Logs
Look for Firebase initialization success in logs:
```
✓ Firebase initialized successfully
```

### 3. Verify in Firebase Console
1. Go to Firebase Console → **Analytics** → **Dashboard**
2. Wait 24 hours (first-time data collection)
3. You should see app usage data

### 4. Test Cloud Messaging
```bash
# Send a test notification from Firebase Console
# Go to: Cloud Messaging → New notification
# - Title: "Test"
# - Text: "Dona AI is connected!"
# - Target: Your Android/iOS app
# Click "Send test message"
```

---

## Part 8: Troubleshooting

### Error: "MissingPluginException"
**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Error: "google-services.json not found"
**Solution:**
- Verify file location: `android/app/google-services.json`
- Check package name matches: `com.dona.ai`
- Re-download from Firebase Console if needed

### Error: "GoogleService-Info.plist not found"
**Solution:**
- Verify file is in Xcode project (not just filesystem)
- Re-add using Xcode: Right-click Runner → Add Files
- Check Bundle ID matches: `com.dona.ai`

### Error: "Firebase not initialized"
**Solution:**
- Ensure `Firebase.initializeApp()` is called BEFORE `runApp()`
- Verify `firebase_options.dart` exists
- Run `flutterfire configure` again

### iOS Build Errors
**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run -d ios
```

---

## Security Best Practices

### 1. Verify .gitignore
Make sure these are in `.gitignore`:
```gitignore
# Firebase
google-services.json
GoogleService-Info.plist
firebase_options.dart  # Sometimes you commit this, sometimes not
lib/config/api_keys.dart

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec

# Android
android/app/google-services.json
```

### 2. Firebase Security Rules
Set up Firestore/Storage rules in Firebase Console:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;  // Only authenticated users
    }
  }
}
```

---

## Quick Reference Commands

```bash
# Create platform directories
./FIX_CRITICAL_BLOCKER.sh

# Configure Firebase (auto-generates firebase_options.dart)
flutterfire configure

# Get dependencies
flutter pub get

# Clean build
flutter clean && flutter pub get

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Build release APK
flutter build apk --release

# Build iOS release
flutter build ios --release

# Check Firebase status
flutter doctor -v
```

---

## File Structure After Setup

```
Dona/
├── android/
│   └── app/
│       ├── google-services.json  ✅ Firebase Android config
│       └── build.gradle
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist  ✅ Firebase iOS config
│       ├── Info.plist
│       └── AppDelegate.swift
├── lib/
│   ├── firebase_options.dart  ✅ Auto-generated by flutterfire
│   ├── config/
│   │   └── api_keys.dart  ✅ Your API keys (not in git)
│   └── main.dart  ✅ Firebase.initializeApp() uncommented
├── pubspec.yaml  ✅ Already has firebase_core & firebase_messaging
└── FIX_CRITICAL_BLOCKER.sh
```

---

## Next Steps After Firebase Setup

1. ✅ Firebase configured and working
2. 🔔 Test push notifications
3. 📊 Enable Firebase Analytics (optional)
4. 🔐 Set up Firebase Authentication (optional for user login)
5. 💾 Configure Firestore for cloud storage (optional)
6. 🚀 Deploy to Google Play / App Store

---

## Support Resources

- **Firebase Documentation**: https://firebase.google.com/docs
- **FlutterFire Documentation**: https://firebase.flutter.dev/
- **FlutterFire CLI**: https://firebase.flutter.dev/docs/cli/
- **Firebase Console**: https://console.firebase.google.com/
- **Cloud Messaging Setup**: https://firebase.flutter.dev/docs/messaging/overview/

---

## Summary Checklist

- [ ] Run `FIX_CRITICAL_BLOCKER.sh` to create platform directories
- [ ] Create Firebase project at console.firebase.google.com
- [ ] Register Android app → Download `google-services.json` → Place in `android/app/`
- [ ] Register iOS app → Download `GoogleService-Info.plist` → Place in `ios/Runner/`
- [ ] Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- [ ] Run `flutterfire configure` to generate `firebase_options.dart`
- [ ] Uncomment `Firebase.initializeApp()` in `lib/main.dart`
- [ ] Add import: `import 'firebase_options.dart';`
- [ ] Run `flutter pub get`
- [ ] Test on Android: `flutter run -d android`
- [ ] Test on iOS: `flutter run -d ios`
- [ ] Send test notification from Firebase Console
- [ ] Verify app receives notification ✅

---

**Need help?** Check the Troubleshooting section or Firebase documentation.

**Ready to go?** Start with Part 1 on your local machine! 🚀
