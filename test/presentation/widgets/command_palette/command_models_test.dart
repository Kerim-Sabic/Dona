import 'package:flutter_test/flutter_test.dart';
import 'package:dona_ai/presentation/widgets/command_palette/command_models.dart';

void main() {
  group('PaletteCommand', () {
    test('Matches query against title', () {
      final command = PaletteCommand(
        id: 'test_1',
        title: 'Plan My Day',
        description: 'Organize your schedule',
        category: 'autopilot',
        keywords: ['plan', 'schedule'],
        onExecute: () async {},
      );

      expect(command.matches('plan'), isTrue);
      expect(command.matches('day'), isTrue);
      expect(command.matches('Plan'), isTrue); // Case insensitive
    });

    test('Matches query against description', () {
      final command = PaletteCommand(
        id: 'test_2',
        title: 'Focus Mode',
        description: 'Start a deep work session',
        category: 'autopilot',
        keywords: [],
        onExecute: () async {},
      );

      expect(command.matches('deep'), isTrue);
      expect(command.matches('work'), isTrue);
      expect(command.matches('session'), isTrue);
    });

    test('Matches query against keywords', () {
      final command = PaletteCommand(
        id: 'test_3',
        title: 'Study Autopilot',
        description: 'Create study plan',
        category: 'autopilot',
        keywords: ['exam', 'flashcards', 'quiz'],
        onExecute: () async {},
      );

      expect(command.matches('exam'), isTrue);
      expect(command.matches('flashcards'), isTrue);
      expect(command.matches('quiz'), isTrue);
    });

    test('Does not match unrelated queries', () {
      final command = PaletteCommand(
        id: 'test_4',
        title: 'Plan My Day',
        description: 'Organize your schedule',
        category: 'autopilot',
        keywords: ['plan', 'schedule'],
        onExecute: () async {},
      );

      expect(command.matches('email'), isFalse);
      expect(command.matches('workout'), isFalse);
    });

    test('Empty query matches everything', () {
      final command = PaletteCommand(
        id: 'test_5',
        title: 'Any Command',
        description: 'Does something',
        category: 'action',
        keywords: [],
        onExecute: () async {},
      );

      expect(command.matches(''), isTrue);
    });

    test('Display title includes icon when present', () {
      final command = PaletteCommand(
        id: 'test_6',
        title: 'Focus Mode',
        description: 'Deep work',
        category: 'autopilot',
        keywords: [],
        icon: '🎯',
        onExecute: () async {},
      );

      expect(command.displayTitle, equals('🎯 Focus Mode'));
    });

    test('Display title is just title when no icon', () {
      final command = PaletteCommand(
        id: 'test_7',
        title: 'Plain Command',
        description: 'No icon',
        category: 'action',
        keywords: [],
        onExecute: () async {},
      );

      expect(command.displayTitle, equals('Plain Command'));
    });
  });

  group('CommandCategory Extension', () {
    test('Has correct display names', () {
      expect(CommandCategory.autopilot.displayName, equals('Autopilots'));
      expect(CommandCategory.navigation.displayName, equals('Navigation'));
      expect(CommandCategory.action.displayName, equals('Actions'));
      expect(CommandCategory.search.displayName, equals('Search'));
      expect(CommandCategory.settings.displayName, equals('Settings'));
    });

    test('Has icons for all categories', () {
      expect(CommandCategory.autopilot.icon, equals('🤖'));
      expect(CommandCategory.navigation.icon, equals('🧭'));
      expect(CommandCategory.action.icon, equals('⚡'));
      expect(CommandCategory.search.icon, equals('🔍'));
      expect(CommandCategory.settings.icon, equals('⚙️'));
    });
  });
}
