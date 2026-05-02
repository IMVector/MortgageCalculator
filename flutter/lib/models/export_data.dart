import 'loan_info.dart';
import 'prepayment_node.dart';

class ExportData {
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final List<PrepaymentNode> prepayments;
  final DateTime exportDate;
  final String version;

  const ExportData({
    this.commercialLoan,
    this.providentFundLoan,
    this.prepayments = const [],
    required this.exportDate,
    this.version = '1.0',
  });

  Map<String, dynamic> toJson() => {
    if (commercialLoan != null) 'commercialLoan': commercialLoan!.toJson(),
    if (providentFundLoan != null) 'providentFundLoan': providentFundLoan!.toJson(),
    'prepayments': prepayments.map((p) => p.toJson()).toList(),
    'exportDate': exportDate.toIso8601String(),
    'version': version,
  };

  factory ExportData.fromJson(Map<String, dynamic> json) => ExportData(
    commercialLoan: json['commercialLoan'] != null
        ? LoanInfo.fromJson(json['commercialLoan'] as Map<String, dynamic>)
        : null,
    providentFundLoan: json['providentFundLoan'] != null
        ? LoanInfo.fromJson(json['providentFundLoan'] as Map<String, dynamic>)
        : null,
    prepayments: (json['prepayments'] as List<dynamic>?)
        ?.map((p) => PrepaymentNode.fromJson(p as Map<String, dynamic>))
        .toList() ?? [],
    exportDate: DateTime.parse(json['exportDate'] as String),
    version: json['version'] as String? ?? '1.0',
  );
}
