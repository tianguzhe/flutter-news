import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/realtime_estimate.dart';
import '../../data/repositories/fund_estimate_repository.dart';
import '../../data/repositories/fund_estimate_repository_provider.dart';
import '../../data/repositories/fund_holding_repository.dart';
import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';
import '../pages/fund_holding_entry_page.dart';
import '../pages/fund_holding_estimate_page.dart';
import '../utils/fund_holding_display_helpers.dart';
import '../widgets/fund_holding_card.dart';
import '../widgets/fund_holding_detail_sheet.dart';
import '../widgets/fund_holding_portfolio_overview.dart';
import '../widgets/fund_holding_status_pill.dart';
import '../widgets/fund_holdings_by_channel_section.dart';

const fundHoldingPreviewGroup = 'Fund holding';

final _previewHoldings = <FundHoldingInput>[
  FundHoldingInput(
    id: 1,
    code: '000171',
    purchaseDate: DateTime(2026, 1, 8),
    shares: 1000,
    channel: '天天基金',
    purchaseNav: 2.00,
    fee: 1.5,
  ),
  FundHoldingInput(
    id: 2,
    code: '000171',
    purchaseDate: DateTime(2026, 3, 12),
    shares: 520,
    channel: '天天基金',
    purchaseNav: 2.08,
    fee: 0,
  ),
  FundHoldingInput(
    id: 3,
    code: '000385',
    purchaseDate: DateTime(2026, 5, 18),
    shares: 48263.58,
    channel: '支付宝',
    purchaseNav: 1.895,
    fee: 0,
  ),
];

const _previewEstimate = RealtimeEstimate(
  code: '000171',
  name: '易方达裕丰回报债券A',
  prevNavDate: '2026-06-01',
  prevNav: 2.08,
  estNav: 2.10,
  estChangePct: 0.49,
  estTime: '2026-06-02 11:30',
  previousTradingNavDate: '2026-05-29',
  previousTradingNav: 2.09,
);

const _previewNegativeEstimate = RealtimeEstimate(
  code: '000385',
  name: '景顺长城景颐双利债券A',
  prevNavDate: '2026-06-01',
  prevNav: 1.895,
  estNav: 1.892,
  estChangePct: -0.16,
  estTime: '2026-06-02 11:30',
  previousTradingNavDate: '2026-05-29',
  previousTradingNav: 1.898,
);

final _previewEstimates = <int, AsyncValue<FundHoldingEstimate>>{
  1: AsyncData(
    calculateFundHoldingEstimate(
      input: _previewHoldings[0],
      realtimeEstimate: _previewEstimate,
    ),
  ),
  2: AsyncData(
    calculateFundHoldingEstimate(
      input: _previewHoldings[1],
      realtimeEstimate: _previewEstimate,
    ),
  ),
  3: AsyncData(
    calculateFundHoldingEstimate(
      input: _previewHoldings[2],
      realtimeEstimate: _previewNegativeEstimate,
    ),
  ),
};

final _previewEstimateList = _previewEstimates.values
    .whereType<AsyncData<FundHoldingEstimate>>()
    .map((state) => state.value)
    .toList();

Widget fundPreviewWrapper(Widget child) {
  return _FundPreviewDependencies(child: _FundPreviewShell(child: child));
}

Widget fundBoundedPreviewWrapper(Widget child) {
  return _FundPreviewDependencies(
    child: _FundBoundedPreviewShell(child: child),
  );
}

Widget fundPreviewPageWrapper(Widget child) {
  return _FundPreviewDependencies(child: child);
}

PreviewThemeData fundPreviewTheme() {
  return PreviewThemeData(
    materialLight: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      useMaterial3: true,
    ),
    materialDark: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF60A5FA),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Estimate page',
  size: Size(430, 920),
  wrapper: fundPreviewPageWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingEstimatePagePreview() {
  return const FundHoldingEstimatePage();
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Entry page - add',
  size: Size(430, 760),
  wrapper: fundPreviewPageWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingEntryAddPreview() {
  return const FundHoldingEntryPage();
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Entry page - edit',
  size: Size(430, 760),
  wrapper: fundPreviewPageWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingEntryEditPreview() {
  return FundHoldingEntryPage(initialHolding: _previewHoldings.first);
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Portfolio overview',
  size: Size(430, 320),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundPortfolioOverviewPreview() {
  return FundPortfolioOverview(
    holdings: _previewHoldings,
    estimates: _previewEstimateList,
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Portfolio overview - syncing',
  size: Size(430, 300),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundPortfolioOverviewLoadingPreview() {
  return FundPortfolioOverview(holdings: _previewHoldings, estimates: const []);
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holdings by channel',
  size: Size(430, 760),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingsByChannelPreview() {
  return FundHoldingsByChannelSection(
    holdings: _previewHoldings,
    states: _previewEstimates,
    isLoading: false,
    loadError: null,
    onRefresh: (_) {},
    onEdit: (_) {},
    onRemove: (_) {},
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holdings by channel - empty',
  size: Size(430, 360),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingsByChannelEmptyPreview() {
  return FundHoldingsByChannelSection(
    holdings: const [],
    states: const {},
    isLoading: false,
    loadError: null,
    onRefresh: (_) {},
    onEdit: (_) {},
    onRemove: (_) {},
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holding card - data',
  size: Size(430, 116),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingCardDataPreview() {
  return FundHoldingCard(
    holding: _previewHoldings.first,
    state: _previewEstimates[1]!,
    onRefresh: () {},
    onEdit: () {},
    onRemove: () {},
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holding card - loading',
  size: Size(430, 116),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingCardLoadingPreview() {
  return FundHoldingCard(
    holding: _previewHoldings.first,
    state: const AsyncLoading(),
    onRefresh: () {},
    onEdit: () {},
    onRemove: () {},
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holding card - error',
  size: Size(430, 116),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingCardErrorPreview() {
  return FundHoldingCard(
    holding: _previewHoldings.first,
    state: AsyncError(StateError('估值接口暂不可用'), StackTrace.empty),
    onRefresh: () {},
    onEdit: () {},
    onRemove: () {},
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holding detail sheet',
  size: Size(430, 720),
  wrapper: fundBoundedPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingDetailSheetPreview() {
  return FundHoldingDetailSheet(
    holding: _previewHoldings.first,
    state: _previewEstimates[1]!,
    onRefresh: () {},
    onEdit: () {},
    onRemove: () {},
  );
}

@Preview(
  group: fundHoldingPreviewGroup,
  name: 'Holding status pill',
  size: Size(180, 64),
  wrapper: fundPreviewWrapper,
  theme: fundPreviewTheme,
)
Widget fundHoldingStatusPillPreview() {
  final color = fundHoldingReturnColor(1);
  return FundHoldingStatusPill(
    label: '已估算',
    color: color,
    icon: Icons.check_circle_outline,
  );
}

class _FundPreviewDependencies extends StatelessWidget {
  const _FundPreviewDependencies({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        fundEstimateRepositoryProvider.overrideWithValue(
          const _PreviewFundEstimateRepository(),
        ),
        fundHoldingRepositoryProvider.overrideWithValue(
          _PreviewFundHoldingRepository(_previewHoldings),
        ),
      ],
      child: child,
    );
  }
}

class _FundPreviewShell extends StatelessWidget {
  const _FundPreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MaterialApp(
      theme: ThemeData(colorScheme: cs, useMaterial3: true),
      home: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: fundHoldingContentMaxWidth,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FundBoundedPreviewShell extends StatelessWidget {
  const _FundBoundedPreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MaterialApp(
      theme: ThemeData(colorScheme: cs, useMaterial3: true),
      home: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: fundHoldingContentMaxWidth,
                maxHeight: 680,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

final class _PreviewFundEstimateRepository implements FundEstimateRepository {
  const _PreviewFundEstimateRepository();

  @override
  Future<RealtimeEstimate> fetchRealtimeEstimate(String code) async {
    if (code == _previewNegativeEstimate.code) {
      return _previewNegativeEstimate;
    }
    return _previewEstimate;
  }
}

final class _PreviewFundHoldingRepository implements FundHoldingRepository {
  _PreviewFundHoldingRepository(List<FundHoldingInput> holdings)
    : _holdings = [...holdings];

  final List<FundHoldingInput> _holdings;

  @override
  Future<List<FundHoldingInput>> listActiveHoldings() async {
    return [..._holdings];
  }

  @override
  Future<FundHoldingInput> insertHolding(FundHoldingDraft draft) async {
    final holding = _fromDraft(_holdings.length + 1, draft);
    _holdings.add(holding);
    return holding;
  }

  @override
  Future<FundHoldingInput> updateHolding({
    required int id,
    required FundHoldingDraft draft,
  }) async {
    final holding = _fromDraft(id, draft);
    final index = _holdings.indexWhere((item) => item.id == id);
    if (index == -1) {
      _holdings.add(holding);
    } else {
      _holdings[index] = holding;
    }
    return holding;
  }

  @override
  Future<void> softDeleteHolding(int id) async {
    _holdings.removeWhere((holding) => holding.id == id);
  }

  FundHoldingInput _fromDraft(int id, FundHoldingDraft draft) {
    return FundHoldingInput(
      id: id,
      code: draft.code,
      purchaseDate: draft.purchaseDate,
      shares: draft.shares,
      channel: draft.channel,
      purchaseNav: draft.purchaseNav,
      fee: draft.fee,
    );
  }
}
