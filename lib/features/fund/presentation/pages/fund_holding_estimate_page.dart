import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fund_estimate_repository_provider.dart';
import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';

const _cardRadius = 8.0;
const _quietBorderAlpha = 150;

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

class _PortfolioOverview extends StatelessWidget {
  const _PortfolioOverview({required this.holdings, required this.estimates});

  final List<FundHoldingInput> holdings;
  final List<FundHoldingEstimate> estimates;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final channels = holdings.map((h) => h.channel).toSet().length;
    final totalCost = estimates.fold<double>(0, (s, e) => s + e.cost);
    final totalValue = estimates.fold<double>(
      0,
      (s, e) => s + e.estimatedValue,
    );
    final totalReturn = totalValue - totalCost;
    final totalRate = totalCost == 0 ? 0.0 : totalReturn / totalCost;
    final hasEstimate = estimates.isNotEmpty;
    final returnColor = hasEstimate ? _returnColor(totalReturn) : cs.primary;
    final todayFloat = hasEstimate
        ? estimates.fold<double>(
            0,
            (s, e) =>
                s +
                (e.realtimeEstimate.estNav - e.realtimeEstimate.prevNav) *
                    e.input.shares,
          )
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(
          color: cs.outlineVariant.withAlpha(_quietBorderAlpha),
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(icon: Icons.pie_chart_outline, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '组合概览',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${holdings.length} 笔持仓 · $channels 个渠道',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasEstimate)
                  _TrendPill(
                    label: _formatPercent(totalRate),
                    color: returnColor,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _AmountPanel(
              label: hasEstimate ? '持仓总收益' : '正在拉取盘中估值',
              value: hasEstimate ? _formatSignedMoney(totalReturn) : '估算中...',
              color: returnColor,
              trailing: hasEstimate
                  ? _formatSignedMoney(todayFloat)
                  : '${holdings.length} 笔',
              trailingLabel: hasEstimate ? '今日浮动' : '持仓数量',
            ),
            const SizedBox(height: 12),
            _SummaryMetricGrid(
              items: [
                _MetricItem(
                  '估算总市值',
                  hasEstimate ? _formatMoney(totalValue) : '--',
                ),
                _MetricItem(
                  '持仓成本',
                  hasEstimate ? _formatMoney(totalCost) : '--',
                ),
                _MetricItem('持仓渠道', '$channels 个'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({
    required this.label,
    required this.value,
    required this.color,
    required this.trailing,
    required this.trailingLabel,
  });

  final String label;
  final String value;
  final Color color;
  final String trailing;
  final String trailingLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        border: Border.all(color: color.withAlpha(55)),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailingLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        border: Border.all(color: color.withAlpha(70)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryMetricGrid extends StatelessWidget {
  const _SummaryMetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 1;
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
                child: _SummaryMetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

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
    _purchaseDate = holding.purchaseDate;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _sharesController.dispose();
    _channelController.dispose();
    _purchaseNavController.dispose();
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
        border: Border.all(
          color: cs.outlineVariant.withAlpha(_quietBorderAlpha),
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(
                  icon: isEditing ? Icons.edit_note : Icons.add_chart,
                  color: cs.primary,
                ),
                const SizedBox(width: 10),
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
                      border: const OutlineInputBorder(),
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
                    borderRadius: BorderRadius.circular(_cardRadius),
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
                        borderRadius: BorderRadius.circular(_cardRadius),
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
                      border: const OutlineInputBorder(),
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
                      border: const OutlineInputBorder(),
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
                      border: const OutlineInputBorder(),
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
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_cardRadius),
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
    final estimates = holdings
        .map((h) => states[h.id])
        .whereType<AsyncData<FundHoldingEstimate>>()
        .map((s) => s.value)
        .toList();
    final totalCost = estimates.fold<double>(0, (s, e) => s + e.cost);
    final totalValue = estimates.fold<double>(
      0,
      (s, e) => s + e.estimatedValue,
    );
    final totalReturn = totalValue - totalCost;
    final totalRate = totalCost == 0 ? 0.0 : totalReturn / totalCost;
    final hasEstimate = estimates.isNotEmpty;
    final returnColor = hasEstimate ? _returnColor(totalReturn) : cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(
          color: cs.outlineVariant.withAlpha(_quietBorderAlpha),
        ),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(
                  icon: Icons.account_balance_wallet_outlined,
                  color: cs.primary,
                ),
                const SizedBox(width: 10),
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
                      Text(
                        '${holdings.length} 笔',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasEstimate)
                  _TrendPill(
                    label: _formatPercent(totalRate),
                    color: returnColor,
                  )
                else
                  _CountPill(label: '${holdings.length} 笔'),
              ],
            ),
          ),
          if (hasEstimate) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _SummaryMetricGrid(
                items: [
                  _MetricItem('总市值', _formatMoney(totalValue)),
                  _MetricItem('持仓成本', _formatMoney(totalCost)),
                  _MetricItem('渠道收益', _formatSignedMoney(totalReturn)),
                ],
              ),
            ),
          ],
          Container(height: 1, color: cs.outlineVariant.withAlpha(120)),
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
                  if (i < holdings.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = state.when(
      loading: () => cs.outline,
      error: (_, _) => cs.error,
      data: (e) => _returnColor(e.totalReturn),
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant.withAlpha(115)),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: accentColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: state.when(
              loading: () => _HoldingLoading(holding: holding),
              error: (error, _) => _HoldingError(
                holding: holding,
                message: error.toString(),
                onRefresh: onRefresh,
                onEdit: onEdit,
                onRemove: onRemove,
              ),
              data: (estimate) => _HoldingEstimateResult(
                estimate: estimate,
                onRefresh: onRefresh,
                onEdit: onEdit,
                onRemove: onRemove,
              ),
            ),
          ),
        ],
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
    final color = _returnColor(estimate.totalReturn);
    final realtime = estimate.realtimeEstimate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HoldingHeader(
          title: '${realtime.name} (${realtime.code})',
          subtitle: '买入日 ${_formatDate(estimate.input.purchaseDate)}',
          changePct: realtime.estChangePct,
          onRefresh: onRefresh,
          onEdit: onEdit,
          onRemove: onRemove,
        ),
        const SizedBox(height: 12),
        _ReturnBanner(
          totalReturn: estimate.totalReturn,
          totalReturnRate: estimate.totalReturnRate,
          color: color,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          items: [
            _MetricItem('今日估算净值', _formatNumber(realtime.estNav, 4)),
            _MetricItem('估值涨跌幅', _formatSignedPercent(realtime.estChangePct)),
            _MetricItem('估算市值', _formatMoney(estimate.estimatedValue)),
            _MetricItem('持仓成本', _formatMoney(estimate.cost)),
            _MetricItem('购买净值', _formatNumber(estimate.input.purchaseNav, 4)),
            _MetricItem('持有份额', _formatNumber(estimate.input.shares, 2)),
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
    required this.color,
  });

  final double totalReturn;
  final double totalReturnRate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总收益',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatSignedMoney(totalReturn),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _TrendPill(label: _formatPercent(totalReturnRate), color: color),
          ],
        ),
      ),
    );
  }
}

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
                if (i < children.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) const SizedBox(width: 8),
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
        color: cs.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.helper != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.helper!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
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

class _HoldingLoading extends StatelessWidget {
  const _HoldingLoading({required this.holding});
  final FundHoldingInput holding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
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
                '买入日 ${_formatDate(holding.purchaseDate)} · 正在拉取估值',
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
          subtitle: '买入日 ${_formatDate(holding.purchaseDate)}',
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

class _HoldingHeader extends StatelessWidget {
  const _HoldingHeader({
    required this.title,
    required this.subtitle,
    required this.changePct,
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
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
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
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
                    _TrendPill(
                      label: '今日 ${_formatSignedPercent(changePct!)}',
                      color: _returnColor(changePct!),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
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
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: icon,
        color: color,
        iconSize: 19,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
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
        border: Border.all(
          color: cs.outlineVariant.withAlpha(_quietBorderAlpha),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            _IconBadge(icon: icon, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

Color _returnColor(double value) =>
    value >= 0 ? Colors.red.shade700 : Colors.green.shade700;
