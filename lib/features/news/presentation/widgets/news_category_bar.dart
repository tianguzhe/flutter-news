import 'package:flutter/material.dart';

/// 新闻分类横向选择条。
class NewsCategoryBar extends StatelessWidget {
  const NewsCategoryBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];

          // 使用 ChoiceChip 组件，自动处理选中态的样式变化。
          return ChoiceChip(
            label: Text(_labelFor(category)),
            selected: category == selectedCategory,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

String _labelFor(String category) {
  // 分类英文值映射为中文展示文案。
  return switch (category) {
    'technology' => '科技',
    'business' => '商业',
    'science' => '科学',
    'health' => '健康',
    'sports' => '体育',
    'entertainment' => '娱乐',
    'world' => '国际',
    _ => category,
  };
}
