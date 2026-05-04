import 'package:flutter/material.dart';

import '../models/loan_comparison_result.dart';
import '../services/mortgage_calculator_service.dart';

/// Card displaying savings from prepayment: interest saved, monthly savings, shortened term.
class SavingsCard extends StatelessWidget {
  final LoanComparisonResult comparisonResult;

  const SavingsCard({super.key, required this.comparisonResult});

  @override
  Widget build(BuildContext context) {
    if (!comparisonResult.hasPrepayment) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SavingsItem(
                title: '节省利息',
                value: MortgageCalculatorService.formatCurrency(
                  comparisonResult.savedInterest,
                ),
                unit: '元',
              ),
            ),
            Expanded(
              child: SavingsItem(
                title: '节省月供',
                value: MortgageCalculatorService.formatCurrency(
                  comparisonResult.savedFirstMonthPayment,
                ),
                unit: '元/月',
              ),
            ),
            Expanded(
              child: SavingsItem(
                title: '缩短期数',
                value: '${comparisonResult.shortenedMonths}',
                unit: '个月',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single metric item within [SavingsCard].
class SavingsItem extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const SavingsItem({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
