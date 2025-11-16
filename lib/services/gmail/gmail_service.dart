import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';
import '../../config/api_keys_secure.dart';
import '../storage/local_storage_service.dart';

/// Email message model
class EmailMessage {
  final String? id;
  final String? threadId;
  final List<String> to;
  final List<String>? cc;
  final List<String>? bcc;
  final String subject;
  final String body;
  final String? from;
  final DateTime? date;
  final bool? isRead;
  final List<String>? labels;

  EmailMessage({
    this.id,
    this.threadId,
    required this.to,
    this.cc,
    this.bcc,
    required this.subject,
    required this.body,
    this.from,
    this.date,
    this.isRead,
    this.labels,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    // Parse Gmail API response
    final payload = json['payload'] as Map<String, dynamic>?;
    final headers = payload?['headers'] as List<dynamic>? ?? [];

    String getHeader(String name) {
      final header = headers.firstWhere(
        (h) => (h['name'] as String).toLowerCase() == name.toLowerCase(),
        orElse: () => {'value': ''},
      );
      return header['value'] as String;
    }

    return EmailMessage(
      id: json['id'] as String?,
      threadId: json['threadId'] as String?,
      to: [getHeader('To')],
      subject: getHeader('Subject'),
      body: _extractBody(payload),
      from: getHeader('From'),
      date: DateTime.tryParse(getHeader('Date')),
      isRead: !(json['labelIds'] as List<dynamic>? ?? []).contains('UNREAD'),
      labels: (json['labelIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  static String _extractBody(Map<String, dynamic>? payload) {
    if (payload == null) return '';

    // Try to get plain text body
    if (payload['body'] != null && payload['body']['data'] != null) {
      return _decodeBase64(payload['body']['data']);
    }

    // Check parts for multipart messages
    final parts = payload['parts'] as List<dynamic>?;
    if (parts != null) {
      for (var part in parts) {
        if (part['mimeType'] == 'text/plain' && part['body']?['data'] != null) {
          return _decodeBase64(part['body']['data']);
        }
      }
    }

    return '';
  }

  static String _decodeBase64(String data) {
    try {
      // Gmail uses URL-safe base64
      final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
      return utf8.decode(base64.decode(normalized));
    } catch (e) {
      return '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'raw': _createRawMessage(),
    };
  }

  String _createRawMessage() {
    final buffer = StringBuffer();
    buffer.writeln('To: ${to.join(", ")}');
    if (cc != null && cc!.isNotEmpty) {
      buffer.writeln('Cc: ${cc!.join(", ")}');
    }
    if (bcc != null && bcc!.isNotEmpty) {
      buffer.writeln('Bcc: ${bcc!.join(", ")}');
    }
    buffer.writeln('Subject: $subject');
    buffer.writeln('Content-Type: text/plain; charset=utf-8');
    buffer.writeln();
    buffer.writeln(body);

    // Encode as base64url
    final bytes = utf8.encode(buffer.toString());
    final base64 = base64Encode(bytes);
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }
}

/// Service for Gmail API integration
class GmailService {
  static final GmailService _instance = GmailService._internal();
  static GmailService get instance => _instance;

  GmailService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> init() async {
    try {
      // Try to load saved access token
      _accessToken = LocalStorageService.instance.getString('gmail_access_token');
      final expiryStr = LocalStorageService.instance.getString('gmail_token_expiry');
      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr);
      }

      AppLogger.info('GmailService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GmailService', e, stackTrace);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Authenticate user with Google OAuth 2.0
  Future<bool> authenticate() async {
    try {
      AppLogger.info('Starting Gmail OAuth authentication...');

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': ApiKeys.gmailClientId,
        'redirect_uri': ApiKeys.googleCalendarRedirectUri,
        'response_type': 'token',
        'scope': ApiKeys.gmailScopes.join(' '),
        'include_granted_scopes': 'true',
        'state': 'dona_ai_gmail',
      });

      AppLogger.debug('OAuth URL: $authUrl');

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        AppLogger.info('OAuth browser opened');
        return false; // User needs to complete OAuth flow
      } else {
        throw Exception('Could not launch OAuth URL');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to authenticate', e, stackTrace);
      return false;
    }
  }

  /// Manually set access token
  Future<void> setAccessToken(String token, {int expiresInSeconds = 3600}) async {
    _accessToken = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));

    await LocalStorageService.instance.setString('gmail_access_token', token);
    await LocalStorageService.instance.setString(
      'gmail_token_expiry',
      _tokenExpiry!.toIso8601String(),
    );

    AppLogger.info('Gmail access token set successfully');
  }

  /// Get inbox messages
  Future<List<EmailMessage>> getInboxMessages({int maxResults = 20}) async {
    try {
      if (!isAuthenticated) {
        AppLogger.warning('Not authenticated');
        return [];
      }

      AppLogger.debug('Fetching inbox messages...');

      final url = Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages',
        {
          'maxResults': maxResults.toString(),
          'labelIds': 'INBOX',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messages = data['messages'] ?? [];

        // Fetch full message details
        final detailedMessages = <EmailMessage>[];
        for (var msg in messages.take(maxResults)) {
          final detailed = await _getMessageDetails(msg['id']);
          if (detailed != null) {
            detailedMessages.add(detailed);
          }
        }

        AppLogger.info('Fetched ${detailedMessages.length} messages');
        return detailedMessages;
      } else if (response.statusCode == 401) {
        AppLogger.warning('Access token expired or invalid');
        _accessToken = null;
        return [];
      } else {
        throw Exception('Gmail API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch inbox messages', e, stackTrace);
      return [];
    }
  }

  /// Get message details
  Future<EmailMessage?> _getMessageDetails(String messageId) async {
    try {
      final url = Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages/$messageId',
        {'format': 'full'},
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmailMessage.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch message details', e);
      return null;
    }
  }

  /// Send email
  Future<EmailMessage?> sendEmail(EmailMessage email) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated. Please sign in first.');
      }

      AppLogger.debug('Sending email: ${email.subject}');

      final url = Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages/send',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(email.toJson()),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Email sent successfully: ${data['id']}');
        return EmailMessage.fromJson(data);
      } else {
        AppLogger.error('Failed to send email: ${response.statusCode}', response.body, StackTrace.current);
        throw Exception('Failed to send email: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send email', e, stackTrace);
      return null;
    }
  }

  /// Mark message as read
  Future<bool> markAsRead(String messageId) async {
    return _modifyLabels(messageId, removeLabelIds: ['UNREAD']);
  }

  /// Mark message as unread
  Future<bool> markAsUnread(String messageId) async {
    return _modifyLabels(messageId, addLabelIds: ['UNREAD']);
  }

  /// Modify message labels
  Future<bool> _modifyLabels(
    String messageId, {
    List<String>? addLabelIds,
    List<String>? removeLabelIds,
  }) async {
    try {
      if (!isAuthenticated) return false;

      final url = Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages/$messageId/modify',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (addLabelIds != null) 'addLabelIds': addLabelIds,
          if (removeLabelIds != null) 'removeLabelIds': removeLabelIds,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to modify labels', e, stackTrace);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _accessToken = null;
    _tokenExpiry = null;
    await LocalStorageService.instance.remove('gmail_access_token');
    await LocalStorageService.instance.remove('gmail_token_expiry');
    AppLogger.info('Signed out from Gmail');
  }
}
