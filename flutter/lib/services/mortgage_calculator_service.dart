import 'dart:math';

import '../models/models.dart';

/// 房贷计算器服务 - 提供等额本息和等额本金计算
class MortgageCalculatorService {
  MortgageCalculatorService._();

  // MARK: - 等额本息计算

  /// 计算等额本息月供
  ///
  /// [principal] 贷款本金
  /// [monthlyRate] 月利率
  /// [remainingMonths] 剩余期数
  static double calculateEqualPaymentMonthly({
    required double principal,
    required double monthlyRate,
    required int remainingMonths,
  }) {
    if (monthlyRate <= 0 || remainingMonths <= 0) {
      return principal / remainingMonths;
    }

    final factor = pow(1 + monthlyRate, remainingMonths);
    return principal * monthlyRate * factor / (factor - 1);
  }

  /// 生成等额本息还款明细
  static List<MonthlyPayment> generateEqualPaymentSchedule({
    required LoanInfo loan,
    List<PrepaymentNode> prepayments = const [],
  }) {
    final payments = <MonthlyPayment>[];
    var remainingPrincipal = loan.principal;
    var currentDate = loan.startDate;
    var monthIndex = 1;

    // 按日期排序提前还款节点
    final sortedPrepayments = List<PrepaymentNode>.of(prepayments)
      ..sort((a, b) => a.prepaymentDate.compareTo(b.prepaymentDate));

    var nextPrepaymentIndex = 0;

    while (remainingPrincipal > 0.01) {
      // 收集本期所有到期的提前还款（修复：同一账单期内多个提前还款不能丢弃）
      final currentPrepayments = <PrepaymentNode>[];
      while (nextPrepaymentIndex < sortedPrepayments.length) {
        final prepayment = sortedPrepayments[nextPrepaymentIndex];
        if (!prepayment.prepaymentDate.isAfter(currentDate)) {
          currentPrepayments.add(prepayment);
          nextPrepaymentIndex += 1;
        } else {
          break;
        }
      }

      // 计算当期月供
      final remainingMonths = loan.loanTermMonths - monthIndex + 1;
      var monthlyPayment = calculateEqualPaymentMonthly(
        principal: remainingPrincipal,
        monthlyRate: loan.monthlyRate,
        remainingMonths: remainingMonths,
      );

      // 如果是最后一期，调整月供
      if (monthlyPayment > remainingPrincipal * (1 + loan.monthlyRate)) {
        monthlyPayment = remainingPrincipal * (1 + loan.monthlyRate);
      }

      // 计算利息和本金
      final interest = remainingPrincipal * loan.monthlyRate;
      var principalPaid = monthlyPayment - interest;

      // 处理所有提前还款
      var totalExtraPayment = 0.0;
      for (final prepayment in currentPrepayments) {
        final extraPayment = min(
          prepayment.prepaymentAmount,
          remainingPrincipal - principalPaid - totalExtraPayment,
        );
        totalExtraPayment += extraPayment;

        if (principalPaid + totalExtraPayment >= remainingPrincipal) {
          // 提前还清
          principalPaid = remainingPrincipal - totalExtraPayment + extraPayment;
          totalExtraPayment = remainingPrincipal - principalPaid;
          break;
        }
      }

      remainingPrincipal -= (principalPaid + totalExtraPayment);

      // 当月还款 = 原月供 + 提前还款金额
      final actualMonthlyPayment = monthlyPayment + totalExtraPayment;

      final payment = MonthlyPayment(
        id: monthIndex,
        date: currentDate,
        monthlyPayment: actualMonthlyPayment,
        principal: principalPaid + totalExtraPayment,
        interest: interest,
        remainingPrincipal: max(0, remainingPrincipal),
        loanType: loan.loanType,
      );
      payments.add(payment);

      // 月次递增
      monthIndex += 1;
      currentDate = DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      );

      // 防止无限循环
      if (monthIndex > loan.loanTermMonths * 2) {
        break;
      }
    }

    return payments;
  }

  // MARK: - 等额本金计算

  /// 计算等额本金月供
  static double calculateEqualPrincipalMonthly({
    required double principal,
    required double monthlyRate,
    required int monthIndex,
    required int totalMonths,
  }) {
    final monthlyPrincipal = principal / totalMonths;
    final remaining = principal - monthlyPrincipal * (monthIndex - 1);
    final interest = remaining * monthlyRate;
    return monthlyPrincipal + interest;
  }

  /// 生成等额本金还款明细
  static List<MonthlyPayment> generateEqualPrincipalSchedule({
    required LoanInfo loan,
    List<PrepaymentNode> prepayments = const [],
  }) {
    final payments = <MonthlyPayment>[];
    var remainingPrincipal = loan.principal;
    var currentDate = loan.startDate;
    var monthIndex = 1;
    var remainingMonths = loan.loanTermMonths;
    // 每月偿还本金 = 总本金 / 总期数
    var monthlyPrincipal = loan.principal / loan.loanTermMonths;

    final sortedPrepayments = List<PrepaymentNode>.of(prepayments)
      ..sort((a, b) => a.prepaymentDate.compareTo(b.prepaymentDate));
    var nextPrepaymentIndex = 0;

    while (remainingPrincipal > 0.01 && monthIndex <= loan.loanTermMonths * 2) {
      // 收集本期所有到期的提前还款（修复：同一账单期内多个提前还款不能丢弃）
      final currentPrepayments = <PrepaymentNode>[];
      while (nextPrepaymentIndex < sortedPrepayments.length) {
        final prepayment = sortedPrepayments[nextPrepaymentIndex];
        if (!prepayment.prepaymentDate.isAfter(currentDate)) {
          currentPrepayments.add(prepayment);
          nextPrepaymentIndex += 1;
        } else {
          break;
        }
      }

      // 当期利息 = 剩余本金 * 月利率
      final interest = remainingPrincipal * loan.monthlyRate;
      var principalPaid = min(monthlyPrincipal, remainingPrincipal);
      var totalExtraPayment = 0.0;

      // 处理所有提前还款
      for (final prepayment in currentPrepayments) {
        final extraPayment = min(
          prepayment.prepaymentAmount,
          remainingPrincipal - principalPaid - totalExtraPayment,
        );
        totalExtraPayment += extraPayment;

        if (prepayment.prepaymentType == PrepaymentType.shortenTerm) {
          // 缩短期限：保持每月本金不变，减少期数
        } else {
          // 减少月供：保持期数不变，减少每月本金
          remainingMonths = max(1, loan.loanTermMonths - monthIndex + 1);
          monthlyPrincipal = (remainingPrincipal - principalPaid - totalExtraPayment) / remainingMonths;
        }
      }

      remainingPrincipal -= (principalPaid + totalExtraPayment);

      // 最后一期调整
      if (remainingPrincipal < 0.01) {
        principalPaid += remainingPrincipal;
        remainingPrincipal = 0;
      }

      // 当月还款 = 本金 + 利息 + 提前还款金额
      final monthlyPayment = principalPaid + interest + totalExtraPayment;
      final payment = MonthlyPayment(
        id: monthIndex,
        date: currentDate,
        monthlyPayment: monthlyPayment,
        principal: principalPaid + totalExtraPayment,
        interest: interest,
        remainingPrincipal: max(0, remainingPrincipal),
        loanType: loan.loanType,
      );
      payments.add(payment);

      monthIndex += 1;
      currentDate = DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      );
    }

    return payments;
  }

  // MARK: - 完整贷款计算

  /// 计算完整贷款（含提前还款）
  static LoanCalculationResult calculateLoan({
    LoanInfo? commercial,
    LoanInfo? providentFund,
    List<PrepaymentNode> prepayments = const [],
  }) {
    List<RepaymentSegment> commercialSegments = [];
    List<RepaymentSegment> providentFundSegments = [];
    List<MonthlyPayment> commercialMonthlyPayments = [];
    List<MonthlyPayment> providentFundMonthlyPayments = [];
    double totalCommercialInterest = 0;
    double totalProvidentFundInterest = 0;

    // 商业贷款 - 只处理目标为商业贷款的提前还款
    if (commercial != null) {
      final commercialPrepayments =
          prepayments.where((p) => p.targetLoanType == LoanType.commercial).toList();

      switch (commercial.repaymentType) {
        case RepaymentType.equalPrincipalAndInterest:
          commercialMonthlyPayments = generateEqualPaymentSchedule(
            loan: commercial,
            prepayments: commercialPrepayments,
          );
        case RepaymentType.equalPrincipal:
          commercialMonthlyPayments = generateEqualPrincipalSchedule(
            loan: commercial,
            prepayments: commercialPrepayments,
          );
      }
      totalCommercialInterest = commercialMonthlyPayments.fold(
        0,
        (sum, p) => sum + p.interest,
      );
      commercialSegments = _generateSegments(
        commercialMonthlyPayments,
        LoanType.commercial,
      );
    }

    // 公积金贷款 - 只处理目标为公积金贷款的提前还款
    if (providentFund != null) {
      final providentFundPrepayments =
          prepayments.where((p) => p.targetLoanType == LoanType.providentFund).toList();

      switch (providentFund.repaymentType) {
        case RepaymentType.equalPrincipalAndInterest:
          providentFundMonthlyPayments = generateEqualPaymentSchedule(
            loan: providentFund,
            prepayments: providentFundPrepayments,
          );
        case RepaymentType.equalPrincipal:
          providentFundMonthlyPayments = generateEqualPrincipalSchedule(
            loan: providentFund,
            prepayments: providentFundPrepayments,
          );
      }
      totalProvidentFundInterest = providentFundMonthlyPayments.fold(
        0,
        (sum, p) => sum + p.interest,
      );
      providentFundSegments = _generateSegments(
        providentFundMonthlyPayments,
        LoanType.providentFund,
      );
    }

    return LoanCalculationResult(
      commercialLoan: commercial,
      providentFundLoan: providentFund,
      prepaymentNodes: prepayments,
      commercialSegments: commercialSegments,
      providentFundSegments: providentFundSegments,
      commercialMonthlyPayments: commercialMonthlyPayments,
      providentFundMonthlyPayments: providentFundMonthlyPayments,
      totalCommercialInterest: totalCommercialInterest,
      totalProvidentFundInterest: totalProvidentFundInterest,
    );
  }

  /// 生成还款计划段
  static List<RepaymentSegment> _generateSegments(
    List<MonthlyPayment> payments,
    LoanType loanType,
  ) {
    if (payments.isEmpty) return [];

    final segments = <RepaymentSegment>[];
    var currentSegmentPayments = <MonthlyPayment>[];
    MonthlyPayment? lastPayment;

    for (final payment in payments) {
      if (lastPayment != null) {
        // 检查是否应该开始新段
        // 如果月供金额变化超过1元（等额本金每月递减或提前还款后变化）
        final paymentDiff = (payment.monthlyPayment - lastPayment.monthlyPayment).abs();
        final isNewSegment = paymentDiff > 1.0;

        if (isNewSegment) {
          // 保存当前段
          if (currentSegmentPayments.isNotEmpty) {
            segments.add(_createSegment(currentSegmentPayments));
          }
          currentSegmentPayments = [payment];
        } else {
          currentSegmentPayments.add(payment);
        }
      } else {
        currentSegmentPayments.add(payment);
      }
      lastPayment = payment;
    }

    // 添加最后一个段
    if (currentSegmentPayments.isNotEmpty) {
      segments.add(_createSegment(currentSegmentPayments));
    }

    return segments;
  }

  static RepaymentSegment _createSegment(List<MonthlyPayment> payments) {
    final totalInterest = payments.fold(0.0, (sum, p) => sum + p.interest);
    final avgPayment =
        payments.fold(0.0, (sum, p) => sum + p.monthlyPayment) / payments.length;

    return RepaymentSegment(
      startMonth: payments.first.id,
      endMonth: payments.last.id,
      monthlyPayment: avgPayment,
      totalInterest: totalInterest,
      remainingPrincipal: payments.last.remainingPrincipal,
    );
  }

  // MARK: - 日期工具

  /// 计算两个日期间的月数
  static int monthsBetween(DateTime start, DateTime end) {
    final yearDiff = end.year - start.year;
    final monthDiff = end.month - start.month;
    return max(0, yearDiff * 12 + monthDiff);
  }

  // MARK: - 格式化工具

  /// 格式化金额（带千分位分隔符）
  static String formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = isNegative ? -amount : amount;

    // 分离整数和小数部分
    final fixed = absAmount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // 添加千分位分隔符
    final buffer = StringBuffer();
    final digits = intPart.length;
    for (var i = 0; i < digits; i++) {
      if (i > 0 && (digits - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    final result = '${buffer.toString()}.$decPart';
    return isNegative ? '-$result' : result;
  }
}
