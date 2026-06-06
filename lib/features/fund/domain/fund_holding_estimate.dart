import '../data/models/realtime_estimate.dart';

/// 新增持仓草稿，尚未分配本地数据库 id。
final class FundHoldingDraft {
  const FundHoldingDraft({
    required this.code,
    required this.purchaseDate,
    required this.shares,
    required this.channel,
    required this.purchaseNav,
    required this.fee,
  });

  final String code;
  final DateTime purchaseDate;
  final double shares;
  final String channel;
  final double purchaseNav;
  final double fee;
}

/// 用户持仓输入。
final class FundHoldingInput {
  const FundHoldingInput({
    required this.id,
    required this.code,
    required this.purchaseDate,
    required this.shares,
    required this.channel,
    required this.purchaseNav,
    required this.fee,
  });

  final int id;
  final String code;
  final DateTime purchaseDate;
  final double shares;
  final String channel;
  final double purchaseNav;
  final double fee;
}

/// 基于盘中估值和持仓输入计算出的收益结果。
final class FundHoldingEstimate {
  const FundHoldingEstimate({
    required this.input,
    required this.realtimeEstimate,
    required this.cost,
    required this.estimatedValue,
    required this.totalReturn,
    required this.totalReturnRate,
  });

  final FundHoldingInput input;
  final RealtimeEstimate realtimeEstimate;
  final double cost;
  final double estimatedValue;
  final double totalReturn;
  final double totalReturnRate;

  bool get isProfitable => totalReturn >= 0;
}

FundHoldingEstimate calculateFundHoldingEstimate({
  required FundHoldingInput input,
  required RealtimeEstimate realtimeEstimate,
}) {
  if (input.shares <= 0) {
    throw ArgumentError.value(input.shares, 'shares', 'must be greater than 0');
  }
  if (input.purchaseNav <= 0) {
    throw ArgumentError.value(
      input.purchaseNav,
      'purchaseNav',
      'must be greater than 0',
    );
  }
  if (input.fee < 0) {
    throw ArgumentError.value(input.fee, 'fee', 'must not be negative');
  }

  final cost = input.purchaseNav * input.shares + input.fee;
  final estimatedValue = realtimeEstimate.valuationNav * input.shares;
  final totalReturn = estimatedValue - cost;

  return FundHoldingEstimate(
    input: input,
    realtimeEstimate: realtimeEstimate,
    cost: cost,
    estimatedValue: estimatedValue,
    totalReturn: totalReturn,
    totalReturnRate: totalReturn / cost,
  );
}
