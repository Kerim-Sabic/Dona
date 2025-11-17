import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/input_sanitizer.dart';

/// Photo model
class Photo {
  final String id;
  final String name;
  final String filePath;
  final DateTime dateTime;
  final String? location;
  final List<String> tags;
  final int? width;
  final int? height;
  final int fileSizeBytes;
  final bool isFavorite;
  final String? albumId;

  Photo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.dateTime,
    this.location,
    this.tags = const [],
    this.width,
    this.height,
    required this.fileSizeBytes,
    this.isFavorite = false,
    this.albumId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'dateTime': dateTime.toIso8601String(),
        'location': location,
        'tags': tags,
        'width': width,
        'height': height,
        'fileSizeBytes': fileSizeBytes,
        'isFavorite': isFavorite,
        'albumId': albumId,
      };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'],
        name: json['name'],
        filePath: json['filePath'],
        dateTime: DateTime.parse(json['dateTime']),
        location: json['location'],
        tags: List<String>.from(json['tags'] ?? []),
        width: json['width'],
        height: json['height'],
        fileSizeBytes: json['fileSizeBytes'],
        isFavorite: json['isFavorite'] ?? false,
        albumId: json['albumId'],
      );

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get resolution {
    if (width == null || height == null) return 'Unknown';
    return '${width}x$height';
  }
}

/// Album model
class Album {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String? coverPhotoId;
  final int photoCount;

  Album({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.coverPhotoId,
    this.photoCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'coverPhotoId': coverPhotoId,
        'photoCount': photoCount,
      };

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        coverPhotoId: json['coverPhotoId'],
        photoCount: json['photoCount'] ?? 0,
      );
}

/// Photo & Gallery Management Service
/// Provides photo organization, search, and management capabilities
class PhotoGalleryService {
  static final PhotoGalleryService _instance = PhotoGalleryService._internal();
  static PhotoGalleryService get instance => _instance;

  PhotoGalleryService._internal();

  // Mock in-memory storage (In production, use Hive/SQLite)
  final List<Photo> _photos = [];
  final List<Album> _albums = [];

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      AppLogger.info('Initializing Photo Gallery Service...');

      // Load photos from storage
      await _loadPhotos();

      // Load albums from storage
      await _loadAlbums();

      // Create some demo data
      _createDemoData();

      _isInitialized = true;
      AppLogger.info('Photo Gallery Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Photo Gallery Service', e, stackTrace);
    }
  }

  Future<void> _loadPhotos() async {
    // In production, load from Hive database
    // For now, photos will be added via device camera/gallery
    AppLogger.debug('Photos loaded from storage');
  }

  Future<void> _loadAlbums() async {
    // In production, load from Hive database
    AppLogger.debug('Albums loaded from storage');
  }

  void _createDemoData() {
    // Create demo albums
    final vacationAlbum = Album(
      id: 'album_1',
      name: 'Summer Vacation 2024',
      description: 'Trip to the beach',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      photoCount: 12,
    );

    final familyAlbum = Album(
      id: 'album_2',
      name: 'Family',
      description: 'Family photos and memories',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      photoCount: 45,
    );

    final eventsAlbum = Album(
      id: 'album_3',
      name: 'Special Events',
      description: 'Birthdays, weddings, celebrations',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      photoCount: 28,
    );

    _albums.addAll([vacationAlbum, familyAlbum, eventsAlbum]);

    // Create demo photos
    final now = DateTime.now();
    final demoPhotos = [
      Photo(
        id: 'photo_1',
        name: 'Beach Sunset',
        filePath: '/storage/photos/beach_sunset.jpg',
        dateTime: now.subtract(const Duration(days: 30)),
        location: 'Miami Beach, FL',
        tags: ['sunset', 'beach', 'vacation'],
        width: 4032,
        height: 3024,
        fileSizeBytes: 3 * 1024 * 1024,
        isFavorite: true,
        albumId: 'album_1',
      ),
      Photo(
        id: 'photo_2',
        name: 'Family Dinner',
        filePath: '/storage/photos/family_dinner.jpg',
        dateTime: now.subtract(const Duration(days: 15)),
        location: 'Home',
        tags: ['family', 'dinner', 'celebration'],
        width: 3840,
        height: 2160,
        fileSizeBytes: 2 * 1024 * 1024,
        isFavorite: false,
        albumId: 'album_2',
      ),
      Photo(
        id: 'photo_3',
        name: 'Birthday Party',
        filePath: '/storage/photos/birthday_party.jpg',
        dateTime: now.subtract(const Duration(days: 60)),
        location: 'Restaurant',
        tags: ['birthday', 'party', 'celebration'],
        width: 4032,
        height: 3024,
        fileSizeBytes: 4 * 1024 * 1024,
        isFavorite: true,
        albumId: 'album_3',
      ),
    ];

    _photos.addAll(demoPhotos);
  }

  /// Get all photos
  Future<List<Photo>> getAllPhotos({
    String? sortBy = 'date',
    bool ascending = false,
  }) async {
    var photos = List<Photo>.from(_photos);

    // Sort photos
    switch (sortBy) {
      case 'date':
        photos.sort((a, b) => ascending
            ? a.dateTime.compareTo(b.dateTime)
            : b.dateTime.compareTo(a.dateTime));
        break;
      case 'name':
        photos.sort((a, b) =>
            ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 'size':
        photos.sort((a, b) => ascending
            ? a.fileSizeBytes.compareTo(b.fileSizeBytes)
            : b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
    }

    return photos;
  }

  /// Get photos by album
  Future<List<Photo>> getPhotosByAlbum(String albumId) async {
    return _photos.where((photo) => photo.albumId == albumId).toList();
  }

  /// Get favorite photos
  Future<List<Photo>> getFavoritePhotos() async {
    return _photos.where((photo) => photo.isFavorite).toList();
  }

  /// Search photos by tags
  Future<List<Photo>> searchPhotosByTags(List<String> tags) async {
    return _photos.where((photo) {
      return photo.tags.any((tag) => tags.contains(tag.toLowerCase()));
    }).toList();
  }

  /// Search photos by location
  Future<List<Photo>> searchPhotosByLocation(String location) async {
    final sanitizedLocation = InputSanitizer.sanitizeLocationName(location);
    return _photos.where((photo) {
      return photo.location?.toLowerCase().contains(sanitizedLocation.toLowerCase()) ?? false;
    }).toList();
  }

  /// Search photos by date range
  Future<List<Photo>> searchPhotosByDateRange(DateTime start, DateTime end) async {
    return _photos.where((photo) {
      return photo.dateTime.isAfter(start) && photo.dateTime.isBefore(end);
    }).toList();
  }

  /// Get photos from today
  Future<List<Photo>> getPhotosToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return searchPhotosByDateRange(startOfDay, endOfDay);
  }

  /// Get photos from this week
  Future<List<Photo>> getPhotosThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return searchPhotosByDateRange(startOfWeek, endOfWeek);
  }

  /// Get photos from this month
  Future<List<Photo>> getPhotosThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return searchPhotosByDateRange(startOfMonth, endOfMonth);
  }

  /// Add photo to favorites
  Future<bool> toggleFavorite(String photoId) async {
    try {
      final index = _photos.indexWhere((p) => p.id == photoId);
      if (index == -1) return false;

      final photo = _photos[index];
      final updated = Photo(
        id: photo.id,
        name: photo.name,
        filePath: photo.filePath,
        dateTime: photo.dateTime,
        location: photo.location,
        tags: photo.tags,
        width: photo.width,
        height: photo.height,
        fileSizeBytes: photo.fileSizeBytes,
        isFavorite: !photo.isFavorite,
        albumId: photo.albumId,
      );

      _photos[index] = updated;
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle favorite', e, stackTrace);
      return false;
    }
  }

  /// Add tags to photo
  Future<bool> addTagsToPhoto(String photoId, List<String> tags) async {
    try {
      final index = _photos.indexWhere((p) => p.id == photoId);
      if (index == -1) return false;

      final photo = _photos[index];
      final sanitizedTags = tags
          .map((tag) => InputSanitizer.sanitizeText(tag, maxLength: 50))
          .where((tag) => tag.isNotEmpty)
          .toList();

      final updatedTags = [...photo.tags, ...sanitizedTags].toSet().toList();

      final updated = Photo(
        id: photo.id,
        name: photo.name,
        filePath: photo.filePath,
        dateTime: photo.dateTime,
        location: photo.location,
        tags: updatedTags,
        width: photo.width,
        height: photo.height,
        fileSizeBytes: photo.fileSizeBytes,
        isFavorite: photo.isFavorite,
        albumId: photo.albumId,
      );

      _photos[index] = updated;
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add tags', e, stackTrace);
      return false;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(String photoId) async {
    try {
      final index = _photos.indexWhere((p) => p.id == photoId);
      if (index == -1) return false;

      _photos.removeAt(index);
      AppLogger.info('Photo deleted: $photoId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete photo', e, stackTrace);
      return false;
    }
  }

  /// Get all albums
  Future<List<Album>> getAllAlbums() async {
    return List<Album>.from(_albums);
  }

  /// Create new album
  Future<Album> createAlbum({
    required String name,
    String? description,
  }) async {
    final sanitizedName = InputSanitizer.sanitizeText(name, maxLength: 100);
    final sanitizedDesc = description != null
        ? InputSanitizer.sanitizeText(description, maxLength: 500)
        : null;

    final album = Album(
      id: 'album_${DateTime.now().millisecondsSinceEpoch}',
      name: sanitizedName,
      description: sanitizedDesc,
      createdAt: DateTime.now(),
      photoCount: 0,
    );

    _albums.add(album);
    AppLogger.info('Album created: ${album.name}');
    return album;
  }

  /// Delete album
  Future<bool> deleteAlbum(String albumId) async {
    try {
      final index = _albums.indexWhere((a) => a.id == albumId);
      if (index == -1) return false;

      _albums.removeAt(index);

      // Remove album association from photos
      for (var i = 0; i < _photos.length; i++) {
        if (_photos[i].albumId == albumId) {
          final photo = _photos[i];
          _photos[i] = Photo(
            id: photo.id,
            name: photo.name,
            filePath: photo.filePath,
            dateTime: photo.dateTime,
            location: photo.location,
            tags: photo.tags,
            width: photo.width,
            height: photo.height,
            fileSizeBytes: photo.fileSizeBytes,
            isFavorite: photo.isFavorite,
            albumId: null,
          );
        }
      }

      AppLogger.info('Album deleted: $albumId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete album', e, stackTrace);
      return false;
    }
  }

  /// Move photo to album
  Future<bool> movePhotoToAlbum(String photoId, String albumId) async {
    try {
      final photoIndex = _photos.indexWhere((p) => p.id == photoId);
      if (photoIndex == -1) return false;

      final albumExists = _albums.any((a) => a.id == albumId);
      if (!albumExists) return false;

      final photo = _photos[photoIndex];
      _photos[photoIndex] = Photo(
        id: photo.id,
        name: photo.name,
        filePath: photo.filePath,
        dateTime: photo.dateTime,
        location: photo.location,
        tags: photo.tags,
        width: photo.width,
        height: photo.height,
        fileSizeBytes: photo.fileSizeBytes,
        isFavorite: photo.isFavorite,
        albumId: albumId,
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to move photo to album', e, stackTrace);
      return false;
    }
  }

  /// Get gallery summary
  Future<String> getGallerySummary() async {
    try {
      final totalPhotos = _photos.length;
      final favoritePhotos = _photos.where((p) => p.isFavorite).length;
      final totalAlbums = _albums.length;

      final totalSize = _photos.fold<int>(
        0,
        (sum, photo) => sum + photo.fileSizeBytes,
      );

      final formattedSize = _formatBytes(totalSize);

      final buffer = StringBuffer('📸 Photo Gallery Summary\n\n');
      buffer.writeln('📊 Statistics:');
      buffer.writeln('  • Total Photos: $totalPhotos');
      buffer.writeln('  • Favorites: $favoritePhotos');
      buffer.writeln('  • Albums: $totalAlbums');
      buffer.writeln('  • Total Size: $formattedSize');
      buffer.writeln();

      if (_albums.isNotEmpty) {
        buffer.writeln('📁 Albums:');
        for (var i = 0; i < _albums.length && i < 5; i++) {
          final album = _albums[i];
          final photoCount = _photos.where((p) => p.albumId == album.id).length;
          buffer.writeln('  ${i + 1}. ${album.name} ($photoCount photos)');
        }
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get gallery summary', e, stackTrace);
      return 'Unable to load gallery summary.';
    }
  }

  /// Get photo details
  String formatPhotoDetails(Photo photo) {
    final buffer = StringBuffer('📷 Photo Details\n\n');
    buffer.writeln('📝 Name: ${photo.name}');
    buffer.writeln('📅 Date: ${_formatDate(photo.dateTime)}');
    buffer.writeln('📐 Resolution: ${photo.resolution}');
    buffer.writeln('💾 Size: ${photo.formattedSize}');

    if (photo.location != null) {
      buffer.writeln('📍 Location: ${photo.location}');
    }

    if (photo.tags.isNotEmpty) {
      buffer.writeln('🏷️ Tags: ${photo.tags.join(", ")}');
    }

    if (photo.isFavorite) {
      buffer.writeln('⭐ Favorite');
    }

    if (photo.albumId != null) {
      final album = _albums.firstWhere(
        (a) => a.id == photo.albumId,
        orElse: () => Album(
          id: '',
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );
      buffer.writeln('📁 Album: ${album.name}');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get help message
  String getPhotoHelp() {
    return '''
📸 Photo & Gallery Help:

Gallery Management:
• "Show my photos" - View all photos
• "Show favorites" - View favorite photos
• "Photos from today/this week/this month"

Albums:
• "Create album [name]" - Create new album
• "Show albums" - View all albums
• "Photos in [album name]" - View photos in album

Search:
• "Photos with tag [tag]" - Find photos by tag
• "Photos in [location]" - Find photos by location
• "Beach photos" or "Sunset photos" - Natural search

Organization:
• "Add to favorites [photo]" - Mark as favorite
• "Add tags [photo]" - Add tags to photo
• "Move to album [photo] [album]" - Organize photos

Examples:
• "Show my favorite photos"
• "Photos from last week"
• "Create album Summer 2024"
• "Photos tagged with vacation"
''';
  }
}
