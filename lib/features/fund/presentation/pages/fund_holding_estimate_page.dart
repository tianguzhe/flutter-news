import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/realtime_estimate.dart';
import '../../data/repositories/fund_estimate_repository_provider.dart';
import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';
import '../utils/fund_holding_json_codec.dart';
import '../widgets/fund_holding_portfolio_overview.dart';
import '../widgets/fund_holdings_by_channel_section.dart';
import 'fund_holding_entry_page.dart';

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
  // code -> in-flight or completed Future; same-code holdings share one request.
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
      for (final h in _holdings.where((h) => h.code == updated.code)) {
        _holdingStates[h.id] = const AsyncLoading();
      }
    });
    await Future.wait(
      _holdings.where((h) => h.code == updated.code).map(_computeEstimate),
    );
  }

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

    final repository = ref.read(fundHoldingRepositoryProvider);
    final result = await importFundHoldingsFromJson(
      jsonText,
      insertHolding: (draft) async {
        await repository.insertHolding(draft);
      },
    );
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
    final controller = TextEditingController(
      text: encodeFundHoldingsJson(_holdings),
    );
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

  Future<void> _handleDataMenuAction(_HoldingDataAction action) async {
    switch (action) {
      case _HoldingDataAction.importJson:
        await _openImportJsonDialog();
      case _HoldingDataAction.exportJson:
        await _openExportJsonDialog();
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
              tintFundHoldingSurface(cs.primary, cs.surfaceContainerLowest, 10),
              cs.surfaceContainerLowest,
              tintFundHoldingSurface(cs.tertiary, cs.surfaceContainerLowest, 8),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: fundHoldingContentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_holdings.isNotEmpty) ...[
                        FundPortfolioOverview(
                          holdings: _holdings,
                          estimates: estimates,
                        ),
                        const SizedBox(height: 18),
                      ],
                      FundHoldingsByChannelSection(
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
