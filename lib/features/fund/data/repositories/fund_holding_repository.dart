import 'package:drift/drift.dart';

import '../../domain/fund_holding_estimate.dart';
import '../local/fund_holdings_database.dart';

abstract interface class FundHoldingRepository {
  Future<List<FundHoldingInput>> listActiveHoldings();

  Future<FundHoldingInput> insertHolding(FundHoldingDraft draft);

  Future<FundHoldingInput> updateHolding({
    required int id,
    required FundHoldingDraft draft,
  });

  Future<void> softDeleteHolding(int id);
}

final class DriftFundHoldingRepository implements FundHoldingRepository {
  const DriftFundHoldingRepository(this._database);

  final FundHoldingsDatabase _database;

  @override
  Future<List<FundHoldingInput>> listActiveHoldings() async {
    final rows =
        await (_database.select(_database.fundHoldings)
              ..where((holding) => holding.deletedAt.isNull())
              ..orderBy([
                (holding) => OrderingTerm(expression: holding.channel),
                (holding) => OrderingTerm(expression: holding.purchaseDate),
                (holding) => OrderingTerm(expression: holding.id),
              ]))
            .get();
    return rows.map(_toInput).toList();
  }

  @override
  Future<FundHoldingInput> insertHolding(FundHoldingDraft draft) async {
    final now = DateTime.now();
    final id = await _database
        .into(_database.fundHoldings)
        .insert(
          FundHoldingsCompanion.insert(
            code: draft.code,
            purchaseDate: draft.purchaseDate,
            shares: draft.shares,
            channel: draft.channel,
            purchaseNav: draft.purchaseNav,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row = await (_database.select(
      _database.fundHoldings,
    )..where((holding) => holding.id.equals(id))).getSingle();
    return _toInput(row);
  }

  @override
  Future<FundHoldingInput> updateHolding({
    required int id,
    required FundHoldingDraft draft,
  }) async {
    final now = DateTime.now();
    await (_database.update(_database.fundHoldings)..where(
          (holding) => holding.id.equals(id) & holding.deletedAt.isNull(),
        ))
        .write(
          FundHoldingsCompanion(
            code: Value(draft.code),
            purchaseDate: Value(draft.purchaseDate),
            shares: Value(draft.shares),
            channel: Value(draft.channel),
            purchaseNav: Value(draft.purchaseNav),
            updatedAt: Value(now),
          ),
        );
    final row =
        await (_database.select(_database.fundHoldings)..where(
              (holding) => holding.id.equals(id) & holding.deletedAt.isNull(),
            ))
            .getSingle();
    return _toInput(row);
  }

  @override
  Future<void> softDeleteHolding(int id) async {
    final now = DateTime.now();
    await (_database.update(
      _database.fundHoldings,
    )..where((holding) => holding.id.equals(id))).write(
      FundHoldingsCompanion(updatedAt: Value(now), deletedAt: Value(now)),
    );
  }
}

FundHoldingInput _toInput(FundHolding row) {
  return FundHoldingInput(
    id: row.id,
    code: row.code,
    purchaseDate: row.purchaseDate,
    shares: row.shares,
    channel: row.channel,
    purchaseNav: row.purchaseNav,
  );
}
