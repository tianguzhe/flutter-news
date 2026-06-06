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
import 'package:untitled/features/fund/presentation/widgets/fund_holding_portfolio_overview.dart';
import 'package:untitled/core/widgets/num_text.dart';

void main() {
  testWidgets(
    'groups channel holdings by fund and shows purchase lots in detail',
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
      expect(find.textContaining('2 笔'), findsAtLeastNWidgets(1));
      expect(find.text('组合概览'), findsOneWidget);
      expect(find.text('易方达裕丰回报债券A'), findsOneWidget);
      expect(find.text('000171'), findsOneWidget);
      expect(find.textContaining('份额 1500.00'), findsOneWidget);
      expect(find.textContaining('成本 3025.00'), findsAtLeastNWidgets(1));
      expect(find.text('今日估值'), findsAtLeastNWidgets(1));
      expect(find.text('昨日收益'), findsAtLeastNWidgets(1));
      expect(find.textContaining('2026-06-01 净值基准'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+30.00'), findsAtLeastNWidgets(1));
      expect(find.text('-15.00'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+125.00'), findsAtLeastNWidgets(1));

      await _openFirstHoldingDetail(tester);

      expect(find.text('分笔明细'), findsOneWidget);
      expect(find.textContaining('2 笔 · 支付宝'), findsOneWidget);
      expect(find.textContaining('买入 2026-06-01'), findsOneWidget);
      expect(find.textContaining('买入 2026-06-02'), findsOneWidget);
      expect(find.text('今日估值'), findsAtLeastNWidgets(1));
      expect(find.text('昨日收益'), findsAtLeastNWidgets(1));
      expect(find.text('累计收益'), findsAtLeastNWidgets(1));
      expect(find.textContaining('估算净值 2.1000'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+20.00'), findsAtLeastNWidgets(1));
      expect(find.textContaining('+10.00'), findsAtLeastNWidgets(1));
      expect(find.text('3150.00'), findsOneWidget);
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
    expect(find.text('易方达裕丰回报债券A'), findsOneWidget);
    expect(find.text('000171'), findsAtLeastNWidgets(1));
    expect(find.text('-10.00'), findsAtLeastNWidgets(1));
    expect(find.text('+100.00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('+20.00'), findsAtLeastNWidgets(1));
    expect(estimateRepository.requestedCodes, ['000171']);
  });

  testWidgets('hides portfolio market value and cost until tapped', (
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

    expect(find.text('估算市值'), findsOneWidget);
    expect(find.text('持仓成本'), findsOneWidget);
    expect(find.text('***'), findsNWidgets(2));
    expect(find.text('2100.00'), findsNothing);
    expect(find.text('2000.00'), findsNothing);

    await tester.tap(find.text('估算市值'));
    await tester.pumpAndSettle();

    expect(find.text('***'), findsNothing);
    expect(find.text('2100.00'), findsOneWidget);
    expect(find.text('2000.00'), findsOneWidget);

    await tester.tap(find.text('持仓成本'));
    await tester.pumpAndSettle();

    expect(find.text('***'), findsNWidgets(2));
    expect(find.text('2100.00'), findsNothing);
    expect(find.text('2000.00'), findsNothing);
  });

  testWidgets('renders fund code with NumText styling', (tester) async {
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

    expect(
      find.byWidgetPredicate(
        (widget) => widget is NumText && widget.data == '000171',
      ),
      findsWidgets,
    );
  });

  testWidgets('uses a data menu for importing and exporting holdings json', (
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
          fee: 3,
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

    await tester.tap(find.byTooltip('持仓数据'));
    await tester.pumpAndSettle();

    expect(find.text('导入 JSON'), findsOneWidget);
    expect(find.text('导出 JSON'), findsOneWidget);

    await tester.tap(find.text('导出 JSON'));
    await tester.pumpAndSettle();

    expect(find.text('导出 JSON'), findsOneWidget);
    final exportField = tester.widget<TextField>(find.byType(TextField));
    expect(exportField.controller?.text, contains('"天天基金"'));
    expect(exportField.controller?.text, contains('"code": "000171"'));
    expect(exportField.controller?.text, contains('"buy_date": "2026-01-01"'));
    expect(exportField.controller?.text, contains('"fee": 3.0'));
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

    await _openFirstHoldingDetail(tester);

    final deleteButton = find.byTooltip('删除持仓');
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

    await _openFirstHoldingDetail(tester);
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
    expect(find.text('+890.00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('+30.00'), findsAtLeastNWidgets(1));
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

    await _openFirstHoldingDetail(tester);

    expect(find.text('今日估值'), findsAtLeastNWidgets(1));
    expect(find.text('昨日收益'), findsAtLeastNWidgets(1));
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

    await _openFirstHoldingDetail(tester);

    expect(find.text('累计收益'), findsAtLeastNWidgets(1));
    expect(find.text('0.00'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'shows confirmed nav as actual return after net value is published',
    (tester) async {
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fundEstimateRepositoryProvider.overrideWithValue(
              _FakeFundEstimateRepository(
                estimate: const RealtimeEstimate(
                  code: '000171',
                  name: '易方达裕丰回报债券A',
                  prevNavDate: '2026-06-01',
                  prevNav: 2.08,
                  estNav: 2.10,
                  estChangePct: 0.96,
                  estTime: '2026-06-02 14:30',
                  confirmedNavDate: '2026-06-02',
                  confirmedNav: 2.12,
                  previousTradingNavDate: '2026-05-29',
                  previousTradingNav: 2.09,
                ),
              ),
            ),
            fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
          ],
          child: const MaterialApp(home: FundHoldingEstimatePage()),
        ),
      );
      await tester.pumpAndSettle();

      final overview = find.byType(FundPortfolioOverview);
      expect(
        find.descendant(of: overview, matching: find.text('实际市值')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('估算市值')),
        findsNothing,
      );
      expect(
        find.descendant(of: overview, matching: find.text('今日最终收益')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('今日估值')),
        findsNothing,
      );
      expect(
        find.descendant(of: overview, matching: find.text('昨日收益')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: overview,
          matching: find.textContaining('2026-06-02 净值确认'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: overview,
          matching: find.textContaining('较 2026-06-01'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('+40.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('-10.00')),
        findsNothing,
      );

      await _openFirstHoldingDetail(tester);

      expect(find.text('今日最终收益'), findsAtLeastNWidgets(1));
      expect(find.text('今日估值'), findsNothing);
      expect(find.textContaining('确认净值 2.1200'), findsOneWidget);
      expect(find.textContaining('+40.00'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'keeps portfolio overview estimated until every holding has confirmed nav',
    (tester) async {
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
          FundHoldingInput(
            id: 2,
            code: '000385',
            purchaseDate: DateTime(2026, 1, 1),
            shares: 1000,
            channel: '支付宝',
            purchaseNav: 1.8,
            fee: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fundEstimateRepositoryProvider.overrideWithValue(
              _FakeFundEstimateRepository(
                estimatesByCode: {
                  '000171': const RealtimeEstimate(
                    code: '000171',
                    name: '易方达裕丰回报债券A',
                    prevNavDate: '2026-06-01',
                    prevNav: 2.08,
                    estNav: 2.10,
                    estChangePct: 0.96,
                    estTime: '2026-06-02 14:30',
                    confirmedNavDate: '2026-06-02',
                    confirmedNav: 2.12,
                    previousTradingNavDate: '2026-05-29',
                    previousTradingNav: 2.09,
                  ),
                  '000385': const RealtimeEstimate(
                    code: '000385',
                    name: '景顺长城景颐双利债券A',
                    prevNavDate: '2026-06-01',
                    prevNav: 1.89,
                    estNav: 1.91,
                    estChangePct: 1.06,
                    estTime: '2026-06-02 14:30',
                    previousTradingNavDate: '2026-05-29',
                    previousTradingNav: 1.88,
                  ),
                },
              ),
            ),
            fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
          ],
          child: const MaterialApp(home: FundHoldingEstimatePage()),
        ),
      );
      await tester.pumpAndSettle();

      final overview = find.byType(FundPortfolioOverview);
      expect(
        find.descendant(of: overview, matching: find.text('估算市值')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('实际市值')),
        findsNothing,
      );
      expect(
        find.descendant(of: overview, matching: find.text('今日估值')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('昨日收益')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('今日最终收益')),
        findsNothing,
      );

      await tester.tap(find.text('估算市值'));
      await tester.pumpAndSettle();

      expect(find.text('4010.00'), findsOneWidget);
      expect(find.text('4030.00'), findsNothing);
    },
  );

  testWidgets(
    'summarizes portfolio estimate time without using one fund as the source',
    (tester) async {
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
          FundHoldingInput(
            id: 2,
            code: '000385',
            purchaseDate: DateTime(2026, 1, 1),
            shares: 1000,
            channel: '支付宝',
            purchaseNav: 1.8,
            fee: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fundEstimateRepositoryProvider.overrideWithValue(
              _FakeFundEstimateRepository(
                estimatesByCode: {
                  '000171': const RealtimeEstimate(
                    code: '000171',
                    name: '易方达裕丰回报债券A',
                    prevNavDate: '2026-06-01',
                    prevNav: 2.08,
                    estNav: 2.10,
                    estChangePct: 0.96,
                    estTime: '2026-06-02 10:30',
                    previousTradingNavDate: '2026-05-29',
                    previousTradingNav: 2.09,
                  ),
                  '000385': const RealtimeEstimate(
                    code: '000385',
                    name: '景顺长城景颐双利债券A',
                    prevNavDate: '2026-05-31',
                    prevNav: 1.89,
                    estNav: 1.91,
                    estChangePct: 1.06,
                    estTime: '2026-06-02 14:30',
                    previousTradingNavDate: '2026-05-30',
                    previousTradingNav: 1.88,
                  ),
                },
              ),
            ),
            fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
          ],
          child: const MaterialApp(home: FundHoldingEstimatePage()),
        ),
      );
      await tester.pumpAndSettle();

      final overview = find.byType(FundPortfolioOverview);
      expect(
        find.descendant(of: overview, matching: find.text('今日估值')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('昨日收益')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: overview,
          matching: find.text('多基金净值基准 · 更新至 2026-06-02 14:30'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('2026-06-01 净值基准'), findsNothing);
      expect(find.textContaining('2026-05-31 净值基准'), findsNothing);
    },
  );

  testWidgets(
    'does not show a single actual date when confirmed nav dates differ',
    (tester) async {
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
          FundHoldingInput(
            id: 2,
            code: '000385',
            purchaseDate: DateTime(2026, 1, 1),
            shares: 1000,
            channel: '支付宝',
            purchaseNav: 1.8,
            fee: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fundEstimateRepositoryProvider.overrideWithValue(
              _FakeFundEstimateRepository(
                estimatesByCode: {
                  '000171': const RealtimeEstimate(
                    code: '000171',
                    name: '易方达裕丰回报债券A',
                    prevNavDate: '2026-06-01',
                    prevNav: 2.08,
                    estNav: 2.10,
                    estChangePct: 0.96,
                    estTime: '2026-06-02 14:30',
                    confirmedNavDate: '2026-06-02',
                    confirmedNav: 2.12,
                    previousTradingNavDate: '2026-05-29',
                    previousTradingNav: 2.09,
                  ),
                  '000385': const RealtimeEstimate(
                    code: '000385',
                    name: '景顺长城景颐双利债券A',
                    prevNavDate: '2026-05-31',
                    prevNav: 1.89,
                    estNav: 1.91,
                    estChangePct: 1.06,
                    estTime: '2026-06-02 14:30',
                    confirmedNavDate: '2026-06-01',
                    confirmedNav: 1.92,
                    previousTradingNavDate: '2026-05-30',
                    previousTradingNav: 1.88,
                  ),
                },
              ),
            ),
            fundHoldingRepositoryProvider.overrideWithValue(holdingRepository),
          ],
          child: const MaterialApp(home: FundHoldingEstimatePage()),
        ),
      );
      await tester.pumpAndSettle();

      final overview = find.byType(FundPortfolioOverview);
      expect(
        find.descendant(of: overview, matching: find.text('估算市值')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('实际市值')),
        findsNothing,
      );
      expect(
        find.descendant(of: overview, matching: find.text('今日估值')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('昨日收益')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: overview, matching: find.text('今日最终收益')),
        findsNothing,
      );
    },
  );
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

Future<void> _openFirstHoldingDetail(WidgetTester tester) async {
  final holdingTitle = find.textContaining('债券').first;
  await tester.ensureVisible(holdingTitle);
  await tester.tap(holdingTitle);
  await tester.pumpAndSettle();
}

final class _FakeFundEstimateRepository implements FundEstimateRepository {
  _FakeFundEstimateRepository({
    RealtimeEstimate? estimate,
    this._estimatesByCode = const {},
  }) : _estimate =
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
  final Map<String, RealtimeEstimate> _estimatesByCode;

  @override
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) async {
    requestedCodes.add(code);
    return _estimatesByCode[code] ?? _estimate;
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
