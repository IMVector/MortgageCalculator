import 'package:flutter/material.dart';

import '../models/loan_comparison_result.dart';
import '../services/mortgage_calculator_service.dart';

/// Combined monthly payment view for commercial + provident fund loans.
class CombinedSummaryView extends StatefulWidget {
  final List<MergedMonthlyPayment> mergedPayments;

  const CombinedSummaryView({super.key, required this.mergedPayments});

  @override
  State<CombinedSummaryView> createState() => _CombinedSummaryViewState();
}

class _CombinedSummaryViewState extends State<CombinedSummaryView> {
  static const int _initialCount = 24;
  bool _isExpanded = false;
  bool _showAll = false;

  List<MergedMonthlyPayment> get _displayed =>
      _showAll || widget.mergedPayments.length <= _initialCount
          ? widget.mergedPayments
          : widget.mergedPayments.sublist(0, _initialCount);

  bool get _hasMore => widget.mergedPayments.length > _initialCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        _buildHeader(context),
        if (_isExpanded) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumnHeaders(context),
                _buildPaymentList(context),
              ],
            ),
          ),
          if (_hasMore && !_showAll) _buildShowAllButton(context),
        ],
      ]),
    );
  }

  // MARK: - Header

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        child: Row(children: [
          const Icon(Icons.table_chart, size: 20),
          const SizedBox(width: 12),
          Text('合并还款明细',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('共 ${widget.mergedPayments.length} 期',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  // MARK: - Column Headers

  Widget _buildColumnHeaders(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.15),
      child: Row(children: [
        SizedBox(width: 32, child: Text('期数', style: style)),
        SizedBox(width: 52, child: Text('日期', style: style)),
        SizedBox(
            width: 70,
            child: Text('合计月供', textAlign: TextAlign.right, style: style)),
        SizedBox(
            width: 65,
            child: Text('商贷月供', textAlign: TextAlign.right, style: style)),
        SizedBox(
            width: 65,
            child: Text('商贷本金', textAlign: TextAlign.right, style: style)),
        SizedBox(
            width: 60,
            child: Text('商贷利息', textAlign: TextAlign.right, style: style)),
        SizedBox(
            width: 65,
            child: Text('公积金月供', textAlign: TextAlign.right, style: style)),
        SizedBox(
            width: 65,
            child: Text('公积金本金', textAlign: TextAlign.right, style: style)),
        SizedBox(
            width: 60,
            child: Text('公积金利息', textAlign: TextAlign.right, style: style)),
      ]),
    );
  }

  // MARK: - Payment List

  Widget _buildPaymentList(BuildContext context) {
    final payments = _displayed;
    return Column(
      children: [
        for (var index = 0; index < payments.length; index++)
          _buildRow(context, payments[index], isEven: index.isEven),
      ],
    );
  }

  // MARK: - Payment Row

  Widget _buildRow(BuildContext context, MergedMonthlyPayment payment,
      {required bool isEven}) {
    final dateStr =
        '${payment.date.year}-${payment.date.month.toString().padLeft(2, '0')}';
    final commText = payment.commercialPayment != null
        ? MortgageCalculatorService.formatCurrency(payment.commercialPayment!)
        : '已还清';
    final provText = payment.providentFundPayment != null
        ? MortgageCalculatorService.formatCurrency(
            payment.providentFundPayment!)
        : '已还清';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isEven
          ? Colors.transparent
          : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.08),
      child: Row(children: [
        SizedBox(
            width: 32,
            child: Text('${payment.id}',
                style: Theme.of(context).textTheme.bodySmall)),
        SizedBox(
            width: 52,
            child: Text(dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        _amountCell(context,
            MortgageCalculatorService.formatCurrency(payment.totalPayment),
            width: 70, fontWeight: FontWeight.w600),
        // 商贷：月供、本金、利息
        _amountCell(context, commText,
            width: 65,
            color: payment.commercialPayment != null
                ? Colors.blue
                : Theme.of(context).colorScheme.onSurfaceVariant),
        _amountCell(
            context,
            payment.commercialPrincipal != null
                ? MortgageCalculatorService.formatCurrency(
                    payment.commercialPrincipal!)
                : '已还清',
            width: 65,
            color: payment.commercialPrincipal != null
                ? Colors.blue
                : Theme.of(context).colorScheme.onSurfaceVariant),
        _amountCell(
            context,
            payment.commercialInterest != null
                ? MortgageCalculatorService.formatCurrency(
                    payment.commercialInterest!)
                : '已还清',
            width: 60,
            color: payment.commercialInterest != null
                ? Colors.orange
                : Theme.of(context).colorScheme.onSurfaceVariant),
        // 公积金：月供、本金、利息
        _amountCell(context, provText,
            width: 65,
            color: payment.providentFundPayment != null
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant),
        _amountCell(
            context,
            payment.providentFundPrincipal != null
                ? MortgageCalculatorService.formatCurrency(
                    payment.providentFundPrincipal!)
                : '已还清',
            width: 65,
            color: payment.providentFundPrincipal != null
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant),
        _amountCell(
            context,
            payment.providentFundInterest != null
                ? MortgageCalculatorService.formatCurrency(
                    payment.providentFundInterest!)
                : '已还清',
            width: 60,
            color: payment.providentFundInterest != null
                ? Colors.orange
                : Theme.of(context).colorScheme.onSurfaceVariant),
      ]),
    );
  }

  Widget _amountCell(BuildContext context, String text,
      {required double width, Color? color, FontWeight? fontWeight}) {
    return SizedBox(
      width: width,
      child: Text(text,
          textAlign: TextAlign.right,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: fontWeight)),
    );
  }

  // MARK: - Show All Button

  Widget _buildShowAllButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextButton(
        onPressed: () => setState(() => _showAll = true),
        child: Text('显示全部（共 ${widget.mergedPayments.length} 期）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}
