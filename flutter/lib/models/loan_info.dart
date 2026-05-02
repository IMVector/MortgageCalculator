import 'loan_type.dart';
import 'repayment_type.dart';

class LoanInfo {
  final String id;
  final LoanType loanType;
  final double principal;       // 贷款本金（元）
  final double annualRate;      // 年利率 (%)
  final int loanTermMonths;     // 贷款期限（月）
  final DateTime startDate;     // 贷款开始日期
  final RepaymentType repaymentType;

  const LoanInfo({
    required this.id,
    required this.loanType,
    required this.principal,
    required this.annualRate,
    required this.loanTermMonths,
    required this.startDate,
    this.repaymentType = RepaymentType.equalPrincipalAndInterest,
  });

  double get monthlyRate => annualRate / 100.0 / 12.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'loanType': loanType.name,
    'principal': principal,
    'annualRate': annualRate,
    'loanTermMonths': loanTermMonths,
    'startDate': startDate.toIso8601String(),
    'repaymentType': repaymentType.name,
  };

  factory LoanInfo.fromJson(Map<String, dynamic> json) => LoanInfo(
    id: json['id'] as String,
    loanType: LoanType.values.byName(json['loanType'] as String),
    principal: (json['principal'] as num).toDouble(),
    annualRate: (json['annualRate'] as num).toDouble(),
    loanTermMonths: json['loanTermMonths'] as int,
    startDate: DateTime.parse(json['startDate'] as String),
    repaymentType: RepaymentType.values.byName(json['repaymentType'] as String),
  );
}
