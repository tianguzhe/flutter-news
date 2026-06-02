/// 统一的接口异常类型：
/// - message：给 UI 层展示的可读错误信息
/// - statusCode：可选 HTTP 状态码，方便后续做分支处理
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 打印异常时直接输出用户可读文案。
  @override
  String toString() => message;
}
