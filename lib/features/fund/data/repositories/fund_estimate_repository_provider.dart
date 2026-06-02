import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/fund_estimate_api_provider.dart';
import 'fund_estimate_repository.dart';

part 'fund_estimate_repository_provider.g.dart';

@Riverpod(keepAlive: true)
/// Provides the fund estimate repository.
FundEstimateRepository fundEstimateRepository(Ref ref) {
  return FundEstimateRepositoryImpl(ref.watch(fundEstimateApiProvider));
}
