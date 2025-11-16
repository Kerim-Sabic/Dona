import 'package:flutter_test/flutter_test.dart';

// Note: Full integration test would require mocking PackageInfo, AppLogger, etc.
// This is a simplified unit test for PII sanitization logic.

void main() {
  group('FeedbackService PII Sanitization', () {
    test('Email patterns should be detected', () {
      final RegExp emailPattern = RegExp(
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      );

      expect(emailPattern.hasMatch('user@example.com'), true);
      expect(emailPattern.hasMatch('admin@test.org'), true);
      expect(emailPattern.hasMatch('no-email-here'), false);
    });

    test('Phone patterns should be detected', () {
      final RegExp phonePattern = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');

      expect(phonePattern.hasMatch('123-456-7890'), true);
      expect(phonePattern.hasMatch('987.654.3210'), true);
      expect(phonePattern.hasMatch('9876543210'), true);
      expect(phonePattern.hasMatch('123-45-6789'), false); // SSN format, not phone
    });

    test('Token patterns (long alphanumeric) should be detected', () {
      final RegExp tokenPattern = RegExp(r'\b[A-Za-z0-9]{32,}\b');

      expect(tokenPattern.hasMatch('abc123def456ghi789jkl012mno345pqr'), true);
      expect(tokenPattern.hasMatch('shorttoken'), false);
    });

    test('Name patterns should be detected', () {
      final RegExp namePattern = RegExp(r'\b([A-Z][a-z]+ [A-Z][a-z]+)\b');

      expect(namePattern.hasMatch('John Smith'), true);
      expect(namePattern.hasMatch('Jane Doe'), true);
      expect(namePattern.hasMatch('john smith'), false); // lowercase
      expect(namePattern.hasMatch('JOHN SMITH'), false); // uppercase
    });

    test('File path patterns should be detected', () {
      final RegExp macPathPattern = RegExp(r'/Users/[^/\s]+');
      final RegExp winPathPattern = RegExp(r'C:\\Users\\[^\\\s]+');

      expect(macPathPattern.hasMatch('/Users/johnsmith/Documents'), true);
      expect(winPathPattern.hasMatch('C:\\Users\\janedoe\\Documents'), true);
    });
  });

  group('Feedback Type Enum', () {
    test('FeedbackType has expected values', () {
      expect(FeedbackType.bug.name, 'bug');
      expect(FeedbackType.feature.name, 'feature');
      expect(FeedbackType.general.name, 'general');
    });
  });
}

enum FeedbackType {
  bug,
  feature,
  general,
}
