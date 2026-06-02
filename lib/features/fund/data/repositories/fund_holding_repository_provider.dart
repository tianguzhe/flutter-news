import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../local/fund_holdings_database.dart';
import 'fund_holding_repository.dart';

part 'fund_holding_repository_provider.g.dart';

@Riverpod(keepAlive: true)
FundHoldingsDatabase fundHoldingsDatabase(Ref ref) {
  final database = FundHoldingsDatabase();
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
FundHoldingRepository fundHoldingRepository(Ref ref) {
  return DriftFundHoldingRepository(ref.watch(fundHoldingsDatabaseProvider));
}
