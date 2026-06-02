import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/news_detail_provider.dart';
import '../widgets/news_cover.dart';
import '../widgets/news_state_view.dart';

/// 文件作用：
/// - 承载新闻详情 UI，是新闻功能中的页面层入口。
/// - 通过 Riverpod 读取指定新闻 id 的详情状态，并把 loading/error/data
///   三种状态映射为对应的界面。
/// - 与 `news_detail_provider.dart` 协作获取数据，与 `NewsCover`、
///   `NewsLoadingView`、`NewsErrorView` 协作完成页面展示。
///
/// 新闻详情页
///
/// 职责：
/// - 展示文章标题、来源、作者、发布时间、封面和正文。
/// - 在文章存在原文链接时，提供跳转系统浏览器阅读原文的入口。
///
/// Riverpod 语义：
/// - 状态来源：`newsDetailProvider(newsId)` 参数化 Provider。
/// - 刷新方式：错误态点击重试时，通过 `ref.invalidate(...)` 让 Provider
///   失效并重新拉取详情。
@Dependencies([newsDetail])
class NewsDetailPage extends ConsumerWidget {
  const NewsDetailPage({super.key, required this.newsId});

  /// 当前页面要展示的新闻 id。
  ///
  /// 该 id 会作为 family 参数传给详情 Provider，因此同一个页面组件可以复用在
  /// 不同文章详情上，同时让 Riverpod 按 id 隔离缓存与状态。
  final String newsId;

  /// 构建新闻详情页。
  ///
  /// 执行流程：
  /// 1. 监听当前 `newsId` 对应的详情 Provider。
  /// 2. 根据异步状态渲染加载、错误或正文内容。
  /// 3. 仅在数据声明存在原文链接时展示“阅读原文”按钮。
  ///
  /// ⚠️ 注意：
  /// - `ref.watch` 会让页面在 Provider 状态变化时自动重建。
  /// - 原文链接使用 `article.link!` 前，先由 `hasOriginalLink` 作为业务保护条件。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用参数化 Provider 获取对应 id 的详情状态，避免不同文章详情互相污染。
    final detailState = ref.watch(newsDetailProvider(newsId));

    return Scaffold(
      appBar: AppBar(title: const Text('新闻详情')),
      body: detailState.when(
        loading: () => const NewsLoadingView(),
        error: (error, _) => NewsErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(newsDetailProvider(newsId)),
        ),
        data: (article) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              article.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${article.sourceName} · ${article.authorText} · ${_formatDate(article.pubDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            NewsCover(imageUrl: article.imageUrl, height: 210),
            const SizedBox(height: 20),
            Text(
              article.bodyText,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            if (article.hasOriginalLink) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openOriginal(context, article.link!),
                icon: const Icon(Icons.open_in_new),
                label: const Text('阅读原文'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 使用系统外部浏览器打开文章原文。
  ///
  /// @param context 当前页面上下文，用于在打开失败时提示用户。
  /// @param url 原文链接，调用前应确保它来自有效的文章数据。
  ///
  /// 执行流程：
  /// 1. 将字符串链接解析为 `Uri`。
  /// 2. 通过 `url_launcher` 请求系统外部应用打开。
  /// 3. 若打开失败且页面仍然挂载，则展示 SnackBar。
  ///
  /// ⚠️ 风险：
  /// - 外部浏览器可能因系统策略、无可用应用或链接格式异常而打开失败。
  /// - `await` 之后页面可能已经销毁，因此必须检查 `context.mounted`。
  Future<void> _openOriginal(BuildContext context, String url) async {
    // 调起系统外部浏览器，避免在应用内承担网页渲染和返回栈管理。
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    // 异步回调后先判断 mounted，避免页面销毁后继续访问上下文。
    if (!context.mounted || opened) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法打开原文链接')));
  }
}

/// 将文章发布时间格式化为详情页展示文案。
///
/// @param value 原始发布时间，允许为空。
/// @return `yyyy-MM-dd HH:mm` 格式的本地时间；为空时返回兜底文案。
///
/// 设计原因：
/// - 新闻详情页比列表页需要更明确的发布时间，因此保留到分钟。
/// - 统一转成本地时间，避免后端时区和用户设备时区不一致导致展示困惑。
///
/// ⚠️ 注意：
/// - 这里是轻量格式化逻辑，不处理国际化；如果后续支持多语言，应迁移到
///   `intl` 或项目统一的日期格式化工具。
String _formatDate(DateTime? value) {
  if (value == null) {
    return '未知时间';
  }

  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
