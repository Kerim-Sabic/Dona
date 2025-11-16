## Environment Variables Configuration

Create a `.env` file in the project root with the following variables:

```env
# AI Services
CLAUDE_API_KEY=your-claude-api-key-here
OPENAI_API_KEY=your-openai-api-key-here
DEEPSEEK_API_KEY=your-deepseek-api-key-here

# Google Cloud
GOOGLE_CLOUD_API_KEY=your-google-cloud-api-key-here

# Google OAuth (Calendar, Gmail, Drive, Tasks)
GOOGLE_OAUTH_CLIENT_ID=your-client-id-here
GOOGLE_OAUTH_CLIENT_SECRET=your-client-secret-here
GOOGLE_OAUTH_REDIRECT_URI=http://localhost:8080/auth/callback

# Twilio
TWILIO_ACCOUNT_SID=your-account-sid-here
TWILIO_AUTH_TOKEN=your-auth-token-here
TWILIO_PHONE_NUMBER=your-twilio-phone-number-here

# Google Maps
GOOGLE_MAPS_API_KEY=your-maps-api-key-here

# Firebase (if using)
# Add your Firebase config here or use google-services.json
```

## Setup Instructions

1. Copy `.env.example` to `.env`
2. Fill in your actual API keys and secrets
3. **NEVER commit `.env` to version control**
4. The `.env` file is already in `.gitignore`

## Loading Environment Variables

For Flutter, you'll need to use one of these approaches:

### Option 1: flutter_dotenv (Recommended)

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

Then in your app:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

### Option 2: Build-time Environment Variables

Use `--dart-define`:
```bash
flutter run --dart-define=DEEPSEEK_API_KEY=your-key-here
```

### Option 3: flutter_config

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_config: ^2.0.2
```

## Security Best Practices

1. ✅ Never commit `.env` files
2. ✅ Use `.env.example` as a template (with placeholder values)
3. ✅ Rotate secrets regularly
4. ✅ Use different keys for dev/staging/production
5. ✅ Consider using a secret manager for production (AWS Secrets Manager, Google Secret Manager)
6. ✅ Validate that all required env vars are present at app startup
