// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 详情 Provider：按新闻 id 拉取单篇文章。

@ProviderFor(newsDetail)
final newsDetailProvider = NewsDetailFamily._();

/// 详情 Provider：按新闻 id 拉取单篇文章。

final class NewsDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<NewsArticle>,
          NewsArticle,
          FutureOr<NewsArticle>
        >
    with $FutureModifier<NewsArticle>, $FutureProvider<NewsArticle> {
  /// 详情 Provider：按新闻 id 拉取单篇文章。
  NewsDetailProvider._({
    required NewsDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'newsDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = newsApiProvider;

  @override
  String debugGetCreateSourceHash() => _$newsDetailHash();

  @override
  String toString() {
    return r'newsDetailProvider'
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
    return newsDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NewsDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$newsDetailHash() => r'db4d56e59c0186588bd58ca56a369826708c6d9a';

/// 详情 Provider：按新闻 id 拉取单篇文章。

final class NewsDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NewsArticle>, String> {
  NewsDetailFamily._()
    : super(
        retry: null,
        name: r'newsDetailProvider',
        dependencies: <ProviderOrFamily>[newsApiProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          NewsDetailProvider.$allTransitiveDependencies0,
        ],
        isAutoDispose: true,
      );

  /// 详情 Provider：按新闻 id 拉取单篇文章。

  NewsDetailProvider call(String id) =>
      NewsDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'newsDetailProvider';
}
