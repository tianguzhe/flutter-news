import 'dart:convert';

import '../../domain/fund_holding_estimate.dart';
import 'fund_holding_display_helpers.dart';

String encodeFundHoldingsJson(Iterable<FundHoldingInput> holdings) {
  final holdingsByChannel = <String, List<Map<String, Object?>>>{};
  final sortedHoldings = [...holdings]
    ..sort((a, b) {
      final channelCompare = a.channel.compareTo(b.channel);
      if (channelCompare != 0) return channelCompare;
      return a.purchaseDate.compareTo(b.purchaseDate);
    });

  for (final holding in sortedHoldings) {
    holdingsByChannel.putIfAbsent(holding.channel, () => []).add({
      'code': holding.code,
      'buy_date': formatFundHoldingDate(holding.purchaseDate),
      'shares': holding.shares,
      'cost_nav': holding.purchaseNav,
      'fee': holding.fee,
    });
  }

  return const JsonEncoder.withIndent(
    '  ',
  ).convert({'holdings': holdingsByChannel});
}

Future<({int imported, int failed})> importFundHoldingsFromJson(
  String jsonText, {
  required Future<void> Function(FundHoldingDraft draft) insertHolding,
}) async {
  final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
  final holdingsMap = decoded['holdings'] as Map<String, dynamic>;

  var imported = 0;
  var failed = 0;

  for (final channelEntry in holdingsMap.entries) {
    final channel = channelEntry.key;
    final items = channelEntry.value as List<dynamic>;
    for (final item in items) {
      try {
        final h = item as Map<String, dynamic>;
        final draft = FundHoldingDraft(
          code: h['code'] as String,
          purchaseDate: DateTime.parse(h['buy_date'] as String),
          shares: (h['shares'] as num).toDouble(),
          channel: channel,
          purchaseNav: (h['cost_nav'] as num).toDouble(),
          fee: (h['fee'] as num?)?.toDouble() ?? 0.0,
        );
        await insertHolding(draft);
        imported++;
      } catch (_) {
        failed++;
      }
    }
  }

  return (imported: imported, failed: failed);
}
