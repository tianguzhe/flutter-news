import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/news_article.dart';
import '../../data/repositories/news_repository_provider.dart';

part 'news_detail_view_model.g.dart';

@Riverpod()
/// 详情 Provider：按新闻 id 拉取单篇文章。
Future<NewsArticle> newsDetailViewModel(Ref ref, String id) {
  // family 参数 id 来自路由 /news/:id。
  return ref.read(newsRepositoryProvider).fetchById(id);
}
