/// Command Palette Models
///
/// Defines commands that can be executed from the global command palette

/// A single command in the palette
class PaletteCommand {
  final String id;
  final String title;
  final String description;
  final String category; // 'autopilot', 'navigation', 'action', 'search'
  final List<String> keywords; // For fuzzy search
  final String? icon; // Optional emoji or icon
  final bool requiresConfirmation;
  final Future<void> Function() onExecute;

  const PaletteCommand({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.keywords,
    this.icon,
    this.requiresConfirmation = false,
    required this.onExecute,
  });

  /// Check if command matches search query
  bool matches(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();

    // Check title
    if (title.toLowerCase().contains(lowerQuery)) return true;

    // Check description
    if (description.toLowerCase().contains(lowerQuery)) return true;

    // Check keywords
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(lowerQuery)) return true;
    }

    return false;
  }

  /// Get display string with icon
  String get displayTitle {
    return icon != null ? '$icon $title' : title;
  }
}

/// Command category for grouping
enum CommandCategory {
  autopilot,
  navigation,
  action,
  search,
  settings,
}

extension CommandCategoryExtension on CommandCategory {
  String get displayName {
    switch (this) {
      case CommandCategory.autopilot:
        return 'Autopilots';
      case CommandCategory.navigation:
        return 'Navigation';
      case CommandCategory.action:
        return 'Actions';
      case CommandCategory.search:
        return 'Search';
      case CommandCategory.settings:
        return 'Settings';
    }
  }

  String get icon {
    switch (this) {
      case CommandCategory.autopilot:
        return '🤖';
      case CommandCategory.navigation:
        return '🧭';
      case CommandCategory.action:
        return '⚡';
      case CommandCategory.search:
        return '🔍';
      case CommandCategory.settings:
        return '⚙️';
    }
  }
}
