import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/news/data/models/news_article.dart';
import 'package:untitled/features/news/data/models/news_page.dart';
import 'package:untitled/features/news/data/repositories/news_repository.dart';
import 'package:untitled/features/news/data/repositories/news_repository_provider.dart';
import 'package:untitled/features/news/presentation/view_models/news_detail_view_model.dart';
import 'package:untitled/features/news/presentation/view_models/news_list_view_model.dart';

void main() {
  group('NewsListViewModel', () {
    test('loads latest news through the repository', () async {
      final repository = _FakeNewsRepository(
        latestPage: NewsPage(
          articles: [NewsArticle(articleId: 'article-1', title: 'Title')],
        ),
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      final articles = await container.read(newsListViewModelProvider.future);

      expect(articles.single.articleId, 'article-1');
      expect(repository.latestQuery, 'ai');
      expect(repository.latestCategory, 'technology');
    });

    test('updates the selected category and reloads data', () async {
      final repository = _FakeNewsRepository(
        latestPage: NewsPage(
          articles: [NewsArticle(articleId: 'article-1', title: 'Title')],
        ),
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      await container.read(newsListViewModelProvider.future);
      await container
          .read(newsListViewModelProvider.notifier)
          .selectCategory('science');

      expect(container.read(selectedNewsCategoryProvider), 'science');
      expect(repository.latestCategory, 'science');
    });
  });

  group('newsDetailViewModel', () {
    test('loads article details through the repository', () async {
      final repository = _FakeNewsRepository(
        detailArticle: NewsArticle(articleId: 'article-2', title: 'Detail'),
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      final article = await container.read(
        newsDetailViewModelProvider('article-2').future,
      );

      expect(article.title, 'Detail');
      expect(repository.detailId, 'article-2');
    });
  });
}

ProviderContainer _createContainer(NewsRepository repository) {
  return ProviderContainer(
    overrides: [newsRepositoryProvider.overrideWithValue(repository)],
  );
}

final class _FakeNewsRepository implements NewsRepository {
  _FakeNewsRepository({NewsPage? latestPage, NewsArticle? detailArticle})
    : latestPage = latestPage ?? NewsPage(articles: const []),
      detailArticle = detailArticle ?? NewsArticle();

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
