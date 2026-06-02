import '../models/realtime_estimate.dart';
import '../services/fund_estimate_api.dart';

/// Data-layer boundary for fund realtime estimates.
abstract interface class FundEstimateRepository {
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code);
}

final class FundEstimateRepositoryImpl implements FundEstimateRepository {
  const FundEstimateRepositoryImpl(this._api);

  final FundEstimateApi _api;

  @override
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) {
    return _api.fetchRealtimeEstimate(code);
  }
}
