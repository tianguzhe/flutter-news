import 'dart:convert';

import '../models/realtime_estimate.dart';
import 'fund_estimate_exception.dart';

/// 剥离 `jsonpgz(...)` 包裹并解析基金估值。
RealtimeEstimate parseFundEstimateJsonp(String body, {String code = ''}) {
  final trimmed = body.trim();
  final open = trimmed.indexOf('(');
  final close = trimmed.lastIndexOf(')');
  final json = open >= 0 && close > open
      ? trimmed.substring(open + 1, close).trim()
      : '';

  if (json.isEmpty) {
    final tag = code.isEmpty ? '' : ' [$code]';
    throw FundEstimateException('无实时估值数据（代码无效 / 货币基金 / 暂未开盘）$tag');
  }

  final Map<String, dynamic> raw;
  try {
    raw = jsonDecode(json) as Map<String, dynamic>;
  } on FormatException {
    throw FundEstimateException('解析 fundgz 估值 JSON 失败: $json');
  } on TypeError {
    throw FundEstimateException('解析 fundgz 估值 JSON 失败: $json');
  }

  return RealtimeEstimate(
    code: raw['fundcode']?.toString() ?? '',
    name: raw['name']?.toString() ?? '',
    prevNavDate: raw['jzrq']?.toString() ?? '',
    prevNav: _parseDouble(raw['dwjz'], 'dwjz'),
    estNav: _parseDouble(raw['gsz'], 'gsz'),
    estChangePct: _parseDouble(raw['gszzl'], 'gszzl'),
    estTime: raw['gztime']?.toString() ?? '',
  );
}

double _parseDouble(Object? value, String field) {
  final text = value?.toString().trim() ?? '';
  final number = double.tryParse(text);
  if (number == null) {
    throw FundEstimateException('估值字段 $field 非法数值: "$text"');
  }
  return number;
}
