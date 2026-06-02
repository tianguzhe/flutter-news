// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_estimate_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the fund estimate repository.

@ProviderFor(fundEstimateRepository)
final fundEstimateRepositoryProvider = FundEstimateRepositoryProvider._();

/// Provides the fund estimate repository.

final class FundEstimateRepositoryProvider
    extends
        $FunctionalProvider<
          FundEstimateRepository,
          FundEstimateRepository,
          FundEstimateRepository
        >
    with $Provider<FundEstimateRepository> {
  /// Provides the fund estimate repository.
  FundEstimateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundEstimateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundEstimateRepositoryHash();

  @$internal
  @override
  $ProviderElement<FundEstimateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FundEstimateRepository create(Ref ref) {
    return fundEstimateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FundEstimateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FundEstimateRepository>(value),
    );
  }
}

String _$fundEstimateRepositoryHash() =>
    r'ac8574a132dde18ea41a5740245853e1855411cf';
