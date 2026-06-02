import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fund_estimate_repository_provider.dart';
import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';

const _cardRadius = 16.0;
const _innerRadius = 10.0;

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
      await Future.wait(holdings.map(_refreshHolding));
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
    setState(() {
      _holdings.add(input);
      _holdingStates[input.id] = const AsyncLoading();
    });
    await _refreshHolding(input);
  }

  Future<void> _openEditHoldingPage(FundHoldingInput holding) async {
    final updated = await Navigator.of(context).push<FundHoldingInput>(
      MaterialPageRoute(
        builder: (_) => FundHoldingEntryPage(initialHolding: holding),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      final index = _holdings.indexWhere((item) => item.id == updated.id);
      if (index == -1) {
        _holdings.add(updated);
      } else {
        _holdings[index] = updated;
      }
      _holdingStates[updated.id] = const AsyncLoading();
    });
    await _refreshHolding(updated);
  }

  Future<void> _refreshHolding(FundHoldingInput input) async {
    setState(() => _holdingStates[input.id] = const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      final realtimeEstimate = await ref
          .read(fundEstimateRepositoryProvider)
          .fetchRealtimeEstimate(input.code);
      return calculateFundHoldingEstimate(
        input: input,
        realtimeEstimate: realtimeEstimate,
      );
    });
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: '新增持仓',
        onPressed: _openAddHoldingPage,
        icon: const Icon(Icons.add),
        label: const Text('新增持仓'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            if (_holdings.isNotEmpty) ...[
              _PortfolioOverview(holdings: _holdings, estimates: estimates),
              const SizedBox(height: 16),
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

    // Gradient changes with market sentiment (中国习惯：红涨绿跌)
    final List<Color> gradientColors;
    if (!hasEstimate) {
      gradientColors = [const Color(0xFF1A237E), const Color(0xFF3949AB)];
    } else if (yesterdayActualReturn >= 0) {
      gradientColors = [const Color(0xFFB71C1C), const Color(0xFFE53935)];
    } else {
      gradientColors = [const Color(0xFF1B5E20), const Color(0xFF388E3C)];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(36),
                    borderRadius: BorderRadius.circular(_innerRadius),
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '组合概览',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        '${holdings.length} 笔持仓 · $channels 个渠道',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasEstimate)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '昨日确认',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Main return figures
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasEstimate ? '昨日资产变动' : '正在拉取估值',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: Colors.white.withAlpha(180)),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasEstimate
                              ? _formatSignedMoney(yesterdayActualReturn)
                              : '估算中...',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                        ),
                      ),
                      if (hasEstimate) ...[
                        const SizedBox(height: 4),
                        Text(
                          '昨日变动率 ${_formatPercent(yesterdayRate)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withAlpha(200),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasEstimate) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(28),
                      borderRadius: BorderRadius.circular(_innerRadius),
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '今日预估',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSignedMoney(todayEstimate),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Bottom stats — 2×2 grid, more breathing room per cell
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(_innerRadius),
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _HeroStat(
                        label: '今日估算市值',
                        value: hasEstimate ? _formatMoney(estimatedValue) : '--',
                      ),
                      _HeroStatDivider(),
                      _HeroStat(
                        label: '持仓成本',
                        value: hasEstimate ? _formatMoney(totalCost) : '--',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.white.withAlpha(25)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeroStat(
                        label: '累计到昨日收益',
                        value: hasEstimate
                            ? _formatSignedMoney(confirmedTotalReturn)
                            : '--',
                      ),
                      _HeroStatDivider(),
                      _HeroStat(
                        label: '持仓渠道',
                        value: '$channels 个',
                      ),
                    ],
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withAlpha(160),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withAlpha(50),
    );
  }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: grouped.entries.map((entry) {
        final channelHoldings = entry.value
          ..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ChannelGroupCard(
            channel: entry.key,
            holdings: channelHoldings,
            states: states,
            onRefresh: onRefresh,
            onEdit: onEdit,
            onRemove: onRemove,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Channel group card
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelGroupCard extends StatelessWidget {
  const _ChannelGroupCard({
    required this.channel,
    required this.holdings,
    required this.states,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final String channel;
  final List<FundHoldingInput> holdings;
  final Map<int, AsyncValue<FundHoldingEstimate>> states;
  final ValueChanged<FundHoldingInput> onRefresh;
  final ValueChanged<FundHoldingInput> onEdit;
  final ValueChanged<FundHoldingInput> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _mochaAccent(channel);
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
        ? _returnColor(yesterdayActualReturn)
        : cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: accent.withAlpha(90), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(36),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top accent strip — clearest channel identity signal
          Container(height: 5, color: accent),
          // Header — gradient overlay (accent left → transparent right)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [accent.withAlpha(55), accent.withAlpha(10)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                // Icon badge using accent colour
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(36),
                    borderRadius: BorderRadius.circular(_innerRadius),
                    border: Border.all(color: accent.withAlpha(80), width: 1.5),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 22,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(22),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: accent.withAlpha(55)),
                            ),
                            child: Text(
                              '${holdings.length} 笔持仓',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasEstimate) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatSignedMoney(yesterdayActualReturn),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: returnColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '昨日变动',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Accent divider before holdings list
          Container(
            height: 1,
            color: accent.withAlpha(60),
            margin: const EdgeInsets.only(bottom: 2),
          ),
          // Holdings list
          Padding(
            padding: const EdgeInsets.all(10),
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
                  if (i < holdings.length - 1) const SizedBox(height: 8),
                ],
              ],
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
      loading: () => cs.outline,
      error: (_, __) => cs.error,
      data: (e) => _returnColor(_yesterdayActualReturn(e)),
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_innerRadius),
        border: Border.all(color: cs.outlineVariant.withAlpha(100)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(context),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: ColoredBox(color: accentColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: state.when(
                  loading: () => Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          holding.code,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '拉取中...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          holding.code,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.error_outline, size: 16, color: cs.error),
                      const SizedBox(width: 4),
                      Text(
                        '拉取失败',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.error,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: cs.outlineVariant,
                      ),
                    ],
                  ),
                  data: (estimate) {
                    final realtime = estimate.realtimeEstimate;
                    final yReturn = _yesterdayActualReturn(estimate);
                    final yRate = _returnRate(yReturn, estimate.cost);
                    final returnColor = _returnColor(yReturn);
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      realtime.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      realtime.code,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    '买入 ${_formatDate(estimate.input.purchaseDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                  ),
                                  if (realtime.estChangePct != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _returnColor(
                                          realtime.estChangePct!,
                                        ).withAlpha(18),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '今日 ${_formatSignedPercent(realtime.estChangePct!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: _returnColor(
                                                realtime.estChangePct!,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatSignedMoney(yReturn),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: returnColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              _formatPercent(yRate),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: returnColor),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: cs.outlineVariant,
                        ),
                      ],
                    );
                  },
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
    final yesterdayActualReturn = _yesterdayActualReturn(estimate);
    final yesterdayActualRate = _returnRate(yesterdayActualReturn, estimate.cost);
    final confirmedTotalReturn = _confirmedTotalReturn(estimate);
    final confirmedTotalRate = _returnRate(confirmedTotalReturn, estimate.cost);
    final todayEstimate = _todayEstimatedReturn(estimate);
    final color = _returnColor(yesterdayActualReturn);
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
        const SizedBox(height: 10),
        _ReturnBanner(
          totalReturn: yesterdayActualReturn,
          totalReturnRate: yesterdayActualRate,
          todayEstimate: todayEstimate,
          color: color,
        ),
        const SizedBox(height: 10),
        _MetricGrid(
          items: [
            _MetricItem('今日估算净值', _formatNumber(realtime.estNav, 4)),
            _MetricItem('估算市值', _formatMoney(estimate.estimatedValue)),
            _MetricItem('持仓成本', _formatMoney(estimate.cost)),
            _MetricItem('昨日变动率', _formatPercent(yesterdayActualRate)),
            _MetricItem('累计到昨日收益', _formatSignedMoney(confirmedTotalReturn)),
            _MetricItem('累计收益率', _formatPercent(confirmedTotalRate)),
            _MetricItem('今日预估收益', _formatSignedMoney(todayEstimate)),
            _MetricItem('涨跌幅', _formatSignedPercent(realtime.estChangePct)),
            _MetricItem('购买净值', _formatNumber(estimate.input.purchaseNav, 4)),
            _MetricItem('持有份额', _formatNumber(estimate.input.shares, 2)),
            _MetricItem('手续费', _formatMoney(estimate.input.fee)),
            _MetricItem('昨日净值', _formatNumber(realtime.prevNav, 4)),
          ],
        ),
        const SizedBox(height: 10),
        _EstimateMetaRow(
          items: [
            _EstimateMetaItem(
              icon: Icons.schedule,
              label: '估值时间',
              value: realtime.estTime,
            ),
            _EstimateMetaItem(
              icon: Icons.history,
              label: '昨日净值',
              value: _formatNumber(realtime.prevNav, 4),
              helper: realtime.prevNavDate,
            ),
            if (realtime.previousTradingNav != null)
              _EstimateMetaItem(
                icon: Icons.trending_flat,
                label: '上一交易日',
                value: _formatNumber(realtime.previousTradingNav!, 4),
                helper: realtime.previousTradingNavDate,
              ),
          ],
        ),
      ],
    );
  }
}

class _ReturnBanner extends StatelessWidget {
  const _ReturnBanner({
    required this.totalReturn,
    required this.totalReturnRate,
    required this.todayEstimate,
    required this.color,
  });

  final double totalReturn;
  final double totalReturnRate;
  final double todayEstimate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(_innerRadius),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '昨日资产变动',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatSignedMoney(totalReturn),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _formatPercent(totalReturnRate),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: color.withAlpha(50),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日预估收益',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatSignedMoney(todayEstimate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _signedColor(todayEstimate, cs),
                        fontWeight: FontWeight.w900,
                      ),
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
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
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
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (changePct != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _returnColor(changePct!).withAlpha(18),
                        border: Border.all(
                          color: _returnColor(changePct!).withAlpha(70),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '今日 ${_formatSignedPercent(changePct!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _returnColor(changePct!),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
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
        const spacing = 6.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: tileWidth, child: _MetricTile(item: item)),
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
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(160),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estimate meta row
// ─────────────────────────────────────────────────────────────────────────────

class _EstimateMetaRow extends StatelessWidget {
  const _EstimateMetaRow({required this.items});

  final List<_EstimateMetaItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 480;
        final children = items
            .map((item) => _EstimateMetaTile(item: item))
            .toList();

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 6),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) const SizedBox(width: 6),
            ],
          ],
        );
      },
    );
  }
}

class _EstimateMetaTile extends StatelessWidget {
  const _EstimateMetaTile({required this.item});

  final _EstimateMetaItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.helper != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.helper!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
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

class _EstimateMetaItem {
  const _EstimateMetaItem({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '买入 ${_formatDate(holding.purchaseDate)} · 正在拉取估值',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value);

  final String label;
  final String value;
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
                          color:
                              purchaseDate != null ? cs.primary : cs.outline,
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

// ─────────────────────────────────────────────────────────────────────────────
// Catppuccin Mocha accent palette — one colour per channel (hash-assigned)
// ─────────────────────────────────────────────────────────────────────────────

const _mochaAccents = [
  Color(0xFFcba6f7), // Mauve
  Color(0xFF89b4fa), // Blue
  Color(0xFF94e2d5), // Teal
  Color(0xFFa6e3a1), // Green
  Color(0xFFfab387), // Peach
  Color(0xFFf9e2af), // Yellow
  Color(0xFF89dceb), // Sky
  Color(0xFF74c7ec), // Sapphire
  Color(0xFFf5c2e7), // Pink
  Color(0xFFeba0ac), // Maroon
  Color(0xFFf38ba8), // Red
  Color(0xFFf5e0dc), // Rosewater
];

Color _mochaAccent(String channel) {
  var hash = 0;
  for (final c in channel.codeUnits) {
    hash = (hash * 31 + c) & 0x7fffffff;
  }
  return _mochaAccents[hash % _mochaAccents.length];
}