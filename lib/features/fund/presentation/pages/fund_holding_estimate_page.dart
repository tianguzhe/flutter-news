import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fund_estimate_repository_provider.dart';
import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';

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
      if (!mounted) {
        return;
      }

      setState(() {
        _holdings
          ..clear()
          ..addAll(holdings);
        _holdingStates
          ..clear()
          ..addEntries(
            holdings.map(
              (holding) => MapEntry(holding.id, const AsyncLoading()),
            ),
          );
        _loadHoldingsError = null;
        _isLoadingHoldings = false;
      });

      await Future.wait(holdings.map(_refreshHolding));
    } catch (error) {
      if (!mounted) {
        return;
      }
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
    if (input == null || !mounted) {
      return;
    }

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
    if (updated == null || !mounted) {
      return;
    }

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
    if (!mounted) {
      return;
    }
    setState(() {
      if (_holdings.any((holding) => holding.id == input.id)) {
        _holdingStates[input.id] = result;
      }
    });
  }

  Future<void> _removeHolding(FundHoldingInput input) async {
    try {
      await ref.read(fundHoldingRepositoryProvider).softDeleteHolding(input.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _holdings.removeWhere((holding) => holding.id == input.id);
        _holdingStates.remove(input.id);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除持仓失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimates = _holdings
        .map((holding) => _holdingStates[holding.id])
        .whereType<AsyncData<FundHoldingEstimate>>()
        .map((state) => state.value)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('基金收益估算'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '新增持仓',
            onPressed: _openAddHoldingPage,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (_holdings.isNotEmpty) ...[
              _PortfolioOverview(holdings: _holdings, estimates: estimates),
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
    );
  }
}

class _PortfolioOverview extends StatelessWidget {
  const _PortfolioOverview({required this.holdings, required this.estimates});

  final List<FundHoldingInput> holdings;
  final List<FundHoldingEstimate> estimates;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final channels = holdings.map((holding) => holding.channel).toSet().length;
    final totalCost = estimates.fold<double>(0, (sum, item) => sum + item.cost);
    final totalValue = estimates.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    final totalReturn = totalValue - totalCost;
    final hasEstimate = estimates.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.pie_chart,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _OverviewMetricGrid(
              items: [
                _OverviewMetricItem(
                  label: '估算总市值',
                  value: hasEstimate ? _formatMoney(totalValue) : '计算中',
                ),
                _OverviewMetricItem(
                  label: '持仓成本',
                  value: hasEstimate ? _formatMoney(totalCost) : '计算中',
                ),
                _OverviewMetricItem(
                  label: '总收益',
                  value: hasEstimate ? _formatSignedMoney(totalReturn) : '计算中',
                  valueColor: hasEstimate
                      ? _returnColor(totalReturn)
                      : colorScheme.onSurface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetricGrid extends StatelessWidget {
  const _OverviewMetricGrid({required this.items});

  final List<_OverviewMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 1;
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
                child: _OverviewMetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewMetricTile extends StatelessWidget {
  const _OverviewMetricTile({required this.item});

  final _OverviewMetricItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: item.valueColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetricItem {
  const _OverviewMetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
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
    if (holding == null) {
      return;
    }
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
    if (picked == null) {
      return;
    }
    setState(() => _purchaseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
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
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(input);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存持仓失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑持仓' : '新增持仓'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _InputSection(
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

class _InputSection extends StatelessWidget {
  const _InputSection({
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_note,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '持仓信息',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '按实际购买记录填写，保存后自动估算收益',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: '基金代码',
                  hintText: '例如 000171',
                  border: OutlineInputBorder(),
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
              OutlinedButton.icon(
                onPressed: onPickPurchaseDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  purchaseDate == null
                      ? '选择购买时间'
                      : '购买时间 ${_formatDate(purchaseDate!)}',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sharesController,
                decoration: const InputDecoration(
                  labelText: '份额',
                  hintText: '例如 1000.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_DecimalTextInputFormatter()],
                validator: (value) => _validatePositiveNumber(value, '请输入份额'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: channelController,
                decoration: const InputDecoration(
                  labelText: '渠道',
                  hintText: '例如 支付宝 / 天天基金 / 银行',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入渠道' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: purchaseNavController,
                decoration: const InputDecoration(
                  labelText: '购买时净值',
                  hintText: '例如 2.0820',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_DecimalTextInputFormatter()],
                validator: (value) =>
                    _validatePositiveNumber(value, '请输入购买时净值'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isEditing ? Icons.save_outlined : Icons.add),
                label: Text(isEditing ? '保存并计算' : '添加并计算'),
              ),
            ],
          ),
        ),
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
        message: '添加后会按渠道分组；同一基金不同购买时间会分别计算。',
      );
    }

    final grouped = <String, List<FundHoldingInput>>{};
    for (final holding in holdings) {
      grouped.putIfAbsent(holding.channel, () => []).add(holding);
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
    final estimates = holdings
        .map((holding) => states[holding.id])
        .whereType<AsyncData<FundHoldingEstimate>>()
        .map((state) => state.value)
        .toList();
    final totalCost = estimates.fold<double>(0, (sum, item) => sum + item.cost);
    final totalValue = estimates.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    final totalReturn = totalValue - totalCost;
    final totalRate = totalCost == 0 ? 0.0 : totalReturn / totalCost;

    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    channel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      '${holdings.length} 笔',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (estimates.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ChannelSummary(
                totalCost: totalCost,
                totalValue: totalValue,
                totalReturn: totalReturn,
                totalRate: totalRate,
              ),
            ],
            const SizedBox(height: 12),
            for (final holding in holdings) ...[
              _HoldingCard(
                holding: holding,
                state: states[holding.id] ?? const AsyncLoading(),
                onRefresh: () => onRefresh(holding),
                onEdit: () => onEdit(holding),
                onRemove: () => onRemove(holding),
              ),
              if (holding != holdings.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelSummary extends StatelessWidget {
  const _ChannelSummary({
    required this.totalCost,
    required this.totalValue,
    required this.totalReturn,
    required this.totalRate,
  });

  final double totalCost;
  final double totalValue;
  final double totalReturn;
  final double totalRate;

  @override
  Widget build(BuildContext context) {
    final color = _returnColor(totalReturn);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _SummaryText(
                label: '渠道总市值',
                value: _formatMoney(totalValue),
              ),
            ),
            Expanded(
              child: _SummaryText(
                label: '渠道成本',
                value: _formatMoney(totalCost),
              ),
            ),
            Expanded(
              child: _SummaryText(
                label: '渠道收益',
                value:
                    '${_formatSignedMoney(totalReturn)} / ${_formatPercent(totalRate)}',
                valueColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(72)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总收益',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatSignedMoney(totalReturn),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Text(
                  _formatPercent(totalReturnRate),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
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
              for (final child in children) ...[
                child,
                if (child != children.last) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last) const SizedBox(width: 8),
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 18, color: colorScheme.onSurfaceVariant),
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
                      color: colorScheme.onSurfaceVariant,
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
                        color: colorScheme.onSurfaceVariant,
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
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${holding.code} · ${_formatDate(holding.purchaseDate)} 正在估算',
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
    required this.onRefresh,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          tooltip: '刷新估值',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: onEdit,
          tooltip: '编辑持仓',
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: onRemove,
          tooltip: '删除持仓',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
  if (text.isEmpty) {
    return emptyMessage;
  }
  final number = double.tryParse(text);
  if (number == null || number <= 0) {
    return '请输入大于 0 的数字';
  }
  return null;
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatMoney(double value) {
  return value.toStringAsFixed(2);
}

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

String _formatNumber(double value, int fractionDigits) {
  return value.toStringAsFixed(fractionDigits);
}

String _formatEditableNumber(double value) {
  return value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
}

Color _returnColor(double value) {
  return value >= 0 ? Colors.red.shade700 : Colors.green.shade700;
}
