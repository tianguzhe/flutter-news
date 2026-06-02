import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';

import 'core/log/log_overlay.dart';
import 'core/log/talker.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';

@Dependencies([appRouter])
void main() {
  // ProviderScope 是 Riverpod 的根容器，所有 Provider 都需要它。
  runApp(
    ProviderScope(
      observers: [TalkerRiverpodObserver(talker: talker)],
      child: const NewsApp(),
    ),
  );
}

/// 应用根组件，负责挂载主题和路由。
@Dependencies([appRouter])
class NewsApp extends ConsumerWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 Riverpod 读取 GoRouter 对象。
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'News Course',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2563eb)),
        useMaterial3: true,
      ),
      // 把 go_router 交给 MaterialApp.router 管理导航。
      routerConfig: router,
      // 在所有页面之上叠加全局日志悬浮球（仅 debug 构建显示）。
      builder: (context, child) {
        if (!kDebugMode) return child!;
        return LogOverlay(
          // push 返回的 Future 在日志页 pop 后才完成，
          // LogOverlay 据此忽略打开期间的重复点击，避免叠加多层 TalkerScreen。
          onTap: () => router.push(AppRoutes.logger),
          child: child!,
        );
      },
    );
  }
}
