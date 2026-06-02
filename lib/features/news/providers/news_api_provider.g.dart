// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 注入 NewsApi 单例，供列表与详情 Provider 复用。

@ProviderFor(newsApi)
final newsApiProvider = NewsApiProvider._();

/// 注入 NewsApi 单例，供列表与详情 Provider 复用。

final class NewsApiProvider
    extends $FunctionalProvider<NewsApi, NewsApi, NewsApi>
    with $Provider<NewsApi> {
  /// 注入 NewsApi 单例，供列表与详情 Provider 复用。
  NewsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsApiProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$newsApiHash();

  @$internal
  @override
  $ProviderElement<NewsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NewsApi create(Ref ref) {
    return newsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewsApi>(value),
    );
  }
}

String _$newsApiHash() => r'4a74d5a3e74da61161f80b4cd6b1d9a8dce4159d';
