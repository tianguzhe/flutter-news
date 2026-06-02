import 'package:flutter/material.dart';

/// 新闻封面图组件：统一处理空图、加载中、加载失败三种状态。
class NewsCover extends StatelessWidget {
  const NewsCover({super.key, this.imageUrl, this.height = 96});

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    // 无图片地址时直接显示占位图，避免网络组件不必要初始化。
    if (url == null || url.isEmpty) {
      return _Placeholder(height: height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          // 加载完成，显示图片。
          if (progress == null) {
            return child;
          }
          // 加载中，显示加载指示器。
          return _Placeholder(height: height, isLoading: true);
        },
        errorBuilder: (_, _, _) => _Placeholder(height: height),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.height, this.isLoading = false});

  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // 使用主题色保证在亮色/暗色模式下都具备可读性。
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox.square(
              dimension: 18, // 18x18 的加载指示器大小适中，不会过于抢眼。
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.image_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
    );
  }
}
