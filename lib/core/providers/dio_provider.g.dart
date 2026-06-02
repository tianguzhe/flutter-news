// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局 Dio Provider（常驻）：
/// - 统一对外提供 HTTP 客户端
/// - 作为数据层请求入口依赖

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// 全局 Dio Provider（常驻）：
/// - 统一对外提供 HTTP 客户端
/// - 作为数据层请求入口依赖

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 全局 Dio Provider（常驻）：
  /// - 统一对外提供 HTTP 客户端
  /// - 作为数据层请求入口依赖
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'42680fcb09dab905866465f05e0bd91e5d96e992';
