import 'package:flutter/material.dart';

import '../../domain/fund_holding_estimate.dart';

const fundHoldingCardRadius = 12.0;
const fundHoldingInnerRadius = 8.0;
const fundHoldingContentMaxWidth = 760.0;

String formatFundHoldingDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatFundHoldingMoney(double value) => value.toStringAsFixed(2);

String formatSignedFundHoldingMoney(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}';
}

String formatFundHoldingPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${(value * 100).toStringAsFixed(2)}%';
}

String formatSignedFundHoldingPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String formatFundHoldingNumber(double value, int fractionDigits) =>
    value.toStringAsFixed(fractionDigits);

String formatEditableFundHoldingNumber(double value) =>
    value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');

double fundHoldingYesterdayValue(FundHoldingEstimate estimate) =>
    estimate.realtimeEstimate.prevNav * estimate.input.shares;

double fundHoldingConfirmedTotalReturn(FundHoldingEstimate estimate) =>
    fundHoldingYesterdayValue(estimate) - estimate.cost;

double fundHoldingYesterdayActualReturn(FundHoldingEstimate estimate) {
  final previousNav = estimate.realtimeEstimate.previousTradingNav;
  if (previousNav == null) return 0;
  return (estimate.realtimeEstimate.prevNav - previousNav) *
      estimate.input.shares;
}

double fundHoldingTodayEstimatedReturn(FundHoldingEstimate estimate) =>
    (estimate.realtimeEstimate.estNav - estimate.realtimeEstimate.prevNav) *
    estimate.input.shares;

double fundHoldingReturnRate(double totalReturn, double cost) {
  if (cost == 0) return 0;
  return totalReturn / cost;
}

Color fundHoldingReturnColor(double value) =>
    value >= 0 ? Colors.red.shade700 : Colors.green.shade700;

Color fundHoldingSignedColor(double value, ColorScheme colorScheme) {
  if (value == 0) return colorScheme.onSurfaceVariant;
  return fundHoldingReturnColor(value);
}

Color fundHoldingEstimateAccent(ColorScheme colorScheme) =>
    colorScheme.tertiary;

Color tintFundHoldingSurface(Color tint, Color surface, int alpha) =>
    Color.alphaBlend(tint.withAlpha(alpha), surface);

// ─────────────────────────────────────────────────────────────────────────────
// Channel accent palette, assigned by visible group order.
// ─────────────────────────────────────────────────────────────────────────────

const _fundHoldingChannelAccents = [
  Color(0xFF2563EB), // Blue
  Color(0xFF0F766E), // Teal
  Color(0xFF7C3AED), // Violet
  Color(0xFFB45309), // Amber
  Color(0xFF0369A1), // Sky
  Color(0xFFBE123C), // Rose
  Color(0xFF15803D), // Green
  Color(0xFFC2410C), // Orange
  Color(0xFF6D28D9), // Purple
  Color(0xFF0E7490), // Cyan
  Color(0xFF9D174D), // Pink
  Color(0xFF4F46E5), // Indigo
  Color(0xFF047857), // Emerald
  Color(0xFFA21CAF), // Fuchsia
  Color(0xFF4338CA), // Deep indigo
  Color(0xFF92400E), // Ochre
  Color(0xFF1D4ED8), // Royal blue
  Color(0xFF047481), // Deep cyan
  Color(0xFFB91C1C), // Red
  Color(0xFF166534), // Forest
];

Color fundHoldingChannelAccent(int index) =>
    _fundHoldingChannelAccents[index % _fundHoldingChannelAccents.length];
