# 📘 Production Deployment Guide - Dona AI Assistant
**Comprehensive Step-by-Step Guide for Beta & Production Deployment**

---

## 📚 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Security Setup](#security-setup)
3. [Environment Configuration](#environment-configuration)
4. [Building for Production](#building-for-production)
5. [Platform-Specific Deployment](#platform-specific-deployment)
6. [Monitoring & Support](#monitoring--support)
7. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Required Tools
- [ ] Flutter SDK (3.0.0+)
- [ ] Dart SDK (3.0.0+)
- [ ] Android Studio (for Android builds)
- [ ] Xcode (for iOS builds, macOS only)
- [ ] Git
- [ ] Access to all API service dashboards

### Required Accounts
- [ ] Google Cloud Console account
- [ ] Twilio account
- [ ] DeepSeek account
- [ ] OpenWeather account
- [ ] WorldNewsAPI account
- [ ] Google Play Console (for Android)
- [ ] Apple Developer account (for iOS)

### Verify Installation
```bash
flutter doctor -v
```
Ensure all checks pass for your target platforms.

---

## 🔐 Security Setup

### Step 1: Rotate ALL API Keys

**⚠️ CRITICAL:** The following keys were exposed and MUST be rotated:

#### 1.1 Google OAuth Credentials
```
Exposed Secret: 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
```

**How to rotate:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find the OAuth 2.0 Client ID: `289123966827-6olc8qc04htpn13jhfvd42u8ejvof90o`
4. Click **Delete** (or create a new one)
5. Click **Create Credentials** → **OAuth 2.0 Client ID**
6. Configure:
   - Application type: **Web application** (for Flutter web) or **Android/iOS**
   - Authorized redirect URIs: `https://yourdomain.com/auth/callback`
7. Download credentials
8. Save **Client ID** and **Client Secret** securely

#### 1.2 Google Maps API Key
```
Exposed Key: AIzaSyBSQQ3TdZ2fYpEUEfJhet7vZtGPfKhDHpU
```

**How to rotate:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find the API key
4. Click **Delete** or **Regenerate**
5. Create a new API key
6. Set **Application restrictions**:
   - HTTP referrers (for web): `yourdomain.com/*`
   - Android apps: Add your app's package name + SHA-1
   - iOS apps: Add your bundle ID
7. Set **API restrictions**:
   - Directions API
   - Maps JavaScript API
   - Places API
   - Geocoding API
8. Save the new key

#### 1.3 Twilio Credentials

**⚠️ CRITICAL: Your Twilio credentials were exposed in the repository and must be rotated immediately!**

**How to rotate:**
1. Go to [Twilio Console](https://console.twilio.com/)
2. Navigate to **Account** → **API Keys & Tokens**
3. Click **Create new Auth Token**
4. Confirm and save the new token
5. Update your application IMMEDIATELY
6. Optionally: Create a new subaccount for production

#### 1.4 Other API Keys

**DeepSeek:**
1. Log in to DeepSeek dashboard
2. Regenerate API key
3. Update `.env.production`

**OpenWeather:**
1. Go to [OpenWeather](https://openweathermap.org/api)
2. Navigate to **API Keys**
3. Generate new key
4. Delete old key

**WorldNewsAPI:**
1. Go to WorldNewsAPI dashboard
2. Regenerate API key
3. Update configuration

---

## ⚙️ Environment Configuration

### Step 2: Set Up Environment Files

#### 2.1 Create Production Environment File
```bash
# Copy the template
cp .env.production.example .env.production

# Edit with your NEW rotated keys
nano .env.production
# or
code .env.production
```

#### 2.2 Fill in ALL Required Values
```env
# Example .env.production (use YOUR new keys!)
DEEPSEEK_API_KEY=sk-prod-NEW-KEY-HERE
GOOGLE_OAUTH_CLIENT_ID=YOUR-NEW-CLIENT-ID.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=GOCSPX-YOUR-NEW-SECRET-HERE
GOOGLE_MAPS_API_KEY=AIzaSy-YOUR-NEW-MAPS-KEY
TWILIO_ACCOUNT_SID=AC-YOUR-NEW-SID
TWILIO_AUTH_TOKEN=YOUR-NEW-AUTH-TOKEN
TWILIO_PHONE_NUMBER=+1234567890
WORLD_NEWS_API_KEY=YOUR-NEW-NEWS-KEY
OPENWEATHER_API_KEY=YOUR-NEW-WEATHER-KEY
```

#### 2.3 Verify Environment File
```bash
# Check that all required variables are set
cat .env.production | grep "=YOUR-" && echo "⚠️  Some keys not configured!" || echo "✅ All keys appear configured"

# IMPORTANT: Verify .env.production is in .gitignore
grep ".env.production" .gitignore && echo "✅ Safe from Git" || echo "⚠️  ADD TO .gitignore!"
```

### Step 3: Test Configuration Locally

```bash
# Build in debug mode first with production keys to test
flutter run --dart-define-from-file=.env.production

# Check console for:
# "✅ API configuration validated successfully"
# NOT: "⚠️  Some API keys are not configured"
```

---

## 🏗️ Building for Production

### Step 4: Use the Build Script

We've created an automated build script to simplify the process:

```bash
# Make script executable (if not already)
chmod +x scripts/build_production.sh

# Run the build script
./scripts/build_production.sh
```

The script will:
1. ✅ Verify `.env.production` exists
2. ✅ Validate required environment variables
3. ✅ Prompt you for platform (Android/iOS/Web)
4. ✅ Build with all environment variables
5. ✅ Show build location

### Manual Build (Alternative)

If you prefer manual builds:

#### Android APK
```bash
flutter build apk --release \
  --dart-define=DEEPSEEK_API_KEY=$(grep DEEPSEEK_API_KEY .env.production | cut -d '=' -f2) \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=$(grep GOOGLE_OAUTH_CLIENT_ID .env.production | cut -d '=' -f2) \
  # ... add all other keys
```

#### Android App Bundle (Play Store)
```bash
flutter build appbundle --release \
  --dart-define=DEEPSEEK_API_KEY=... \
  # ... add all keys
```

#### iOS
```bash
flutter build ios --release \
  --dart-define=DEEPSEEK_API_KEY=... \
  # ... add all keys
```

---

## 📱 Platform-Specific Deployment

### Step 5: Deploy to Android (Google Play)

#### 5.1 Prepare App Bundle
```bash
# Build the App Bundle
flutter build appbundle --release \
  $(cat .env.production | sed 's/^/--dart-define=/')
```

#### 5.2 Upload to Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (or create new app)
3. Navigate to **Release** → **Testing** → **Internal testing** (or **Closed testing**)
4. Click **Create new release**
5. Upload `build/app/outputs/bundle/release/app-release.aab`
6. Fill in release notes
7. Review and rollout

#### 5.3 Add Beta Testers
1. In Play Console, go to **Testing** → **Testers**
2. Create a list of email addresses
3. Share the opt-in link with testers
4. Monitor feedback

### Step 6: Deploy to iOS (TestFlight)

#### 6.1 Build Archive in Xcode
```bash
# Build iOS
flutter build ios --release \
  $(cat .env.production | sed 's/^/--dart-define=/')

# Open Xcode
open ios/Runner.xcworkspace
```

#### 6.2 Archive and Upload
1. In Xcode, select **Product** → **Archive**
2. Wait for archive to complete
3. Click **Distribute App**
4. Select **TestFlight & App Store**
5. Follow the wizard to upload

#### 6.3 Configure TestFlight
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to **TestFlight** tab
4. Select the build
5. Add internal/external testers
6. Submit for beta review (if external)

### Step 7: Deploy to Web (Optional)

#### 7.1 Build Web App
```bash
flutter build web --release \
  $(cat .env.production | sed 's/^/--dart-define=/')
```

#### 7.2 Deploy to Hosting
```bash
# Firebase Hosting (example)
firebase deploy --only hosting

# Or copy to your web server
scp -r build/web/* user@yourserver.com:/var/www/dona/

# Or use any static hosting (Netlify, Vercel, etc.)
```

---

## 📊 Monitoring & Support

### Step 8: Set Up Monitoring

#### 8.1 Firebase Crashlytics (Recommended)
```bash
# Add to pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_crashlytics: ^3.4.0

# Initialize in main.dart
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

#### 8.2 Analytics
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^10.7.0
```

#### 8.3 Error Tracking (Alternative: Sentry)
```yaml
dependencies:
  sentry_flutter: ^7.14.0
```

### Step 9: Monitor Key Metrics

**Track Daily:**
- Crash-free rate (target: >99%)
- API error rates
- App launch time
- User engagement

**Track Weekly:**
- User retention (Day 1, Day 7)
- Feature usage
- Performance metrics
- Feedback sentiment

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: "API key validation failed"
```
Solution:
1. Check .env.production has all keys
2. Verify build command includes all --dart-define flags
3. Check for typos in environment variable names
```

#### Issue: "Service initialization failed"
```
Solution:
1. Check logs for specific service that failed
2. Verify API key is valid for that service
3. Test API key directly in service dashboard
4. Ensure network connectivity
```

#### Issue: "App crashes on launch"
```
Solution:
1. Check crash logs (Crashlytics/Play Console)
2. Verify all required permissions granted
3. Test in debug mode to see detailed error
4. Check for missing assets or configuration
```

#### Issue: "OAuth authentication not working"
```
Solution:
1. Verify redirect URI matches exactly
2. Check OAuth consent screen is configured
3. Verify client ID and secret are correct
4. Check package name (Android) or bundle ID (iOS) matches
```

---

## ✅ Deployment Verification

After deployment, verify:

1. **App Launches:** ✅ App opens without crashes
2. **Services Initialize:** ✅ Check logs for "✅ All services initialized"
3. **AI Chat Works:** ✅ Test sending a message
4. **Google Auth Works:** ✅ Test signing in with Google
5. **API Calls Work:** ✅ Test news, weather, calendar
6. **No Crashes:** ✅ Monitor crash-free rate

---

## 🎉 Success Criteria

**Beta is successful when:**
- ✅ 99%+ crash-free rate for 7 days
- ✅ 50+ active beta testers
- ✅ Positive feedback (4+ star average)
- ✅ All critical features working
- ✅ No security issues reported

**Ready for production when:**
- ✅ Beta success criteria met
- ✅ All high-priority bugs fixed
- ✅ Performance metrics meeting targets
- ✅ Legal compliance verified (privacy policy, terms)
- ✅ Support system ready

---

## 📞 Support Resources

### Documentation
- **Security Audit:** `SECURITY_AUDIT_PHASE1.md`
- **Service Initialization:** `PHASE2_CRITICAL_FLOWS.md`
- **Code Quality:** `PHASE3_CODE_QUALITY.md`
- **Environment Setup:** `ENV_SETUP.md`
- **Comprehensive Audit:** `COMPREHENSIVE_AUDIT_SUMMARY.md`
- **Deployment Checklist:** `DEPLOYMENT_CHECKLIST.md`

### External Resources
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)
- [Firebase Documentation](https://firebase.google.com/docs)

---

**Guide prepared by:** Claude Code
**Date:** 2025-11-16
**Status:** Ready for deployment
**Version:** 1.0.0

---

*Good luck with your beta deployment! 🚀*
