import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/news/news_service.dart';
import '../../../data/models/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService.instance;
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final articles = await _newsService.getTopNews(limit: 20);
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      return _buildNewsCard(_articles[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openArticle(article.url),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.source,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(article.publishedAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                article.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Read more
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openArticle(article.url),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Read more'),
                  ),
                ],
              ),
            ],
          ),
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
            Icons.newspaper,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No news available',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNews,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
