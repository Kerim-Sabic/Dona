import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../../config/api_keys_secure.dart';

/// SMS Message model
class SmsMessage {
  final String? sid;
  final String to;
  final String? from;
  final String body;
  final String? status;
  final DateTime? dateSent;
  final DateTime? dateCreated;
  final String? errorMessage;
  final String? errorCode;

  SmsMessage({
    this.sid,
    required this.to,
    this.from,
    required this.body,
    this.status,
    this.dateSent,
    this.dateCreated,
    this.errorMessage,
    this.errorCode,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      sid: json['sid'] as String?,
      to: (json['to'] as String?) ?? '',
      from: json['from'] as String?,
      body: (json['body'] as String?) ?? '',
      status: json['status'] as String?,
      dateSent: json['date_sent'] != null ? DateTime.parse(json['date_sent']) : null,
      dateCreated: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      errorMessage: json['error_message'] as String?,
      errorCode: json['error_code'] as String?,
    );
  }

  bool get isDelivered => status == 'delivered';
  bool get isSent => status == 'sent';
  bool get hasFailed => status == 'failed';
}

/// Phone Call model
class PhoneCall {
  final String? sid;
  final String to;
  final String? from;
  final String? status;
  final DateTime? dateCreated;
  final int? duration;
  final String? direction;
  final String? errorMessage;

  PhoneCall({
    this.sid,
    required this.to,
    this.from,
    this.status,
    this.dateCreated,
    this.duration,
    this.direction,
    this.errorMessage,
  });

  factory PhoneCall.fromJson(Map<String, dynamic> json) {
    return PhoneCall(
      sid: json['sid'] as String?,
      to: (json['to'] as String?) ?? '',
      from: json['from'] as String?,
      status: json['status'] as String?,
      dateCreated: json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      duration: json['duration'] != null ? int.tryParse(json['duration'].toString()) : null,
      direction: json['direction'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in-progress';
  bool get hasFailed => status == 'failed';
}

/// Service for Twilio Voice & SMS APIs
class TwilioService {
  static final TwilioService _instance = TwilioService._internal();
  static TwilioService get instance => _instance;

  TwilioService._internal();

  String get _accountSid => ApiKeys.twilioAccountSid;
  String get _authToken => ApiKeys.twilioAuthToken;
  String get _fromPhoneNumber => ApiKeys.twilioPhoneNumber;

  /// Get Basic Auth credentials for Twilio API
  String get _basicAuth {
    final credentials = '$_accountSid:$_authToken';
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  Future<void> init() async {
    try {
      AppLogger.info('TwilioService initialized');
      AppLogger.debug('Account SID: $_accountSid');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize TwilioService', e, stackTrace);
    }
  }

  /// Send SMS message
  Future<SmsMessage?> sendSms({
    required String to,
    required String message,
    String? from,
  }) async {
    try {
      AppLogger.debug('Sending SMS to $to');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid/Messages.json',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': _basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': to,
          'From': from ?? _fromPhoneNumber,
          'Body': message,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sms = SmsMessage.fromJson(data);
        AppLogger.info('SMS sent successfully: ${sms.sid}');
        return sms;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Twilio SMS error: ${error['message'] ?? response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send SMS', e, stackTrace);
      return null;
    }
  }

  /// Make phone call
  Future<PhoneCall?> makeCall({
    required String to,
    required String twimlUrl, // URL to TwiML instructions
    String? from,
    String? statusCallback,
  }) async {
    try {
      AppLogger.debug('Making call to $to');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid/Calls.json',
      );

      final body = {
        'To': to,
        'From': from ?? _fromPhoneNumber,
        'Url': twimlUrl,
      };

      if (statusCallback != null) {
        body['StatusCallback'] = statusCallback;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': _basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final call = PhoneCall.fromJson(data);
        AppLogger.info('Call initiated successfully: ${call.sid}');
        return call;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Twilio Call error: ${error['message'] ?? response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to make call', e, stackTrace);
      return null;
    }
  }

  /// Make a simple call with text-to-speech
  /// Creates a basic TwiML response that speaks the message
  Future<PhoneCall?> makeCallWithMessage({
    required String to,
    required String message,
    String? from,
    String voice = 'alice', // alice, man, woman
    String language = 'en-US',
  }) async {
    try {
      // For a simple implementation, we'll need a TwiML endpoint
      // In a real app, you'd host this TwiML on your server
      // For now, we'll use Twilio's TwiML Bins or assume you have an endpoint

      AppLogger.warning(
        'makeCallWithMessage requires a TwiML endpoint. Please set up TwiML Bins or host your own endpoint.',
      );

      // Example TwiML:
      // <?xml version="1.0" encoding="UTF-8"?>
      // <Response>
      //   <Say voice="alice" language="en-US">$message</Say>
      // </Response>

      // You would need to create this TwiML dynamically on your server
      // and pass the URL to makeCall()

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to make call with message', e, stackTrace);
      return null;
    }
  }

  /// Get SMS message status
  Future<SmsMessage?> getSmsStatus(String messageSid) async {
    try {
      AppLogger.debug('Getting SMS status: $messageSid');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid/Messages/$messageSid.json',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _basicAuth,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SmsMessage.fromJson(data);
      } else {
        throw Exception('Twilio API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get SMS status', e, stackTrace);
      return null;
    }
  }

  /// Get call status
  Future<PhoneCall?> getCallStatus(String callSid) async {
    try {
      AppLogger.debug('Getting call status: $callSid');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid/Calls/$callSid.json',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _basicAuth,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PhoneCall.fromJson(data);
      } else {
        throw Exception('Twilio API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get call status', e, stackTrace);
      return null;
    }
  }

  /// Get recent SMS messages
  Future<List<SmsMessage>> getRecentMessages({int limit = 20}) async {
    try {
      AppLogger.debug('Getting recent messages');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid/Messages.json',
      ).replace(queryParameters: {
        'PageSize': limit.toString(),
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': _basicAuth,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List<dynamic>?)
                ?.map((msg) => SmsMessage.fromJson(msg))
                .toList() ??
            [];

        AppLogger.info('Fetched ${messages.length} messages');
        return messages;
      } else {
        throw Exception('Twilio API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get recent messages', e, stackTrace);
      return [];
    }
  }

  /// Get recent calls
  Future<List<PhoneCall>> getRecentCalls({int limit = 20}) async {
    try {
      AppLogger.debug('Getting recent calls');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid/Calls.json',
      ).replace(queryParameters: {
        'PageSize': limit.toString(),
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': _basicAuth,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final calls = (data['calls'] as List<dynamic>?)
                ?.map((call) => PhoneCall.fromJson(call))
                .toList() ??
            [];

        AppLogger.info('Fetched ${calls.length} calls');
        return calls;
      } else {
        throw Exception('Twilio API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get recent calls', e, stackTrace);
      return [];
    }
  }

  /// Verify Twilio credentials
  Future<bool> verifyCredentials() async {
    try {
      AppLogger.debug('Verifying Twilio credentials');

      final url = Uri.parse(
        '${ApiConfig.twilioBaseUrl}/Accounts/$_accountSid.json',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': _basicAuth,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        AppLogger.info('Twilio credentials verified successfully');
        return true;
      } else {
        AppLogger.error('Invalid Twilio credentials: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to verify credentials', e, stackTrace);
      return false;
    }
  }

  /// Generate TwiML for text-to-speech
  String generateTwiML({
    required String message,
    String voice = 'alice',
    String language = 'en-US',
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="$voice" language="$language">$message</Say>
</Response>''';
  }
}
