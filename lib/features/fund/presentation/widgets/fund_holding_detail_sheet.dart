import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/num_text.dart';
import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';

class FundHoldingDetailSheet extends StatelessWidget {
  const FundHoldingDetailSheet({
    super.key,
    required this.holding,
    required this.state,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final FundHoldingInput holding;
  final AsyncValue<FundHoldingEstimate> state;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    void pop() => Navigator.of(context).pop();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
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
                  state.when(
                    loading: () => _HoldingLoading(holding: holding),
                    error: (error, _) => _HoldingError(
                      holding: holding,
                      message: error.toString(),
                      onRefresh: () {
                        pop();
                        onRefresh();
                      },
                      onEdit: () {
                        pop();
                        onEdit();
                      },
                      onRemove: () {
                        pop();
                        onRemove();
                      },
                    ),
                    data: (estimate) => _HoldingEstimateResult(
                      estimate: estimate,
                      onRefresh: () {
                        pop();
                        onRefresh();
                      },
                      onEdit: () {
                        pop();
                        onEdit();
                      },
                      onRemove: () {
                        pop();
                        onRemove();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingEstimateResult extends StatelessWidget {
  const _HoldingEstimateResult({
    required this.estimate,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final FundHoldingEstimate estimate;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final realtime = estimate.realtimeEstimate;
    final hasConfirmedNav = realtime.hasConfirmedNav;
    final todayEstimate = fundHoldingTodayIntradayEstimateReturn(estimate);
    final finalReturn = fundHoldingTodayEstimatedReturn(estimate);
    final yesterdayReturn = fundHoldingYesterdayActualReturn(estimate);
    final displayValue = hasConfirmedNav
        ? estimate.estimatedValue
        : realtime.estNav * estimate.input.shares;
    final displayTotalReturn = displayValue - estimate.cost;
    final displayTotalRate = fundHoldingReturnRate(
      displayTotalReturn,
      estimate.cost,
    );
    final color = fundHoldingSignedColor(
      hasConfirmedNav ? finalReturn : todayEstimate,
      cs,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HoldingHeader(
          title: realtime.name,
          code: realtime.code,
          subtitle: '买入 ${formatFundHoldingDate(estimate.input.purchaseDate)}',
          changePct: realtime.estChangePct,
          onRefresh: onRefresh,
          onEdit: onEdit,
          onRemove: onRemove,
        ),
        const SizedBox(height: 12),
        Container(
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
              if (hasConfirmedNav)
                _PrimaryReturnMetric(
                  label: '今日最终收益',
                  value: finalReturn,
                  helper:
                      '确认净值 ${formatFundHoldingNumber(realtime.valuationNav, 4)} · ${realtime.confirmedNavDate}',
                  color: color,
                )
              else
                _PendingReturnMetrics(
                  todayEstimate: todayEstimate,
                  yesterdayReturn: yesterdayReturn,
                  estimateTime: realtime.estTime,
                  estimateNav: realtime.estNav,
                  yesterdayNavDate: realtime.prevNavDate,
                ),
              const SizedBox(height: 6),
              Text(
                hasConfirmedNav ? '最终数据已确认' : '最终净值未确认，先显示昨日收益和今日盘中估值',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DetailSectionTitle(
          icon: Icons.assessment_outlined,
          label: '收益结果',
          color: fundHoldingSignedColor(displayTotalReturn, cs),
        ),
        const SizedBox(height: 9),
        _MetricGrid(
          items: [
            _MetricItem('持仓成本', formatFundHoldingMoney(estimate.cost)),
            _MetricItem(
              hasConfirmedNav ? '实际市值' : '估算市值',
              formatFundHoldingMoney(displayValue),
            ),
            _MetricItem(
              '累计收益',
              formatSignedFundHoldingMoney(displayTotalReturn),
              valueColor: fundHoldingSignedColor(displayTotalReturn, cs),
            ),
            _MetricItem(
              '累计收益率',
              formatFundHoldingPercent(displayTotalRate),
              valueColor: fundHoldingSignedColor(displayTotalRate, cs),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailSectionTitle(
          icon: Icons.receipt_long_outlined,
          label: '计算依据',
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(height: 9),
        _MetricGrid(
          items: [
            _MetricItem(
              '买入时间',
              formatFundHoldingDate(estimate.input.purchaseDate),
            ),
            _MetricItem(
              '持有份额',
              formatFundHoldingNumber(estimate.input.shares, 2),
            ),
            _MetricItem(
              '购买净值',
              formatFundHoldingNumber(estimate.input.purchaseNav, 4),
            ),
            _MetricItem('手续费', formatFundHoldingMoney(estimate.input.fee)),
          ],
        ),
      ],
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({
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

class _HoldingHeader extends StatelessWidget {
  const _HoldingHeader({
    required this.title,
    required this.code,
    required this.subtitle,
    required this.changePct,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String code;
  final String subtitle;
  final double? changePct;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
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
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (changePct != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: fundHoldingSignedColor(
                          changePct!,
                          cs,
                        ).withAlpha(18),
                        border: Border.all(
                          color: fundHoldingSignedColor(
                            changePct!,
                            cs,
                          ).withAlpha(70),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '今日 ${formatSignedFundHoldingPercent(changePct!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fundHoldingSignedColor(changePct!, cs),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric grid
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error states
// ─────────────────────────────────────────────────────────────────────────────

class _HoldingLoading extends StatelessWidget {
  const _HoldingLoading({required this.holding});

  final FundHoldingInput holding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                holding.code,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '买入 ${formatFundHoldingDate(holding.purchaseDate)} · 正在拉取估值',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoldingError extends StatelessWidget {
  const _HoldingError({
    required this.holding,
    required this.message,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final FundHoldingInput holding;
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HoldingHeader(
          title: holding.code,
          code: holding.code,
          subtitle: '买入 ${formatFundHoldingDate(holding.purchaseDate)}',
          changePct: null,
          onRefresh: onRefresh,
          onEdit: onEdit,
          onRemove: onRemove,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

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

class _MetricItem {
  const _MetricItem(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}
