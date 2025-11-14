class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String source;
  final String? author;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.source,
    this.author,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'No title',
      description: json['text'] ?? json['description'] ?? 'No description',
      url: json['url'] ?? '',
      imageUrl: json['image'] ?? json['image_url'],
      publishedAt: json['publish_date'] != null
          ? DateTime.parse(json['publish_date'])
          : DateTime.now(),
      source: json['source'] ?? json['source_name'] ?? 'Unknown',
      author: json['author'] ?? json['authors']?.first,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'image_url': imageUrl,
      'publish_date': publishedAt.toIso8601String(),
      'source': source,
      'author': author,
    };
  }
}
