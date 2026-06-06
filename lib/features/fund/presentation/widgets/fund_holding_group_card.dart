import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/num_text.dart';
import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import '../utils/fund_holding_group_summary.dart';
import 'fund_holding_group_detail_sheet.dart';

class FundHoldingGroupCard extends StatelessWidget {
  const FundHoldingGroupCard({
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FundHoldingGroupDetailSheet(
        holdings: holdings,
        states: states,
        channel: channel,
        onRefresh: onRefresh,
        onEdit: onEdit,
        onRemove: onRemove,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary = summarizeFundHoldingGroup(
      holdings: holdings,
      states: states,
    );
    final primaryReturn = summary.hasFinalReturn
        ? summary.finalReturn
        : summary.todayEstimateReturn;
    final accentColor = summary.hasError
        ? cs.error
        : summary.hasCompleteEstimates
        ? fundHoldingSignedColor(primaryReturn, cs)
        : cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: _GroupListShell(
            accentColor: accentColor,
            leadingIcon: _leadingIcon(summary, accentColor, cs),
            title: summary.title,
            code: summary.code.isEmpty ? null : summary.code,
            subtitle: _subtitle(summary),
            trailing: _trailing(context, summary, accentColor),
          ),
        ),
      ),
    );
  }

  Widget _leadingIcon(
    FundHoldingGroupSummary summary,
    Color accentColor,
    ColorScheme cs,
  ) {
    if (!summary.hasCompleteEstimates && !summary.hasError) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
      );
    }
    if (summary.hasError) {
      return Icon(Icons.error_outline, size: 17, color: cs.error);
    }
    return Icon(Icons.query_stats_rounded, size: 17, color: accentColor);
  }

  String _subtitle(FundHoldingGroupSummary summary) {
    if (!summary.hasCompleteEstimates) {
      if (summary.hasError) return '${summary.holdings.length} 笔 · 拉取失败';
      return '${summary.holdings.length} 笔 · 正在估算';
    }
    return '${summary.holdings.length} 笔 · 份额 ${formatFundHoldingNumber(summary.totalShares, 2)} · 成本 ${formatFundHoldingMoney(summary.totalCost)}';
  }

  Widget _trailing(
    BuildContext context,
    FundHoldingGroupSummary summary,
    Color accentColor,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (!summary.hasCompleteEstimates) {
      return Text(
        summary.hasError ? '拉取失败' : '拉取中...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: summary.hasError ? cs.error : cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (summary.hasFinalReturn) {
      return _GroupReturnSummary(
        label: '今日最终',
        value: formatSignedFundHoldingMoney(summary.finalReturn),
        helper: summary.changePct == null
            ? ''
            : formatSignedFundHoldingPercent(summary.changePct!),
        color: accentColor,
      );
    }
    return _GroupEstimateSummary(
      todayValue: formatSignedFundHoldingMoney(summary.todayEstimateReturn),
      yesterdayValue: formatSignedFundHoldingMoney(summary.yesterdayReturn),
      todayColor: accentColor,
      yesterdayColor: fundHoldingSignedColor(summary.yesterdayReturn, cs),
    );
  }
}

class _GroupListShell extends StatelessWidget {
  const _GroupListShell({
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

class _GroupReturnSummary extends StatelessWidget {
  const _GroupReturnSummary({
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
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
          if (helper.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupEstimateSummary extends StatelessWidget {
  const _GroupEstimateSummary({
    required this.todayValue,
    required this.yesterdayValue,
    required this.todayColor,
    required this.yesterdayColor,
  });

  final String todayValue;
  final String yesterdayValue;
  final Color todayColor;
  final Color yesterdayColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _GroupMiniMetric(label: '今日估值', value: todayValue, color: todayColor),
          const SizedBox(height: 5),
          _GroupMiniMetric(
            label: '昨日收益',
            value: yesterdayValue,
            color: yesterdayColor,
          ),
        ],
      ),
    );
  }
}

class _GroupMiniMetric extends StatelessWidget {
  const _GroupMiniMetric({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
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
      ],
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
