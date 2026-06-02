import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:url_launcher/url_launcher.dart';

import '../view_models/news_detail_view_model.dart';
import '../widgets/news_cover.dart';
import '../widgets/news_state_view.dart';

/// 新闻详情页：展示单篇文章，并在失败时允许重新拉取。
@Dependencies([newsDetailViewModel])
class NewsDetailPage extends ConsumerWidget {
  const NewsDetailPage({super.key, required this.newsId});

  /// 当前页面要展示的新闻 id，作为 family 参数隔离不同详情状态。
  final String newsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(newsDetailViewModelProvider(newsId));

    return Scaffold(
      appBar: AppBar(title: const Text('新闻详情')),
      body: detailState.when(
        loading: () => const NewsLoadingView(),
        error: (error, _) => NewsErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(newsDetailViewModelProvider(newsId)),
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
