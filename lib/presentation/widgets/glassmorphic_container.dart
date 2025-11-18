import 'dart:ui';
import 'package:flutter/material.dart';

/// GlassmorphicContainer - iOS-style frosted glass effect container
///
/// Creates a translucent container with blur effect, gradient, and border
/// following iOS Human Interface Guidelines for glassmorphism design.
///
/// Usage:
/// ```dart
/// GlassmorphicContainer(
///   width: 200,
///   height: 100,
///   child: Text('Hello'),
/// )
/// ```
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final BoxShape shape;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.gradientColors,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default colors based on theme
    final defaultColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);

    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.3);

    final defaultGradientColors = isDark
        ? [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ]
        : [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
        shape: shape,
        border: Border.all(
          color: borderColor ?? defaultBorderColor,
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ?? defaultGradientColors,
                begin: gradientBegin ?? Alignment.topLeft,
                end: gradientEnd ?? Alignment.bottomRight,
              ),
              color: color ?? defaultColor,
              borderRadius: shape == BoxShape.rectangle
                  ? BorderRadius.circular(borderRadius)
                  : null,
              shape: shape,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// GlassCard - Glassmorphic card widget with elevation effect
///
/// A pre-configured glassmorphic container optimized for card layouts.
///
/// Usage:
/// ```dart
/// GlassCard(
///   child: ListTile(
///     title: Text('Item'),
///     subtitle: Text('Description'),
///   ),
/// )
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    this.borderRadius = 16,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final glassCard = GlassmorphicContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: elevated ? 15 : 10,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: glassCard,
      );
    }

    return glassCard;
  }
}

/// GlassAppBar - Glassmorphic app bar with translucent effect
///
/// Creates an iOS-style translucent app bar that blurs content behind it.
///
/// Usage:
/// ```dart
/// GlassAppBar(
///   title: Text('My App'),
///   actions: [IconButton(...)],
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.2),
                    ]
                  : [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            title: title,
            actions: actions,
            leading: leading,
            centerTitle: centerTitle,
            elevation: elevation,
            backgroundColor: backgroundColor ?? Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// GlassBottomSheet - Glassmorphic bottom sheet
///
/// Creates a translucent bottom sheet with blur effect.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   backgroundColor: Colors.transparent,
///   builder: (context) => GlassBottomSheet(
///     child: YourContent(),
///   ),
/// )
/// ```
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// GlassDialog - Glassmorphic dialog
///
/// Creates a translucent dialog with blur effect.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierColor: Colors.black26,
///   builder: (context) => GlassDialog(
///     title: Text('Title'),
///     content: Text('Content'),
///     actions: [TextButton(...)],
///   ),
/// )
/// ```
class GlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;

  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding = const EdgeInsets.all(20),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassmorphicContainer(
        borderRadius: borderRadius,
        padding: const EdgeInsets.all(0),
        blur: 15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.headlineSmall!,
                  child: title!,
                ),
              ),
            if (content != null)
              Flexible(
                child: Padding(
                  padding: contentPadding!,
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyLarge!,
                    child: content!,
                  ),
                ),
              ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// GlassButton - Glassmorphic button
///
/// Creates a translucent button with blur effect.
///
/// Usage:
/// ```dart
/// GlassButton(
///   onPressed: () {},
///   child: Text('Button'),
/// )
/// ```
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 12,
    this.blur = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: GlassmorphicContainer(
          padding: padding,
          borderRadius: borderRadius,
          blur: blur,
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
