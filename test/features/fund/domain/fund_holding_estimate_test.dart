import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/fund/data/models/realtime_estimate.dart';
import 'package:untitled/features/fund/domain/fund_holding_estimate.dart';

void main() {
  group('calculateFundHoldingEstimate', () {
    test('calculates cost, estimated value, total return and return rate', () {
      final result = calculateFundHoldingEstimate(
        input: FundHoldingInput(
          id: 1,
          code: '000171',
          purchaseDate: DateTime(2026, 1, 1),
          shares: 1000,
          channel: '支付宝',
          purchaseNav: 2,
          fee: 0,
        ),
        realtimeEstimate: const RealtimeEstimate(
          code: '000171',
          name: '易方达裕丰回报债券A',
          prevNavDate: '2026-06-01',
          prevNav: 2.08,
          estNav: 2.1,
          estChangePct: 0.49,
          estTime: '2026-06-02 11:30',
        ),
      );

      expect(result.cost, 2000);
      expect(result.estimatedValue, 2100);
      expect(result.totalReturn, 100);
      expect(result.totalReturnRate, closeTo(0.05, 1e-9));
      expect(result.isProfitable, isTrue);
    });

    test('includes fee in holding cost and total return', () {
      final result = calculateFundHoldingEstimate(
        input: FundHoldingInput(
          id: 1,
          code: '000171',
          purchaseDate: DateTime(2026, 1, 1),
          shares: 1000,
          channel: '支付宝',
          purchaseNav: 2,
          fee: 15,
        ),
        realtimeEstimate: const RealtimeEstimate(
          code: '000171',
          name: '易方达裕丰回报债券A',
          prevNavDate: '2026-06-01',
          prevNav: 2.08,
          estNav: 2.1,
          estChangePct: 0.49,
          estTime: '2026-06-02 11:30',
        ),
      );

      expect(result.cost, 2015);
      expect(result.estimatedValue, 2100);
      expect(result.totalReturn, 85);
      expect(result.totalReturnRate, closeTo(85 / 2015, 1e-9));
    });

    test('rejects non-positive shares', () {
      expect(
        () => calculateFundHoldingEstimate(
          input: FundHoldingInput(
            id: 1,
            code: '000171',
            purchaseDate: DateTime(2026, 1, 1),
            shares: 0,
            channel: '银行',
            purchaseNav: 2,
            fee: 0,
          ),
          realtimeEstimate: _estimate,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive purchase nav', () {
      expect(
        () => calculateFundHoldingEstimate(
          input: FundHoldingInput(
            id: 1,
            code: '000171',
            purchaseDate: DateTime(2026, 1, 1),
            shares: 1000,
            channel: '银行',
            purchaseNav: 0,
            fee: 0,
          ),
          realtimeEstimate: _estimate,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative fee', () {
      expect(
        () => calculateFundHoldingEstimate(
          input: FundHoldingInput(
            id: 1,
            code: '000171',
            purchaseDate: DateTime(2026, 1, 1),
            shares: 1000,
            channel: '银行',
            purchaseNav: 2,
            fee: -1,
          ),
          realtimeEstimate: _estimate,
        ),
        throwsArgumentError,
      );
    });
  });
}

const _estimate = RealtimeEstimate(
  code: '000171',
  name: '易方达裕丰回报债券A',
  prevNavDate: '2026-06-01',
  prevNav: 2.08,
  estNav: 2.1,
  estChangePct: 0.49,
  estTime: '2026-06-02 11:30',
);
