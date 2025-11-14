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
}
