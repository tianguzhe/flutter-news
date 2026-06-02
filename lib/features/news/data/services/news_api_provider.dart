import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/dio_provider.dart';
import 'news_api.dart';

part 'news_api_provider.g.dart';

@Riverpod(keepAlive: true)
/// 注入 NewsApi 单例，供列表与详情 Provider 复用。
NewsApi newsApi(Ref ref) {
  // 通过 ref.watch 读取第 4 课创建的 Dio 依赖。
  return NewsApi(ref.watch(dioProvider));
}
