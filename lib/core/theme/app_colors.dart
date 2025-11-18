import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Professional, confident (inspired by Donna's style)
  static const Color primary = Color(0xFF2C3E50); // Dark blue-grey
  static const Color primaryLight = Color(0xFF34495E);
  static const Color primaryDark = Color(0xFF1A252F);

  // Secondary Colors - Warm, friendly
  static const Color secondary = Color(0xFF3498DB); // Bright blue
  static const Color secondaryLight = Color(0xFF5DADE2);
  static const Color secondaryDark = Color(0xFF2874A6);

  // Accent Colors
  static const Color accent = Color(0xFFE74C3C); // Red accent
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentYellow = Color(0xFFF39C12);

  // Background
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Colors.white;

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Chat Bubbles
  static const Color userMessageBg = Color(0xFF3498DB);
  static const Color assistantMessageBg = Color(0xFFECF0F1);
  static const Color userMessageText = Colors.white;
  static const Color assistantMessageText = Color(0xFF2C3E50);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // iOS Glassmorphism Colors & Gradients
  // Light theme glass colors
  static LinearGradient glassGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.25),
      Colors.white.withOpacity(0.15),
    ],
  );

  // Dark theme glass colors
  static LinearGradient glassGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.15),
      Colors.white.withOpacity(0.05),
    ],
  );

  // Translucent background for screens
  static LinearGradient backgroundGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8EAF6), // Light indigo
      Color(0xFFF5F6FA), // Very light grey
    ],
  );

  static LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E), // Dark navy
      Color(0xFF16213E), // Darker navy
    ],
  );

  // Accent glass gradients (for colored cards)
  static LinearGradient glassAccentBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3498DB).withOpacity(0.2),
      Color(0xFF2874A6).withOpacity(0.1),
    ],
  );

  static LinearGradient glassAccentGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF27AE60).withOpacity(0.2),
      Color(0xFF1E8449).withOpacity(0.1),
    ],
  );

  static LinearGradient glassAccentRed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE74C3C).withOpacity(0.2),
      Color(0xFFC0392B).withOpacity(0.1),
    ],
  );

  static LinearGradient glassAccentYellow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF39C12).withOpacity(0.2),
      Color(0xFFD68910).withOpacity(0.1),
    ],
  );

  // Border colors for glass effect
  static Color glassBorderLight = Colors.white.withOpacity(0.3);
  static Color glassBorderDark = Colors.white.withOpacity(0.15);

  // Translucent overlay colors
  static Color glassOverlayLight = Colors.white.withOpacity(0.2);
  static Color glassOverlayDark = Colors.black.withOpacity(0.2);
}
