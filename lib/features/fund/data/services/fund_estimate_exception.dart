/// 基金估值业务异常，例如无估值数据或 JSONP 解析失败。
final class FundEstimateException implements Exception {
  const FundEstimateException(this.message);

  final String message;

  @override
  String toString() => message;
}
