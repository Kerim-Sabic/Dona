#!/bin/bash
#
# Firebase Setup Quick-Start Script for Dona AI
# Run this on your LOCAL MACHINE with Flutter installed
#

set -e  # Exit on error

echo "================================================"
echo "  🔥 Firebase Setup Quick-Start for Dona AI"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Create Platform Directories${NC}"
echo "Running FIX_CRITICAL_BLOCKER.sh..."
chmod +x FIX_CRITICAL_BLOCKER.sh
./FIX_CRITICAL_BLOCKER.sh

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Platform directories created${NC}"
else
    echo -e "${RED}✗ Failed to create platform directories${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Manual Setup Required${NC}"
echo "Please complete these steps in Firebase Console:"
echo ""
echo "  1. Go to: https://console.firebase.google.com/"
echo "  2. Create new project: 'dona-ai'"
echo "  3. Add Android app (com.dona.ai)"
echo "     → Download google-services.json"
echo "     → Place in: android/app/google-services.json"
echo ""
echo "  4. Add iOS app (com.dona.ai)"
echo "     → Download GoogleService-Info.plist"
echo "     → Place in: ios/Runner/GoogleService-Info.plist"
echo ""
read -p "Press ENTER when you've completed these steps..."

echo ""
echo -e "${BLUE}Step 3: Verify Configuration Files${NC}"

if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✓ android/app/google-services.json found${NC}"
else
    echo -e "${RED}✗ android/app/google-services.json NOT FOUND${NC}"
    echo "  Please download from Firebase Console and place it in android/app/"
    exit 1
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✓ ios/Runner/GoogleService-Info.plist found${NC}"
else
    echo -e "${RED}✗ ios/Runner/GoogleService-Info.plist NOT FOUND${NC}"
    echo "  Please download from Firebase Console and place it in ios/Runner/"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 4: Install FlutterFire CLI${NC}"
echo "Installing flutterfire_cli..."
dart pub global activate flutterfire_cli

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ FlutterFire CLI installed${NC}"
else
    echo -e "${RED}✗ Failed to install FlutterFire CLI${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 5: Configure Firebase${NC}"
echo "Running flutterfire configure..."
flutterfire configure

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Firebase configured (firebase_options.dart generated)${NC}"
else
    echo -e "${RED}✗ Failed to configure Firebase${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 6: Update main.dart${NC}"
echo "Uncommenting Firebase.initializeApp()..."

# Uncomment the Firebase initialization line
sed -i.bak 's|// await Firebase.initializeApp(|await Firebase.initializeApp(|g' lib/main.dart

# Check if firebase_options import exists, if not add it
if ! grep -q "import 'firebase_options.dart';" lib/main.dart; then
    # Find the line after firebase_core import and add our import
    sed -i.bak "/import 'package:firebase_core\/firebase_core.dart';/a\\
import 'firebase_options.dart';" lib/main.dart
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ main.dart updated${NC}"
else
    echo -e "${YELLOW}⚠ Could not auto-update main.dart - please update manually${NC}"
fi

echo ""
echo -e "${BLUE}Step 7: Get Dependencies${NC}"
flutter pub get

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 8: iOS Pod Install${NC}"
cd ios
pod install
cd ..

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ iOS pods installed${NC}"
else
    echo -e "${YELLOW}⚠ iOS pod install failed - you may need to run manually${NC}"
fi

echo ""
echo "================================================"
echo -e "${GREEN}  ✅ Firebase Setup Complete!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Run: flutter run -d android    (test on Android)"
echo "  2. Run: flutter run -d ios        (test on iOS)"
echo "  3. Send test notification from Firebase Console"
echo ""
echo "Troubleshooting:"
echo "  - If build fails, run: flutter clean && flutter pub get"
echo "  - If iOS fails, run: cd ios && pod install && cd .."
echo "  - See FIREBASE_SETUP_GUIDE.md for detailed help"
echo ""
