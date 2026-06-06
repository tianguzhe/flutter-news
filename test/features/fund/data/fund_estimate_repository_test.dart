import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/core/network/api_exception.dart';
import 'package:untitled/core/network/dio_client.dart';
import 'package:untitled/features/fund/data/repositories/fund_estimate_repository.dart';
import 'package:untitled/features/fund/data/services/fund_estimate_api.dart';

void main() {
  test(
    'FundEstimateRepositoryImpl delegates loading to the API service',
    () async {
      final dio = Dio();
      Uri? requestedUri;
      Uri? historyUri;
      String? accept;
      String? userAgent;
      String? referer;
      dio.interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) {
            final isHistory = options.uri.host == 'api.fund.eastmoney.com';
            if (isHistory) {
              historyUri = options.uri;
            } else {
              requestedUri = options.uri;
              accept = options.headers['Accept'] as String?;
              userAgent = options.headers['User-Agent'] as String?;
              referer = options.headers['Referer'] as String?;
            }
            final body = isHistory
                ? '{"Data":{"LSJZList":['
                      '{"FSRQ":"2026-06-01","DWJZ":"2.0820"},'
                      '{"FSRQ":"2026-05-29","DWJZ":"2.0910"}'
                      ']}}'
                : 'jsonpgz({"fundcode":"000171","name":"易方达裕丰回报债券A",'
                      '"jzrq":"2026-06-01","dwjz":"2.0820","gsz":"2.0922",'
                      '"gszzl":"0.49","gztime":"2026-06-02 11:30"});';
            handler.resolve(
              Response<List<int>>(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(body),
              ),
            );
          },
        ),
      );
      final api = FundEstimateApi(dio);
      final repository = FundEstimateRepositoryImpl(api);

      final estimate = await repository.fetchRealtimeEstimate('000171');

      expect(estimate.code, '000171');
      expect(estimate.name, '易方达裕丰回报债券A');
      expect(estimate.previousTradingNavDate, '2026-05-29');
      expect(estimate.previousTradingNav, closeTo(2.0910, 1e-9));
      expect(requestedUri?.toString(), endsWith('/000171.js'));
      expect(historyUri?.path, '/f10/lsjz');
      expect(accept, contains('application/javascript'));
      expect(userAgent, isNotEmpty);
      expect(referer, 'https://fund.eastmoney.com/000171.html');
    },
  );

  test('FundEstimateApi reports non-200 fundgz responses', () async {
    final dio = Dio();
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              statusCode: 404,
              data: const [],
            ),
          );
        },
      ),
    );
    final api = FundEstimateApi(dio);

    await expectLater(
      api.fetchRealtimeEstimate('000000'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', 'fundgz HTTP 404')
            .having((error) => error.statusCode, 'statusCode', 404),
      ),
    );
  });

  test(
    'FundEstimateApi overrides global JSON accept header for fundgz',
    () async {
      final dio = DioClient.create();
      Uri? requestedUri;
      String? accept;
      String? referer;
      dio.interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) {
            final isHistory = options.uri.host == 'api.fund.eastmoney.com';
            if (!isHistory) {
              requestedUri = options.uri;
              accept = options.headers['Accept'] as String?;
              referer = options.headers['Referer'] as String?;
            }
            final body = isHistory
                ? '{"Data":{"LSJZList":['
                      '{"FSRQ":"2026-06-01","DWJZ":"1.0785"},'
                      '{"FSRQ":"2026-05-29","DWJZ":"1.0784"}'
                      ']}}'
                : 'jsonpgz({"fundcode":"020262","name":"平安鑫惠90天持有债券A",'
                      '"jzrq":"2026-06-01","dwjz":"1.0785","gsz":"1.0785",'
                      '"gszzl":"0.00","gztime":"2026-06-02 15:00"});';
            handler.resolve(
              Response<List<int>>(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(body),
              ),
            );
          },
        ),
      );
      final api = FundEstimateApi(dio);

      final estimate = await api.fetchRealtimeEstimate('020262');

      expect(estimate.code, '020262');
      expect(estimate.name, '平安鑫惠90天持有债券A');
      expect(requestedUri?.toString(), endsWith('/020262.js'));
      expect(accept, contains('application/javascript'));
      expect(accept, isNot('application/json'));
      expect(referer, 'https://fund.eastmoney.com/020262.html');
    },
  );

  test(
    'FundEstimateApi uses newer historical net value as confirmed nav',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) {
            final isHistory = options.uri.host == 'api.fund.eastmoney.com';
            final body = isHistory
                ? '{"Data":{"LSJZList":['
                      '{"FSRQ":"2026-06-02","DWJZ":"2.1200"},'
                      '{"FSRQ":"2026-06-01","DWJZ":"2.0800"},'
                      '{"FSRQ":"2026-05-29","DWJZ":"2.0900"}'
                      ']}}'
                : 'jsonpgz({"fundcode":"000171","name":"易方达裕丰回报债券A",'
                      '"jzrq":"2026-06-01","dwjz":"2.0800","gsz":"2.1000",'
                      '"gszzl":"0.96","gztime":"2026-06-02 14:30"});';
            handler.resolve(
              Response<List<int>>(
                requestOptions: options,
                statusCode: 200,
                data: utf8.encode(body),
              ),
            );
          },
        ),
      );
      final api = FundEstimateApi(dio);

      final estimate = await api.fetchRealtimeEstimate('000171');

      expect(estimate.confirmedNavDate, '2026-06-02');
      expect(estimate.confirmedNav, closeTo(2.1200, 1e-9));
      expect(estimate.previousTradingNavDate, '2026-05-29');
      expect(estimate.previousTradingNav, closeTo(2.0900, 1e-9));
      expect(estimate.valuationNav, closeTo(2.1200, 1e-9));
    },
  );

  test(
    'FundEstimateApi rejects invalid fund codes before network requests',
    () {
      final api = FundEstimateApi(Dio());

      expect(
        () => api.fetchRealtimeEstimate('abc'),
        throwsA(isA<ArgumentError>()),
      );
    },
  );
}
