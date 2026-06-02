// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_article.freezed.dart';
part 'news_article.g.dart';

@freezed
/// News Article 接口单条结果实体。
abstract class NewsArticle with _$NewsArticle {
  const NewsArticle._();

  const factory NewsArticle({
    @JsonKey(name: 'article_id') @Default('') String articleId,
    String? link,
    @Default('') String title,
    String? description,
    String? content,
    @JsonKey(fromJson: _stringListFromJson)
    @Default(<String>[])
    List<String> keywords,
    @JsonKey(fromJson: _stringListFromJson)
    @Default(<String>[])
    List<String> creator,
    String? language,
    @JsonKey(fromJson: _stringListFromJson)
    @Default(<String>[])
    List<String> country,
    @JsonKey(fromJson: _stringListFromJson)
    @Default(<String>[])
    List<String> category,
    String? datatype,
    @JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson) DateTime? pubDate,
    @JsonKey(name: 'pubDateTZ') String? pubDateTZ,
    @JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson)
    DateTime? fetchedAt,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'source_id') String? sourceId,
    @JsonKey(name: 'source_name') String? sourceName,
    @JsonKey(name: 'source_priority') int? sourcePriority,
    @JsonKey(name: 'source_url') String? sourceUrl,
    @JsonKey(name: 'source_icon') String? sourceIcon,
    String? sentiment,
    @JsonKey(name: 'sentiment_stats') String? sentimentStats,
    @JsonKey(name: 'ai_tag') String? aiTag,
    @JsonKey(name: 'ai_region') String? aiRegion,
    @JsonKey(name: 'ai_org') String? aiOrg,
    @JsonKey(name: 'ai_summary') String? aiSummary,
    @Default(false) bool duplicate,
  }) = _NewsArticle;

  /// 作者展示文本：没有作者时给出兜底文案，避免页面出现空白。
  String get authorText {
    if (creator.isEmpty) {
      return '未知作者';
    }
    return creator.join('、');
  }

  /// 摘要展示文本：优先 description，空值时返回默认提示。
  String get summaryText {
    final summary = description?.trim();
    if (summary == null || summary.isEmpty) {
      return '暂无摘要';
    }
    return summary;
  }

  /// 正文展示文本：过滤 Newsdata 免费计划中的占位正文。
  String get bodyText {
    final text = content?.trim();
    if (text != null &&
        text.isNotEmpty &&
        text != 'ONLY AVAILABLE IN PAID PLANS') {
      return text;
    }
    return summaryText;
  }

  /// 是否可跳转原文：要求 URL 可被解析且包含协议头。
  bool get hasOriginalLink {
    final value = link;
    if (value == null) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme;
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) =>
      _$NewsArticleFromJson(json);
}

List<String> _stringListFromJson(Object? value) {
  if (value == null || value is! List) {
    return const [];
  }
  return value.map((e) => e.toString()).toList();
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  final normalized = value.trim().replaceFirst(' ', 'T');
  return DateTime.tryParse('${normalized}Z') ?? DateTime.tryParse(value);
}
