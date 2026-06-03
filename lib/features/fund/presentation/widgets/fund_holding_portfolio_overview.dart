import 'package:flutter/material.dart';

import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import 'fund_holding_status_pill.dart';

class FundPortfolioOverview extends StatelessWidget {
  const FundPortfolioOverview({
    super.key,
    required this.holdings,
    required this.estimates,
  });

  final List<FundHoldingInput> holdings;
  final List<FundHoldingEstimate> estimates;

  @override
  Widget build(BuildContext context) {
    final channels = holdings.map((h) => h.channel).toSet().length;
    final totalCost = estimates.fold<double>(0, (s, e) => s + e.cost);
    final estimatedValue = estimates.fold<double>(
      0,
      (s, e) => s + e.estimatedValue,
    );
    final yesterdayValue = estimates.fold<double>(
      0,
      (s, e) => s + fundHoldingYesterdayValue(e),
    );
    final confirmedTotalReturn = yesterdayValue - totalCost;
    final yesterdayActualReturn = estimates.fold<double>(
      0,
      (s, e) => s + fundHoldingYesterdayActualReturn(e),
    );
    final yesterdayRate = fundHoldingReturnRate(
      yesterdayActualReturn,
      totalCost,
    );
    final hasEstimate = estimates.isNotEmpty;
    final todayEstimate = hasEstimate
        ? estimates.fold<double>(
            0,
            (s, e) => s + fundHoldingTodayEstimatedReturn(e),
          )
        : 0.0;

    final cs = Theme.of(context).colorScheme;
    final estimateColor = fundHoldingEstimateAccent(cs);
    final sentimentColor = hasEstimate
        ? fundHoldingSignedColor(yesterdayActualReturn, cs)
        : cs.primary;

    final stats = [
      _OverviewStatItem(
        label: '估算市值',
        value: hasEstimate ? formatFundHoldingMoney(estimatedValue) : '--',
        valueColor: hasEstimate ? estimateColor : cs.onSurface,
      ),
      _OverviewStatItem(
        label: '持仓成本',
        value: hasEstimate ? formatFundHoldingMoney(totalCost) : '--',
      ),
      _OverviewStatItem(
        label: '累计收益',
        value: hasEstimate
            ? formatSignedFundHoldingMoney(confirmedTotalReturn)
            : '--',
        valueColor: hasEstimate
            ? fundHoldingSignedColor(confirmedTotalReturn, cs)
            : cs.onSurface,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            tintFundHoldingSurface(cs.primary, cs.surface, 14),
            tintFundHoldingSurface(cs.tertiary, cs.surface, 10),
          ],
        ),
        borderRadius: BorderRadius.circular(fundHoldingCardRadius),
        border: Border.all(color: cs.outlineVariant.withAlpha(115)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tintFundHoldingSurface(sentimentColor, cs.surface, 28),
                  borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
                ),
                child: Icon(
                  Icons.donut_large_outlined,
                  size: 21,
                  color: sentimentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '组合概览',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${holdings.length} 笔持仓 · $channels 个渠道',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FundHoldingStatusPill(
                label: hasEstimate ? '已估算' : '同步中',
                color: hasEstimate ? sentimentColor : cs.primary,
                icon: hasEstimate
                    ? Icons.check_circle_outline
                    : Icons.sync_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final headline = _OverviewHeadline(
                label: hasEstimate ? '昨日资产变动' : '正在拉取估值',
                value: hasEstimate
                    ? formatSignedFundHoldingMoney(yesterdayActualReturn)
                    : '估算中...',
                helper: hasEstimate
                    ? '昨日变动率 ${formatFundHoldingPercent(yesterdayRate)}'
                    : '完成后会自动刷新组合摘要',
                color: sentimentColor,
              );

              if (constraints.maxWidth >= 560 && hasEstimate) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: headline),
                    const SizedBox(width: 18),
                    _TodayEstimatePill(value: todayEstimate),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headline,
                  if (hasEstimate) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _TodayEstimatePill(value: todayEstimate),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _OverviewStatGrid(items: stats),
        ],
      ),
    );
  }
}

class _OverviewHeadline extends StatelessWidget {
  const _OverviewHeadline({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                helper,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayEstimatePill extends StatelessWidget {
  const _TodayEstimatePill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = fundHoldingEstimateAccent(cs);
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tintFundHoldingSurface(color, cs.surface, 18),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.query_stats_rounded, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                '实时预估',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatSignedFundHoldingMoney(value),
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatGrid extends StatelessWidget {
  const _OverviewStatGrid({required this.items});

  final List<_OverviewStatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 430 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: _OverviewStat(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.item});

  final _OverviewStatItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(184),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        border: Border.all(color: cs.outlineVariant.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: item.valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatItem {
  const _OverviewStatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}
