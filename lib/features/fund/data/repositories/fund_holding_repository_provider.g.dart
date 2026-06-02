// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_holding_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fundHoldingsDatabase)
final fundHoldingsDatabaseProvider = FundHoldingsDatabaseProvider._();

final class FundHoldingsDatabaseProvider
    extends
        $FunctionalProvider<
          FundHoldingsDatabase,
          FundHoldingsDatabase,
          FundHoldingsDatabase
        >
    with $Provider<FundHoldingsDatabase> {
  FundHoldingsDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundHoldingsDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundHoldingsDatabaseHash();

  @$internal
  @override
  $ProviderElement<FundHoldingsDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FundHoldingsDatabase create(Ref ref) {
    return fundHoldingsDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FundHoldingsDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FundHoldingsDatabase>(value),
    );
  }
}

String _$fundHoldingsDatabaseHash() =>
    r'245d03621aa36f7ccd270f8819e1b05501a788ee';

@ProviderFor(fundHoldingRepository)
final fundHoldingRepositoryProvider = FundHoldingRepositoryProvider._();

final class FundHoldingRepositoryProvider
    extends
        $FunctionalProvider<
          FundHoldingRepository,
          FundHoldingRepository,
          FundHoldingRepository
        >
    with $Provider<FundHoldingRepository> {
  FundHoldingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundHoldingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundHoldingRepositoryHash();

  @$internal
  @override
  $ProviderElement<FundHoldingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FundHoldingRepository create(Ref ref) {
    return fundHoldingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FundHoldingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FundHoldingRepository>(value),
    );
  }
}

String _$fundHoldingRepositoryHash() =>
    r'f3ac9386d28557e39d73e839e5cfb5395ff85be1';
