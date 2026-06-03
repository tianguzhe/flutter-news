import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/num_text.dart';
import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import 'fund_holding_detail_sheet.dart';

class FundHoldingCard extends StatelessWidget {
  const FundHoldingCard({
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FundHoldingDetailSheet(
        holding: holding,
        state: state,
        onRefresh: onRefresh,
        onEdit: onEdit,
        onRemove: onRemove,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = state.when(
      loading: () => cs.primary,
      error: (_, _) => cs.error,
      data: (e) =>
          fundHoldingSignedColor(fundHoldingYesterdayActualReturn(e), cs),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: state.when(
            loading: () => _HoldingListShell(
              accentColor: accentColor,
              leadingIcon: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
              title: holding.code,
              subtitle: '买入 ${formatFundHoldingDate(holding.purchaseDate)}',
              trailing: Text(
                '拉取中...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            error: (_, _) => _HoldingListShell(
              accentColor: accentColor,
              leadingIcon: Icon(Icons.error_outline, size: 17, color: cs.error),
              title: holding.code,
              subtitle: '买入 ${formatFundHoldingDate(holding.purchaseDate)}',
              trailing: Text(
                '拉取失败',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            data: (estimate) {
              final realtime = estimate.realtimeEstimate;
              final todayEstimate = fundHoldingTodayEstimatedReturn(estimate);
              final estimateColor = fundHoldingEstimateAccent(cs);
              return _HoldingListShell(
                accentColor: estimateColor,
                leadingIcon: Icon(
                  Icons.query_stats_rounded,
                  size: 17,
                  color: estimateColor,
                ),
                title: realtime.name,
                code: realtime.code,
                subtitle:
                    '成本 ${formatFundHoldingMoney(estimate.cost)} · ${formatFundHoldingDate(estimate.input.purchaseDate)}',
                trailing: _HoldingReturnSummary(
                  value: formatSignedFundHoldingMoney(todayEstimate),
                  percent: formatSignedFundHoldingPercent(
                    realtime.estChangePct,
                  ),
                  color: estimateColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HoldingListShell extends StatelessWidget {
  const _HoldingListShell({
    required this.accentColor,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.code,
  });

  final Color accentColor;
  final Widget leadingIcon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tintFundHoldingSurface(accentColor, cs.surface, 18),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: leadingIcon,
        ),
        const SizedBox(width: 11),
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
                  if (code != null) ...[
                    const SizedBox(width: 6),
                    _CodeChip(code!),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, size: 16, color: cs.outline),
      ],
    );
  }
}

class _HoldingReturnSummary extends StatelessWidget {
  const _HoldingReturnSummary({
    required this.value,
    required this.percent,
    required this.color,
  });

  final String value;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '实时预估',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            percent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
        color: cs.surface.withAlpha(160),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.outlineVariant.withAlpha(70)),
      ),
      child: NumText(
        code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Holding detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
