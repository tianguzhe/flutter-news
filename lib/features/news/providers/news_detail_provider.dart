import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/news_article.dart';
import 'news_api_provider.dart';

part 'news_detail_provider.g.dart';

@Riverpod()
/// 详情 Provider：按新闻 id 拉取单篇文章。
Future<NewsArticle> newsDetail(Ref ref, String id) {
  // family 参数 id 来自路由 /news/:id。
  return ref.read(newsApiProvider).fetchById(id);
}
