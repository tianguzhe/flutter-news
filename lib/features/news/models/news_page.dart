import 'news_article.dart';

/// 新闻分页结果：当前页文章 + 下一页游标。
class NewsPage {
  const NewsPage({required this.articles, this.nextPage});

  /// 当前页文章列表。
  final List<NewsArticle> articles;

  /// 下一页标记，接口可能为空，表示没有更多数据。
  final String? nextPage;
}
