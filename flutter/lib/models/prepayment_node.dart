import 'loan_type.dart';
import 'prepayment_type.dart';

class PrepaymentNode {
  final String id;
  final DateTime prepaymentDate;
  final double prepaymentAmount;
  final PrepaymentType prepaymentType;
  final LoanType targetLoanType;
  final bool canShortenTerm;

  const PrepaymentNode({
    required this.id,
    required this.prepaymentDate,
    required this.prepaymentAmount,
    required this.prepaymentType,
    this.targetLoanType = LoanType.commercial,
    this.canShortenTerm = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'prepaymentDate': prepaymentDate.toIso8601String(),
    'prepaymentAmount': prepaymentAmount,
    'prepaymentType': prepaymentType.name,
    'targetLoanType': targetLoanType.name,
    'canShortenTerm': canShortenTerm,
  };

  factory PrepaymentNode.fromJson(Map<String, dynamic> json) => PrepaymentNode(
    id: json['id'] as String,
    prepaymentDate: DateTime.parse(json['prepaymentDate'] as String),
    prepaymentAmount: (json['prepaymentAmount'] as num).toDouble(),
    prepaymentType: PrepaymentType.values.byName(json['prepaymentType'] as String),
    targetLoanType: LoanType.values.byName(json['targetLoanType'] as String),
    canShortenTerm: json['canShortenTerm'] as bool? ?? true,
  );
}
