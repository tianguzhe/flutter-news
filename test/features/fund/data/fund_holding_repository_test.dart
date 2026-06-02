import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/fund/data/local/fund_holdings_database.dart';
import 'package:untitled/features/fund/data/repositories/fund_holding_repository.dart';
import 'package:untitled/features/fund/domain/fund_holding_estimate.dart';

void main() {
  late FundHoldingsDatabase database;
  late FundHoldingRepository repository;

  setUp(() {
    database = FundHoldingsDatabase(NativeDatabase.memory());
    repository = DriftFundHoldingRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts and lists active holdings in stable order', () async {
    final later = DateTime(2026, 2, 1);
    final earlier = DateTime(2026, 1, 1);

    await repository.insertHolding(
      FundHoldingDraft(
        code: '000171',
        purchaseDate: later,
        shares: 500,
        channel: '支付宝',
        purchaseNav: 2.05,
      ),
    );
    await repository.insertHolding(
      FundHoldingDraft(
        code: '000171',
        purchaseDate: earlier,
        shares: 1000,
        channel: '支付宝',
        purchaseNav: 2,
      ),
    );

    final holdings = await repository.listActiveHoldings();

    expect(holdings, hasLength(2));
    expect(holdings[0].purchaseDate, earlier);
    expect(holdings[1].purchaseDate, later);
    expect(holdings[0].id, isPositive);
  });

  test('soft deletes holdings from active list', () async {
    final holding = await repository.insertHolding(
      FundHoldingDraft(
        code: '000171',
        purchaseDate: DateTime(2026, 1, 1),
        shares: 1000,
        channel: '银行',
        purchaseNav: 2,
      ),
    );

    await repository.softDeleteHolding(holding.id);

    expect(await repository.listActiveHoldings(), isEmpty);
  });

  test('updates active holding fields', () async {
    final holding = await repository.insertHolding(
      FundHoldingDraft(
        code: '000171',
        purchaseDate: DateTime(2026, 1, 1),
        shares: 1000,
        channel: '支付宝',
        purchaseNav: 2,
      ),
    );

    final updated = await repository.updateHolding(
      id: holding.id,
      draft: FundHoldingDraft(
        code: '000172',
        purchaseDate: DateTime(2026, 2, 2),
        shares: 1500,
        channel: '天天基金',
        purchaseNav: 1.5,
      ),
    );

    expect(updated.id, holding.id);
    expect(updated.code, '000172');
    expect(updated.purchaseDate, DateTime(2026, 2, 2));
    expect(updated.shares, 1500);
    expect(updated.channel, '天天基金');
    expect(updated.purchaseNav, 1.5);
    final holdings = await repository.listActiveHoldings();
    expect(holdings, hasLength(1));
    expect(holdings.single.id, updated.id);
    expect(holdings.single.code, updated.code);
    expect(holdings.single.purchaseDate, updated.purchaseDate);
    expect(holdings.single.shares, updated.shares);
    expect(holdings.single.channel, updated.channel);
    expect(holdings.single.purchaseNav, updated.purchaseNav);
  });

  test(
    'allows duplicate fund codes and purchase dates as separate holdings',
    () async {
      final purchaseDate = DateTime(2026, 1, 1);

      await repository.insertHolding(
        FundHoldingDraft(
          code: '000171',
          purchaseDate: purchaseDate,
          shares: 1000,
          channel: '天天基金',
          purchaseNav: 2,
        ),
      );
      await repository.insertHolding(
        FundHoldingDraft(
          code: '000171',
          purchaseDate: purchaseDate,
          shares: 500,
          channel: '天天基金',
          purchaseNav: 2,
        ),
      );

      final holdings = await repository.listActiveHoldings();

      expect(holdings, hasLength(2));
      expect(holdings.map((holding) => holding.id).toSet(), hasLength(2));
    },
  );
}
