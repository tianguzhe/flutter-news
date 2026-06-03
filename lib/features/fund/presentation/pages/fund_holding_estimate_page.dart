import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/num_text.dart';
import '../../data/models/realtime_estimate.dart';
import '../../data/repositories/fund_estimate_repository_provider.dart';
import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';

const _cardRadius = 12.0;
const _innerRadius = 8.0;
const _contentMaxWidth = 760.0;

enum _HoldingDataAction { importJson, exportJson }

class FundHoldingEstimatePage extends ConsumerStatefulWidget {
  const FundHoldingEstimatePage({super.key});

  @override
  ConsumerState<FundHoldingEstimatePage> createState() =>
      _FundHoldingEstimatePageState();
}

class _FundHoldingEstimatePageState
    extends ConsumerState<FundHoldingEstimatePage> {
  var _isLoadingHoldings = true;
  Object? _loadHoldingsError;
  final _holdings = <FundHoldingInput>[];
  final _holdingStates = <int, AsyncValue<FundHoldingEstimate>>{};
  // code → in-flight or completed Future; multiple holdings with same code share one request
  final _estimateCache = <String, Future<RealtimeEstimate>>{};

  @override
  void initState() {
    super.initState();
    _loadHoldings();
  }

  Future<void> _loadHoldings() async {
    try {
      final holdings = await ref
          .read(fundHoldingRepositoryProvider)
          .listActiveHoldings();
      if (!mounted) return;
      _estimateCache.clear();
      setState(() {
        _holdings
          ..clear()
          ..addAll(holdings);
        _holdingStates
          ..clear()
          ..addEntries(
            holdings.map((h) => MapEntry(h.id, const AsyncLoading())),
          );
        _loadHoldingsError = null;
        _isLoadingHoldings = false;
      });
      // same-code holdings share one in-flight Future via _getEstimate
      await Future.wait(holdings.map(_computeEstimate));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadHoldingsError = error;
        _isLoadingHoldings = false;
      });
    }
  }

  Future<void> _openAddHoldingPage() async {
    final input = await Navigator.of(context).push<FundHoldingInput>(
      MaterialPageRoute(builder: (_) => const FundHoldingEntryPage()),
    );
    if (input == null || !mounted) return;
    _estimateCache.remove(input.code);
    setState(() {
      _holdings.add(input);
      _holdingStates[input.id] = const AsyncLoading();
    });
    await _computeEstimate(input);
  }

  Future<void> _openEditHoldingPage(FundHoldingInput holding) async {
    final updated = await Navigator.of(context).push<FundHoldingInput>(
      MaterialPageRoute(
        builder: (_) => FundHoldingEntryPage(initialHolding: holding),
      ),
    );
    if (updated == null || !mounted) return;
    _estimateCache.remove(updated.code);
    setState(() {
      final index = _holdings.indexWhere((item) => item.id == updated.id);
      if (index == -1) {
        _holdings.add(updated);
      } else {
        _holdings[index] = updated;
      }
      // refresh all holdings sharing the same code
      for (final h in _holdings.where((h) => h.code == updated.code)) {
        _holdingStates[h.id] = const AsyncLoading();
      }
    });
    await Future.wait(
      _holdings.where((h) => h.code == updated.code).map(_computeEstimate),
    );
  }

  // Called from UI refresh button: invalidates cache and refreshes all same-code holdings.
  Future<void> _refreshHolding(FundHoldingInput input) async {
    _estimateCache.remove(input.code);
    final targets = _holdings.where((h) => h.code == input.code).toList();
    setState(() {
      for (final t in targets) {
        _holdingStates[t.id] = const AsyncLoading();
      }
    });
    await Future.wait(targets.map(_computeEstimate));
  }

  Future<RealtimeEstimate> _getEstimate(String code) =>
      _estimateCache.putIfAbsent(
        code,
        () => ref
            .read(fundEstimateRepositoryProvider)
            .fetchRealtimeEstimate(code),
      );

  Future<void> _computeEstimate(FundHoldingInput input) async {
    final result = await AsyncValue.guard(
      () async => calculateFundHoldingEstimate(
        input: input,
        realtimeEstimate: await _getEstimate(input.code),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (_holdings.any((h) => h.id == input.id)) {
        _holdingStates[input.id] = result;
      }
    });
  }

  Future<void> _removeHolding(FundHoldingInput input) async {
    try {
      await ref.read(fundHoldingRepositoryProvider).softDeleteHolding(input.id);
      if (!mounted) return;
      setState(() {
        _holdings.removeWhere((h) => h.id == input.id);
        _holdingStates.remove(input.id);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除持仓失败：$error')));
    }
  }

  Future<void> _openImportJsonDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('从 JSON 导入持仓'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '粘贴 holdings.json 内容，格式：\n{"holdings":{"渠道名":[{...}]}}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '在此粘贴 JSON...',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final jsonText = controller.text.trim();
    if (jsonText.isEmpty) return;

    final result = await _importHoldingsFromJson(jsonText);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.failed == 0
              ? '成功导入 ${result.imported} 笔持仓'
              : '导入 ${result.imported} 笔，${result.failed} 笔失败',
        ),
      ),
    );

    if (result.imported > 0) {
      await _loadHoldings();
    }
  }

  Future<void> _openExportJsonDialog() async {
    final controller = TextEditingController(text: _exportHoldingsToJson());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导出 JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '复制以下内容保存为 holdings.json，可直接用于导入。',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                readOnly: true,
                maxLines: 10,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: controller.text));
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已复制导出 JSON')));
            },
            icon: const Icon(Icons.content_copy_outlined),
            label: const Text('复制'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  String _exportHoldingsToJson() {
    final holdingsByChannel = <String, List<Map<String, Object?>>>{};
    final sortedHoldings = [..._holdings]
      ..sort((a, b) {
        final channelCompare = a.channel.compareTo(b.channel);
        if (channelCompare != 0) return channelCompare;
        return a.purchaseDate.compareTo(b.purchaseDate);
      });

    for (final holding in sortedHoldings) {
      holdingsByChannel.putIfAbsent(holding.channel, () => []).add({
        'code': holding.code,
        'buy_date': _formatDate(holding.purchaseDate),
        'shares': holding.shares,
        'cost_nav': holding.purchaseNav,
        'fee': holding.fee,
      });
    }

    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'holdings': holdingsByChannel});
  }

  Future<void> _handleDataMenuAction(_HoldingDataAction action) async {
    switch (action) {
      case _HoldingDataAction.importJson:
        await _openImportJsonDialog();
      case _HoldingDataAction.exportJson:
        await _openExportJsonDialog();
    }
  }

  Future<({int imported, int failed})> _importHoldingsFromJson(
    String jsonText,
  ) async {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final holdingsMap = decoded['holdings'] as Map<String, dynamic>;
    final repository = ref.read(fundHoldingRepositoryProvider);

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
          await repository.insertHolding(draft);
          imported++;
        } catch (_) {
          failed++;
        }
      }
    }

    return (imported: imported, failed: failed);
  }

  @override
  Widget build(BuildContext context) {
    final estimates = _holdings
        .map((h) => _holdingStates[h.id])
        .whereType<AsyncData<FundHoldingEstimate>>()
        .map((s) => s.value)
        .toList();

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('基金收益估算'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          PopupMenuButton<_HoldingDataAction>(
            tooltip: '持仓数据',
            icon: const Icon(Icons.more_vert),
            onSelected: _handleDataMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _HoldingDataAction.importJson,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text('导入 JSON'),
                ),
              ),
              PopupMenuItem(
                value: _HoldingDataAction.exportJson,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download_outlined),
                  title: Text('导出 JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: '新增持仓',
        onPressed: _openAddHoldingPage,
        icon: const Icon(Icons.add),
        label: const Text('新增持仓'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _tintSurface(cs.primary, cs.surfaceContainerLowest, 10),
              cs.surfaceContainerLowest,
              _tintSurface(cs.tertiary, cs.surfaceContainerLowest, 8),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_holdings.isNotEmpty) ...[
                        _PortfolioOverview(
                          holdings: _holdings,
                          estimates: estimates,
                        ),
                        const SizedBox(height: 18),
                      ],
                      _HoldingsByChannelSection(
                        holdings: _holdings,
                        states: _holdingStates,
                        isLoading: _isLoadingHoldings,
                        loadError: _loadHoldingsError,
                        onRefresh: _refreshHolding,
                        onEdit: _openEditHoldingPage,
                        onRemove: _removeHolding,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio overview hero card
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioOverview extends StatelessWidget {
  const _PortfolioOverview({required this.holdings, required this.estimates});

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
      (s, e) => s + _yesterdayValue(e),
    );
    final confirmedTotalReturn = yesterdayValue - totalCost;
    final yesterdayActualReturn = estimates.fold<double>(
      0,
      (s, e) => s + _yesterdayActualReturn(e),
    );
    final yesterdayRate = _returnRate(yesterdayActualReturn, totalCost);
    final hasEstimate = estimates.isNotEmpty;
    final todayEstimate = hasEstimate
        ? estimates.fold<double>(0, (s, e) => s + _todayEstimatedReturn(e))
        : 0.0;

    final cs = Theme.of(context).colorScheme;
    final estimateColor = _estimateAccent(cs);
    final sentimentColor = hasEstimate
        ? _signedColor(yesterdayActualReturn, cs)
        : cs.primary;

    final stats = [
      _OverviewStatItem(
        label: '估算市值',
        value: hasEstimate ? _formatMoney(estimatedValue) : '--',
        valueColor: hasEstimate ? estimateColor : cs.onSurface,
      ),
      _OverviewStatItem(
        label: '持仓成本',
        value: hasEstimate ? _formatMoney(totalCost) : '--',
      ),
      _OverviewStatItem(
        label: '累计收益',
        value: hasEstimate ? _formatSignedMoney(confirmedTotalReturn) : '--',
        valueColor: hasEstimate
            ? _signedColor(confirmedTotalReturn, cs)
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
            _tintSurface(cs.primary, cs.surface, 14),
            _tintSurface(cs.tertiary, cs.surface, 10),
          ],
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
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
                  color: _tintSurface(sentimentColor, cs.surface, 28),
                  borderRadius: BorderRadius.circular(_innerRadius),
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
              _StatusPill(
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
                    ? _formatSignedMoney(yesterdayActualReturn)
                    : '估算中...',
                helper: hasEstimate
                    ? '昨日变动率 ${_formatPercent(yesterdayRate)}'
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
    final color = _estimateAccent(cs);
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _tintSurface(color, cs.surface, 18),
        borderRadius: BorderRadius.circular(_innerRadius),
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
              _formatSignedMoney(value),
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
        borderRadius: BorderRadius.circular(_innerRadius),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
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

// ─────────────────────────────────────────────────────────────────────────────
// Holdings by channel section
// ─────────────────────────────────────────────────────────────────────────────

class _HoldingsByChannelSection extends StatelessWidget {
  const _HoldingsByChannelSection({
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
    final accent = _channelAccent(channelIndex);
    final estimates = holdings
        .map((h) => states[h.id])
        .whereType<AsyncData<FundHoldingEstimate>>()
        .map((s) => s.value)
        .toList();
    final yesterdayActualReturn = estimates.fold<double>(
      0,
      (s, e) => s + _yesterdayActualReturn(e),
    );
    final hasEstimate = estimates.isNotEmpty;
    final returnColor = hasEstimate
        ? _signedColor(yesterdayActualReturn, cs)
        : cs.primary;
    final totalValue = estimates.fold<double>(
      0,
      (sum, estimate) => sum + _yesterdayValue(estimate),
    );
    final totalCost = estimates.fold<double>(
      0,
      (sum, estimate) => sum + estimate.cost,
    );

    return Container(
      decoration: BoxDecoration(
        color: _tintSurface(accent, cs.surface, 7),
        borderRadius: BorderRadius.circular(_cardRadius),
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
                        borderRadius: BorderRadius.circular(_innerRadius),
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
                                ? '${holdings.length} 笔 · 成本 ${_formatMoney(totalCost)} · 昨日市值 ${_formatMoney(totalValue)}'
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
                  value: _formatSignedMoney(yesterdayActualReturn),
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
                  _HoldingCard(
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
        color: _tintSurface(color, cs.surface, 16),
        borderRadius: BorderRadius.circular(_innerRadius),
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

// ─────────────────────────────────────────────────────────────────────────────
// Individual holding card
// ─────────────────────────────────────────────────────────────────────────────

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({
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
      builder: (_) => _HoldingDetailSheet(
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
      data: (e) => _signedColor(_yesterdayActualReturn(e), cs),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(_innerRadius),
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
              subtitle: '买入 ${_formatDate(holding.purchaseDate)}',
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
              subtitle: '买入 ${_formatDate(holding.purchaseDate)}',
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
              final todayEstimate = _todayEstimatedReturn(estimate);
              final estimateColor = _estimateAccent(cs);
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
                    '成本 ${_formatMoney(estimate.cost)} · ${_formatDate(estimate.input.purchaseDate)}',
                trailing: _HoldingReturnSummary(
                  value: _formatSignedMoney(todayEstimate),
                  percent: _formatSignedPercent(realtime.estChangePct),
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
            color: _tintSurface(accentColor, cs.surface, 18),
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

class _HoldingDetailSheet extends StatelessWidget {
  const _HoldingDetailSheet({
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
    final confirmedTotalReturn = _confirmedTotalReturn(estimate);
    final confirmedTotalRate = _returnRate(confirmedTotalReturn, estimate.cost);
    final todayEstimate = _todayEstimatedReturn(estimate);
    final color = _estimateAccent(cs);
    final realtime = estimate.realtimeEstimate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HoldingHeader(
          title: realtime.name,
          code: realtime.code,
          subtitle: '买入 ${_formatDate(estimate.input.purchaseDate)}',
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
                _tintSurface(color, cs.surface, 18),
                _tintSurface(cs.primary, cs.surface, 8),
              ],
            ),
            borderRadius: BorderRadius.circular(_innerRadius),
            border: Border.all(color: color.withAlpha(45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日预估收益',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatSignedMoney(todayEstimate),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                  _StatusPill(
                    label: '预估 ${_formatSignedPercent(realtime.estChangePct)}',
                    color: color,
                    icon: Icons.query_stats_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '估算净值 ${_formatNumber(realtime.estNav, 4)}  ·  ${realtime.estTime}',
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
          color: _signedColor(confirmedTotalReturn, cs),
        ),
        const SizedBox(height: 9),
        _MetricGrid(
          items: [
            _MetricItem('持仓成本', _formatMoney(estimate.cost)),
            _MetricItem('估算市值', _formatMoney(estimate.estimatedValue)),
            _MetricItem(
              '累计收益',
              _formatSignedMoney(confirmedTotalReturn),
              valueColor: _signedColor(confirmedTotalReturn, cs),
            ),
            _MetricItem(
              '累计收益率',
              _formatPercent(confirmedTotalRate),
              valueColor: _signedColor(confirmedTotalRate, cs),
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
            _MetricItem('买入时间', _formatDate(estimate.input.purchaseDate)),
            _MetricItem('持有份额', _formatNumber(estimate.input.shares, 2)),
            _MetricItem('购买净值', _formatNumber(estimate.input.purchaseNav, 4)),
            _MetricItem('手续费', _formatMoney(estimate.input.fee)),
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
                        color: _signedColor(changePct!, cs).withAlpha(18),
                        border: Border.all(
                          color: _signedColor(changePct!, cs).withAlpha(70),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '今日 ${_formatSignedPercent(changePct!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _signedColor(changePct!, cs),
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
        color: _tintSurface(cs.primary, cs.surfaceContainerLowest, 5),
        borderRadius: BorderRadius.circular(_innerRadius),
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
                '买入 ${_formatDate(holding.purchaseDate)} · 正在拉取估值',
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
          subtitle: '买入 ${_formatDate(holding.purchaseDate)}',
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
// Empty / status panel
// ─────────────────────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(_cardRadius),
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

// ─────────────────────────────────────────────────────────────────────────────
// Entry / edit form page — unchanged except minor style polish
// ─────────────────────────────────────────────────────────────────────────────

class FundHoldingEntryPage extends ConsumerStatefulWidget {
  const FundHoldingEntryPage({super.key, this.initialHolding});

  final FundHoldingInput? initialHolding;

  @override
  ConsumerState<FundHoldingEntryPage> createState() =>
      _FundHoldingEntryPageState();
}

class _FundHoldingEntryPageState extends ConsumerState<FundHoldingEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _sharesController = TextEditingController();
  final _channelController = TextEditingController();
  final _purchaseNavController = TextEditingController();
  final _feeController = TextEditingController(text: '0');

  DateTime? _purchaseDate;
  var _isSaving = false;

  bool get _isEditing => widget.initialHolding != null;

  @override
  void initState() {
    super.initState();
    final holding = widget.initialHolding;
    if (holding == null) return;
    _codeController.text = holding.code;
    _sharesController.text = _formatEditableNumber(holding.shares);
    _channelController.text = holding.channel;
    _purchaseNavController.text = _formatEditableNumber(holding.purchaseNav);
    _feeController.text = _formatEditableNumber(holding.fee);
    _purchaseDate = holding.purchaseDate;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _sharesController.dispose();
    _channelController.dispose();
    _purchaseNavController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _purchaseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择购买时间')));
      return;
    }

    final draft = FundHoldingDraft(
      code: _codeController.text.trim(),
      purchaseDate: _purchaseDate!,
      shares: double.parse(_sharesController.text.trim()),
      channel: _channelController.text.trim(),
      purchaseNav: double.parse(_purchaseNavController.text.trim()),
      fee: double.parse(_feeController.text.trim()),
    );

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(fundHoldingRepositoryProvider);
      final input = _isEditing
          ? await repository.updateHolding(
              id: widget.initialHolding!.id,
              draft: draft,
            )
          : await repository.insertHolding(draft);
      if (!mounted) return;
      Navigator.of(context).pop(input);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存持仓失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑持仓' : '新增持仓'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _EntryFormCard(
              formKey: _formKey,
              codeController: _codeController,
              sharesController: _sharesController,
              channelController: _channelController,
              purchaseNavController: _purchaseNavController,
              feeController: _feeController,
              purchaseDate: _purchaseDate,
              onPickPurchaseDate: _pickPurchaseDate,
              onSubmit: _submit,
              isSaving: _isSaving,
              isEditing: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryFormCard extends StatelessWidget {
  const _EntryFormCard({
    required this.formKey,
    required this.codeController,
    required this.sharesController,
    required this.channelController,
    required this.purchaseNavController,
    required this.feeController,
    required this.purchaseDate,
    required this.onPickPurchaseDate,
    required this.onSubmit,
    required this.isSaving,
    required this.isEditing,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController sharesController;
  final TextEditingController channelController;
  final TextEditingController purchaseNavController;
  final TextEditingController feeController;
  final DateTime? purchaseDate;
  final VoidCallback onPickPurchaseDate;
  final VoidCallback onSubmit;
  final bool isSaving;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(_innerRadius),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note : Icons.add_chart,
                    size: 22,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? '编辑持仓信息' : '新增持仓信息',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '按实际购买记录填写，保存后自动估算收益',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(120)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: '基金代码',
                      hintText: '例如 000171',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                      prefixIcon: Icon(Icons.tag, color: cs.primary, size: 20),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: _validateFundCode,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: onPickPurchaseDate,
                    borderRadius: BorderRadius.circular(_innerRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: purchaseDate != null ? cs.primary : cs.outline,
                          width: purchaseDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: purchaseDate != null
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              purchaseDate == null
                                  ? '选择购买时间'
                                  : _formatDate(purchaseDate!),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: purchaseDate != null
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          if (purchaseDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '已选',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sharesController,
                    decoration: InputDecoration(
                      labelText: '份额',
                      hintText: '例如 1000.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                      prefixIcon: Icon(
                        Icons.stacked_bar_chart,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    validator: (v) => _validatePositiveNumber(v, '请输入份额'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: channelController,
                    decoration: InputDecoration(
                      labelText: '渠道',
                      hintText: '例如 支付宝 / 天天基金 / 银行',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '请输入渠道' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: purchaseNavController,
                    decoration: InputDecoration(
                      labelText: '购买时净值',
                      hintText: '例如 2.0820',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                      prefixIcon: Icon(
                        Icons.price_change,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    validator: (v) => _validatePositiveNumber(v, '请输入购买时净值'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: feeController,
                    decoration: InputDecoration(
                      labelText: '手续费',
                      hintText: '没有就填 0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    validator: _validateNonNegativeNumber,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_innerRadius),
                      ),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isEditing
                                ? Icons.save_outlined
                                : Icons.add_circle_outline,
                          ),
                    label: Text(
                      isEditing ? '保存并计算' : '添加并计算',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text input formatter
// ─────────────────────────────────────────────────────────────────────────────

class _DecimalTextInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Validators
// ─────────────────────────────────────────────────────────────────────────────

String? _validateFundCode(String? value) {
  final text = value?.trim() ?? '';
  if (!RegExp(r'^\d{6}$').hasMatch(text)) {
    return '请输入 6 位基金代码';
  }
  return null;
}

String? _validatePositiveNumber(String? value, String emptyMessage) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return emptyMessage;
  final number = double.tryParse(text);
  if (number == null || number <= 0) return '请输入大于 0 的数字';
  return null;
}

String? _validateNonNegativeNumber(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '请输入手续费，没有就填 0';
  final number = double.tryParse(text);
  if (number == null || number < 0) return '请输入不小于 0 的数字';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatters & helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatMoney(double value) => value.toStringAsFixed(2);

String _formatSignedMoney(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}';
}

String _formatPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${(value * 100).toStringAsFixed(2)}%';
}

String _formatSignedPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String _formatNumber(double value, int fractionDigits) =>
    value.toStringAsFixed(fractionDigits);

String _formatEditableNumber(double value) =>
    value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');

double _yesterdayValue(FundHoldingEstimate estimate) =>
    estimate.realtimeEstimate.prevNav * estimate.input.shares;

double _confirmedTotalReturn(FundHoldingEstimate estimate) =>
    _yesterdayValue(estimate) - estimate.cost;

double _yesterdayActualReturn(FundHoldingEstimate estimate) {
  final previousNav = estimate.realtimeEstimate.previousTradingNav;
  if (previousNav == null) return 0;
  return (estimate.realtimeEstimate.prevNav - previousNav) *
      estimate.input.shares;
}

double _todayEstimatedReturn(FundHoldingEstimate estimate) =>
    (estimate.realtimeEstimate.estNav - estimate.realtimeEstimate.prevNav) *
    estimate.input.shares;

double _returnRate(double totalReturn, double cost) {
  if (cost == 0) return 0;
  return totalReturn / cost;
}

Color _returnColor(double value) =>
    value >= 0 ? Colors.red.shade700 : Colors.green.shade700;

Color _signedColor(double value, ColorScheme colorScheme) {
  if (value == 0) return colorScheme.onSurfaceVariant;
  return _returnColor(value);
}

Color _estimateAccent(ColorScheme colorScheme) => colorScheme.tertiary;

Color _tintSurface(Color tint, Color surface, int alpha) =>
    Color.alphaBlend(tint.withAlpha(alpha), surface);

// ─────────────────────────────────────────────────────────────────────────────
// Channel accent palette — assigned by visible group order.
// ─────────────────────────────────────────────────────────────────────────────

const _channelAccents = [
  Color(0xFF2563EB), // Blue
  Color(0xFF0F766E), // Teal
  Color(0xFF7C3AED), // Violet
  Color(0xFFB45309), // Amber
  Color(0xFF0369A1), // Sky
  Color(0xFFBE123C), // Rose
  Color(0xFF15803D), // Green
  Color(0xFFC2410C), // Orange
  Color(0xFF6D28D9), // Purple
  Color(0xFF0E7490), // Cyan
  Color(0xFF9D174D), // Pink
  Color(0xFF4F46E5), // Indigo
  Color(0xFF047857), // Emerald
  Color(0xFFA21CAF), // Fuchsia
  Color(0xFF4338CA), // Deep indigo
  Color(0xFF92400E), // Ochre
  Color(0xFF1D4ED8), // Royal blue
  Color(0xFF047481), // Deep cyan
  Color(0xFFB91C1C), // Red
  Color(0xFF166534), // Forest
];

Color _channelAccent(int index) =>
    _channelAccents[index % _channelAccents.length];
