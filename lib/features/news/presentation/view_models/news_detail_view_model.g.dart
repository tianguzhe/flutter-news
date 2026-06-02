// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 详情 Provider：按新闻 id 拉取单篇文章。

@ProviderFor(newsDetailViewModel)
final newsDetailViewModelProvider = NewsDetailViewModelFamily._();

/// 详情 Provider：按新闻 id 拉取单篇文章。

final class NewsDetailViewModelProvider
    extends
        $FunctionalProvider<
          AsyncValue<NewsArticle>,
          NewsArticle,
          FutureOr<NewsArticle>
        >
    with $FutureModifier<NewsArticle>, $FutureProvider<NewsArticle> {
  /// 详情 Provider：按新闻 id 拉取单篇文章。
  NewsDetailViewModelProvider._({
    required NewsDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'newsDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$newsDetailViewModelHash();

  @override
  String toString() {
    return r'newsDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NewsArticle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NewsArticle> create(Ref ref) {
    final argument = this.argument as String;
    return newsDetailViewModel(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NewsDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$newsDetailViewModelHash() =>
    r'4c2da49d673e804988356dada58aabca6c9a0439';

/// 详情 Provider：按新闻 id 拉取单篇文章。

final class NewsDetailViewModelFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NewsArticle>, String> {
  NewsDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'newsDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 详情 Provider：按新闻 id 拉取单篇文章。

  NewsDetailViewModelProvider call(String id) =>
      NewsDetailViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'newsDetailViewModelProvider';
}
