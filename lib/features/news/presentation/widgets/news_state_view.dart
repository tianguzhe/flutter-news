import 'package:flutter/material.dart';

/// 通用加载态视图。
class NewsLoadingView extends StatelessWidget {
  const NewsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class NewsErrorView extends StatelessWidget {
  const NewsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // 错误态统一提供重试入口，避免用户只能返回上一页。
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标使用主题色的 error，确保在亮色/暗色模式下都具备可读性。
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            // 错误信息文本居中显示，字体颜色使用主题色的 onSurfaceVariant，确保在亮色/暗色模式下都具备可读性。
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // 重试按钮使用 FilledButton，提供明确的点击区域和视觉反馈。
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

// 空态视图：当数据为空时展示，提示用户当前没有内容。
class NewsEmptyView extends StatelessWidget {
  const NewsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('暂无新闻', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
