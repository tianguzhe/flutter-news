// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_estimate_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the fund estimate API service.

@ProviderFor(fundEstimateApi)
final fundEstimateApiProvider = FundEstimateApiProvider._();

/// Provides the fund estimate API service.

final class FundEstimateApiProvider
    extends
        $FunctionalProvider<FundEstimateApi, FundEstimateApi, FundEstimateApi>
    with $Provider<FundEstimateApi> {
  /// Provides the fund estimate API service.
  FundEstimateApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundEstimateApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundEstimateApiHash();

  @$internal
  @override
  $ProviderElement<FundEstimateApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FundEstimateApi create(Ref ref) {
    return fundEstimateApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FundEstimateApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FundEstimateApi>(value),
    );
  }
}

String _$fundEstimateApiHash() => r'7623f236bcd51537c192023aca216d8410f678e8';
