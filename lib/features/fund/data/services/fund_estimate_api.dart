import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_mapper.dart';
import '../models/realtime_estimate.dart';
import 'fund_estimate_exception.dart';
import 'fund_estimate_parser.dart';

/// 东方财富 fundgz 基金盘中估值接口访问层。
final class FundEstimateApi {
  const FundEstimateApi(this._dio);

  static const _baseUrl = 'https://fundgz.1234567.com.cn/js';
  static const _scriptAcceptHeader =
      'application/javascript, text/javascript, '
      'application/x-javascript, */*';
  static const _browserUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/125.0.0.0 Safari/537.36';
  static final _fundCodePattern = RegExp(r'^\d{6}$');

  final Dio _dio;

  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) async {
    final trimmedCode = code.trim();
    if (!_fundCodePattern.hasMatch(trimmedCode)) {
      throw ArgumentError('fund code must be a 6-digit string');
    }

    try {
      final response = await _dio.get<Object>(
        '$_baseUrl/$trimmedCode.js',
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
          headers: {
            Headers.acceptHeader: _scriptAcceptHeader,
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'User-Agent': _browserUserAgent,
            'Referer': 'https://fund.eastmoney.com/$trimmedCode.html',
            'Sec-Fetch-Dest': 'script',
            'Sec-Fetch-Mode': 'no-cors',
            'Sec-Fetch-Site': 'cross-site',
          },
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200) {
        throw ApiException('fundgz HTTP $statusCode', statusCode: statusCode);
      }

      return parseFundEstimateJsonp(
        _decodeBody(response.data),
        code: trimmedCode,
      );
    } on FundEstimateException catch (error) {
      throw ApiException(error.message);
    } catch (error) {
      throw mapNetworkError(error);
    }
  }

  String _decodeBody(Object? data) {
    return switch (data) {
      List<int> bytes => utf8.decode(bytes),
      String text => text,
      _ => throw const ApiException('fundgz 响应格式异常'),
    };
  }
}
