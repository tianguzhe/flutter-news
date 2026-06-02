import '../models/news_article.dart';
import '../models/news_page.dart';
import '../services/news_api.dart';

/// Data-layer boundary for news content.
///
/// UI view models depend on this repository instead of the HTTP service so the
/// feature can later add caching, pagination, or local data without changing UI.
abstract interface class NewsRepository {
  Future<NewsPage> fetchLatest({
    String query = 'ai',
    String category = 'technology',
    String? page,
  });

  Future<NewsArticle> fetchById(String id);
}

final class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl(this._api);

  final NewsApi _api;

  @override
  Future<NewsPage> fetchLatest({
    String query = 'ai',
    String category = 'technology',
    String? page,
  }) {
    return _api.fetchLatest(query: query, category: category, page: page);
  }

  @override
  Future<NewsArticle> fetchById(String id) {
    return _api.fetchById(id);
  }
}
