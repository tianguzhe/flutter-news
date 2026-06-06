import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/num_text.dart';
import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import '../utils/fund_holding_group_summary.dart';

class FundHoldingGroupDetailSheet extends StatelessWidget {
  const FundHoldingGroupDetailSheet({
    super.key,
    required this.holdings,
    required this.states,
    required this.channel,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final List<FundHoldingInput> holdings;
  final Map<int, AsyncValue<FundHoldingEstimate>> states;
  final String channel;
  final ValueChanged<FundHoldingInput> onRefresh;
  final ValueChanged<FundHoldingInput> onEdit;
  final ValueChanged<FundHoldingInput> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary = summarizeFundHoldingGroup(
      holdings: holdings,
      states: states,
    );

    void closeAndRun(
      FundHoldingInput holding,
      ValueChanged<FundHoldingInput> action,
    ) {
      Navigator.of(context).pop();
      action(holding);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
                children: [
                  _GroupHeader(summary: summary, channel: channel),
                  const SizedBox(height: 12),
                  _GroupReturnPanel(summary: summary),
                  const SizedBox(height: 14),
                  if (summary.hasCompleteEstimates) ...[
                    _SectionTitle(
                      icon: Icons.assessment_outlined,
                      label: '收益结果',
                      color: fundHoldingSignedColor(
                        summary.displayTotalReturn,
                        cs,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _MetricGrid(
                      items: [
                        _MetricItem(
                          '持仓成本',
                          formatFundHoldingMoney(summary.totalCost),
                        ),
                        _MetricItem(
                          summary.hasFinalReturn ? '实际市值' : '估算市值',
                          formatFundHoldingMoney(summary.marketValue),
                        ),
                        _MetricItem(
                          '累计收益',
                          formatSignedFundHoldingMoney(
                            summary.displayTotalReturn,
                          ),
                          valueColor: fundHoldingSignedColor(
                            summary.displayTotalReturn,
                            cs,
                          ),
                        ),
                        _MetricItem(
                          '累计收益率',
                          formatFundHoldingPercent(
                            summary.displayTotalReturnRate,
                          ),
                          valueColor: fundHoldingSignedColor(
                            summary.displayTotalReturnRate,
                            cs,
                          ),
                        ),
                        _MetricItem(
                          '持有份额',
                          formatFundHoldingNumber(summary.totalShares, 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionTitle(
                    icon: Icons.receipt_long_outlined,
                    label: '分笔明细',
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 9),
                  for (int i = 0; i < holdings.length; i++) ...[
                    _HoldingLotCard(
                      holding: holdings[i],
                      estimate: summary.estimateFor(holdings[i]),
                      state: states[holdings[i].id] ?? const AsyncLoading(),
                      onRefresh: () => closeAndRun(holdings[i], onRefresh),
                      onEdit: () => closeAndRun(holdings[i], onEdit),
                      onRemove: () => closeAndRun(holdings[i], onRemove),
                    ),
                    if (i < holdings.length - 1) const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.summary, required this.channel});

  final FundHoldingGroupSummary summary;
  final String channel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (summary.code.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _CodeChip(summary.code),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${summary.holdings.length} 笔 · $channel',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (summary.changePct != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: fundHoldingSignedColor(
                          summary.changePct!,
                          cs,
                        ).withAlpha(18),
                        border: Border.all(
                          color: fundHoldingSignedColor(
                            summary.changePct!,
                            cs,
                          ).withAlpha(70),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '今日 ${formatSignedFundHoldingPercent(summary.changePct!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fundHoldingSignedColor(summary.changePct!, cs),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupReturnPanel extends StatelessWidget {
  const _GroupReturnPanel({required this.summary});

  final FundHoldingGroupSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!summary.hasCompleteEstimates) {
      final color = summary.hasError ? cs.error : cs.primary;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: tintFundHoldingSurface(color, cs.surface, 10),
          borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
          border: Border.all(color: color.withAlpha(45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.hasError)
              Icon(Icons.error_outline, color: color)
            else
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.hasError ? '估值拉取失败' : '正在拉取估值',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    summary.hasError
                        ? summary.errorMessage ?? '请刷新该基金估值后重试'
                        : '数据回来后会汇总该基金在当前渠道下的全部买入记录',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final primaryReturn = summary.hasFinalReturn
        ? summary.finalReturn
        : summary.todayEstimateReturn;
    final color = fundHoldingSignedColor(primaryReturn, cs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tintFundHoldingSurface(color, cs.surface, 18),
            tintFundHoldingSurface(cs.primary, cs.surface, 8),
          ],
        ),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.hasFinalReturn)
            _PrimaryReturnMetric(
              label: '今日最终收益',
              value: summary.finalReturn,
              helper:
                  '确认净值 ${formatFundHoldingNumber(summary.estimates.first.realtimeEstimate.valuationNav, 4)} · ${summary.confirmedNavDate}',
              color: color,
            )
          else
            _PendingReturnMetrics(
              todayEstimate: summary.todayEstimateReturn,
              yesterdayReturn: summary.yesterdayReturn,
              estimateTime: summary.estimateTime ?? '-',
              estimateNav: summary.estimateNav ?? 0,
              yesterdayNavDate: summary.prevNavDate ?? '-',
            ),
          const SizedBox(height: 6),
          Text(
            summary.hasFinalReturn ? '最终数据已确认' : '最终净值未确认，先显示昨日收益和今日盘中估值',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HoldingLotCard extends StatelessWidget {
  const _HoldingLotCard({
    required this.holding,
    required this.estimate,
    required this.state,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final FundHoldingInput holding;
  final FundHoldingEstimate? estimate;
  final AsyncValue<FundHoldingEstimate> state;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = estimate == null
        ? state.when(
            loading: () => cs.primary,
            error: (_, _) => cs.error,
            data: (value) => fundHoldingSignedColor(
              value.realtimeEstimate.hasConfirmedNav
                  ? fundHoldingTodayEstimatedReturn(value)
                  : fundHoldingTodayIntradayEstimateReturn(value),
              cs,
            ),
          )
        : fundHoldingSignedColor(
            estimate!.realtimeEstimate.hasConfirmedNav
                ? fundHoldingTodayEstimatedReturn(estimate!)
                : fundHoldingTodayIntradayEstimateReturn(estimate!),
            cs,
          );
    final cost =
        estimate?.cost ?? holding.purchaseNav * holding.shares + holding.fee;
    final marketValue = estimate == null
        ? null
        : estimate!.realtimeEstimate.hasConfirmedNav
        ? estimate!.estimatedValue
        : estimate!.realtimeEstimate.estNav * estimate!.input.shares;
    final dailyReturn = estimate == null
        ? null
        : estimate!.realtimeEstimate.hasConfirmedNav
        ? fundHoldingTodayEstimatedReturn(estimate!)
        : fundHoldingTodayIntradayEstimateReturn(estimate!);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 9, 11),
      decoration: BoxDecoration(
        color: tintFundHoldingSurface(color, cs.surfaceContainerLowest, 7),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tintFundHoldingSurface(color, cs.surface, 18),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_outlined, size: 17, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '买入 ${formatFundHoldingDate(holding.purchaseDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '份额 ${formatFundHoldingNumber(holding.shares, 2)} · 净值 ${formatFundHoldingNumber(holding.purchaseNav, 4)} · 成本 ${formatFundHoldingMoney(cost)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (marketValue != null && dailyReturn != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _LotMetric(
                        label: estimate!.realtimeEstimate.hasConfirmedNav
                            ? '实际市值'
                            : '估算市值',
                        value: formatFundHoldingMoney(marketValue),
                      ),
                      _LotMetric(
                        label: estimate!.realtimeEstimate.hasConfirmedNav
                            ? '今日最终'
                            : '今日估值',
                        value: formatSignedFundHoldingMoney(dailyReturn),
                        color: fundHoldingSignedColor(dailyReturn, cs),
                      ),
                      if (!estimate!.realtimeEstimate.hasConfirmedNav)
                        _LotMetric(
                          label: '昨日收益',
                          value: formatSignedFundHoldingMoney(
                            fundHoldingYesterdayActualReturn(estimate!),
                          ),
                          color: fundHoldingSignedColor(
                            fundHoldingYesterdayActualReturn(estimate!),
                            cs,
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    state is AsyncError<FundHoldingEstimate>
                        ? '拉取失败'
                        : '拉取中...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: state is AsyncError<FundHoldingEstimate>
                          ? cs.error
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 7),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.end,
            children: [
              _IconActionButton(
                onPressed: onRefresh,
                tooltip: '刷新估值',
                icon: const Icon(Icons.refresh),
              ),
              _IconActionButton(
                onPressed: onEdit,
                tooltip: '编辑持仓',
                icon: const Icon(Icons.edit_outlined),
              ),
              _IconActionButton(
                onPressed: onRemove,
                tooltip: '删除持仓',
                icon: const Icon(Icons.delete_outline),
                color: cs.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PrimaryReturnMetric extends StatelessWidget {
  const _PrimaryReturnMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final double value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatSignedFundHoldingMoney(value),
            maxLines: 1,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PendingReturnMetrics extends StatelessWidget {
  const _PendingReturnMetrics({
    required this.todayEstimate,
    required this.yesterdayReturn,
    required this.estimateTime,
    required this.estimateNav,
    required this.yesterdayNavDate,
  });

  final double todayEstimate;
  final double yesterdayReturn;
  final String estimateTime;
  final double estimateNav;
  final String yesterdayNavDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _ReturnMiniMetric(
          label: '今日估值',
          value: todayEstimate,
          helper:
              '估算净值 ${formatFundHoldingNumber(estimateNav, 4)} · $estimateTime',
          color: fundHoldingSignedColor(todayEstimate, cs),
        ),
        _ReturnMiniMetric(
          label: '昨日收益',
          value: yesterdayReturn,
          helper: '$yesterdayNavDate 已确认',
          color: fundHoldingSignedColor(yesterdayReturn, cs),
        ),
      ],
    );
  }
}

class _ReturnMiniMetric extends StatelessWidget {
  const _ReturnMiniMetric({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final double value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatSignedFundHoldingMoney(value),
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        const spacing = 8.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: _MetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: tintFundHoldingSurface(cs.primary, cs.surfaceContainerLowest, 5),
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
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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

class _LotMetric extends StatelessWidget {
  const _LotMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant.withAlpha(65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color ?? cs.onSurface,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final Widget icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: icon,
        color: color,
        iconSize: 18,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      child: NumText(
        code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}
