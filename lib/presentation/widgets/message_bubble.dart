import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../screens/chat/chat_screen.dart';

/// MessageBubble - Glassmorphic chat message bubble
///
/// A beautiful iOS-style translucent message bubble for chat interface.
/// Different styles for user messages vs assistant messages with icons.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getBubbleColors(isDark, isUser),
                    ),
                    border: Border.all(
                      color: _getBorderColor(isDark, isUser),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon for assistant messages
                      if (!isUser) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary.withOpacity(0.3),
                                AppColors.info.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.psychology,
                            size: 16,
                            color: isDark
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Message content
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style:
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: _getTextColor(isDark, isUser),
                                        height: 1.4,
                                      ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.5)
                                        : (isUser
                                            ? Colors.white.withOpacity(0.7)
                                            : AppColors.textSecondary.withOpacity(0.7)),
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getBubbleColors(bool isDark, bool isUser) {
    if (isUser) {
      // User message: Blue gradient
      return isDark
          ? [
              AppColors.secondary.withOpacity(0.4),
              AppColors.info.withOpacity(0.3),
            ]
          : [
              AppColors.secondary.withOpacity(0.35),
              AppColors.info.withOpacity(0.25),
            ];
    } else {
      // Assistant message: Neutral gradient
      return isDark
          ? [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.08),
            ]
          : [
              Colors.white.withOpacity(0.7),
              Colors.white.withOpacity(0.5),
            ];
    }
  }

  Color _getBorderColor(bool isDark, bool isUser) {
    if (isUser) {
      return isDark
          ? AppColors.secondary.withOpacity(0.3)
          : AppColors.secondary.withOpacity(0.4);
    } else {
      return isDark
          ? Colors.white.withOpacity(0.15)
          : Colors.white.withOpacity(0.3);
    }
  }

  Color _getTextColor(bool isDark, bool isUser) {
    if (isDark) {
      return Colors.white.withOpacity(0.95);
    } else {
      return isUser ? Colors.white : AppColors.textPrimary;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
