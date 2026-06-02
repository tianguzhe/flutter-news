// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the news repository used by presentation view models.

@ProviderFor(newsRepository)
final newsRepositoryProvider = NewsRepositoryProvider._();

/// Provides the news repository used by presentation view models.

final class NewsRepositoryProvider
    extends $FunctionalProvider<NewsRepository, NewsRepository, NewsRepository>
    with $Provider<NewsRepository> {
  /// Provides the news repository used by presentation view models.
  NewsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NewsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NewsRepository create(Ref ref) {
    return newsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewsRepository>(value),
    );
  }
}

String _$newsRepositoryHash() => r'e7fd1dfb60783215f36b78bca53532d693b8db59';
