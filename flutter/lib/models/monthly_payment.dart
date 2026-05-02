import 'loan_type.dart';

class MonthlyPayment {
  final int id;
  final DateTime date;
  final double monthlyPayment;
  final double principal;
  final double interest;
  final double remainingPrincipal;
  final LoanType loanType;

  const MonthlyPayment({
    required this.id,
    required this.date,
    required this.monthlyPayment,
    required this.principal,
    required this.interest,
    required this.remainingPrincipal,
    required this.loanType,
  });
}
