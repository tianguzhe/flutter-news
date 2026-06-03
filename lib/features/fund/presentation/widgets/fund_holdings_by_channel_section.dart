import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import 'fund_holding_card.dart';

class FundHoldingsByChannelSection extends StatelessWidget {
  const FundHoldingsByChannelSection({
    super.key,
    required this.holdings,
    required this.states,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final List<FundHoldingInput> holdings;
  final Map<int, AsyncValue<FundHoldingEstimate>> states;
  final bool isLoading;
  final Object? loadError;
  final ValueChanged<FundHoldingInput> onRefresh;
  final ValueChanged<FundHoldingInput> onEdit;
  final ValueChanged<FundHoldingInput> onRemove;

  @override
  Widget build(BuildContext context) {
    if (isLoading && holdings.isEmpty) {
      return const _StatePanel(
        icon: Icons.storage,
        title: '读取本地持仓',
        message: '正在从本地数据库加载持仓记录。',
      );
    }
    if (loadError != null && holdings.isEmpty) {
      return _StatePanel(
        icon: Icons.error_outline,
        title: '本地持仓读取失败',
        message: loadError.toString(),
      );
    }
    if (holdings.isEmpty) {
      return const _StatePanel(
        icon: Icons.insights,
        title: '按渠道展示持仓',
        message: '点击右下角按钮添加持仓，系统会按渠道分组显示收益。',
      );
    }

    final grouped = <String, List<FundHoldingInput>>{};
    for (final h in holdings) {
      grouped.putIfAbsent(h.channel, () => []).add(h);
    }

    final entries = grouped.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int index = 0; index < entries.length; index++)
          Builder(
            builder: (context) {
              final entry = entries[index];
              final channelHoldings = entry.value
                ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ChannelGroupCard(
                  channel: entry.key,
                  channelIndex: index,
                  holdings: channelHoldings,
                  states: states,
                  onRefresh: onRefresh,
                  onEdit: onEdit,
                  onRemove: onRemove,
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Channel group card
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelGroupCard extends StatelessWidget {
  const _ChannelGroupCard({
    required this.channel,
    required this.channelIndex,
    required this.holdings,
    required this.states,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final String channel;
  final int channelIndex;
  final List<FundHoldingInput> holdings;
  final Map<int, AsyncValue<FundHoldingEstimate>> states;
  final ValueChanged<FundHoldingInput> onRefresh;
  final ValueChanged<FundHoldingInput> onEdit;
  final ValueChanged<FundHoldingInput> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = fundHoldingChannelAccent(channelIndex);
    final estimates = holdings
        .map((h) => states[h.id])
        .whereType<AsyncData<FundHoldingEstimate>>()
        .map((s) => s.value)
        .toList();
    final yesterdayActualReturn = estimates.fold<double>(
      0,
      (s, e) => s + fundHoldingYesterdayActualReturn(e),
    );
    final hasEstimate = estimates.isNotEmpty;
    final returnColor = hasEstimate
        ? fundHoldingSignedColor(yesterdayActualReturn, cs)
        : cs.primary;
    final totalValue = estimates.fold<double>(
      0,
      (sum, estimate) => sum + fundHoldingYesterdayValue(estimate),
    );
    final totalCost = estimates.fold<double>(
      0,
      (sum, estimate) => sum + estimate.cost,
    );

    return Container(
      decoration: BoxDecoration(
        color: tintFundHoldingSurface(accent, cs.surface, 7),
        borderRadius: BorderRadius.circular(fundHoldingCardRadius),
        border: Border.all(color: accent.withAlpha(45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final header = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(26),
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 19,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasEstimate
                                ? '${holdings.length} 笔 · 成本 ${formatFundHoldingMoney(totalCost)} · 昨日市值 ${formatFundHoldingMoney(totalValue)}'
                                : '${holdings.length} 笔持仓 · 正在估算',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (!hasEstimate) return header;

                final change = _ChannelChangeBadge(
                  label: '昨日变动',
                  value: formatSignedFundHoldingMoney(yesterdayActualReturn),
                  color: returnColor,
                );

                if (constraints.maxWidth < 430) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerLeft, child: change),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: header),
                    const SizedBox(width: 12),
                    change,
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
            child: Column(
              children: [
                for (int i = 0; i < holdings.length; i++) ...[
                  FundHoldingCard(
                    holding: holdings[i],
                    state: states[holdings[i].id] ?? const AsyncLoading(),
                    onRefresh: () => onRefresh(holdings[i]),
                    onEdit: () => onEdit(holdings[i]),
                    onRemove: () => onRemove(holdings[i]),
                  ),
                  if (i < holdings.length - 1)
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: accent.withAlpha(35),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelChangeBadge extends StatelessWidget {
  const _ChannelChangeBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: tintFundHoldingSurface(color, cs.surface, 16),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(fundHoldingCardRadius),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual holding card
// ─────────────────────────────────────────────────────────────────────────────
