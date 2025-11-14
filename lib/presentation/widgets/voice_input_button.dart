import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class VoiceInputButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isListening ? AppColors.error : AppColors.secondary,
          shape: BoxShape.circle,
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
