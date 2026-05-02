class RepaymentSegment {
  final int startMonth;
  final int endMonth;
  final double monthlyPayment;
  final double totalInterest;
  final double remainingPrincipal;

  const RepaymentSegment({
    required this.startMonth,
    required this.endMonth,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.remainingPrincipal,
  });

  int get monthCount => endMonth - startMonth + 1;
}
