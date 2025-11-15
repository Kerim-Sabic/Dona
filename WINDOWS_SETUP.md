# 🪟 Dona AI - Windows Setup Guide

Complete guide for running Dona AI on Windows 10/11.

## 📋 Prerequisites

### 1. Install Flutter for Windows

1. Download Flutter SDK for Windows from [flutter.dev](https://docs.flutter.dev/get-started/install/windows)
2. Extract to `C:\src\flutter` (recommended)
3. Add Flutter to PATH:
   - Open "Environment Variables"
   - Add `C:\src\flutter\bin` to System PATH
   - Add `C:\src\flutter\bin\cache\dart-sdk\bin` to System PATH

4. Verify installation:
```powershell
flutter doctor
```

### 2. Install Visual Studio 2022

1. Download [Visual Studio 2022 Community](https://visualstudio.microsoft.com/downloads/)
2. During installation, select:
   - "Desktop development with C++"
   - Windows 10 SDK
   - C++ CMake tools for Windows

### 3. Enable Windows Desktop Development

```powershell
flutter config --enable-windows-desktop
```

### 4. Install Git for Windows

Download from [git-scm.com](https://git-scm.com/download/win)

---

## 🚀 Quick Start

### 1. Clone the Repository

```powershell
git clone https://github.com/yourusername/Dona.git
cd Dona
```

### 2. Install Dependencies

```powershell
flutter pub get
```

### 3. Configure API Keys

1. Copy the template:
```powershell
copy lib\config\api_keys.dart.template lib\config\api_keys.dart
```

2. Edit `lib\config\api_keys.dart` with your keys:
```dart
class ApiKeys {
  // Google Maps API
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Twilio
  static const String twilioAccountSid = 'YOUR_TWILIO_SID';
  static const String twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';

  // ... add other keys
}
```

### 4. Run on Windows

```powershell
flutter run -d windows
```

Or build release version:
```powershell
flutter build windows --release
```

---

## 🔧 Windows-Specific Configuration

### File Paths

Dona automatically handles Windows paths using the `PlatformService`:

```dart
// Don't do this:
final path = 'data/folder/file.txt'; // Unix-style

// Do this:
final path = PlatformService.instance.joinPath('data', 'folder', 'file.txt');
// Automatically becomes: data\folder\file.txt on Windows
```

### Data Storage Locations

On Windows, Dona stores data in:
- **User Data**: `%APPDATA%\Dona\`
- **Cache**: `%LOCALAPPDATA%\Dona\Cache\`
- **Logs**: `%APPDATA%\Dona\Logs\`

### Notifications on Windows

Windows notifications are handled via `flutter_local_notifications`:

1. Notifications appear in Windows Action Center
2. Sounds use `.wav` format
3. Icons use `.ico` format

---

## 🎯 Windows-Optimized Features

### 1. Desktop Integration

Dona includes Windows-specific features:

- **System Tray Icon**: Minimize to tray
- **Startup on Boot**: Optional auto-start
- **Windows Notifications**: Native toast notifications
- **File Associations**: Open .dona files directly
- **Jump Lists**: Quick actions from taskbar

### 2. Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl + /` | Quick voice command |
| `Ctrl + N` | New task |
| `Ctrl + E` | New email |
| `Ctrl + Shift + F` | Start focus mode |
| `Ctrl + ,` | Settings |
| `Win + D` | Hide/Show Dona |

### 3. Performance Optimizations

Dona is optimized for Windows:

- **Native Window Controls**: Minimize, maximize, close
- **GPU Acceleration**: Uses DirectX for smooth animations
- **Background Services**: Efficient Windows services
- **Memory Management**: Optimized for Windows RAM handling

---

## 🔐 Windows Firewall Configuration

Allow Dona through Windows Firewall:

```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Dona AI" dir=in action=allow program="C:\path\to\dona\build\windows\runner\Release\dona_ai.exe" enable=yes
```

---

## 📊 Running as Windows Service (Optional)

To run Dona in the background:

### 1. Install NSSM

Download from [nssm.cc](https://nssm.cc/download)

### 2. Create Service

```powershell
nssm install DonaAI "C:\path\to\dona\build\windows\runner\Release\dona_ai.exe"
nssm set DonaAI AppDirectory "C:\path\to\dona"
nssm set DonaAI DisplayName "Dona AI Personal Assistant"
nssm set DonaAI Description "Your intelligent personal assistant"
nssm set DonaAI Start SERVICE_AUTO_START
nssm start DonaAI
```

---

## 🐛 Troubleshooting

### Issue: "Visual Studio not found"

**Solution:**
```powershell
# Ensure Visual Studio 2022 is installed
# Re-run flutter doctor
flutter doctor -v
```

### Issue: "Windows SDK not found"

**Solution:**
1. Open Visual Studio Installer
2. Modify installation
3. Add "Windows 10 SDK (10.0.19041.0)" or later

### Issue: "CMake not found"

**Solution:**
```powershell
# Install via Visual Studio Installer
# OR install standalone from cmake.org
```

### Issue: "Speech recognition not working"

**Solution:**
1. Ensure Windows Speech Recognition is enabled:
   - Settings → Privacy → Speech
   - Enable "Online speech recognition"
2. Ensure microphone permissions:
   - Settings → Privacy → Microphone
   - Allow apps to access microphone

### Issue: "Notifications not showing"

**Solution:**
1. Enable notifications in Windows Settings:
   - Settings → System → Notifications
   - Find "Dona AI" and enable
2. Check Focus Assist is not blocking:
   - Settings → System → Focus Assist

### Issue: "File access errors"

**Solution:**
```powershell
# Run as Administrator, then:
icacls "C:\path\to\dona" /grant Users:(OI)(CI)F /T
```

---

## 🏗️ Building for Distribution

### Create Windows Installer

1. Install Inno Setup from [jrsoftware.org](https://jrsoftware.org/isdl.php)

2. Create installer script (`installer.iss`):

```iss
[Setup]
AppName=Dona AI
AppVersion=1.0.0
DefaultDirName={pf}\Dona AI
DefaultGroupName=Dona AI
OutputDir=installer
OutputBaseFilename=DonaAI-Setup

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Dona AI"; Filename: "{app}\dona_ai.exe"
Name: "{commondesktop}\Dona AI"; Filename: "{app}\dona_ai.exe"

[Run]
Filename: "{app}\dona_ai.exe"; Description: "Launch Dona AI"; Flags: nowait postinstall skipifsilent
```

3. Build installer:
```powershell
flutter build windows --release
iscc installer.iss
```

---

## 💡 Windows Performance Tips

### 1. Optimize for Performance

```powershell
# Build with profile mode for testing
flutter build windows --profile

# Build release for production
flutter build windows --release --split-debug-info=./debug_symbols
```

### 2. Reduce Memory Usage

Edit `windows/runner/main.cpp` and set:

```cpp
// Set process priority
SetPriorityClass(GetCurrentProcess(), BELOW_NORMAL_PRIORITY_CLASS);
```

### 3. Enable GPU Acceleration

Dona automatically uses DirectX on Windows. Verify with:

```powershell
# Check GPU usage in Task Manager
# Performance → GPU → Look for "dona_ai.exe"
```

---

## 🔄 Auto-Update on Windows

### Using Sparkle for Windows

1. Add to `pubspec.yaml`:
```yaml
dependencies:
  sparkle: ^0.1.0
```

2. Configure auto-update:
```dart
import 'package:sparkle/sparkle.dart';

void checkForUpdates() {
  if (PlatformService.instance.isWindows) {
    Sparkle.checkForUpdates();
  }
}
```

---

## 🌐 Windows-Specific API Integration

### Speech Recognition

Dona uses Windows Speech Recognition API:

```dart
// Already configured in enhanced_voice_assistant.dart
// Ensure microphone permissions are granted
```

### Text-to-Speech

Uses Windows SAPI voices:

```dart
// List available voices
final voices = await FlutterTts().getVoices;
// Select Microsoft David or Zira
await FlutterTts().setVoice({"name": "Microsoft David Desktop", "locale": "en-US"});
```

### Notifications

Windows Action Center notifications:

```dart
// Already configured in smart_notification_service.dart
// Customize notification sounds in assets/sounds/
```

---

## 📚 Additional Resources

- [Flutter Windows Desktop](https://docs.flutter.dev/desktop)
- [Windows App Development](https://docs.microsoft.com/en-us/windows/apps/)
- [Dona Documentation](./README.md)
- [API Configuration](./docs/NEW_INTEGRATIONS.md)

---

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] `flutter doctor` shows no errors
- [ ] App runs with `flutter run -d windows`
- [ ] Voice recognition works
- [ ] Notifications appear in Action Center
- [ ] File operations work correctly
- [ ] API integrations connect successfully
- [ ] Focus mode enables/disables correctly
- [ ] Offline mode caches data
- [ ] All features accessible via keyboard

---

## 🎉 You're All Set!

Dona AI is now configured for Windows. Enjoy your perfect personal assistant!

For issues or questions, check the [Troubleshooting](#-troubleshooting) section or open an issue on GitHub.

**Made with ❤️ for Windows users**
