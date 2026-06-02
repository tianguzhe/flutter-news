import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_mapper.dart';
import '../models/news_article.dart';
import '../models/news_page.dart';

/// 新闻接口访问层：负责把远端 JSON 转成应用内可用的数据模型。
class NewsApi {
  NewsApi(this._dio);

  /// 统一接口地址，域名来自第 4 课的 DioClient.baseUrl。
  static const _endpoint = '/api/1/latest';

  /// 本地兜底 Key，便于课程演示直接运行。
  static const _fallbackApiKey = 'pub_6d86ed0fa9ad4b318a7c561bf7c6854b';

  /// 优先读取编译期环境变量，未提供时回落到兜底值。
  static const _apiKey = String.fromEnvironment(
    'NEWSDATA_API_KEY',
    defaultValue: _fallbackApiKey,
  );

  final Dio _dio;

  Future<NewsPage> fetchLatest({
    String query = 'ai',
    String category = 'technology',
    String? page,
  }) async {
    try {
      // 组装查询参数并请求 Newsdata 最新新闻接口。
      final response = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: _queryParameters(
          query: query,
          category: category,
          page: page,
        ),
      );
      final body = response.data ?? const <String, dynamic>{};
      _ensureSuccess(body);

      final results = body['results'];
      // 只保留结构正确且 article_id 不为空的文章，避免脏数据进入 UI。
      final articles = results is List
          ? results
                .whereType<Map<String, dynamic>>()
                .map(NewsArticle.fromJson)
                .where((article) => article.articleId.isNotEmpty)
                .toList()
          : <NewsArticle>[];

      return NewsPage(
        articles: articles,
        nextPage: body['nextPage'] as String?,
      );
    } catch (error) {
      // 统一把 DioException 和业务异常转成 ApiException。
      throw mapNetworkError(error);
    }
  }

  Future<NewsArticle> fetchById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {'apikey': _apiKey, 'id': id},
      );
      final body = response.data ?? const <String, dynamic>{};
      _ensureSuccess(body);

      final results = body['results'];
      // 详情接口理论上返回单条结果，这里做边界保护。
      if (results is! List || results.isEmpty) {
        throw const ApiException('没有找到这篇新闻');
      }

      final first = results.first;
      if (first is! Map<String, dynamic>) {
        throw const ApiException('新闻详情格式异常');
      }

      return NewsArticle.fromJson(first);
    } catch (error) {
      throw mapNetworkError(error);
    }
  }

  Map<String, dynamic> _queryParameters({
    required String query,
    required String category,
    String? page,
  }) {
    // 统一维护查询参数，避免调用方散落拼装逻辑。
    final params = <String, dynamic>{
      'apikey': _apiKey,
      'q': query,
      'country': 'cn,hk',
      'category': category,
      'language': 'zh,en',
      'removeduplicate': 1,
    };
    if (page != null) {
      params['page'] = page;
    }
    return params;
  }

  void _ensureSuccess(Map<String, dynamic> body) {
    if (body['status'] == 'success') {
      return;
    }

    // 服务端失败时优先透传后端消息，便于页面展示可读错误。
    final message = body['results'] ?? body['message'] ?? '新闻服务返回异常';
    throw ApiException(message.toString());
  }
}
