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
      expect(find.text('易方达裕丰回报债券A (000171)'), findsNWidgets(2));
      expect(find.textContaining('买入日'), findsNWidgets(2));
      expect(find.text('+100.00'), findsOneWidget);
      expect(find.text('+25.00'), findsOneWidget);
      expect(find.text('总收益 +5.00%'), findsOneWidget);
      expect(find.text('总收益 +2.44%'), findsOneWidget);
      expect(find.text('2.1000'), findsNWidgets(2));
      expect(find.text('2100.00'), findsOneWidget);
      expect(find.text('渠道收益'), findsOneWidget);
      expect(find.textContaining('+125.00'), findsOneWidget);
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
    expect(find.text('易方达裕丰回报债券A (000171)'), findsOneWidget);
    expect(find.text('+100.00'), findsOneWidget);
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
  final requestedCodes = <String>[];

  @override
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) async {
    requestedCodes.add(code);
    return RealtimeEstimate(
      code: code,
      name: '易方达裕丰回报债券A',
      prevNavDate: '2026-06-01',
      prevNav: 2.08,
      estNav: 2.1,
      estChangePct: 0.49,
      estTime: '2026-06-02 11:30',
    );
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
    );
    _holdings.add(holding);
    return holding;
  }

  @override
  Future<void> softDeleteHolding(int id) async {
    deletedIds.add(id);
    _holdings.removeWhere((holding) => holding.id == id);
  }
}
