import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../core/log/log.dart';
import '../../../../core/router/app_routes.dart';
import '../view_models/news_list_view_model.dart';
import '../widgets/news_card.dart';
import '../widgets/news_category_bar.dart';
import '../widgets/news_state_view.dart';

/// 新闻列表页：展示分类、列表数据，并处理加载/错误/空态。
@Dependencies([NewsListViewModel, selectedNewsCategory])
class NewsListPage extends ConsumerWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 数据流：UI -> ViewModel -> Repository -> API service。
    final newsState = ref.watch(newsListViewModelProvider);
    // 分类高亮状态单独由 Provider 暴露，避免 UI 直接读取 Notifier 字段。
    final selectedCategory = ref.watch(selectedNewsCategoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('News Course'), centerTitle: false),
      body: Column(
        children: [
          // 分类选择条，切换分类会触发 Provider 内部刷新数据。
          NewsCategoryBar(
            categories: newsCategories,
            selectedCategory: selectedCategory,
            onSelected: (category) {
              // 触发分类切换后，Provider 内部会刷新数据。
              ref
                  .read(newsListViewModelProvider.notifier)
                  .selectCategory(category);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: newsState.when(
              loading: () => const NewsLoadingView(),
              error: (error, _) => NewsErrorView(
                message: error.toString(),
                // 直接 invalidate 触发重试，简化交互逻辑。
                onRetry: () => ref.invalidate(newsListViewModelProvider),
              ),
              data: (articles) {
                // 列表数据为空时展示空态视图，提示用户当前没有内容。
                if (articles.isEmpty) {
                  // 空列表时仍保留下拉刷新能力，方便用户主动重试。
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(newsListViewModelProvider.notifier).refresh(),
                    child: const CustomScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      slivers: [SliverFillRemaining(child: NewsEmptyView())],
                    ),
                  );
                }

                // 列表数据正常时展示文章列表，支持下拉刷新。
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(newsListViewModelProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: articles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return NewsCard(
                        article: article,
                        // 使用集中管理的路径生成函数，避免页面里手动拼接路由字符串。
                        onTap: () {
                          YLog.i(article.articleId);
                          context.push(
                            AppRoutes.newsDetailPath(article.articleId),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
