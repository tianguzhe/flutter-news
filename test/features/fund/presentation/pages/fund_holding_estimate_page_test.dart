import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/fund/data/models/realtime_estimate.dart';
import 'package:untitled/features/fund/data/repositories/fund_estimate_repository.dart';
import 'package:untitled/features/fund/data/repositories/fund_estimate_repository_provider.dart';
import 'package:untitled/features/fund/presentation/pages/fund_holding_estimate_page.dart';

void main() {
  testWidgets(
    'groups holdings by channel while keeping different purchase dates separate',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fundEstimateRepositoryProvider.overrideWithValue(
              _FakeFundEstimateRepository(),
            ),
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
  @override
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) async {
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
