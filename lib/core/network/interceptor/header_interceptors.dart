import 'package:dio/dio.dart';

class HeaderInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['User-Agent'] = 'untitled/1.0.0';
    super.onRequest(options, handler);
  }
}
