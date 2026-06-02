/// 基金盘中实时估值，涨跌幅相对上一交易日单位净值。
final class RealtimeEstimate {
  const RealtimeEstimate({
    required this.code,
    required this.name,
    required this.prevNavDate,
    required this.prevNav,
    required this.estNav,
    required this.estChangePct,
    required this.estTime,
  });

  final String code;
  final String name;
  final String prevNavDate;
  final double prevNav;
  final double estNav;
  final double estChangePct;
  final String estTime;

  bool get isUp => estChangePct >= 0;

  @override
  String toString() {
    final sign = isUp ? '+' : '';
    return '$code $name  $prevNav -> $estNav  '
        '$sign${estChangePct.toStringAsFixed(2)}%  @$estTime';
  }
}
