import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'command_models.dart';
import 'command_registry.dart';
import '../../../core/utils/logger.dart';

/// Global Command Palette
///
/// Allows users to search and execute commands from anywhere in the app.
/// Features:
/// - Fuzzy search over actions, autopilots, navigation
/// - Keyboard shortcuts support
/// - Real-time filtering
/// - Category grouping
class CommandPalette extends StatefulWidget {
  const CommandPalette({Key? key}) : super(key: key);

  /// Show command palette as bottom sheet
  static Future<void> show(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommandPalette(),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PaletteCommand> _filteredCommands = [];
  int _selectedIndex = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _filteredCommands = CommandRegistry.instance.allCommands;
    _searchController.addListener(_onSearchChanged);

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search to avoid excessive filtering
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      setState(() {
        final query = _searchController.text;
        _filteredCommands = CommandRegistry.instance.search(query);
        _selectedIndex = 0; // Reset selection on search
      });
    });
  }

  void _executeCommand(PaletteCommand command) async {
    try {
      AppLogger.info('Executing command: ${command.title}');

      // Close palette
      Navigator.of(context).pop();

      // Execute command
      await command.onExecute();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to execute command: ${command.title}', e, stackTrace);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to execute: ${command.title}')),
        );
      }
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) % _filteredCommands.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_filteredCommands.isNotEmpty) {
          _executeCommand(_filteredCommands[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyPress,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Command Palette',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search commands, autopilots, actions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.requestFocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${_filteredCommands.length} command${_filteredCommands.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_filteredCommands.isNotEmpty)
                    Text(
                      '↑↓ Navigate  ↵ Select  ESC Close',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Command list
            Expanded(
              child: _filteredCommands.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredCommands.length,
                      itemBuilder: (context, index) {
                        final command = _filteredCommands[index];
                        final isSelected = index == _selectedIndex;

                        return _buildCommandTile(command, isSelected);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandTile(PaletteCommand command, bool isSelected) {
    return InkWell(
      onTap: () => _executeCommand(command),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // Icon
            if (command.icon != null)
              Text(
                command.icon!,
                style: const TextStyle(fontSize: 24),
              ),
            if (command.icon != null) const SizedBox(width: 12),

            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    command.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(command.category),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                command.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No commands found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'autopilot':
        return Colors.blue;
      case 'navigation':
        return Colors.green;
      case 'action':
        return Colors.orange;
      case 'search':
        return Colors.purple;
      case 'settings':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
