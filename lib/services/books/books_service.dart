import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Book model
class Book {
  final String key;
  final String title;
  final List<String> authors;
  final String? firstPublishYear;
  final List<String> isbn;
  final String? coverUrl;
  final int? numberOfPages;
  final List<String> subjects;
  final String? description;

  Book({
    required this.key,
    required this.title,
    required this.authors,
    this.firstPublishYear,
    required this.isbn,
    this.coverUrl,
    this.numberOfPages,
    required this.subjects,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Extract authors
    final authors = <String>[];
    if (json['author_name'] is List) {
      authors.addAll(List<String>.from(json['author_name']));
    } else if (json['authors'] is List) {
      for (var author in json['authors']) {
        if (author['name'] != null) {
          authors.add(author['name']);
        }
      }
    }

    // Extract ISBN
    final isbn = <String>[];
    if (json['isbn'] is List) {
      isbn.addAll(List<String>.from(json['isbn']));
    }

    // Extract subjects
    final subjects = <String>[];
    if (json['subject'] is List) {
      subjects.addAll(List<String>.from(json['subject']).take(10).toList());
    }

    // Get cover URL
    String? coverUrl;
    if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-L.jpg';
    } else if (isbn.isNotEmpty) {
      coverUrl = 'https://covers.openlibrary.org/b/isbn/${isbn.first}-L.jpg';
    }

    return Book(
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      authors: authors,
      firstPublishYear: json['first_publish_year']?.toString(),
      isbn: isbn,
      coverUrl: coverUrl,
      numberOfPages: json['number_of_pages_median'],
      subjects: subjects,
      description: json['description'] is String
          ? json['description']
          : json['description']?['value'],
    );
  }
}

/// Author model
class Author {
  final String key;
  final String name;
  final String? birthDate;
  final String? bio;
  final String? photoUrl;

  Author({
    required this.key,
    required this.name,
    this.birthDate,
    this.bio,
    this.photoUrl,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    String? photoUrl;
    if (json['photos'] is List && (json['photos'] as List).isNotEmpty) {
      final photoId = json['photos'][0];
      photoUrl = 'https://covers.openlibrary.org/a/id/$photoId-L.jpg';
    }

    return Author(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      birthDate: json['birth_date'],
      bio: json['bio'] is String
          ? json['bio']
          : json['bio']?['value'],
      photoUrl: photoUrl,
    );
  }
}

/// Open Library Books API Service
/// https://openlibrary.org/ - Completely FREE, No API Key Required!
/// 30+ million books from Internet Archive
class BooksService {
  static final BooksService _instance = BooksService._internal();
  static BooksService get instance => _instance;

  BooksService._internal();

  static const String _baseUrl = 'https://openlibrary.org';
  static const String _searchUrl = 'https://openlibrary.org/search.json';
  static const Duration _timeout = Duration(seconds: 15);

  Future<void> init() async {
    AppLogger.info('BooksService initialized with Open Library API');
  }

  /// Search books by query
  Future<List<Book>> searchBooks(String query, {int limit = 10}) async {
    try {
      AppLogger.debug('Searching books: $query');

      final params = {
        'q': query,
        'limit': limit.toString(),
        'fields': 'key,title,author_name,first_publish_year,isbn,cover_i,number_of_pages_median,subject',
      };

      final uri = Uri.parse(_searchUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = data['docs'] as List<dynamic>?;
        if (docs != null) {
          return docs.map((doc) => Book.fromJson(doc)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search books', e, stackTrace);
      return [];
    }
  }

  /// Search books by author
  Future<List<Book>> searchByAuthor(String author, {int limit = 10}) async {
    try {
      AppLogger.debug('Searching books by author: $author');

      final params = {
        'author': author,
        'limit': limit.toString(),
        'fields': 'key,title,author_name,first_publish_year,isbn,cover_i,number_of_pages_median,subject',
      };

      final uri = Uri.parse(_searchUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = data['docs'] as List<dynamic>?;
        if (docs != null) {
          return docs.map((doc) => Book.fromJson(doc)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search by author', e, stackTrace);
      return [];
    }
  }

  /// Search books by subject/genre
  Future<List<Book>> searchBySubject(String subject, {int limit = 10}) async {
    try {
      AppLogger.debug('Searching books by subject: $subject');

      final params = {
        'subject': subject,
        'limit': limit.toString(),
        'fields': 'key,title,author_name,first_publish_year,isbn,cover_i,number_of_pages_median,subject',
      };

      final uri = Uri.parse(_searchUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = data['docs'] as List<dynamic>?;
        if (docs != null) {
          return docs.map((doc) => Book.fromJson(doc)).toList();
        }
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search by subject', e, stackTrace);
      return [];
    }
  }

  /// Get book by ISBN
  Future<Book?> getBookByISBN(String isbn) async {
    try {
      AppLogger.debug('Fetching book by ISBN: $isbn');

      final url = Uri.parse('$_baseUrl/isbn/$isbn.json');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Book.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get book by ISBN', e, stackTrace);
      return null;
    }
  }

  /// Get book details by key
  Future<Book?> getBookByKey(String key) async {
    try {
      AppLogger.debug('Fetching book: $key');

      final url = Uri.parse('$_baseUrl$key.json');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Book.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get book', e, stackTrace);
      return null;
    }
  }

  /// Get author details
  Future<Author?> getAuthor(String authorKey) async {
    try {
      AppLogger.debug('Fetching author: $authorKey');

      final url = Uri.parse('$_baseUrl$authorKey.json');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Author.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get author', e, stackTrace);
      return null;
    }
  }

  /// Get trending books (bestsellers)
  Future<List<Book>> getTrendingBooks({int limit = 10}) async {
    // Open Library doesn't have a trending endpoint, so we search popular subjects
    return searchBySubject('bestseller', limit: limit);
  }

  /// Get book recommendations by genre
  Future<List<Book>> getBooksByGenre(String genre, {int limit = 10}) async {
    return searchBySubject(genre, limit: limit);
  }

  /// Format book for display
  String formatBook(Book book) {
    final buffer = StringBuffer();
    buffer.writeln('📖 ${book.title}');

    if (book.authors.isNotEmpty) {
      buffer.writeln('✍️ by ${book.authors.join(', ')}');
    }

    if (book.firstPublishYear != null) {
      buffer.writeln('📅 First published: ${book.firstPublishYear}');
    }

    if (book.numberOfPages != null) {
      buffer.writeln('📄 Pages: ${book.numberOfPages}');
    }

    if (book.subjects.isNotEmpty) {
      buffer.writeln('🏷️ Genres: ${book.subjects.take(3).join(', ')}');
    }

    if (book.description != null && book.description!.isNotEmpty) {
      final desc = book.description!.length > 200
          ? '${book.description!.substring(0, 200)}...'
          : book.description!;
      buffer.writeln('\n📝 $desc');
    }

    return buffer.toString();
  }

  /// Get book summary
  Future<String> getBookSummary(String query) async {
    try {
      final books = await searchBooks(query, limit: 5);

      if (books.isEmpty) {
        return 'No books found for "$query"';
      }

      final buffer = StringBuffer('📚 Book Search Results:\n\n');

      for (var i = 0; i < books.length && i < 3; i++) {
        buffer.writeln('${i + 1}. ${formatBook(books[i])}\n');
      }

      if (books.length > 3) {
        buffer.writeln('...and ${books.length - 3} more results');
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get book summary', e, stackTrace);
      return 'Unable to search books at this time.';
    }
  }

  /// Get genre recommendations
  Future<String> getGenreRecommendations(String genre) async {
    try {
      final books = await getBooksByGenre(genre, limit: 5);

      if (books.isEmpty) {
        return 'No books found in genre "$genre"';
      }

      final buffer = StringBuffer('📚 $genre Books:\n\n');

      for (var i = 0; i < books.length && i < 5; i++) {
        final book = books[i];
        buffer.writeln('${i + 1}. ${book.title}');
        if (book.authors.isNotEmpty) {
          buffer.writeln('   by ${book.authors.first}');
        }
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get genre recommendations', e, stackTrace);
      return 'Unable to fetch book recommendations.';
    }
  }
}
