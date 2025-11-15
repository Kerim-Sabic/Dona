import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';
import '../../config/api_keys.dart';
import '../storage/local_storage_service.dart';

/// Google Drive file model
class DriveFile {
  final String? id;
  final String name;
  final String? mimeType;
  final int? size;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final String? webViewLink;
  final String? webContentLink;
  final bool? starred;
  final bool? trashed;
  final List<String>? parents;
  final Map<String, dynamic>? metadata;

  DriveFile({
    this.id,
    required this.name,
    this.mimeType,
    this.size,
    this.createdTime,
    this.modifiedTime,
    this.webViewLink,
    this.webContentLink,
    this.starred,
    this.trashed,
    this.parents,
    this.metadata,
  });

  factory DriveFile.fromJson(Map<String, dynamic> json) {
    return DriveFile(
      id: json['id'] as String?,
      name: json['name'] as String,
      mimeType: json['mimeType'] as String?,
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
      createdTime: json['createdTime'] != null ? DateTime.parse(json['createdTime']) : null,
      modifiedTime: json['modifiedTime'] != null ? DateTime.parse(json['modifiedTime']) : null,
      webViewLink: json['webViewLink'] as String?,
      webContentLink: json['webContentLink'] as String?,
      starred: json['starred'] as bool?,
      trashed: json['trashed'] as bool?,
      parents: (json['parents'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      metadata: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (mimeType != null) 'mimeType': mimeType,
      if (parents != null) 'parents': parents,
    };
  }

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';
  String get sizeFormatted => size != null ? _formatBytes(size!) : 'Unknown';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Service for Google Drive API integration
class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  static GoogleDriveService get instance => _instance;

  GoogleDriveService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> init() async {
    try {
      // Try to load saved access token
      _accessToken = LocalStorageService.instance.getString('google_drive_access_token');
      final expiryStr = LocalStorageService.instance.getString('google_drive_token_expiry');
      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr);
      }

      AppLogger.info('GoogleDriveService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize GoogleDriveService', e, stackTrace);
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
      AppLogger.info('Starting Google Drive OAuth authentication...');

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': ApiKeys.gmailClientId,
        'redirect_uri': ApiKeys.googleCalendarRedirectUri,
        'response_type': 'token',
        'scope': ApiKeys.googleDriveScopes.join(' '),
        'include_granted_scopes': 'true',
        'state': 'dona_ai_drive',
      });

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        AppLogger.info('OAuth browser opened');
        return false;
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

    await LocalStorageService.instance.setString('google_drive_access_token', token);
    await LocalStorageService.instance.setString(
      'google_drive_token_expiry',
      _tokenExpiry!.toIso8601String(),
    );

    AppLogger.info('Google Drive access token set successfully');
  }

  /// List files in Drive
  Future<List<DriveFile>> listFiles({
    String? query,
    int pageSize = 20,
    String? pageToken,
    String orderBy = 'modifiedTime desc',
  }) async {
    try {
      if (!isAuthenticated) {
        AppLogger.warning('Not authenticated');
        return _getMockFiles();
      }

      AppLogger.debug('Listing Drive files...');

      final queryParams = {
        'pageSize': pageSize.toString(),
        'orderBy': orderBy,
        'fields': 'files(id,name,mimeType,size,createdTime,modifiedTime,webViewLink,webContentLink,starred,trashed,parents)',
      };

      if (query != null) {
        queryParams['q'] = query;
      }
      if (pageToken != null) {
        queryParams['pageToken'] = pageToken;
      }

      final url = Uri.https('www.googleapis.com', '/drive/v3/files', queryParams);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['files'] ?? [];

        final files = items.map((item) => DriveFile.fromJson(item)).toList();

        AppLogger.info('Fetched ${files.length} files');
        return files;
      } else if (response.statusCode == 401) {
        AppLogger.warning('Access token expired or invalid');
        _accessToken = null;
        return _getMockFiles();
      } else {
        throw Exception('Drive API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list files', e, stackTrace);
      return _getMockFiles();
    }
  }

  /// Search files
  Future<List<DriveFile>> searchFiles(String searchTerm) async {
    final query = "name contains '$searchTerm' and trashed=false";
    return listFiles(query: query);
  }

  /// Get recent files
  Future<List<DriveFile>> getRecentFiles({int limit = 20}) async {
    return listFiles(
      query: 'trashed=false',
      orderBy: 'viewedByMeTime desc',
      pageSize: limit,
    );
  }

  /// Get starred files
  Future<List<DriveFile>> getStarredFiles() async {
    return listFiles(query: 'starred=true and trashed=false');
  }

  /// Upload file to Drive
  Future<DriveFile?> uploadFile({
    required String fileName,
    required Uint8List fileContent,
    String? mimeType,
    String? folderId,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated. Please sign in first.');
      }

      AppLogger.debug('Uploading file: $fileName');

      // Create file metadata
      final metadata = {
        'name': fileName,
        if (mimeType != null) 'mimeType': mimeType,
        if (folderId != null) 'parents': [folderId],
      };

      final url = Uri.https(
        'www.googleapis.com',
        '/upload/drive/v3/files',
        {'uploadType': 'multipart'},
      );

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $_accessToken';

      // Add metadata
      request.files.add(
        http.MultipartFile.fromString(
          'metadata',
          jsonEncode(metadata),
          contentType: http.MediaType('application', 'json'),
        ),
      );

      // Add file content
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileContent,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uploadedFile = DriveFile.fromJson(data);
        AppLogger.info('File uploaded successfully: ${uploadedFile.id}');
        return uploadedFile;
      } else {
        throw Exception('Failed to upload file: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload file', e, stackTrace);
      return null;
    }
  }

  /// Download file from Drive
  Future<Uint8List?> downloadFile(String fileId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated');
      }

      AppLogger.debug('Downloading file: $fileId');

      final url = Uri.https(
        'www.googleapis.com',
        '/drive/v3/files/$fileId',
        {'alt': 'media'},
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        AppLogger.info('File downloaded successfully');
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to download file', e, stackTrace);
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile(String fileId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated');
      }

      AppLogger.debug('Deleting file: $fileId');

      final url = Uri.https('www.googleapis.com', '/drive/v3/files/$fileId');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 204) {
        AppLogger.info('File deleted successfully');
        return true;
      } else {
        throw Exception('Failed to delete file: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete file', e, stackTrace);
      return false;
    }
  }

  /// Create folder
  Future<DriveFile?> createFolder(String folderName, {String? parentFolderId}) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Not authenticated');
      }

      AppLogger.debug('Creating folder: $folderName');

      final metadata = {
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
        if (parentFolderId != null) 'parents': [parentFolderId],
      };

      final url = Uri.https('www.googleapis.com', '/drive/v3/files');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(metadata),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final folder = DriveFile.fromJson(data);
        AppLogger.info('Folder created successfully: ${folder.id}');
        return folder;
      } else {
        throw Exception('Failed to create folder: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create folder', e, stackTrace);
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _accessToken = null;
    _tokenExpiry = null;
    await LocalStorageService.instance.remove('google_drive_access_token');
    await LocalStorageService.instance.remove('google_drive_token_expiry');
    AppLogger.info('Signed out from Google Drive');
  }

  /// Get mock files for testing
  List<DriveFile> _getMockFiles() {
    final now = DateTime.now();
    return [
      DriveFile(
        id: '1',
        name: 'Project Proposal.pdf',
        mimeType: 'application/pdf',
        size: 2048576,
        modifiedTime: now.subtract(const Duration(days: 2)),
        starred: true,
      ),
      DriveFile(
        id: '2',
        name: 'Meeting Notes',
        mimeType: 'application/vnd.google-apps.folder',
        modifiedTime: now.subtract(const Duration(days: 5)),
      ),
      DriveFile(
        id: '3',
        name: 'Budget 2024.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        size: 512000,
        modifiedTime: now.subtract(const Duration(days: 10)),
      ),
    ];
  }
}
