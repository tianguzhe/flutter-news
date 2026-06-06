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
    this.confirmedNavDate,
    this.confirmedNav,
    this.previousTradingNavDate,
    this.previousTradingNav,
  });

  final String code;
  final String name;
  final String prevNavDate;
  final double prevNav;
  final double estNav;
  final double estChangePct;
  final String estTime;
  final String? confirmedNavDate;
  final double? confirmedNav;
  final String? previousTradingNavDate;
  final double? previousTradingNav;

  bool get isUp => estChangePct >= 0;
  bool get hasConfirmedNav => confirmedNavDate != null && confirmedNav != null;
  double get valuationNav => confirmedNav ?? estNav;

  RealtimeEstimate copyWith({
    String? code,
    String? name,
    String? prevNavDate,
    double? prevNav,
    double? estNav,
    double? estChangePct,
    String? estTime,
    String? confirmedNavDate,
    double? confirmedNav,
    String? previousTradingNavDate,
    double? previousTradingNav,
  }) {
    return RealtimeEstimate(
      code: code ?? this.code,
      name: name ?? this.name,
      prevNavDate: prevNavDate ?? this.prevNavDate,
      prevNav: prevNav ?? this.prevNav,
      estNav: estNav ?? this.estNav,
      estChangePct: estChangePct ?? this.estChangePct,
      estTime: estTime ?? this.estTime,
      confirmedNavDate: confirmedNavDate ?? this.confirmedNavDate,
      confirmedNav: confirmedNav ?? this.confirmedNav,
      previousTradingNavDate:
          previousTradingNavDate ?? this.previousTradingNavDate,
      previousTradingNav: previousTradingNav ?? this.previousTradingNav,
    );
  }

  @override
  String toString() {
    final sign = isUp ? '+' : '';
    final actual = hasConfirmedNav ? ' confirmed $confirmedNav' : '';
    return '$code $name  $prevNav -> $estNav$actual  '
        '$sign${estChangePct.toStringAsFixed(2)}%  @$estTime';
  }
}
