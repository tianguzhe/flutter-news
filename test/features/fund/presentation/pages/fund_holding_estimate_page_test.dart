import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/fund/data/models/realtime_estimate.dart';
import 'package:untitled/features/fund/data/repositories/fund_estimate_repository.dart';
import 'package:untitled/features/fund/data/repositories/fund_estimate_repository_provider.dart';
import 'package:untitled/features/fund/data/repositories/fund_holding_repository.dart';
import 'package:untitled/features/fund/data/repositories/fund_holding_repository_provider.dart';
import 'package:untitled/features/fund/domain/fund_holding_estimate.dart';
import 'package:untitled/features/fund/presentation/pages/fund_holding_estimate_page.dart';

void main() {
  testWidgets(
    'groups holdings by channel while keeping different purchase dates separate',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final holdingRepository = _FakeFundHoldingRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fundEstimateRepositoryProvider.overrideWithValue(
              _FakeFundEstimateRepository(),
            ),
            fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
          ],
          child: const MaterialApp(home: FundHoldingEstimatePage()),
        ),
      );

      await _addHolding(
        tester,
        code: '000171',
        shares: '1000',
        channel: '支付宝',
        purchaseNav: '2',
        purchaseDayText: '1',
      );
      await _addHolding(
        tester,
        code: '000171',
        shares: '500',
        channel: '支付宝',
        purchaseNav: '2.05',
        purchaseDayText: '2',
      );

      expect(find.text('支付宝'), findsOneWidget);
      expect(find.text('2 笔'), findsOneWidget);
      expect(find.text('组合概览'), findsOneWidget);
      expect(find.text('易方达裕丰回报债券A (000171)'), findsNWidgets(2));
      expect(find.textContaining('买入日'), findsNWidgets(2));
      expect(find.text('-10.00'), findsAtLeastNWidgets(1));
      expect(find.text('-5.00'), findsAtLeastNWidgets(1));
      expect(find.text('昨日资产变动'), findsAtLeastNWidgets(1));
      expect(find.text('今日预估收益'), findsAtLeastNWidgets(1));
      expect(find.text('累计到昨日收益'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+4.00%'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+1.46%'), findsAtLeastNWidgets(1));
      expect(find.text('+20.00'), findsAtLeastNWidgets(1));
      expect(find.text('+10.00'), findsAtLeastNWidgets(1));
      expect(find.text('2.1000'), findsNWidgets(2));
      expect(find.text('2100.00'), findsOneWidget);
      expect(find.text('-15.00'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+95.00'), findsAtLeastNWidgets(1));
      expect(await holdingRepository.listActiveHoldings(), hasLength(2));
    },
  );

  testWidgets('loads persisted holdings and refreshes estimates on startup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final holdingRepository = _FakeFundHoldingRepository(
      initialHoldings: [
        FundHoldingInput(
          id: 1,
          code: '000171',
          purchaseDate: DateTime(2026, 1, 1),
          shares: 1000,
          channel: '天天基金',
          purchaseNav: 2,
          fee: 0,
        ),
      ],
    );
    final estimateRepository = _FakeFundEstimateRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundEstimateRepositoryProvider.overrideWithValue(estimateRepository),
          fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
        ],
        child: const MaterialApp(home: FundHoldingEstimatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('天天基金'), findsOneWidget);
    expect(find.text('组合概览'), findsOneWidget);
    expect(find.text('易方达裕丰回报债券A (000171)'), findsOneWidget);
    expect(find.text('-10.00'), findsAtLeastNWidgets(1));
    expect(find.text('+80.00'), findsAtLeastNWidgets(1));
    expect(find.text('+20.00'), findsAtLeastNWidgets(1));
    expect(estimateRepository.requestedCodes, ['000171']);
  });

  testWidgets('soft deletes persisted holdings from the page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final holdingRepository = _FakeFundHoldingRepository(
      initialHoldings: [
        FundHoldingInput(
          id: 1,
          code: '000171',
          purchaseDate: DateTime(2026, 1, 1),
          shares: 1000,
          channel: '银行',
          purchaseNav: 2,
          fee: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundEstimateRepositoryProvider.overrideWithValue(
            _FakeFundEstimateRepository(),
          ),
          fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
        ],
        child: const MaterialApp(home: FundHoldingEstimatePage()),
      ),
    );
    await tester.pumpAndSettle();

    final deleteButton = find.byIcon(Icons.delete_outline);
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('银行'), findsNothing);
    expect(await holdingRepository.listActiveHoldings(), isEmpty);
    expect(holdingRepository.deletedIds, [1]);
  });

  testWidgets('edits a persisted holding and refreshes its estimate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final holdingRepository = _FakeFundHoldingRepository(
      initialHoldings: [
        FundHoldingInput(
          id: 1,
          code: '000171',
          purchaseDate: DateTime(2026, 1, 1),
          shares: 1000,
          channel: '银行',
          purchaseNav: 2,
          fee: 0,
        ),
      ],
    );
    final estimateRepository = _FakeFundEstimateRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundEstimateRepositoryProvider.overrideWithValue(estimateRepository),
          fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
        ],
        child: const MaterialApp(home: FundHoldingEstimatePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('编辑持仓'));
    await tester.pumpAndSettle();

    expect(find.text('编辑持仓'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '000171'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '1000'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '银行'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '0'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '份额'), '1500');
    await tester.enterText(find.widgetWithText(TextFormField, '渠道'), '天天基金');
    await tester.enterText(find.widgetWithText(TextFormField, '购买时净值'), '1.5');
    await tester.enterText(find.widgetWithText(TextFormField, '手续费'), '10');
    await tester.tap(find.text('保存并计算'));
    await tester.pump();
    await tester.pumpAndSettle();

    final holdings = await holdingRepository.listActiveHoldings();
    expect(holdings, hasLength(1));
    expect(holdings.single.id, 1);
    expect(holdings.single.shares, 1500);
    expect(holdings.single.channel, '天天基金');
    expect(holdings.single.purchaseNav, 1.5);
    expect(holdings.single.fee, 10);
    expect(find.text('银行'), findsNothing);
    expect(find.text('天天基金'), findsOneWidget);
    expect(find.text('-15.00'), findsAtLeastNWidgets(1));
    expect(find.text('+860.00'), findsAtLeastNWidgets(1));
    expect(find.text('+30.00'), findsAtLeastNWidgets(1));
    expect(estimateRepository.requestedCodes, ['000171', '000171']);
  });

  testWidgets('renders metrics without flex overflow on a narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final holdingRepository = _FakeFundHoldingRepository(
      initialHoldings: [
        FundHoldingInput(
          id: 1,
          code: '000171',
          purchaseDate: DateTime(2026, 1, 1),
          shares: 1000,
          channel: '银行',
          purchaseNav: 2,
          fee: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundEstimateRepositoryProvider.overrideWithValue(
            _FakeFundEstimateRepository(),
          ),
          fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
        ],
        child: const MaterialApp(home: FundHoldingEstimatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('组合概览'), findsOneWidget);
    expect(find.text('今日估算净值'), findsOneWidget);
  });

  testWidgets('shows previous trading day movement as yesterday return', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final holdingRepository = _FakeFundHoldingRepository(
      initialHoldings: [
        FundHoldingInput(
          id: 1,
          code: '000385',
          purchaseDate: DateTime(2026, 5, 18),
          shares: 48263.58,
          channel: '天天基金',
          purchaseNav: 1.895,
          fee: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundEstimateRepositoryProvider.overrideWithValue(
            _FakeFundEstimateRepository(
              estimate: const RealtimeEstimate(
                code: '000385',
                name: '景顺长城景颐双利债券A',
                prevNavDate: '2026-06-01',
                prevNav: 1.895,
                estNav: 1.895,
                estChangePct: 0,
                estTime: '2026-06-02 15:00',
                previousTradingNavDate: '2026-05-29',
                previousTradingNav: 1.898,
              ),
            ),
          ),
          fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
        ],
        child: const MaterialApp(home: FundHoldingEstimatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('-144.79'), findsAtLeastNWidgets(1));
    expect(find.text('累计到昨日收益'), findsAtLeastNWidgets(1));
    expect(find.text('0.00'), findsAtLeastNWidgets(1));
    expect(find.text('上一交易日净值'), findsOneWidget);
    expect(find.text('1.8980'), findsOneWidget);
  });
}

Future<void> _addHolding(
  WidgetTester tester, {
  required String code,
  required String shares,
  required String channel,
  required String purchaseNav,
  required String purchaseDayText,
}) async {
  await tester.tap(find.byTooltip('新增持仓'));
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextFormField, '基金代码'), code);
  await tester.enterText(find.widgetWithText(TextFormField, '份额'), shares);
  await tester.enterText(find.widgetWithText(TextFormField, '渠道'), channel);
  await tester.enterText(
    find.widgetWithText(TextFormField, '购买时净值'),
    purchaseNav,
  );
  await tester.enterText(find.widgetWithText(TextFormField, '手续费'), '0');

  await tester.tap(find.text('选择购买时间'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(purchaseDayText).first);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('添加并计算'));
  await tester.pump();
  await tester.pumpAndSettle();
}

final class _FakeFundEstimateRepository implements FundEstimateRepository {
  _FakeFundEstimateRepository({RealtimeEstimate? estimate})
    : _estimate =
          estimate ??
          const RealtimeEstimate(
            code: '000171',
            name: '易方达裕丰回报债券A',
            prevNavDate: '2026-06-01',
            prevNav: 2.08,
            estNav: 2.1,
            estChangePct: 0.49,
            estTime: '2026-06-02 11:30',
            previousTradingNavDate: '2026-05-29',
            previousTradingNav: 2.09,
          );

  final requestedCodes = <String>[];
  final RealtimeEstimate _estimate;

  @override
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) async {
    requestedCodes.add(code);
    return _estimate;
  }
}

final class _FakeFundHoldingRepository implements FundHoldingRepository {
  _FakeFundHoldingRepository({
    List<FundHoldingInput> initialHoldings = const [],
  }) : _holdings = [...initialHoldings],
       _nextId = initialHoldings.isEmpty
           ? 1
           : initialHoldings
                     .map((holding) => holding.id)
                     .reduce((a, b) => a > b ? a : b) +
                 1;

  final List<FundHoldingInput> _holdings;
  final deletedIds = <int>[];
  int _nextId;

  @override
  Future<List<FundHoldingInput>> listActiveHoldings() async {
    return [..._holdings];
  }

  @override
  Future<FundHoldingInput> insertHolding(FundHoldingDraft draft) async {
    final holding = FundHoldingInput(
      id: _nextId++,
      code: draft.code,
      purchaseDate: draft.purchaseDate,
      shares: draft.shares,
      channel: draft.channel,
      purchaseNav: draft.purchaseNav,
      fee: draft.fee,
    );
    _holdings.add(holding);
    return holding;
  }

  @override
  Future<FundHoldingInput> updateHolding({
    required int id,
    required FundHoldingDraft draft,
  }) async {
    final index = _holdings.indexWhere((holding) => holding.id == id);
    if (index == -1) {
      throw StateError('Holding $id not found');
    }
    final holding = FundHoldingInput(
      id: id,
      code: draft.code,
      purchaseDate: draft.purchaseDate,
      shares: draft.shares,
      channel: draft.channel,
      purchaseNav: draft.purchaseNav,
      fee: draft.fee,
    );
    _holdings[index] = holding;
    return holding;
  }

  @override
  Future<void> softDeleteHolding(int id) async {
    deletedIds.add(id);
    _holdings.removeWhere((holding) => holding.id == id);
  }
}
