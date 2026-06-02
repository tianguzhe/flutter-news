import '../data/models/realtime_estimate.dart';

/// 用户持仓输入。
final class FundHoldingInput {
  const FundHoldingInput({
    required this.id,
    required this.code,
    required this.purchaseDate,
    required this.shares,
    required this.channel,
    required this.purchaseNav,
  });

  final int id;
  final String code;
  final DateTime purchaseDate;
  final double shares;
  final String channel;
  final double purchaseNav;
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

  final cost = input.purchaseNav * input.shares;
  final estimatedValue = realtimeEstimate.estNav * input.shares;
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
