import 'package:flutter/material.dart';

import '../models/loan_calculation_result.dart';
import '../models/loan_comparison_result.dart';
import '../services/mortgage_calculator_service.dart';

/// Summary cards showing total principal, interest, and monthly payments.
class SummaryCards extends StatelessWidget {
  final LoanCalculationResult result;
  final LoanComparisonResult? comparisonResult;

  const SummaryCards({
    super.key,
    required this.result,
    this.comparisonResult,
  });

  @override
  Widget build(BuildContext context) {
    // Use originalResult for total principal (unchanged by prepayment),
    // currentResult for interest and monthly payments.
    final totalPrincipal = comparisonResult != null
        ? comparisonResult!.originalResult.totalPrincipal
        : result.totalPrincipal;
    final totalInterest = comparisonResult != null
        ? comparisonResult!.currentResult.totalInterest
        : result.totalInterest;
    final displayResult = comparisonResult?.currentResult ?? result;
    final hasSavings = comparisonResult?.hasPrepayment == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 总贷款金额和总利息
            Row(
              children: [
                Expanded(
                  child: SummaryItem(
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
                  child: InterestSummaryItem(
                    title: '总利息',
                    value: MortgageCalculatorService.formatCurrency(totalInterest),
                    savedAmount: hasSavings
                        ? MortgageCalculatorService.formatCurrency(
                            comparisonResult!.savedInterest,
                          )
                        : null,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 各贷款月供
            Row(
              children: [
                if (displayResult.commercialMonthlyPayments.isNotEmpty)
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
                            displayResult.commercialMonthlyPayments.first.monthlyPayment,
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
                if (displayResult.providentFundMonthlyPayments.isNotEmpty)
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
                            displayResult.providentFundMonthlyPayments.first.monthlyPayment,
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
            if (displayResult.commercialMonthlyPayments.isNotEmpty &&
                displayResult.providentFundMonthlyPayments.isNotEmpty) ...[
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
                      displayResult.commercialMonthlyPayments.first.monthlyPayment +
                          displayResult.providentFundMonthlyPayments.first.monthlyPayment,
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

/// Interest summary item with optional green savings annotation.
class InterestSummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final String? savedAmount;

  const InterestSummaryItem({
    super.key,
    required this.title,
    required this.value,
    this.savedAmount,
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
                  color: Colors.orange,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '元',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (savedAmount != null) ...[
          const SizedBox(height: 2),
          Text(
            '省 $savedAmount 元',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// A single metric display item within [SummaryCards].
class SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const SummaryItem({
    super.key,
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
