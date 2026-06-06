import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/fund_holding_estimate.dart';
import 'fund_holding_display_helpers.dart';

final class FundHoldingGroupSummary {
  const FundHoldingGroupSummary({
    required this.holdings,
    required this.estimates,
    required this.estimatesByHoldingId,
    required this.code,
    required this.title,
    required this.hasCompleteEstimates,
    required this.hasError,
    required this.errorMessage,
    required this.hasFinalReturn,
    required this.confirmedNavDate,
    required this.totalShares,
    required this.totalCost,
    required this.marketValue,
    required this.todayEstimateReturn,
    required this.yesterdayReturn,
    required this.finalReturn,
    required this.displayTotalReturn,
    required this.displayTotalReturnRate,
    required this.estimateTime,
    required this.estimateNav,
    required this.prevNavDate,
    required this.changePct,
  });

  final List<FundHoldingInput> holdings;
  final List<FundHoldingEstimate> estimates;
  final Map<int, FundHoldingEstimate> estimatesByHoldingId;
  final String code;
  final String title;
  final bool hasCompleteEstimates;
  final bool hasError;
  final String? errorMessage;
  final bool hasFinalReturn;
  final String? confirmedNavDate;
  final double totalShares;
  final double totalCost;
  final double marketValue;
  final double todayEstimateReturn;
  final double yesterdayReturn;
  final double finalReturn;
  final double displayTotalReturn;
  final double displayTotalReturnRate;
  final String? estimateTime;
  final double? estimateNav;
  final String? prevNavDate;
  final double? changePct;

  FundHoldingEstimate? estimateFor(FundHoldingInput holding) =>
      estimatesByHoldingId[holding.id];
}

FundHoldingGroupSummary summarizeFundHoldingGroup({
  required List<FundHoldingInput> holdings,
  required Map<int, AsyncValue<FundHoldingEstimate>> states,
}) {
  final estimates = <FundHoldingEstimate>[];
  final estimatesByHoldingId = <int, FundHoldingEstimate>{};
  Object? firstError;

  for (final holding in holdings) {
    final state = states[holding.id];
    if (state is AsyncData<FundHoldingEstimate>) {
      estimates.add(state.value);
      estimatesByHoldingId[holding.id] = state.value;
    } else if (state is AsyncError<FundHoldingEstimate>) {
      firstError ??= state.error;
    }
  }

  final realtime = estimates.isEmpty ? null : estimates.first.realtimeEstimate;
  final fallbackCode = holdings.isEmpty ? '' : holdings.first.code;
  final hasCompleteEstimates =
      holdings.isNotEmpty && estimates.length == holdings.length;
  final confirmedNavDate = hasCompleteEstimates
      ? _singleValue(
          estimates.map(
            (estimate) => estimate.realtimeEstimate.confirmedNavDate ?? '',
          ),
        )
      : null;
  final hasFinalReturn =
      confirmedNavDate != null &&
      estimates.every((estimate) => estimate.realtimeEstimate.hasConfirmedNav);
  final totalShares = holdings.fold<double>(
    0,
    (sum, holding) => sum + holding.shares,
  );
  final inputCost = holdings.fold<double>(
    0,
    (sum, holding) => sum + holding.purchaseNav * holding.shares + holding.fee,
  );
  final totalCost = hasCompleteEstimates
      ? estimates.fold<double>(0, (sum, estimate) => sum + estimate.cost)
      : inputCost;
  final marketValue = hasCompleteEstimates
      ? estimates.fold<double>(
          0,
          (sum, estimate) =>
              sum +
              (hasFinalReturn
                  ? estimate.estimatedValue
                  : estimate.realtimeEstimate.estNav * estimate.input.shares),
        )
      : 0.0;
  final todayEstimateReturn = estimates.fold<double>(
    0,
    (sum, estimate) => sum + fundHoldingTodayIntradayEstimateReturn(estimate),
  );
  final yesterdayReturn = estimates.fold<double>(
    0,
    (sum, estimate) => sum + fundHoldingYesterdayActualReturn(estimate),
  );
  final finalReturn = estimates.fold<double>(
    0,
    (sum, estimate) => sum + fundHoldingTodayEstimatedReturn(estimate),
  );
  final displayTotalReturn = hasCompleteEstimates
      ? marketValue - totalCost
      : 0.0;

  return FundHoldingGroupSummary(
    holdings: holdings,
    estimates: estimates,
    estimatesByHoldingId: estimatesByHoldingId,
    code: realtime?.code ?? fallbackCode,
    title: realtime?.name ?? fallbackCode,
    hasCompleteEstimates: hasCompleteEstimates,
    hasError: firstError != null,
    errorMessage: firstError?.toString(),
    hasFinalReturn: hasFinalReturn,
    confirmedNavDate: confirmedNavDate,
    totalShares: totalShares,
    totalCost: totalCost,
    marketValue: marketValue,
    todayEstimateReturn: todayEstimateReturn,
    yesterdayReturn: yesterdayReturn,
    finalReturn: finalReturn,
    displayTotalReturn: displayTotalReturn,
    displayTotalReturnRate: fundHoldingReturnRate(
      displayTotalReturn,
      totalCost,
    ),
    estimateTime: realtime?.estTime,
    estimateNav: realtime?.estNav,
    prevNavDate: realtime?.prevNavDate,
    changePct: realtime?.estChangePct,
  );
}

String? _singleValue(Iterable<String> values) {
  final nonEmptyValues = values.where((value) => value.isNotEmpty).toSet();
  return nonEmptyValues.length == 1 ? nonEmptyValues.single : null;
}
