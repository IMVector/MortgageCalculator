import 'dart:convert';

import '../models/models.dart';
import 'mortgage_calculator_service.dart';

/// 导入导出服务 - 负责数据的导入和导出
class ImportExportService {
  ImportExportService._();

  // MARK: - 导出数据

  /// 导出为 JSON 格式
  static String? exportToJSON({
    LoanInfo? commercial,
    LoanInfo? providentFund,
    List<PrepaymentNode> prepayments = const [],
  }) {
    try {
      final exportData = ExportData(
        commercialLoan: commercial,
        providentFundLoan: providentFund,
        prepayments: prepayments,
        exportDate: DateTime.now(),
      );
      return const JsonEncoder.withIndent('  ').convert(exportData.toJson());
    } catch (_) {
      return null;
    }
  }

  /// 导出为可读文本格式
  static String exportToText(LoanCalculationResult result) {
    final buffer = StringBuffer();
    buffer.writeln('房贷计算结果');
    buffer.writeln('=' * 30);
    buffer.writeln();

    // 商业贷款信息
    if (result.commercialLoan != null) {
      final commercial = result.commercialLoan!;
      buffer.writeln('【商业贷款】');
      buffer.writeln('贷款本金: ${MortgageCalculatorService.formatCurrency(commercial.principal)} 元');
      buffer.writeln('年利率: ${commercial.annualRate.toStringAsFixed(2)}%');
      buffer.writeln('贷款期限: ${commercial.loanTermMonths} 个月');
      buffer.writeln('还款方式: ${commercial.repaymentType.label}');
      buffer.writeln('起始日期: ${_formatDate(commercial.startDate)}');
      buffer.writeln();
    }

    // 公积金贷款信息
    if (result.providentFundLoan != null) {
      final providentFund = result.providentFundLoan!;
      buffer.writeln('【公积金贷款】');
      buffer.writeln('贷款本金: ${MortgageCalculatorService.formatCurrency(providentFund.principal)} 元');
      buffer.writeln('年利率: ${providentFund.annualRate.toStringAsFixed(2)}%');
      buffer.writeln('贷款期限: ${providentFund.loanTermMonths} 个月');
      buffer.writeln('还款方式: ${providentFund.repaymentType.label}');
      buffer.writeln('起始日期: ${_formatDate(providentFund.startDate)}');
      buffer.writeln();
    }

    // 提前还款节点
    if (result.prepaymentNodes.isNotEmpty) {
      buffer.writeln('【提前还款记录】');
      for (var i = 0; i < result.prepaymentNodes.length; i++) {
        final node = result.prepaymentNodes[i];
        buffer.writeln('${i + 1}. ${_formatDate(node.prepaymentDate)}');
        buffer.writeln('   金额: ${MortgageCalculatorService.formatCurrency(node.prepaymentAmount)} 元');
        buffer.writeln('   方式: ${node.prepaymentType.label}');
      }
      buffer.writeln();
    }

    // 计算结果汇总
    buffer.writeln('【计算结果】');

    if (result.commercialLoan != null) {
      final firstPayment = result.commercialMonthlyPayments.isNotEmpty
          ? result.commercialMonthlyPayments.first.monthlyPayment
          : 0.0;
      buffer.writeln('商业贷款:');
      buffer.writeln('  月供: ${MortgageCalculatorService.formatCurrency(firstPayment)} 元');
      buffer.writeln('  总利息: ${MortgageCalculatorService.formatCurrency(result.totalCommercialInterest)} 元');
      buffer.writeln('  已还期数: ${result.commercialMonthlyPayments.length} 期');
      buffer.writeln();
    }

    if (result.providentFundLoan != null) {
      final firstPayment = result.providentFundMonthlyPayments.isNotEmpty
          ? result.providentFundMonthlyPayments.first.monthlyPayment
          : 0.0;
      buffer.writeln('公积金贷款:');
      buffer.writeln('  月供: ${MortgageCalculatorService.formatCurrency(firstPayment)} 元');
      buffer.writeln('  总利息: ${MortgageCalculatorService.formatCurrency(result.totalProvidentFundInterest)} 元');
      buffer.writeln('  已还期数: ${result.providentFundMonthlyPayments.length} 期');
      buffer.writeln();
    }

    // 还款变化节点
    if (result.commercialSegments.isNotEmpty) {
      buffer.writeln('【商业贷款还款变化】');
      for (final segment in result.commercialSegments) {
        buffer.writeln(
          '第${segment.startMonth}-${segment.endMonth}期: '
          '月供 ${MortgageCalculatorService.formatCurrency(segment.monthlyPayment)} 元',
        );
      }
      buffer.writeln();
    }

    if (result.providentFundSegments.isNotEmpty) {
      buffer.writeln('【公积金贷款还款变化】');
      for (final segment in result.providentFundSegments) {
        buffer.writeln(
          '第${segment.startMonth}-${segment.endMonth}期: '
          '月供 ${MortgageCalculatorService.formatCurrency(segment.monthlyPayment)} 元',
        );
      }
    }

    return buffer.toString();
  }

  // MARK: - 导入数据

  /// 从 JSON 导入，返回 (商业贷款, 公积金贷款, 提前还款列表)，失败返回 null
  static (LoanInfo?, LoanInfo?, List<PrepaymentNode>)? importFromJSON(
    String jsonString,
  ) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exportData = ExportData.fromJson(json);
      return (
        exportData.commercialLoan,
        exportData.providentFundLoan,
        exportData.prepayments,
      );
    } catch (_) {
      return null;
    }
  }

  // MARK: - 辅助函数

  static String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
