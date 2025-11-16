#!/bin/bash
# Production Build Script for Dona AI Assistant
# This script builds the app with production configuration

set -e # Exit on error

echo "🚀 Dona AI Assistant - Production Build Script"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo -e "${RED}❌ ERROR: .env.production file not found${NC}"
    echo -e "${YELLOW}Please copy .env.production.example to .env.production and configure it${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found .env.production${NC}"

# Load environment variables
export $(cat .env.production | xargs)

# Validate required environment variables
REQUIRED_VARS=(
    "DEEPSEEK_API_KEY"
    "GOOGLE_OAUTH_CLIENT_ID"
    "GOOGLE_OAUTH_CLIENT_SECRET"
)

echo ""
echo "📋 Validating environment variables..."
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ ERROR: $var is not set in .env.production${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ $var is configured${NC}"
done

# Ask which platform to build
echo ""
echo "📱 Select platform to build:"
echo "1) Android (APK)"
echo "2) Android (App Bundle for Play Store)"
echo "3) iOS"
echo "4) Web"
echo "5) All platforms"
read -p "Enter choice [1-5]: " platform_choice

# Build command with all environment variables
BUILD_ARGS="--release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY \
  --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
  --dart-define=CLAUDE_API_KEY=$CLAUDE_API_KEY \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=$GOOGLE_OAUTH_CLIENT_ID \
  --dart-define=GOOGLE_OAUTH_CLIENT_SECRET=$GOOGLE_OAUTH_CLIENT_SECRET \
  --dart-define=GOOGLE_OAUTH_REDIRECT_URI=$GOOGLE_OAUTH_REDIRECT_URI \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --dart-define=TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID \
  --dart-define=TWILIO_AUTH_TOKEN=$TWILIO_AUTH_TOKEN \
  --dart-define=TWILIO_PHONE_NUMBER=$TWILIO_PHONE_NUMBER \
  --dart-define=WORLD_NEWS_API_KEY=$WORLD_NEWS_API_KEY \
  --dart-define=OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY"

build_android_apk() {
    echo ""
    echo "🤖 Building Android APK..."
    flutter build apk $BUILD_ARGS
    echo -e "${GREEN}✅ Android APK built successfully!${NC}"
    echo "📦 Location: build/app/outputs/flutter-apk/app-release.apk"
}

build_android_bundle() {
    echo ""
    echo "🤖 Building Android App Bundle..."
    flutter build appbundle $BUILD_ARGS
    echo -e "${GREEN}✅ Android App Bundle built successfully!${NC}"
    echo "📦 Location: build/app/outputs/bundle/release/app-release.aab"
}

build_ios() {
    echo ""
    echo "🍎 Building iOS..."
    flutter build ios $BUILD_ARGS
    echo -e "${GREEN}✅ iOS build completed successfully!${NC}"
    echo "📦 Open Xcode to archive and upload to App Store Connect"
}

build_web() {
    echo ""
    echo "🌐 Building Web..."
    flutter build web $BUILD_ARGS
    echo -e "${GREEN}✅ Web build completed successfully!${NC}"
    echo "📦 Location: build/web/"
}

# Execute build based on choice
case $platform_choice in
    1)
        build_android_apk
        ;;
    2)
        build_android_bundle
        ;;
    3)
        build_ios
        ;;
    4)
        build_web
        ;;
    5)
        build_android_apk
        build_android_bundle
        build_ios
        build_web
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo -e "${GREEN}🎉 Build process completed!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Test the build on a physical device"
echo "2. Upload to beta testing (TestFlight/Play Console)"
echo "3. Collect feedback from beta testers"
echo "4. Monitor for crashes and errors"
echo ""
echo -e "${YELLOW}⚠️  Remember to NEVER commit .env.production!${NC}"
