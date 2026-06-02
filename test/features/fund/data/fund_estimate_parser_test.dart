import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/features/fund/data/services/fund_estimate_exception.dart';
import 'package:untitled/features/fund/data/services/fund_estimate_parser.dart';

void main() {
  group('parseFundEstimateJsonp', () {
    test('parses a normal jsonp response', () {
      const body =
          'jsonpgz({"fundcode":"000171","name":"易方达裕丰回报债券A",'
          '"jzrq":"2026-06-01","dwjz":"2.0820","gsz":"2.0922",'
          '"gszzl":"0.49","gztime":"2026-06-02 11:30"});';

      final estimate = parseFundEstimateJsonp(body);

      expect(estimate.code, '000171');
      expect(estimate.name, '易方达裕丰回报债券A');
      expect(estimate.prevNavDate, '2026-06-01');
      expect(estimate.prevNav, closeTo(2.0820, 1e-9));
      expect(estimate.estNav, closeTo(2.0922, 1e-9));
      expect(estimate.estChangePct, closeTo(0.49, 1e-9));
      expect(estimate.estTime, '2026-06-02 11:30');
      expect(estimate.isUp, isTrue);
    });

    test('preserves Chinese text when caller decodes body bytes as utf8', () {
      const body =
          'jsonpgz({"fundcode":"000171","name":"易方达裕丰回报债券A",'
          '"jzrq":"2026-06-01","dwjz":"2.0820","gsz":"2.0922",'
          '"gszzl":"0.49","gztime":"2026-06-02 11:30"});';
      final decoded = utf8.decode(utf8.encode(body));

      final estimate = parseFundEstimateJsonp(decoded);

      expect(estimate.name, '易方达裕丰回报债券A');
    });

    test('throws when jsonp wrapper is empty', () {
      expect(
        () => parseFundEstimateJsonp('jsonpgz();', code: '000171'),
        throwsA(isA<FundEstimateException>()),
      );
    });

    test('throws when number fields are invalid', () {
      const body =
          'jsonpgz({"fundcode":"000171","name":"易方达裕丰回报债券A",'
          '"jzrq":"2026-06-01","dwjz":"bad","gsz":"2.0922",'
          '"gszzl":"0.49","gztime":"2026-06-02 11:30"});';

      expect(
        () => parseFundEstimateJsonp(body),
        throwsA(isA<FundEstimateException>()),
      );
    });
  });

  group('parseHistoricalNavList', () {
    test('parses recent net values in response order', () {
      const body =
          '{"Data":{"LSJZList":['
          '{"FSRQ":"2026-06-01","DWJZ":"1.8950"},'
          '{"FSRQ":"2026-05-29","DWJZ":"1.8980"}'
          ']}}';

      final history = parseHistoricalNavList(body);

      expect(history, hasLength(2));
      expect(history[0].date, '2026-06-01');
      expect(history[0].nav, closeTo(1.8950, 1e-9));
      expect(history[1].date, '2026-05-29');
      expect(history[1].nav, closeTo(1.8980, 1e-9));
    });
  });
}
