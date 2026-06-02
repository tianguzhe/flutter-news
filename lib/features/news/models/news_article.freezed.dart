// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NewsArticle {

@JsonKey(name: 'article_id') String get articleId; String? get link; String get title; String? get description; String? get content;@JsonKey(fromJson: _stringListFromJson) List<String> get keywords;@JsonKey(fromJson: _stringListFromJson) List<String> get creator; String? get language;@JsonKey(fromJson: _stringListFromJson) List<String> get country;@JsonKey(fromJson: _stringListFromJson) List<String> get category; String? get datatype;@JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson) DateTime? get pubDate;@JsonKey(name: 'pubDateTZ') String? get pubDateTZ;@JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson) DateTime? get fetchedAt;@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'video_url') String? get videoUrl;@JsonKey(name: 'source_id') String? get sourceId;@JsonKey(name: 'source_name') String? get sourceName;@JsonKey(name: 'source_priority') int? get sourcePriority;@JsonKey(name: 'source_url') String? get sourceUrl;@JsonKey(name: 'source_icon') String? get sourceIcon; String? get sentiment;@JsonKey(name: 'sentiment_stats') String? get sentimentStats;@JsonKey(name: 'ai_tag') String? get aiTag;@JsonKey(name: 'ai_region') String? get aiRegion;@JsonKey(name: 'ai_org') String? get aiOrg;@JsonKey(name: 'ai_summary') String? get aiSummary; bool get duplicate;
/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsArticleCopyWith<NewsArticle> get copyWith => _$NewsArticleCopyWithImpl<NewsArticle>(this as NewsArticle, _$identity);

  /// Serializes this NewsArticle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsArticle&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.link, link) || other.link == link)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.keywords, keywords)&&const DeepCollectionEquality().equals(other.creator, creator)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.country, country)&&const DeepCollectionEquality().equals(other.category, category)&&(identical(other.datatype, datatype) || other.datatype == datatype)&&(identical(other.pubDate, pubDate) || other.pubDate == pubDate)&&(identical(other.pubDateTZ, pubDateTZ) || other.pubDateTZ == pubDateTZ)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.sourcePriority, sourcePriority) || other.sourcePriority == sourcePriority)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceIcon, sourceIcon) || other.sourceIcon == sourceIcon)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.sentimentStats, sentimentStats) || other.sentimentStats == sentimentStats)&&(identical(other.aiTag, aiTag) || other.aiTag == aiTag)&&(identical(other.aiRegion, aiRegion) || other.aiRegion == aiRegion)&&(identical(other.aiOrg, aiOrg) || other.aiOrg == aiOrg)&&(identical(other.aiSummary, aiSummary) || other.aiSummary == aiSummary)&&(identical(other.duplicate, duplicate) || other.duplicate == duplicate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,articleId,link,title,description,content,const DeepCollectionEquality().hash(keywords),const DeepCollectionEquality().hash(creator),language,const DeepCollectionEquality().hash(country),const DeepCollectionEquality().hash(category),datatype,pubDate,pubDateTZ,fetchedAt,imageUrl,videoUrl,sourceId,sourceName,sourcePriority,sourceUrl,sourceIcon,sentiment,sentimentStats,aiTag,aiRegion,aiOrg,aiSummary,duplicate]);

@override
String toString() {
  return 'NewsArticle(articleId: $articleId, link: $link, title: $title, description: $description, content: $content, keywords: $keywords, creator: $creator, language: $language, country: $country, category: $category, datatype: $datatype, pubDate: $pubDate, pubDateTZ: $pubDateTZ, fetchedAt: $fetchedAt, imageUrl: $imageUrl, videoUrl: $videoUrl, sourceId: $sourceId, sourceName: $sourceName, sourcePriority: $sourcePriority, sourceUrl: $sourceUrl, sourceIcon: $sourceIcon, sentiment: $sentiment, sentimentStats: $sentimentStats, aiTag: $aiTag, aiRegion: $aiRegion, aiOrg: $aiOrg, aiSummary: $aiSummary, duplicate: $duplicate)';
}


}

/// @nodoc
abstract mixin class $NewsArticleCopyWith<$Res>  {
  factory $NewsArticleCopyWith(NewsArticle value, $Res Function(NewsArticle) _then) = _$NewsArticleCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'article_id') String articleId, String? link, String title, String? description, String? content,@JsonKey(fromJson: _stringListFromJson) List<String> keywords,@JsonKey(fromJson: _stringListFromJson) List<String> creator, String? language,@JsonKey(fromJson: _stringListFromJson) List<String> country,@JsonKey(fromJson: _stringListFromJson) List<String> category, String? datatype,@JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson) DateTime? pubDate,@JsonKey(name: 'pubDateTZ') String? pubDateTZ,@JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson) DateTime? fetchedAt,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'source_id') String? sourceId,@JsonKey(name: 'source_name') String? sourceName,@JsonKey(name: 'source_priority') int? sourcePriority,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'source_icon') String? sourceIcon, String? sentiment,@JsonKey(name: 'sentiment_stats') String? sentimentStats,@JsonKey(name: 'ai_tag') String? aiTag,@JsonKey(name: 'ai_region') String? aiRegion,@JsonKey(name: 'ai_org') String? aiOrg,@JsonKey(name: 'ai_summary') String? aiSummary, bool duplicate
});




}
/// @nodoc
class _$NewsArticleCopyWithImpl<$Res>
    implements $NewsArticleCopyWith<$Res> {
  _$NewsArticleCopyWithImpl(this._self, this._then);

  final NewsArticle _self;
  final $Res Function(NewsArticle) _then;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? articleId = null,Object? link = freezed,Object? title = null,Object? description = freezed,Object? content = freezed,Object? keywords = null,Object? creator = null,Object? language = freezed,Object? country = null,Object? category = null,Object? datatype = freezed,Object? pubDate = freezed,Object? pubDateTZ = freezed,Object? fetchedAt = freezed,Object? imageUrl = freezed,Object? videoUrl = freezed,Object? sourceId = freezed,Object? sourceName = freezed,Object? sourcePriority = freezed,Object? sourceUrl = freezed,Object? sourceIcon = freezed,Object? sentiment = freezed,Object? sentimentStats = freezed,Object? aiTag = freezed,Object? aiRegion = freezed,Object? aiOrg = freezed,Object? aiSummary = freezed,Object? duplicate = null,}) {
  return _then(_self.copyWith(
articleId: null == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as List<String>,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as List<String>,datatype: freezed == datatype ? _self.datatype : datatype // ignore: cast_nullable_to_non_nullable
as String?,pubDate: freezed == pubDate ? _self.pubDate : pubDate // ignore: cast_nullable_to_non_nullable
as DateTime?,pubDateTZ: freezed == pubDateTZ ? _self.pubDateTZ : pubDateTZ // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,sourceName: freezed == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String?,sourcePriority: freezed == sourcePriority ? _self.sourcePriority : sourcePriority // ignore: cast_nullable_to_non_nullable
as int?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceIcon: freezed == sourceIcon ? _self.sourceIcon : sourceIcon // ignore: cast_nullable_to_non_nullable
as String?,sentiment: freezed == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as String?,sentimentStats: freezed == sentimentStats ? _self.sentimentStats : sentimentStats // ignore: cast_nullable_to_non_nullable
as String?,aiTag: freezed == aiTag ? _self.aiTag : aiTag // ignore: cast_nullable_to_non_nullable
as String?,aiRegion: freezed == aiRegion ? _self.aiRegion : aiRegion // ignore: cast_nullable_to_non_nullable
as String?,aiOrg: freezed == aiOrg ? _self.aiOrg : aiOrg // ignore: cast_nullable_to_non_nullable
as String?,aiSummary: freezed == aiSummary ? _self.aiSummary : aiSummary // ignore: cast_nullable_to_non_nullable
as String?,duplicate: null == duplicate ? _self.duplicate : duplicate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsArticle].
extension NewsArticlePatterns on NewsArticle {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsArticle value)  $default,){
final _that = this;
switch (_that) {
case _NewsArticle():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsArticle value)?  $default,){
final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'article_id')  String articleId,  String? link,  String title,  String? description,  String? content, @JsonKey(fromJson: _stringListFromJson)  List<String> keywords, @JsonKey(fromJson: _stringListFromJson)  List<String> creator,  String? language, @JsonKey(fromJson: _stringListFromJson)  List<String> country, @JsonKey(fromJson: _stringListFromJson)  List<String> category,  String? datatype, @JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson)  DateTime? pubDate, @JsonKey(name: 'pubDateTZ')  String? pubDateTZ, @JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson)  DateTime? fetchedAt, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'source_id')  String? sourceId, @JsonKey(name: 'source_name')  String? sourceName, @JsonKey(name: 'source_priority')  int? sourcePriority, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_icon')  String? sourceIcon,  String? sentiment, @JsonKey(name: 'sentiment_stats')  String? sentimentStats, @JsonKey(name: 'ai_tag')  String? aiTag, @JsonKey(name: 'ai_region')  String? aiRegion, @JsonKey(name: 'ai_org')  String? aiOrg, @JsonKey(name: 'ai_summary')  String? aiSummary,  bool duplicate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that.articleId,_that.link,_that.title,_that.description,_that.content,_that.keywords,_that.creator,_that.language,_that.country,_that.category,_that.datatype,_that.pubDate,_that.pubDateTZ,_that.fetchedAt,_that.imageUrl,_that.videoUrl,_that.sourceId,_that.sourceName,_that.sourcePriority,_that.sourceUrl,_that.sourceIcon,_that.sentiment,_that.sentimentStats,_that.aiTag,_that.aiRegion,_that.aiOrg,_that.aiSummary,_that.duplicate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'article_id')  String articleId,  String? link,  String title,  String? description,  String? content, @JsonKey(fromJson: _stringListFromJson)  List<String> keywords, @JsonKey(fromJson: _stringListFromJson)  List<String> creator,  String? language, @JsonKey(fromJson: _stringListFromJson)  List<String> country, @JsonKey(fromJson: _stringListFromJson)  List<String> category,  String? datatype, @JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson)  DateTime? pubDate, @JsonKey(name: 'pubDateTZ')  String? pubDateTZ, @JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson)  DateTime? fetchedAt, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'source_id')  String? sourceId, @JsonKey(name: 'source_name')  String? sourceName, @JsonKey(name: 'source_priority')  int? sourcePriority, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_icon')  String? sourceIcon,  String? sentiment, @JsonKey(name: 'sentiment_stats')  String? sentimentStats, @JsonKey(name: 'ai_tag')  String? aiTag, @JsonKey(name: 'ai_region')  String? aiRegion, @JsonKey(name: 'ai_org')  String? aiOrg, @JsonKey(name: 'ai_summary')  String? aiSummary,  bool duplicate)  $default,) {final _that = this;
switch (_that) {
case _NewsArticle():
return $default(_that.articleId,_that.link,_that.title,_that.description,_that.content,_that.keywords,_that.creator,_that.language,_that.country,_that.category,_that.datatype,_that.pubDate,_that.pubDateTZ,_that.fetchedAt,_that.imageUrl,_that.videoUrl,_that.sourceId,_that.sourceName,_that.sourcePriority,_that.sourceUrl,_that.sourceIcon,_that.sentiment,_that.sentimentStats,_that.aiTag,_that.aiRegion,_that.aiOrg,_that.aiSummary,_that.duplicate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'article_id')  String articleId,  String? link,  String title,  String? description,  String? content, @JsonKey(fromJson: _stringListFromJson)  List<String> keywords, @JsonKey(fromJson: _stringListFromJson)  List<String> creator,  String? language, @JsonKey(fromJson: _stringListFromJson)  List<String> country, @JsonKey(fromJson: _stringListFromJson)  List<String> category,  String? datatype, @JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson)  DateTime? pubDate, @JsonKey(name: 'pubDateTZ')  String? pubDateTZ, @JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson)  DateTime? fetchedAt, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'source_id')  String? sourceId, @JsonKey(name: 'source_name')  String? sourceName, @JsonKey(name: 'source_priority')  int? sourcePriority, @JsonKey(name: 'source_url')  String? sourceUrl, @JsonKey(name: 'source_icon')  String? sourceIcon,  String? sentiment, @JsonKey(name: 'sentiment_stats')  String? sentimentStats, @JsonKey(name: 'ai_tag')  String? aiTag, @JsonKey(name: 'ai_region')  String? aiRegion, @JsonKey(name: 'ai_org')  String? aiOrg, @JsonKey(name: 'ai_summary')  String? aiSummary,  bool duplicate)?  $default,) {final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that.articleId,_that.link,_that.title,_that.description,_that.content,_that.keywords,_that.creator,_that.language,_that.country,_that.category,_that.datatype,_that.pubDate,_that.pubDateTZ,_that.fetchedAt,_that.imageUrl,_that.videoUrl,_that.sourceId,_that.sourceName,_that.sourcePriority,_that.sourceUrl,_that.sourceIcon,_that.sentiment,_that.sentimentStats,_that.aiTag,_that.aiRegion,_that.aiOrg,_that.aiSummary,_that.duplicate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsArticle extends NewsArticle {
  const _NewsArticle({@JsonKey(name: 'article_id') this.articleId = '', this.link, this.title = '', this.description, this.content, @JsonKey(fromJson: _stringListFromJson) final  List<String> keywords = const <String>[], @JsonKey(fromJson: _stringListFromJson) final  List<String> creator = const <String>[], this.language, @JsonKey(fromJson: _stringListFromJson) final  List<String> country = const <String>[], @JsonKey(fromJson: _stringListFromJson) final  List<String> category = const <String>[], this.datatype, @JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson) this.pubDate, @JsonKey(name: 'pubDateTZ') this.pubDateTZ, @JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson) this.fetchedAt, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'video_url') this.videoUrl, @JsonKey(name: 'source_id') this.sourceId, @JsonKey(name: 'source_name') this.sourceName, @JsonKey(name: 'source_priority') this.sourcePriority, @JsonKey(name: 'source_url') this.sourceUrl, @JsonKey(name: 'source_icon') this.sourceIcon, this.sentiment, @JsonKey(name: 'sentiment_stats') this.sentimentStats, @JsonKey(name: 'ai_tag') this.aiTag, @JsonKey(name: 'ai_region') this.aiRegion, @JsonKey(name: 'ai_org') this.aiOrg, @JsonKey(name: 'ai_summary') this.aiSummary, this.duplicate = false}): _keywords = keywords,_creator = creator,_country = country,_category = category,super._();
  factory _NewsArticle.fromJson(Map<String, dynamic> json) => _$NewsArticleFromJson(json);

@override@JsonKey(name: 'article_id') final  String articleId;
@override final  String? link;
@override@JsonKey() final  String title;
@override final  String? description;
@override final  String? content;
 final  List<String> _keywords;
@override@JsonKey(fromJson: _stringListFromJson) List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

 final  List<String> _creator;
@override@JsonKey(fromJson: _stringListFromJson) List<String> get creator {
  if (_creator is EqualUnmodifiableListView) return _creator;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_creator);
}

@override final  String? language;
 final  List<String> _country;
@override@JsonKey(fromJson: _stringListFromJson) List<String> get country {
  if (_country is EqualUnmodifiableListView) return _country;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_country);
}

 final  List<String> _category;
@override@JsonKey(fromJson: _stringListFromJson) List<String> get category {
  if (_category is EqualUnmodifiableListView) return _category;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_category);
}

@override final  String? datatype;
@override@JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson) final  DateTime? pubDate;
@override@JsonKey(name: 'pubDateTZ') final  String? pubDateTZ;
@override@JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson) final  DateTime? fetchedAt;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey(name: 'video_url') final  String? videoUrl;
@override@JsonKey(name: 'source_id') final  String? sourceId;
@override@JsonKey(name: 'source_name') final  String? sourceName;
@override@JsonKey(name: 'source_priority') final  int? sourcePriority;
@override@JsonKey(name: 'source_url') final  String? sourceUrl;
@override@JsonKey(name: 'source_icon') final  String? sourceIcon;
@override final  String? sentiment;
@override@JsonKey(name: 'sentiment_stats') final  String? sentimentStats;
@override@JsonKey(name: 'ai_tag') final  String? aiTag;
@override@JsonKey(name: 'ai_region') final  String? aiRegion;
@override@JsonKey(name: 'ai_org') final  String? aiOrg;
@override@JsonKey(name: 'ai_summary') final  String? aiSummary;
@override@JsonKey() final  bool duplicate;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsArticleCopyWith<_NewsArticle> get copyWith => __$NewsArticleCopyWithImpl<_NewsArticle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsArticleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsArticle&&(identical(other.articleId, articleId) || other.articleId == articleId)&&(identical(other.link, link) || other.link == link)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._keywords, _keywords)&&const DeepCollectionEquality().equals(other._creator, _creator)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._country, _country)&&const DeepCollectionEquality().equals(other._category, _category)&&(identical(other.datatype, datatype) || other.datatype == datatype)&&(identical(other.pubDate, pubDate) || other.pubDate == pubDate)&&(identical(other.pubDateTZ, pubDateTZ) || other.pubDateTZ == pubDateTZ)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.sourcePriority, sourcePriority) || other.sourcePriority == sourcePriority)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceIcon, sourceIcon) || other.sourceIcon == sourceIcon)&&(identical(other.sentiment, sentiment) || other.sentiment == sentiment)&&(identical(other.sentimentStats, sentimentStats) || other.sentimentStats == sentimentStats)&&(identical(other.aiTag, aiTag) || other.aiTag == aiTag)&&(identical(other.aiRegion, aiRegion) || other.aiRegion == aiRegion)&&(identical(other.aiOrg, aiOrg) || other.aiOrg == aiOrg)&&(identical(other.aiSummary, aiSummary) || other.aiSummary == aiSummary)&&(identical(other.duplicate, duplicate) || other.duplicate == duplicate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,articleId,link,title,description,content,const DeepCollectionEquality().hash(_keywords),const DeepCollectionEquality().hash(_creator),language,const DeepCollectionEquality().hash(_country),const DeepCollectionEquality().hash(_category),datatype,pubDate,pubDateTZ,fetchedAt,imageUrl,videoUrl,sourceId,sourceName,sourcePriority,sourceUrl,sourceIcon,sentiment,sentimentStats,aiTag,aiRegion,aiOrg,aiSummary,duplicate]);

@override
String toString() {
  return 'NewsArticle(articleId: $articleId, link: $link, title: $title, description: $description, content: $content, keywords: $keywords, creator: $creator, language: $language, country: $country, category: $category, datatype: $datatype, pubDate: $pubDate, pubDateTZ: $pubDateTZ, fetchedAt: $fetchedAt, imageUrl: $imageUrl, videoUrl: $videoUrl, sourceId: $sourceId, sourceName: $sourceName, sourcePriority: $sourcePriority, sourceUrl: $sourceUrl, sourceIcon: $sourceIcon, sentiment: $sentiment, sentimentStats: $sentimentStats, aiTag: $aiTag, aiRegion: $aiRegion, aiOrg: $aiOrg, aiSummary: $aiSummary, duplicate: $duplicate)';
}


}

/// @nodoc
abstract mixin class _$NewsArticleCopyWith<$Res> implements $NewsArticleCopyWith<$Res> {
  factory _$NewsArticleCopyWith(_NewsArticle value, $Res Function(_NewsArticle) _then) = __$NewsArticleCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'article_id') String articleId, String? link, String title, String? description, String? content,@JsonKey(fromJson: _stringListFromJson) List<String> keywords,@JsonKey(fromJson: _stringListFromJson) List<String> creator, String? language,@JsonKey(fromJson: _stringListFromJson) List<String> country,@JsonKey(fromJson: _stringListFromJson) List<String> category, String? datatype,@JsonKey(name: 'pubDate', fromJson: _dateTimeFromJson) DateTime? pubDate,@JsonKey(name: 'pubDateTZ') String? pubDateTZ,@JsonKey(name: 'fetched_at', fromJson: _dateTimeFromJson) DateTime? fetchedAt,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'source_id') String? sourceId,@JsonKey(name: 'source_name') String? sourceName,@JsonKey(name: 'source_priority') int? sourcePriority,@JsonKey(name: 'source_url') String? sourceUrl,@JsonKey(name: 'source_icon') String? sourceIcon, String? sentiment,@JsonKey(name: 'sentiment_stats') String? sentimentStats,@JsonKey(name: 'ai_tag') String? aiTag,@JsonKey(name: 'ai_region') String? aiRegion,@JsonKey(name: 'ai_org') String? aiOrg,@JsonKey(name: 'ai_summary') String? aiSummary, bool duplicate
});




}
/// @nodoc
class __$NewsArticleCopyWithImpl<$Res>
    implements _$NewsArticleCopyWith<$Res> {
  __$NewsArticleCopyWithImpl(this._self, this._then);

  final _NewsArticle _self;
  final $Res Function(_NewsArticle) _then;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? articleId = null,Object? link = freezed,Object? title = null,Object? description = freezed,Object? content = freezed,Object? keywords = null,Object? creator = null,Object? language = freezed,Object? country = null,Object? category = null,Object? datatype = freezed,Object? pubDate = freezed,Object? pubDateTZ = freezed,Object? fetchedAt = freezed,Object? imageUrl = freezed,Object? videoUrl = freezed,Object? sourceId = freezed,Object? sourceName = freezed,Object? sourcePriority = freezed,Object? sourceUrl = freezed,Object? sourceIcon = freezed,Object? sentiment = freezed,Object? sentimentStats = freezed,Object? aiTag = freezed,Object? aiRegion = freezed,Object? aiOrg = freezed,Object? aiSummary = freezed,Object? duplicate = null,}) {
  return _then(_NewsArticle(
articleId: null == articleId ? _self.articleId : articleId // ignore: cast_nullable_to_non_nullable
as String,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,creator: null == creator ? _self._creator : creator // ignore: cast_nullable_to_non_nullable
as List<String>,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,country: null == country ? _self._country : country // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self._category : category // ignore: cast_nullable_to_non_nullable
as List<String>,datatype: freezed == datatype ? _self.datatype : datatype // ignore: cast_nullable_to_non_nullable
as String?,pubDate: freezed == pubDate ? _self.pubDate : pubDate // ignore: cast_nullable_to_non_nullable
as DateTime?,pubDateTZ: freezed == pubDateTZ ? _self.pubDateTZ : pubDateTZ // ignore: cast_nullable_to_non_nullable
as String?,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,sourceName: freezed == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String?,sourcePriority: freezed == sourcePriority ? _self.sourcePriority : sourcePriority // ignore: cast_nullable_to_non_nullable
as int?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceIcon: freezed == sourceIcon ? _self.sourceIcon : sourceIcon // ignore: cast_nullable_to_non_nullable
as String?,sentiment: freezed == sentiment ? _self.sentiment : sentiment // ignore: cast_nullable_to_non_nullable
as String?,sentimentStats: freezed == sentimentStats ? _self.sentimentStats : sentimentStats // ignore: cast_nullable_to_non_nullable
as String?,aiTag: freezed == aiTag ? _self.aiTag : aiTag // ignore: cast_nullable_to_non_nullable
as String?,aiRegion: freezed == aiRegion ? _self.aiRegion : aiRegion // ignore: cast_nullable_to_non_nullable
as String?,aiOrg: freezed == aiOrg ? _self.aiOrg : aiOrg // ignore: cast_nullable_to_non_nullable
as String?,aiSummary: freezed == aiSummary ? _self.aiSummary : aiSummary // ignore: cast_nullable_to_non_nullable
as String?,duplicate: null == duplicate ? _self.duplicate : duplicate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
