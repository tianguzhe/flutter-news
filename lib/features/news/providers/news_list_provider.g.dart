// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 列表状态控制器：管理分类切换、刷新与列表请求。

@ProviderFor(NewsList)
final newsListProvider = NewsListProvider._();

/// 列表状态控制器：管理分类切换、刷新与列表请求。
final class NewsListProvider
    extends $AsyncNotifierProvider<NewsList, List<NewsArticle>> {
  /// 列表状态控制器：管理分类切换、刷新与列表请求。
  NewsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsListProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[newsApiProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          NewsListProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = newsApiProvider;

  @override
  String debugGetCreateSourceHash() => _$newsListHash();

  @$internal
  @override
  NewsList create() => NewsList();
}

String _$newsListHash() => r'baab7a999af7c80efc2a68ac1c429bc174749f1d';

/// 列表状态控制器：管理分类切换、刷新与列表请求。

abstract class _$NewsList extends $AsyncNotifier<List<NewsArticle>> {
  FutureOr<List<NewsArticle>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<NewsArticle>>, List<NewsArticle>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NewsArticle>>, List<NewsArticle>>,
              AsyncValue<List<NewsArticle>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 当前选中的新闻分类：给 UI 读取高亮状态，避免直接暴露 Notifier getter。

@ProviderFor(selectedNewsCategory)
final selectedNewsCategoryProvider = SelectedNewsCategoryProvider._();

/// 当前选中的新闻分类：给 UI 读取高亮状态，避免直接暴露 Notifier getter。

final class SelectedNewsCategoryProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 当前选中的新闻分类：给 UI 读取高亮状态，避免直接暴露 Notifier getter。
  SelectedNewsCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedNewsCategoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[newsListProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SelectedNewsCategoryProvider.$allTransitiveDependencies0,
          SelectedNewsCategoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = newsListProvider;
  static final $allTransitiveDependencies1 =
      NewsListProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$selectedNewsCategoryHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return selectedNewsCategory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedNewsCategoryHash() =>
    r'2511211e39a897caee612c8a69b04816f3b1c654';
