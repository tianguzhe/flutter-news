// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_list_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 列表状态控制器：管理分类切换、刷新与列表请求。

@ProviderFor(NewsListViewModel)
final newsListViewModelProvider = NewsListViewModelProvider._();

/// 列表状态控制器：管理分类切换、刷新与列表请求。
final class NewsListViewModelProvider
    extends $AsyncNotifierProvider<NewsListViewModel, List<NewsArticle>> {
  /// 列表状态控制器：管理分类切换、刷新与列表请求。
  NewsListViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsListViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsListViewModelHash();

  @$internal
  @override
  NewsListViewModel create() => NewsListViewModel();
}

String _$newsListViewModelHash() => r'54137d75c26714971f2dfcfc4f392b4c027c69c1';

/// 列表状态控制器：管理分类切换、刷新与列表请求。

abstract class _$NewsListViewModel extends $AsyncNotifier<List<NewsArticle>> {
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
        dependencies: null,
        $allTransitiveDependencies: null,
      );

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
    r'1e6c74f9dfcbb3cd0e54794cc37d830fd1ee4c4c';
