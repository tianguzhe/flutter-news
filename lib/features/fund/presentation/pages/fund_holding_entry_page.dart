import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fund_holding_repository_provider.dart';
import '../../domain/fund_holding_estimate.dart';
import '../utils/fund_holding_display_helpers.dart';

class FundHoldingEntryPage extends ConsumerStatefulWidget {
  const FundHoldingEntryPage({super.key, this.initialHolding});

  final FundHoldingInput? initialHolding;

  @override
  ConsumerState<FundHoldingEntryPage> createState() =>
      _FundHoldingEntryPageState();
}

class _FundHoldingEntryPageState extends ConsumerState<FundHoldingEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _sharesController = TextEditingController();
  final _channelController = TextEditingController();
  final _purchaseNavController = TextEditingController();
  final _feeController = TextEditingController(text: '0');

  DateTime? _purchaseDate;
  var _isSaving = false;

  bool get _isEditing => widget.initialHolding != null;

  @override
  void initState() {
    super.initState();
    final holding = widget.initialHolding;
    if (holding == null) return;
    _codeController.text = holding.code;
    _sharesController.text = formatEditableFundHoldingNumber(holding.shares);
    _channelController.text = holding.channel;
    _purchaseNavController.text = formatEditableFundHoldingNumber(
      holding.purchaseNav,
    );
    _feeController.text = formatEditableFundHoldingNumber(holding.fee);
    _purchaseDate = holding.purchaseDate;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _sharesController.dispose();
    _channelController.dispose();
    _purchaseNavController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _purchaseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择购买时间')));
      return;
    }

    final draft = FundHoldingDraft(
      code: _codeController.text.trim(),
      purchaseDate: _purchaseDate!,
      shares: double.parse(_sharesController.text.trim()),
      channel: _channelController.text.trim(),
      purchaseNav: double.parse(_purchaseNavController.text.trim()),
      fee: double.parse(_feeController.text.trim()),
    );

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(fundHoldingRepositoryProvider);
      final input = _isEditing
          ? await repository.updateHolding(
              id: widget.initialHolding!.id,
              draft: draft,
            )
          : await repository.insertHolding(draft);
      if (!mounted) return;
      Navigator.of(context).pop(input);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存持仓失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑持仓' : '新增持仓'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _EntryFormCard(
              formKey: _formKey,
              codeController: _codeController,
              sharesController: _sharesController,
              channelController: _channelController,
              purchaseNavController: _purchaseNavController,
              feeController: _feeController,
              purchaseDate: _purchaseDate,
              onPickPurchaseDate: _pickPurchaseDate,
              onSubmit: _submit,
              isSaving: _isSaving,
              isEditing: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryFormCard extends StatelessWidget {
  const _EntryFormCard({
    required this.formKey,
    required this.codeController,
    required this.sharesController,
    required this.channelController,
    required this.purchaseNavController,
    required this.feeController,
    required this.purchaseDate,
    required this.onPickPurchaseDate,
    required this.onSubmit,
    required this.isSaving,
    required this.isEditing,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController sharesController;
  final TextEditingController channelController;
  final TextEditingController purchaseNavController;
  final TextEditingController feeController;
  final DateTime? purchaseDate;
  final VoidCallback onPickPurchaseDate;
  final VoidCallback onSubmit;
  final bool isSaving;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(fundHoldingCardRadius),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note : Icons.add_chart,
                    size: 22,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? '编辑持仓信息' : '新增持仓信息',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '按实际购买记录填写，保存后自动估算收益',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(120)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: '基金代码',
                      hintText: '例如 000171',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      prefixIcon: Icon(Icons.tag, color: cs.primary, size: 20),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: _validateFundCode,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: onPickPurchaseDate,
                    borderRadius: BorderRadius.circular(fundHoldingInnerRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: purchaseDate != null ? cs.primary : cs.outline,
                          width: purchaseDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: purchaseDate != null
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              purchaseDate == null
                                  ? '选择购买时间'
                                  : formatFundHoldingDate(purchaseDate!),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: purchaseDate != null
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          if (purchaseDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '已选',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sharesController,
                    decoration: InputDecoration(
                      labelText: '份额',
                      hintText: '例如 1000.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.stacked_bar_chart,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    validator: (v) => _validatePositiveNumber(v, '请输入份额'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: channelController,
                    decoration: InputDecoration(
                      labelText: '渠道',
                      hintText: '例如 支付宝 / 天天基金 / 银行',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '请输入渠道' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: purchaseNavController,
                    decoration: InputDecoration(
                      labelText: '购买时净值',
                      hintText: '例如 2.0820',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.price_change,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    validator: (v) => _validatePositiveNumber(v, '请输入购买时净值'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: feeController,
                    decoration: InputDecoration(
                      labelText: '手续费',
                      hintText: '没有就填 0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    validator: _validateNonNegativeNumber,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          fundHoldingInnerRadius,
                        ),
                      ),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isEditing
                                ? Icons.save_outlined
                                : Icons.add_circle_outline,
                          ),
                    label: Text(
                      isEditing ? '保存并计算' : '添加并计算',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text input formatter
// ─────────────────────────────────────────────────────────────────────────────

class _DecimalTextInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Validators
// ─────────────────────────────────────────────────────────────────────────────

String? _validateFundCode(String? value) {
  final text = value?.trim() ?? '';
  if (!RegExp(r'^\d{6}$').hasMatch(text)) {
    return '请输入 6 位基金代码';
  }
  return null;
}

String? _validatePositiveNumber(String? value, String emptyMessage) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return emptyMessage;
  final number = double.tryParse(text);
  if (number == null || number <= 0) return '请输入大于 0 的数字';
  return null;
}

String? _validateNonNegativeNumber(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '请输入手续费，没有就填 0';
  final number = double.tryParse(text);
  if (number == null || number < 0) return '请输入不小于 0 的数字';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatters & helpers
