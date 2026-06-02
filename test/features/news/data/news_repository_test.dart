import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/news/data/models/news_article.dart';
import 'package:untitled/features/news/data/models/news_page.dart';
import 'package:untitled/features/news/data/repositories/news_repository.dart';
import 'package:untitled/features/news/data/services/news_api.dart';

void main() {
  group('NewsPage', () {
    test('stores articles as an immutable list', () {
      final article = NewsArticle(articleId: 'article-1', title: 'Title');
      final page = NewsPage(articles: [article]);

      expect(() => page.articles.add(article), throwsUnsupportedError);
    });
  });

  group('NewsRepositoryImpl', () {
    test('delegates latest-news loading to the API service', () async {
      final api = _FakeNewsApi(
        latestPage: NewsPage(
          articles: [NewsArticle(articleId: 'article-1', title: 'Title')],
        ),
      );
      final repository = NewsRepositoryImpl(api);

      final page = await repository.fetchLatest(
        query: 'ai',
        category: 'technology',
        page: 'next-page',
      );

      expect(page.articles.single.articleId, 'article-1');
      expect(api.latestQuery, 'ai');
      expect(api.latestCategory, 'technology');
      expect(api.latestPageToken, 'next-page');
    });

    test('delegates detail loading to the API service', () async {
      final api = _FakeNewsApi(
        detailArticle: NewsArticle(articleId: 'article-1', title: 'Title'),
      );
      final repository = NewsRepositoryImpl(api);

      final article = await repository.fetchById('article-1');

      expect(article.articleId, 'article-1');
      expect(api.detailId, 'article-1');
    });
  });
}

final class _FakeNewsApi extends NewsApi {
  _FakeNewsApi({NewsPage? latestPage, NewsArticle? detailArticle})
    : latestPage = latestPage ?? NewsPage(articles: const []),
      detailArticle = detailArticle ?? NewsArticle(),
      super(Dio());

  final NewsPage latestPage;
  final NewsArticle detailArticle;

  String? latestQuery;
  String? latestCategory;
  String? latestPageToken;
  String? detailId;

  @override
  Future<NewsPage> fetchLatest({
    String query = 'ai',
    String category = 'technology',
    String? page,
  }) async {
    latestQuery = query;
    latestCategory = category;
    latestPageToken = page;
    return latestPage;
  }

  @override
  Future<NewsArticle> fetchById(String id) async {
    detailId = id;
    return detailArticle;
  }
}
