#!/bin/bash

# ============================================================
# CRITICAL BLOCKER FIX: Generate Missing Platform Directories
# ============================================================
# This script fixes the #1 blocking issue preventing app compilation
#
# MUST BE RUN IN AN ENVIRONMENT WITH FLUTTER SDK INSTALLED
#
# Usage: bash FIX_CRITICAL_BLOCKER.sh
# ============================================================

set -e  # Exit on error

echo "=========================================="
echo "  FIXING CRITICAL BLOCKER #1"
echo "  Generating Flutter Platform Directories"
echo "=========================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter SDK not found!"
    echo ""
    echo "Please install Flutter first:"
    echo "  macOS:   brew install flutter"
    echo "  Linux:   snap install flutter --classic"
    echo "  Windows: https://docs.flutter.dev/get-started/install/windows"
    echo ""
    exit 1
fi

echo "✅ Flutter SDK found: $(flutter --version | head -1)"
echo ""

# Navigate to project root
cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)
echo "📂 Project root: $PROJECT_ROOT"
echo ""

# Backup lib/ just in case
echo "📦 Creating backup of lib/ directory..."
if [ -d "lib" ]; then
    cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup created"
else
    echo "⚠️  lib/ directory not found - unexpected!"
fi
echo ""

# Generate platform directories
echo "🔧 Running: flutter create --org com.dona.ai --platforms android,ios,web ."
echo ""
flutter create --org com.dona.ai --platforms android,ios,web .
echo ""

# Verify directories were created
echo "🔍 Verifying generated directories..."
echo ""

if [ -d "android" ]; then
    echo "✅ android/ directory created"
else
    echo "❌ android/ directory missing!"
fi

if [ -d "ios" ]; then
    echo "✅ ios/ directory created"
else
    echo "❌ ios/ directory missing!"
fi

if [ -d "web" ]; then
    echo "✅ web/ directory created"
else
    echo "❌ web/ directory missing!"
fi

# Create missing directories
echo ""
echo "📁 Creating additional directories..."
mkdir -p test/unit/services
mkdir -p test/widget/screens
mkdir -p test/integration
mkdir -p assets/images
mkdir -p assets/fonts
mkdir -p assets/audio
echo "✅ Created: test/, assets/ directories"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Run analysis
echo "🔍 Running static analysis..."
flutter analyze
echo ""

# Display next steps
echo "=========================================="
echo "  ✅ CRITICAL BLOCKER FIXED!"
echo "=========================================="
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Configure Firebase (Optional but recommended):"
echo "   - Visit: https://console.firebase.google.com"
echo "   - Create project: 'Dona AI'"
echo "   - Register Android app: com.dona.ai.dona_ai"
echo "   - Download google-services.json → android/app/"
echo "   - Register iOS app: com.dona.ai.donaAi"
echo "   - Download GoogleService-Info.plist → ios/Runner/"
echo ""
echo "2. Configure API Keys (REQUIRED):"
echo "   - Edit: lib/config/api_keys.dart"
echo "   - Add at minimum:"
echo "     • Claude API key (for AI)"
echo "     • Google Cloud API key (for speech)"
echo "     • Google Calendar OAuth credentials"
echo ""
echo "3. Set up app signing:"
echo "   Android: android/app/build.gradle (signing configs)"
echo "   iOS: Xcode → Runner.xcworkspace → Signing & Capabilities"
echo ""
echo "4. Test build:"
echo "   flutter run -d <device-id>"
echo ""
echo "5. For production release:"
echo "   flutter build apk --release"
echo "   flutter build ios --release"
echo ""
echo "=========================================="
echo "  Ready to proceed to Phase 2!"
echo "=========================================="
