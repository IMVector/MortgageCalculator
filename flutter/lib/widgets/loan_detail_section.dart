import 'package:flutter/material.dart';

import '../models/monthly_payment.dart';
import '../models/repayment_segment.dart';
import '../services/mortgage_calculator_service.dart';

/// Collapsible section showing loan detail with repayment segments.
class LoanDetailSection extends StatefulWidget {
  final String title;
  final Color color;
  final List<RepaymentSegment> segments;
  final List<MonthlyPayment> monthlyPayments;

  const LoanDetailSection({
    super.key,
    required this.title,
    required this.color,
    required this.segments,
    required this.monthlyPayments,
  });

  @override
  State<LoanDetailSection> createState() => _LoanDetailSectionState();
}

class _LoanDetailSectionState extends State<LoanDetailSection> {
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

              return CollapsibleSegmentRow(
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

/// A collapsible row representing a single repayment segment.
class CollapsibleSegmentRow extends StatelessWidget {
  final RepaymentSegment segment;
  final Color color;
  final List<MonthlyPayment> monthlyPayments;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onToggle;

  const CollapsibleSegmentRow({
    super.key,
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
          ...monthlyPayments.map((payment) => CompactPaymentRow(
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

/// Compact row displaying a single monthly payment detail.
class CompactPaymentRow extends StatelessWidget {
  final MonthlyPayment payment;
  final Color color;
  final bool isLast;

  const CompactPaymentRow({
    super.key,
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
