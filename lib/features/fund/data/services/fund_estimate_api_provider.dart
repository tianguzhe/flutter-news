import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/dio_provider.dart';
import 'fund_estimate_api.dart';

part 'fund_estimate_api_provider.g.dart';

@Riverpod(keepAlive: true)
/// Provides the fund estimate API service.
FundEstimateApi fundEstimateApi(Ref ref) {
  return FundEstimateApi(ref.watch(dioProvider));
}
