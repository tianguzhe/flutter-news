import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/dio_client.dart';

// build_runner 会根据这个 part 生成 dioProvider。
part 'dio_provider.g.dart';

/// 全局 Dio Provider（常驻）：
/// - 统一对外提供 HTTP 客户端
/// - 作为数据层请求入口依赖
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  // API 层通过读取该 Provider 发起请求。
  return DioClient.create();
}
