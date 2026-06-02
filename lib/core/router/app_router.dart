import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_list_page.dart';
import '../log/talker.dart';
import 'app_routes.dart';

// 这一行必须写，build_runner 会根据它生成 app_router.g.dart。
part 'app_router.g.dart';

/// 应用级路由 Provider。
///
/// keepAlive 表示这个路由对象在应用运行期间保持稳定。
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    // 应用启动后默认进入新闻列表页。
    initialLocation: AppRoutes.news,
    routes: [
      // /news -> 新闻列表页
      GoRoute(path: AppRoutes.news, builder: (_, _) => const NewsListPage()),
      // /news/:id -> 新闻详情页
      GoRoute(
        path: AppRoutes.newsDetail,
        builder: (_, state) {
          // 从路径参数中读取 id，例如 /news/article_001 中的 article_001。
          final id = state.pathParameters['id']!;
          return NewsDetailPage(newsId: id);
        },
      ),
      // /logger -> 日志页
      GoRoute(
        path: AppRoutes.logger,
        builder: (_, _) => TalkerScreen(talker: talker),
      ),
    ],
  );
}
