import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/data_manager.dart';
import '../services/import_export_service.dart';
import '../services/mortgage_calculator_service.dart';
import '../widgets/combined_summary_view.dart';
import '../widgets/loan_detail_section.dart';
import '../widgets/savings_card.dart';
import '../widgets/summary_cards.dart';
import 'prepayment_sheet.dart';

class ResultScreen extends StatelessWidget {
  final LoanCalculationResult? result;
  final LoanComparisonResult? comparisonResult;
  final VoidCallback onRecalculate;

  const ResultScreen({
    super.key,
    required this.result,
    this.comparisonResult,
    required this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return _buildEmptyState(context);
    }

    final data = context.watch<DataManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('计算结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResult(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 汇总卡片
            SummaryCards(
              result: result!,
              comparisonResult: comparisonResult,
            ),

            // 节省卡片（有提前还款时显示）
            if (comparisonResult?.hasPrepayment == true) ...[
              const SizedBox(height: 16),
              SavingsCard(comparisonResult: comparisonResult!),
            ],

            // 汇总视角（合并月供明细）
            if (comparisonResult != null) ...[
              const SizedBox(height: 16),
              CombinedSummaryView(
                mergedPayments: comparisonResult!.mergedMonthlyPayments,
              ),
            ],

            const SizedBox(height: 16),

            // 提前还款区域
            if (data.commercialLoan != null || data.providentFundLoan != null)
              _PrepaymentSection(
                onRecalculate: onRecalculate,
              ),

            // 商业贷款详情
            if (result!.commercialSegments.isNotEmpty) ...[
              const SizedBox(height: 16),
              LoanDetailSection(
                title: '商业贷款',
                color: Colors.blue,
                segments: result!.commercialSegments,
                monthlyPayments: result!.commercialMonthlyPayments,
              ),
            ],

            // 公积金贷款详情
            if (result!.providentFundSegments.isNotEmpty) ...[
              const SizedBox(height: 16),
              LoanDetailSection(
                title: '公积金贷款',
                color: Colors.green,
                segments: result!.providentFundSegments,
                monthlyPayments: result!.providentFundMonthlyPayments,
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计算结果')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.house_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '开始计算您的房贷',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请在「贷款输入」页面填写贷款信息',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareResult(BuildContext context) {
    if (result == null) return;
    final text = ImportExportService.exportToText(result!);
    Share.share(text);
  }
}

// MARK: - 提前还款区域

class _PrepaymentSection extends StatefulWidget {
  final VoidCallback onRecalculate;

  const _PrepaymentSection({required this.onRecalculate});

  @override
  State<_PrepaymentSection> createState() => _PrepaymentSectionState();
}

class _PrepaymentSectionState extends State<_PrepaymentSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataManager>();
    final prepayments = data.prepayments.toList()
      ..sort((a, b) => a.prepaymentDate.compareTo(b.prepaymentDate));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 标题栏
          InkWell(
            onTap: () => _showAddSheet(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '添加提前还款',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (prepayments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${prepayments.length} 条',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (prepayments.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // 提前还款列表
          if (prepayments.isNotEmpty && _isExpanded) ...[
            const Divider(height: 1),
            ...prepayments.take(10).map((node) => _PrepaymentMiniCard(
              node: node,
              onEdit: () => _showEditSheet(context, node),
              onDelete: () {
                data.removePrepayment(node.id);
                widget.onRecalculate();
              },
            )),
            if (prepayments.length > 10)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '还有 ${prepayments.length - 10} 条记录...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final data = context.read<DataManager>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPrepaymentSheet(
        commercialLoan: data.commercialLoan,
        providentFundLoan: data.providentFundLoan,
        onSave: widget.onRecalculate,
      ),
    );
  }

  void _showEditSheet(BuildContext context, PrepaymentNode node) {
    final data = context.read<DataManager>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPrepaymentSheet(
        node: node,
        commercialLoan: data.commercialLoan,
        providentFundLoan: data.providentFundLoan,
        onSave: widget.onRecalculate,
      ),
    );
  }
}

class _PrepaymentMiniCard extends StatelessWidget {
  final PrepaymentNode node;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrepaymentMiniCard({
    required this.node,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${node.prepaymentDate.year}-${node.prepaymentDate.month.toString().padLeft(2, '0')}-${node.prepaymentDate.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: node.targetLoanType == LoanType.commercial
                              ? Colors.blue.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          node.targetLoanType.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: node.targetLoanType == LoanType.commercial
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${MortgageCalculatorService.formatCurrency(node.prepaymentAmount)} 元',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        node.prepaymentType.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
