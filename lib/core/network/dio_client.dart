import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

import '../log/talker.dart';
import 'interceptor/header_interceptors.dart';

/// Dio 工厂：
/// 统一创建 HTTP 客户端，集中管理超时、基础地址与默认请求头。
class DioClient {
  const DioClient._();

  /// API 根地址，所有请求 path 都会拼接在该地址之后。
  static const baseUrl = 'https://newsdata.io';

  /// 创建一个具备默认网络配置的 Dio 实例。
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // 连接超时：建立 TCP/SSL 连接的最长等待时间。
        connectTimeout: const Duration(seconds: 10),
        // 接收超时：服务端返回数据的最长等待时间。
        receiveTimeout: const Duration(seconds: 30),
        // 发送超时：上传请求体的最长等待时间。
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(HeaderInterceptors());

    if (kDebugMode) {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: true,
            printResponseMessage: true,
          ),
        ),
      );
    }

    return dio;
  }
}
