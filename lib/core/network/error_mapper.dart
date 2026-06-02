import 'package:dio/dio.dart';

import 'api_exception.dart';

/// 将底层网络异常统一映射为业务可消费的 ApiException。
///
/// 这样 UI 和 Provider 层只处理一种错误模型，不直接依赖 Dio 细节。
ApiException mapNetworkError(Object error) {
  // 已经是业务异常时直接透传，避免重复包装。
  if (error is ApiException) {
    return error;
  }

  if (error is DioException) {
    final statusCode = error.response?.statusCode;

    // 按 Dio 的异常类型映射成用户可读文案。
    return ApiException(switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '网络超时，请稍后重试',
      DioExceptionType.badResponse => '服务暂时不可用',
      DioExceptionType.connectionError => '网络连接失败，请检查网络',
      DioExceptionType.cancel => '请求已取消',
      _ => '网络异常，请稍后重试',
    }, statusCode: statusCode);
  }

  // 非 Dio 异常也要兜底，避免向页面抛出不可读错误。
  return const ApiException('未知错误，请稍后重试');
}
