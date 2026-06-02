import 'package:dio/dio.dart';

class HeaderInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['User-Agent'] =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/537.36';
    super.onRequest(options, handler);
  }
}
