import 'loan_info.dart';
import 'prepayment_node.dart';
import 'monthly_payment.dart';
import 'repayment_segment.dart';

class LoanCalculationResult {
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final List<PrepaymentNode> prepaymentNodes;
  final List<RepaymentSegment> commercialSegments;
  final List<RepaymentSegment> providentFundSegments;
  final List<MonthlyPayment> commercialMonthlyPayments;
  final List<MonthlyPayment> providentFundMonthlyPayments;
  final double totalCommercialInterest;
  final double totalProvidentFundInterest;

  const LoanCalculationResult({
    this.commercialLoan,
    this.providentFundLoan,
    this.prepaymentNodes = const [],
    this.commercialSegments = const [],
    this.providentFundSegments = const [],
    this.commercialMonthlyPayments = const [],
    this.providentFundMonthlyPayments = const [],
    this.totalCommercialInterest = 0,
    this.totalProvidentFundInterest = 0,
  });

  double get totalPrincipal =>
      (commercialLoan?.principal ?? 0) + (providentFundLoan?.principal ?? 0);

  double get totalInterest =>
      totalCommercialInterest + totalProvidentFundInterest;
}
