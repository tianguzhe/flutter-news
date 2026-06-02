import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'fund_holdings_database.g.dart';

class FundHoldings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 6, max: 6)();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get shares => real()();
  TextColumn get channel => text()();
  RealColumn get purchaseNav => real()();
  RealColumn get fee => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [FundHoldings])
final class FundHoldingsDatabase extends _$FundHoldingsDatabase {
  FundHoldingsDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'fund_holdings'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(fundHoldings, fundHoldings.fee);
        }
      },
    );
  }
}
