import 'package:flutter/material.dart';

import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import 'fund_holding_status_pill.dart';

class FundPortfolioOverview extends StatefulWidget {
  const FundPortfolioOverview({
    super.key,
    required this.holdings,
    required this.estimates,
  });

  final List<FundHoldingInput> holdings;
  final List<FundHoldingEstimate> estimates;

  @override
  State<FundPortfolioOverview> createState() => _FundPortfolioOverviewState();
}

class _FundPortfolioOverviewState extends State<FundPortfolioOverview> {
  var _showSensitiveAmounts = false;

  void _toggleSensitiveAmounts() {
    setState(() => _showSensitiveAmounts = !_showSensitiveAmounts);
  }

  @override
  Widget build(BuildContext context) {
    final channels = widget.holdings.map((h) => h.channel).toSet().length;
    final totalCost = widget.estimates.fold<double>(0, (s, e) => s + e.cost);
    final yesterdayValue = widget.estimates.fold<double>(
      0,
      (s, e) => s + fundHoldingYesterdayValue(e),
    );
    final hasEstimate =
        widget.holdings.isNotEmpty &&
        widget.estimates.length == widget.holdings.length;
    final hasConfirmedNav =
        hasEstimate &&
        widget.estimates.every(
          (estimate) => estimate.realtimeEstimate.hasConfirmedNav,
        );
    final confirmedNavDate = hasConfirmedNav
        ? _singleValue(
            widget.estimates.map(
              (estimate) => estimate.realtimeEstimate.confirmedNavDate ?? '',
            ),
          )
        : null;
    final hasFinalReturn = confirmedNavDate != null;
    final portfolioValue = widget.estimates.fold<double>(
      0,
      (s, e) =>
          s +
          (hasFinalReturn
              ? e.estimatedValue
              : e.realtimeEstimate.estNav * e.input.shares),
    );
    final totalReturn = portfolioValue - totalCost;
    final finalReturn = hasEstimate
        ? _portfolioCurrentChange(
            estimates: widget.estimates,
            useConfirmedNav: true,
          )
        : 0.0;
    final todayEstimate = hasEstimate
        ? _portfolioCurrentChange(
            estimates: widget.estimates,
            useConfirmedNav: false,
          )
        : 0.0;
    final yesterdayReturn = hasEstimate
        ? widget.estimates.fold<double>(
            0,
            (sum, estimate) => sum + fundHoldingYesterdayActualReturn(estimate),
          )
        : 0.0;
    final primaryChange = hasFinalReturn ? finalReturn : todayEstimate;

    final cs = Theme.of(context).colorScheme;
    final estimateColor = fundHoldingEstimateAccent(cs);
    final sentimentColor = hasEstimate
        ? fundHoldingSignedColor(primaryChange, cs)
        : cs.primary;

    final stats = [
      _OverviewStatItem(
        label: hasFinalReturn ? '实际市值' : '估算市值',
        value: hasEstimate ? formatFundHoldingMoney(portfolioValue) : '--',
        valueColor: hasEstimate ? estimateColor : cs.onSurface,
        isHidden: hasEstimate && !_showSensitiveAmounts,
        onTap: hasEstimate ? _toggleSensitiveAmounts : null,
      ),
      _OverviewStatItem(
        label: '持仓成本',
        value: hasEstimate ? formatFundHoldingMoney(totalCost) : '--',
        isHidden: hasEstimate && !_showSensitiveAmounts,
        onTap: hasEstimate ? _toggleSensitiveAmounts : null,
      ),
      _OverviewStatItem(
        label: '累计收益',
        value: hasEstimate ? formatSignedFundHoldingMoney(totalReturn) : '--',
        valueColor: hasEstimate
            ? fundHoldingSignedColor(totalReturn, cs)
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
                      '${widget.holdings.length} 笔持仓 · $channels 个渠道',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FundHoldingStatusPill(
                label: hasEstimate
                    ? hasFinalReturn
                          ? '已确认'
                          : '已估算'
                    : '同步中',
                color: hasEstimate ? sentimentColor : cs.primary,
                icon: hasEstimate
                    ? Icons.check_circle_outline
                    : Icons.sync_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PortfolioReturnSection(
            estimates: widget.estimates,
            hasEstimate: hasEstimate,
            hasFinalReturn: hasFinalReturn,
            confirmedNavDate: confirmedNavDate,
            finalReturn: finalReturn,
            todayEstimate: todayEstimate,
            yesterdayReturn: yesterdayReturn,
            yesterdayValue: yesterdayValue,
            color: sentimentColor,
          ),
          const SizedBox(height: 16),
          _OverviewStatGrid(items: stats),
        ],
      ),
    );
  }
}

double _portfolioCurrentChange({
  required List<FundHoldingEstimate> estimates,
  required bool useConfirmedNav,
}) {
  return estimates.fold<double>(
    0,
    (sum, estimate) =>
        sum +
        (useConfirmedNav
            ? fundHoldingTodayEstimatedReturn(estimate)
            : (estimate.realtimeEstimate.estNav -
                      estimate.realtimeEstimate.prevNav) *
                  estimate.input.shares),
  );
}

class _PortfolioReturnSection extends StatelessWidget {
  const _PortfolioReturnSection({
    required this.estimates,
    required this.hasEstimate,
    required this.hasFinalReturn,
    required this.confirmedNavDate,
    required this.finalReturn,
    required this.todayEstimate,
    required this.yesterdayReturn,
    required this.yesterdayValue,
    required this.color,
  });

  final List<FundHoldingEstimate> estimates;
  final bool hasEstimate;
  final bool hasFinalReturn;
  final String? confirmedNavDate;
  final double finalReturn;
  final double todayEstimate;
  final double yesterdayReturn;
  final double yesterdayValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!hasEstimate) {
      return _OverviewHeadline(
        label: '正在拉取估值',
        value: '估算中...',
        helper: '完成后会自动刷新组合摘要',
        color: color,
      );
    }

    if (hasFinalReturn) {
      return _OverviewHeadline(
        label: '今日最终收益',
        value: formatSignedFundHoldingMoney(finalReturn),
        helper: _finalReturnHelper(
          estimates: estimates,
          confirmedNavDate: confirmedNavDate,
          changeRate: fundHoldingReturnRate(finalReturn, yesterdayValue),
        ),
        color: color,
      );
    }

    return _EstimatedReturnOverview(
      estimates: estimates,
      todayEstimate: todayEstimate,
      yesterdayReturn: yesterdayReturn,
      yesterdayValue: yesterdayValue,
      color: color,
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

class _EstimatedReturnOverview extends StatelessWidget {
  const _EstimatedReturnOverview({
    required this.estimates,
    required this.todayEstimate,
    required this.yesterdayReturn,
    required this.yesterdayValue,
    required this.color,
  });

  final List<FundHoldingEstimate> estimates;
  final double todayEstimate;
  final double yesterdayReturn;
  final double yesterdayValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final yesterday = _OverviewSupportMetric(
      label: '昨日收益',
      value: formatSignedFundHoldingMoney(yesterdayReturn),
      helper: _yesterdayReturnHelper(estimates),
      percent: formatFundHoldingPercent(
        fundHoldingReturnRate(yesterdayReturn, yesterdayValue),
      ),
      color: fundHoldingSignedColor(
        yesterdayReturn,
        Theme.of(context).colorScheme,
      ),
    );
    final today = _OverviewHeadline(
      label: '今日估值',
      value: formatSignedFundHoldingMoney(todayEstimate),
      helper: _estimateReturnHelper(estimates),
      color: color,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: today),
              const SizedBox(width: 18),
              SizedBox(width: 168, child: yesterday),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            today,
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: yesterday),
          ],
        );
      },
    );
  }
}

class _OverviewSupportMetric extends StatelessWidget {
  const _OverviewSupportMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(184),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        border: Border.all(color: cs.outlineVariant.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$percent · $helper',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _finalReturnHelper({
  required List<FundHoldingEstimate> estimates,
  required String? confirmedNavDate,
  required double changeRate,
}) {
  final prevNavDate = _singleValue(
    estimates.map((estimate) => estimate.realtimeEstimate.prevNavDate),
  );
  final confirmedText = confirmedNavDate == null
      ? '净值已确认'
      : '$confirmedNavDate 净值确认';
  final basisText = prevNavDate == null ? '多基金净值基准' : '较 $prevNavDate';
  return '$confirmedText · $basisText ${formatFundHoldingPercent(changeRate)}';
}

String _estimateReturnHelper(List<FundHoldingEstimate> estimates) {
  final prevNavDate = _singleValue(
    estimates.map((estimate) => estimate.realtimeEstimate.prevNavDate),
  );
  final latestEstimateTime = _latestValue(
    estimates.map((estimate) => estimate.realtimeEstimate.estTime),
  );
  final baseLabel = prevNavDate == null ? '多基金净值基准' : '$prevNavDate 净值基准';
  return latestEstimateTime == null
      ? baseLabel
      : '$baseLabel · 更新至 $latestEstimateTime';
}

String _yesterdayReturnHelper(List<FundHoldingEstimate> estimates) {
  final previousTradingDate = _singleValue(
    estimates.map(
      (estimate) => estimate.realtimeEstimate.previousTradingNavDate ?? '',
    ),
  );
  final prevNavDate = _singleValue(
    estimates.map((estimate) => estimate.realtimeEstimate.prevNavDate),
  );
  if (previousTradingDate != null && prevNavDate != null) {
    return '$previousTradingDate → $prevNavDate';
  }
  if (prevNavDate != null) return '$prevNavDate 已确认';
  return '最近已确认净值';
}

String? _singleValue(Iterable<String> values) {
  final nonEmptyValues = values.where((value) => value.isNotEmpty).toSet();
  return nonEmptyValues.length == 1 ? nonEmptyValues.single : null;
}

String? _latestValue(Iterable<String> values) {
  final nonEmptyValues = values.where((value) => value.isNotEmpty).toList();
  if (nonEmptyValues.isEmpty) return null;
  nonEmptyValues.sort();
  return nonEmptyValues.last;
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
    final value = item.isHidden ? '***' : item.value;
    final valueColor = item.isHidden
        ? cs.onSurface
        : item.valueColor ?? cs.onSurface;
    final content = Container(
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
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    final onTap = item.onTap;
    if (onTap == null) return content;

    return Semantics(
      button: true,
      toggled: !item.isHidden,
      hint: item.isHidden ? '点击显示金额' : '点击隐藏金额',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
          child: content,
        ),
      ),
    );
  }
}

class _OverviewStatItem {
  const _OverviewStatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isHidden = false,
    this.onTap,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isHidden;
  final VoidCallback? onTap;
}
