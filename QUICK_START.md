# 🚀 DONA AI - QUICK START GUIDE

## Ready to Test Everything RIGHT NOW!

All APIs are configured and ready. Here's exactly what to do:

---

## 1️⃣ **Run the App** (30 seconds)

```bash
cd /home/user/Dona
flutter pub get
flutter run
```

**Choose your platform:**
- Web (fastest): `flutter run -d chrome`
- Desktop: `flutter run -d macos` or `flutter run -d linux`
- Mobile emulator: `flutter run` (if emulator is running)

---

## 2️⃣ **Test All Features**

### ✅ **AI Chat** - WORKS NOW!
1. Tap the blue **"Tap to speak"** button
2. Type: `"Hello Dona, what can you do?"`
3. Watch AI respond with personality!
4. Try: `"Tell me a joke"` or `"What's the weather?"`

**Status:** ✅ Real DeepSeek API - Fully working

---

### ✅ **News Feed** - WORKS NOW!
1. Tap **News** card
2. See Bosnia news articles
3. Tap article to open in browser
4. Pull down to refresh

**Status:** ✅ Real WorldNewsAPI - Fully working

---

### ✅ **Weather** - WORKS NOW!
1. Tap **Weather** card
2. See Sarajevo weather
3. Tap search icon to try other cities
4. View 5-day forecast

**Status:** ✅ Real OpenWeatherMap - Fully working

---

### ✅ **Google Calendar** - WORKS NOW!
1. Tap **Calendar** card
2. **See mock events immediately** (no setup needed)
3. Tap **+ New Event** to create
4. Tap events to view details

**Status:** ✅ Mock data working, OAuth ready

---

## 3️⃣ **Connect Real Google Calendar** (2 minutes)

Your credentials are already configured! Just need to enable:

### **Quick Setup:**

1. **Enable Calendar API:**
   - Go to: https://console.cloud.google.com/apis/library/calendar-json.googleapis.com
   - Click **ENABLE**

2. **Configure OAuth Consent:**
   - Go to: https://console.cloud.google.com/apis/credentials/consent
   - App name: `Dona AI`
   - User support email: your-email@gmail.com
   - Add scopes:
     - `https://www.googleapis.com/auth/calendar`
     - `https://www.googleapis.com/auth/calendar.events`
   - Add test user: your-email@gmail.com
   - Click **Save**

3. **Add Redirect URI:**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Click your OAuth Client ID
   - Under **Authorized redirect URIs**, add:
     - `http://localhost:8080`
   - Click **Save**

4. **Test It:**
   ```bash
   flutter run -d chrome
   ```
   - Go to Calendar screen
   - Tap **Sign in with Google** (login icon)
   - Grant permissions
   - **Your real calendar loads!**

---

## 4️⃣ **All Configured Credentials**

✅ **All API credentials are configured and ready!**

- DeepSeek AI API
- WorldNewsAPI
- OpenWeatherMap
- Google Cloud API (Speech, TTS, Maps)
- Google Calendar OAuth 2.0 (Client ID + Secret)

**All keys are securely stored in:** `lib/config/api_keys.dart` (gitignored for security)

**Note:** The api_keys.dart file contains all your actual API keys and OAuth credentials. This file is excluded from git for security reasons.

---

## 5️⃣ **Test Scenarios**

### **Scenario 1: Morning Briefing**
1. Open Chat
2. Say: `"Good morning Dona, what's my day like?"`
3. Dona will:
   - Greet you warmly
   - Suggest checking weather
   - Suggest viewing calendar

### **Scenario 2: Check Everything**
1. Open News → Read Bosnia headlines
2. Open Weather → See Sarajevo forecast
3. Open Calendar → View upcoming events
4. Open Chat → Ask questions

### **Scenario 3: Create Event**
1. Calendar → Tap **+ New Event**
2. Title: "Meeting with team"
3. Description: "Discuss project updates"
4. Location: "Office"
5. Create → Done!

---

## 6️⃣ **Common Commands to Try**

**In Chat:**
- `"What's the weather in Banja Luka?"`
- `"Show me the latest news"`
- `"What can you help me with?"`
- `"Tell me about yourself"`
- `"Schedule a meeting for tomorrow at 2pm"` (Dona will suggest using Calendar)

---

## 7️⃣ **What Works Right Now**

| Feature | Status | Notes |
|---------|--------|-------|
| 🤖 AI Chat | ✅ LIVE | Real DeepSeek API |
| 📰 News | ✅ LIVE | Bosnia + International |
| 🌤️ Weather | ✅ LIVE | Any city worldwide |
| 📅 Calendar | ✅ MOCK | Real OAuth ready |
| 🗣️ Speech | 🔄 Ready | API configured |

---

## 8️⃣ **Troubleshooting**

### **"Failed to fetch..."**
- ✅ Check internet connection
- ✅ APIs have free tier limits (should be fine)

### **Calendar shows mock data**
- ✅ This is expected! Follow Step 3 to connect real calendar
- ✅ Mock data works perfectly for testing UI

### **App won't build**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 9️⃣ **File Structure**

```
Dona/
├── lib/
│   ├── config/
│   │   └── api_keys.dart          ✅ All credentials here
│   ├── services/
│   │   ├── ai/                     ✅ DeepSeek integration
│   │   ├── news/                   ✅ WorldNewsAPI
│   │   ├── weather/                ✅ OpenWeatherMap
│   │   └── calendar/               ✅ Google Calendar
│   └── presentation/screens/
│       ├── chat/                   ✅ AI chat UI
│       ├── news/                   ✅ News feed UI
│       ├── weather/                ✅ Weather UI
│       └── calendar/               ✅ Calendar UI
└── docs/
    ├── TESTING_GUIDE.md            📖 Full testing guide
    └── GOOGLE_CALENDAR_SETUP.md    📖 Calendar setup details
```

---

## 🔟 **Next Steps After Testing**

Once everything works:

1. **Add Speech:**
   - Implement Google Cloud Speech-to-Text
   - Add voice input to chat
   - Bosnian language support

2. **Enhance Calendar:**
   - AI-powered event creation ("Schedule meeting tomorrow at 2pm")
   - Smart suggestions based on habits
   - Recurring events

3. **Add More Features:**
   - Food ordering (Glovo/Donesi)
   - Phone calls (Twilio)
   - Navigation (Google Maps)

---

## 📱 **READY TO GO!**

Everything is set up and working. Just run:

```bash
cd /home/user/Dona
flutter pub get
flutter run -d chrome
```

Then explore:
- ✅ Chat with Dona AI
- ✅ Read Bosnia news
- ✅ Check weather
- ✅ View calendar (mock or real after setup)

**🎉 ENJOY YOUR AI ASSISTANT!**

---

## 📖 **Full Documentation**

- **Testing Guide:** `docs/TESTING_GUIDE.md`
- **Calendar Setup:** `docs/GOOGLE_CALENDAR_SETUP.md`
- **Architecture:** `docs/ARCHITECTURE.md`
- **API Guide:** `docs/API_INTEGRATIONS.md`

**Questions? Check the docs or ask Dona!** 😊
