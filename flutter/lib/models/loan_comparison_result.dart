import 'loan_calculation_result.dart';
import 'monthly_payment.dart';

/// Result of comparing two loan calculations (original vs current).
class LoanComparisonResult {
  final LoanCalculationResult originalResult;
  final LoanCalculationResult currentResult;
  final List<MergedMonthlyPayment> mergedMonthlyPayments;

  const LoanComparisonResult({
    required this.originalResult,
    required this.currentResult,
    this.mergedMonthlyPayments = const [],
  });

  /// Total interest saved by prepayment or refinancing.
  double get savedInterest =>
      originalResult.totalInterest - currentResult.totalInterest;

  /// First-month payment difference (original - current).
  double get savedFirstMonthPayment {
    final orig = _firstMonthTotal(originalResult);
    final curr = _firstMonthTotal(currentResult);
    return orig - curr;
  }

  /// Number of months shortened by prepayment.
  int get shortenedMonths {
    final origMonths = _totalMonths(originalResult);
    final currMonths = _totalMonths(currentResult);
    return origMonths - currMonths;
  }

  /// Whether the current result includes any prepayment nodes.
  bool get hasPrepayment => currentResult.prepaymentNodes.isNotEmpty;

  static double _firstMonthTotal(LoanCalculationResult r) {
    final c = r.commercialMonthlyPayments.isNotEmpty
        ? r.commercialMonthlyPayments.first.monthlyPayment
        : 0.0;
    final p = r.providentFundMonthlyPayments.isNotEmpty
        ? r.providentFundMonthlyPayments.first.monthlyPayment
        : 0.0;
    return c + p;
  }

  static int _totalMonths(LoanCalculationResult r) {
    final c = r.commercialMonthlyPayments.length;
    final p = r.providentFundMonthlyPayments.length;
    return c > p ? c : p;
  }
}

/// A merged row combining commercial and provident fund monthly payments.
class MergedMonthlyPayment {
  final int id;
  final DateTime date;
  final double? commercialPayment;
  final double? commercialPrincipal;
  final double? commercialInterest;
  final double? providentFundPayment;
  final double? providentFundPrincipal;
  final double? providentFundInterest;

  const MergedMonthlyPayment({
    required this.id,
    required this.date,
    this.commercialPayment,
    this.commercialPrincipal,
    this.commercialInterest,
    this.providentFundPayment,
    this.providentFundPrincipal,
    this.providentFundInterest,
  });

  /// Total payment across both loan types.
  double get totalPayment =>
      (commercialPayment ?? 0) + (providentFundPayment ?? 0);
}
