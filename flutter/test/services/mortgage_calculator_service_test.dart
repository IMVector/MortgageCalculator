import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_calculator/models/models.dart';
import 'package:mortgage_calculator/services/mortgage_calculator_service.dart';

void main() {
  group('MortgageCalculatorService', () {
    group('calculateEqualPaymentMonthly', () {
      test('计算等额本息月供', () {
        final monthly = MortgageCalculatorService.calculateEqualPaymentMonthly(
          principal: 1000000,
          monthlyRate: 0.035 / 12,
          remainingMonths: 360,
        );
        expect(monthly, closeTo(4490.45, 1.0));
      });

      test('利率为0时平均分摊', () {
        final monthly = MortgageCalculatorService.calculateEqualPaymentMonthly(
          principal: 120000,
          monthlyRate: 0,
          remainingMonths: 120,
        );
        expect(monthly, 1000.0);
      });
    });

    group('calculateEqualPrincipalMonthly', () {
      test('第一期月供', () {
        final monthly = MortgageCalculatorService.calculateEqualPrincipalMonthly(
          principal: 1200000,
          monthlyRate: 0.042 / 12,
          monthIndex: 1,
          totalMonths: 360,
        );
        expect(monthly, closeTo(7533.33, 1.0));
      });

      test('最后一期月供', () {
        final monthly = MortgageCalculatorService.calculateEqualPrincipalMonthly(
          principal: 1200000,
          monthlyRate: 0.042 / 12,
          monthIndex: 360,
          totalMonths: 360,
        );
        expect(monthly, closeTo(3345.0, 1.0));
      });
    });

    group('generateEqualPaymentSchedule', () {
      test('生成基本还款计划', () {
        final loan = LoanInfo(
          id: '1',
          loanType: LoanType.commercial,
          principal: 1000000,
          annualRate: 4.2,
          loanTermMonths: 360,
          startDate: DateTime(2024, 1, 1),
        );

        final payments = MortgageCalculatorService.generateEqualPaymentSchedule(loan: loan);
        expect(payments.length, 360);
        expect(payments.last.remainingPrincipal, closeTo(0, 1.0));
      });

      test('带提前还款（减少月供）', () {
        final loan = LoanInfo(
          id: '1',
          loanType: LoanType.commercial,
          principal: 1000000,
          annualRate: 4.2,
          loanTermMonths: 360,
          startDate: DateTime(2024, 1, 1),
        );

        final prepayment = PrepaymentNode(
          id: 'p1',
          prepaymentDate: DateTime(2026, 1, 1),
          prepaymentAmount: 200000,
          prepaymentType: PrepaymentType.reducePayment,
        );

        final payments = MortgageCalculatorService.generateEqualPaymentSchedule(
          loan: loan,
          prepayments: [prepayment],
        );

        // payments[24] is the prepayment month (Jan 2026), which includes the
        // lump-sum extra. Compare a regular month before and after.
        final paymentBefore = payments[22].monthlyPayment; // Nov 2025
        final paymentAfter = payments[25].monthlyPayment;  // Feb 2026
        expect(paymentAfter, lessThan(paymentBefore));
      });
    });

    group('calculateLoan', () {
      test('组合贷款计算', () {
        final commercial = LoanInfo(
          id: '1',
          loanType: LoanType.commercial,
          principal: 800000,
          annualRate: 4.2,
          loanTermMonths: 360,
          startDate: DateTime(2024, 1, 1),
        );

        final providentFund = LoanInfo(
          id: '2',
          loanType: LoanType.providentFund,
          principal: 400000,
          annualRate: 3.1,
          loanTermMonths: 360,
          startDate: DateTime(2024, 1, 1),
          repaymentType: RepaymentType.equalPrincipalAndInterest,
        );

        final result = MortgageCalculatorService.calculateLoan(
          commercial: commercial,
          providentFund: providentFund,
        );

        expect(result.commercialMonthlyPayments, isNotEmpty);
        expect(result.providentFundMonthlyPayments, isNotEmpty);
        expect(result.totalCommercialInterest, greaterThan(0));
        expect(result.totalProvidentFundInterest, greaterThan(0));
        expect(result.commercialSegments, isNotEmpty);
        expect(result.providentFundSegments, isNotEmpty);
      });
    });

    group('monthsBetween', () {
      test('同一年内', () {
        expect(
          MortgageCalculatorService.monthsBetween(
            DateTime(2024, 1, 1),
            DateTime(2024, 6, 1),
          ),
          5,
        );
      });

      test('跨年', () {
        expect(
          MortgageCalculatorService.monthsBetween(
            DateTime(2023, 10, 1),
            DateTime(2024, 3, 1),
          ),
          5,
        );
      });
    });

    group('formatCurrency', () {
      test('格式化金额', () {
        expect(MortgageCalculatorService.formatCurrency(1234567.89), '1,234,567.89');
        expect(MortgageCalculatorService.formatCurrency(1000), '1,000.00');
        expect(MortgageCalculatorService.formatCurrency(0), '0.00');
      });
    });
  });
}
