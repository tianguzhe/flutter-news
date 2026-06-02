import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/news_article.dart';
import 'news_api_provider.dart';

part 'news_list_provider.g.dart';

/// 可选新闻分类，供列表页分类条渲染。
const newsCategories = <String>[
  'technology',
  'business',
  'science',
  'health',
  'sports',
  'entertainment',
  'world',
];

@Riverpod()
/// 列表状态控制器：管理分类切换、刷新与列表请求。
class NewsList extends _$NewsList {
  final String _query = 'ai';
  String _category = 'technology';

  @override
  Future<List<NewsArticle>> build() async {
    return _load();
  }

  Future<void> refresh() async {
    // 显式切到 loading，提升交互可感知性。
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> selectCategory(String category) async {
    // 相同分类不重复请求，减少无效网络调用。
    if (_category == category) {
      return;
    }

    _category = category;
    await refresh();
  }

  Future<List<NewsArticle>> _load() async {
    // 可扩展：后续若接入分页，可在这里返回合并后的列表。
    final page = await ref
        .read(newsApiProvider)
        .fetchLatest(query: _query, category: _category);
    return page.articles;
  }
}

@Riverpod()
/// 当前选中的新闻分类：给 UI 读取高亮状态，避免直接暴露 Notifier getter。
String selectedNewsCategory(Ref ref) {
  // 订阅列表状态，分类切换触发 refresh 后这里会同步重算。
  ref.watch(newsListProvider);
  return ref.read(newsListProvider.notifier)._category;
}
