import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/data_manager.dart';
import '../services/import_export_service.dart';
import '../services/mortgage_calculator_service.dart';
import 'prepayment_sheet.dart';

class ResultScreen extends StatelessWidget {
  final LoanCalculationResult? result;
  final VoidCallback onRecalculate;

  const ResultScreen({
    super.key,
    required this.result,
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
            _SummaryCards(result: result!),

            const SizedBox(height: 16),

            // 提前还款区域
            if (data.commercialLoan != null || data.providentFundLoan != null)
              _PrepaymentSection(
                onRecalculate: onRecalculate,
              ),

            // 商业贷款详情
            if (result!.commercialSegments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _LoanDetailSection(
                title: '商业贷款',
                color: Colors.blue,
                segments: result!.commercialSegments,
                monthlyPayments: result!.commercialMonthlyPayments,
              ),
            ],

            // 公积金贷款详情
            if (result!.providentFundSegments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _LoanDetailSection(
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

// MARK: - 汇总卡片

class _SummaryCards extends StatelessWidget {
  final LoanCalculationResult result;

  const _SummaryCards({required this.result});

  @override
  Widget build(BuildContext context) {
    final totalPrincipal = result.totalPrincipal;
    final totalInterest = result.totalInterest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 总贷款金额和总利息
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    title: '总贷款金额',
                    value: MortgageCalculatorService.formatCurrency(totalPrincipal),
                    subtitle: '元',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: VerticalDivider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    title: '总利息',
                    value: MortgageCalculatorService.formatCurrency(totalInterest),
                    subtitle: '元',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 各贷款月供
            Row(
              children: [
                if (result.commercialMonthlyPayments.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '商业贷款',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MortgageCalculatorService.formatCurrency(
                            result.commercialMonthlyPayments.first.monthlyPayment,
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '元/月',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (result.providentFundMonthlyPayments.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '公积金贷款',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MortgageCalculatorService.formatCurrency(
                            result.providentFundMonthlyPayments.first.monthlyPayment,
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '元/月',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // 合计月供（两种贷款都有时显示）
            if (result.commercialMonthlyPayments.isNotEmpty &&
                result.providentFundMonthlyPayments.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Text(
                    '合计月供',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${MortgageCalculatorService.formatCurrency(
                      result.commercialMonthlyPayments.first.monthlyPayment +
                          result.providentFundMonthlyPayments.first.monthlyPayment,
                    )} 元/月',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
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

// MARK: - 贷款详情区块

class _LoanDetailSection extends StatefulWidget {
  final String title;
  final Color color;
  final List<RepaymentSegment> segments;
  final List<MonthlyPayment> monthlyPayments;

  const _LoanDetailSection({
    required this.title,
    required this.color,
    required this.segments,
    required this.monthlyPayments,
  });

  @override
  State<_LoanDetailSection> createState() => _LoanDetailSectionState();
}

class _LoanDetailSectionState extends State<_LoanDetailSection> {
  bool _isSectionExpanded = true;
  final Set<int> _expandedSegmentMonths = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 区块头部
          InkWell(
            onTap: () {
              setState(() {
                _isSectionExpanded = !_isSectionExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.monthlyPayments.length}期',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isSectionExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // 区块内容
          if (_isSectionExpanded)
            ...widget.segments.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              final isLast = index == widget.segments.length - 1;
              final isExpanded = _expandedSegmentMonths.contains(segment.startMonth);
              final segmentPayments = widget.monthlyPayments
                  .where((p) => p.id >= segment.startMonth && p.id <= segment.endMonth)
                  .toList();

              return _CollapsibleSegmentRow(
                segment: segment,
                color: widget.color,
                monthlyPayments: segmentPayments,
                isExpanded: isExpanded,
                isLast: isLast,
                onToggle: () {
                  setState(() {
                    if (_expandedSegmentMonths.contains(segment.startMonth)) {
                      _expandedSegmentMonths.remove(segment.startMonth);
                    } else {
                      _expandedSegmentMonths.add(segment.startMonth);
                    }
                  });
                },
              );
            }),
        ],
      ),
    );
  }
}

// MARK: - 可折叠还款段

class _CollapsibleSegmentRow extends StatelessWidget {
  final RepaymentSegment segment;
  final Color color;
  final List<MonthlyPayment> monthlyPayments;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onToggle;

  const _CollapsibleSegmentRow({
    required this.segment,
    required this.color,
    required this.monthlyPayments,
    required this.isExpanded,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '第 ${segment.startMonth}-${segment.endMonth} 期',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '共 ${segment.monthCount} 期',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '利息 ${MortgageCalculatorService.formatCurrency(segment.totalInterest)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MortgageCalculatorService.formatCurrency(segment.monthlyPayment),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      '元/月',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // 展开的月供明细
        if (isExpanded) ...[
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '期数',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '日期',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 70,
                  child: Text(
                    '月供',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    '本金',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '利息',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...monthlyPayments.map((payment) => _CompactPaymentRow(
            payment: payment,
            color: color,
            isLast: payment == monthlyPayments.last,
          )),
        ],

        if (!isLast && !isExpanded)
          Divider(
            height: 1,
            indent: 16,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      ],
    );
  }
}

// MARK: - 紧凑月供行

class _CompactPaymentRow extends StatelessWidget {
  final MonthlyPayment payment;
  final Color color;
  final bool isLast;

  const _CompactPaymentRow({
    required this.payment,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${payment.date.year}-${payment.date.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast
                ? Colors.transparent
                : Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${payment.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              dateStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 70,
            child: Text(
              _formatAmount(payment.monthlyPayment),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 65,
            child: Text(
              _formatAmount(payment.principal),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              _formatAmount(payment.interest),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return MortgageCalculatorService.formatCurrency(amount);
  }
}
