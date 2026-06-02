// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_holdings_database.dart';

// ignore_for_file: type=lint
class $FundHoldingsTable extends FundHoldings
    with TableInfo<$FundHoldingsTable, FundHolding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundHoldingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 6,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
    'shares',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseNavMeta = const VerificationMeta(
    'purchaseNav',
  );
  @override
  late final GeneratedColumn<double> purchaseNav = GeneratedColumn<double>(
    'purchase_nav',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    purchaseDate,
    shares,
    channel,
    purchaseNav,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fund_holdings';
  @override
  VerificationContext validateIntegrity(
    Insertable<FundHolding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('shares')) {
      context.handle(
        _sharesMeta,
        shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta),
      );
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('purchase_nav')) {
      context.handle(
        _purchaseNavMeta,
        purchaseNav.isAcceptableOrUnknown(
          data['purchase_nav']!,
          _purchaseNavMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseNavMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FundHolding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FundHolding(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      )!,
      shares: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shares'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      purchaseNav: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_nav'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $FundHoldingsTable createAlias(String alias) {
    return $FundHoldingsTable(attachedDatabase, alias);
  }
}

class FundHolding extends DataClass implements Insertable<FundHolding> {
  final int id;
  final String code;
  final DateTime purchaseDate;
  final double shares;
  final String channel;
  final double purchaseNav;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const FundHolding({
    required this.id,
    required this.code,
    required this.purchaseDate,
    required this.shares,
    required this.channel,
    required this.purchaseNav,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['shares'] = Variable<double>(shares);
    map['channel'] = Variable<String>(channel);
    map['purchase_nav'] = Variable<double>(purchaseNav);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FundHoldingsCompanion toCompanion(bool nullToAbsent) {
    return FundHoldingsCompanion(
      id: Value(id),
      code: Value(code),
      purchaseDate: Value(purchaseDate),
      shares: Value(shares),
      channel: Value(channel),
      purchaseNav: Value(purchaseNav),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FundHolding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FundHolding(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      shares: serializer.fromJson<double>(json['shares']),
      channel: serializer.fromJson<String>(json['channel']),
      purchaseNav: serializer.fromJson<double>(json['purchaseNav']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'shares': serializer.toJson<double>(shares),
      'channel': serializer.toJson<String>(channel),
      'purchaseNav': serializer.toJson<double>(purchaseNav),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  FundHolding copyWith({
    int? id,
    String? code,
    DateTime? purchaseDate,
    double? shares,
    String? channel,
    double? purchaseNav,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => FundHolding(
    id: id ?? this.id,
    code: code ?? this.code,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    shares: shares ?? this.shares,
    channel: channel ?? this.channel,
    purchaseNav: purchaseNav ?? this.purchaseNav,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FundHolding copyWithCompanion(FundHoldingsCompanion data) {
    return FundHolding(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      shares: data.shares.present ? data.shares.value : this.shares,
      channel: data.channel.present ? data.channel.value : this.channel,
      purchaseNav: data.purchaseNav.present
          ? data.purchaseNav.value
          : this.purchaseNav,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FundHolding(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('shares: $shares, ')
          ..write('channel: $channel, ')
          ..write('purchaseNav: $purchaseNav, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    purchaseDate,
    shares,
    channel,
    purchaseNav,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FundHolding &&
          other.id == this.id &&
          other.code == this.code &&
          other.purchaseDate == this.purchaseDate &&
          other.shares == this.shares &&
          other.channel == this.channel &&
          other.purchaseNav == this.purchaseNav &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FundHoldingsCompanion extends UpdateCompanion<FundHolding> {
  final Value<int> id;
  final Value<String> code;
  final Value<DateTime> purchaseDate;
  final Value<double> shares;
  final Value<String> channel;
  final Value<double> purchaseNav;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const FundHoldingsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.shares = const Value.absent(),
    this.channel = const Value.absent(),
    this.purchaseNav = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  FundHoldingsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required DateTime purchaseDate,
    required double shares,
    required String channel,
    required double purchaseNav,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
  }) : code = Value(code),
       purchaseDate = Value(purchaseDate),
       shares = Value(shares),
       channel = Value(channel),
       purchaseNav = Value(purchaseNav),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FundHolding> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<DateTime>? purchaseDate,
    Expression<double>? shares,
    Expression<String>? channel,
    Expression<double>? purchaseNav,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (shares != null) 'shares': shares,
      if (channel != null) 'channel': channel,
      if (purchaseNav != null) 'purchase_nav': purchaseNav,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  FundHoldingsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<DateTime>? purchaseDate,
    Value<double>? shares,
    Value<String>? channel,
    Value<double>? purchaseNav,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return FundHoldingsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      shares: shares ?? this.shares,
      channel: channel ?? this.channel,
      purchaseNav: purchaseNav ?? this.purchaseNav,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (purchaseNav.present) {
      map['purchase_nav'] = Variable<double>(purchaseNav.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundHoldingsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('shares: $shares, ')
          ..write('channel: $channel, ')
          ..write('purchaseNav: $purchaseNav, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$FundHoldingsDatabase extends GeneratedDatabase {
  _$FundHoldingsDatabase(QueryExecutor e) : super(e);
  $FundHoldingsDatabaseManager get managers =>
      $FundHoldingsDatabaseManager(this);
  late final $FundHoldingsTable fundHoldings = $FundHoldingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [fundHoldings];
}

typedef $$FundHoldingsTableCreateCompanionBuilder =
    FundHoldingsCompanion Function({
      Value<int> id,
      required String code,
      required DateTime purchaseDate,
      required double shares,
      required String channel,
      required double purchaseNav,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$FundHoldingsTableUpdateCompanionBuilder =
    FundHoldingsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<DateTime> purchaseDate,
      Value<double> shares,
      Value<String> channel,
      Value<double> purchaseNav,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

class $$FundHoldingsTableFilterComposer
    extends Composer<_$FundHoldingsDatabase, $FundHoldingsTable> {
  $$FundHoldingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shares => $composableBuilder(
    column: $table.shares,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchaseNav => $composableBuilder(
    column: $table.purchaseNav,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FundHoldingsTableOrderingComposer
    extends Composer<_$FundHoldingsDatabase, $FundHoldingsTable> {
  $$FundHoldingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shares => $composableBuilder(
    column: $table.shares,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchaseNav => $composableBuilder(
    column: $table.purchaseNav,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FundHoldingsTableAnnotationComposer
    extends Composer<_$FundHoldingsDatabase, $FundHoldingsTable> {
  $$FundHoldingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<double> get purchaseNav => $composableBuilder(
    column: $table.purchaseNav,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$FundHoldingsTableTableManager
    extends
        RootTableManager<
          _$FundHoldingsDatabase,
          $FundHoldingsTable,
          FundHolding,
          $$FundHoldingsTableFilterComposer,
          $$FundHoldingsTableOrderingComposer,
          $$FundHoldingsTableAnnotationComposer,
          $$FundHoldingsTableCreateCompanionBuilder,
          $$FundHoldingsTableUpdateCompanionBuilder,
          (
            FundHolding,
            BaseReferences<
              _$FundHoldingsDatabase,
              $FundHoldingsTable,
              FundHolding
            >,
          ),
          FundHolding,
          PrefetchHooks Function()
        > {
  $$FundHoldingsTableTableManager(
    _$FundHoldingsDatabase db,
    $FundHoldingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FundHoldingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FundHoldingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FundHoldingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<DateTime> purchaseDate = const Value.absent(),
                Value<double> shares = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<double> purchaseNav = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => FundHoldingsCompanion(
                id: id,
                code: code,
                purchaseDate: purchaseDate,
                shares: shares,
                channel: channel,
                purchaseNav: purchaseNav,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required DateTime purchaseDate,
                required double shares,
                required String channel,
                required double purchaseNav,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => FundHoldingsCompanion.insert(
                id: id,
                code: code,
                purchaseDate: purchaseDate,
                shares: shares,
                channel: channel,
                purchaseNav: purchaseNav,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FundHoldingsTableProcessedTableManager =
    ProcessedTableManager<
      _$FundHoldingsDatabase,
      $FundHoldingsTable,
      FundHolding,
      $$FundHoldingsTableFilterComposer,
      $$FundHoldingsTableOrderingComposer,
      $$FundHoldingsTableAnnotationComposer,
      $$FundHoldingsTableCreateCompanionBuilder,
      $$FundHoldingsTableUpdateCompanionBuilder,
      (
        FundHolding,
        BaseReferences<_$FundHoldingsDatabase, $FundHoldingsTable, FundHolding>,
      ),
      FundHolding,
      PrefetchHooks Function()
    >;

class $FundHoldingsDatabaseManager {
  final _$FundHoldingsDatabase _db;
  $FundHoldingsDatabaseManager(this._db);
  $$FundHoldingsTableTableManager get fundHoldings =>
      $$FundHoldingsTableTableManager(_db, _db.fundHoldings);
}
