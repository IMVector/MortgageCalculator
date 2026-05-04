import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_calculator/models/models.dart';
import 'package:mortgage_calculator/services/loan_comparison_service.dart';

void main() {
  group('LoanComparisonService', () {
    MonthlyPayment _payment({
      required int id,
      required DateTime date,
      required double monthlyPayment,
      required double principal,
      required double interest,
      required LoanType loanType,
    }) {
      return MonthlyPayment(
        id: id,
        date: date,
        monthlyPayment: monthlyPayment,
        principal: principal,
        interest: interest,
        remainingPrincipal: 0,
        loanType: loanType,
      );
    }

    group('mergeMonthlyPayments', () {
      test('merges both loans with same date range - all fields non-null', () {
        final commercial = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
          _payment(
            id: 2,
            date: DateTime(2024, 2),
            monthlyPayment: 5000,
            principal: 3010,
            interest: 1990,
            loanType: LoanType.commercial,
          ),
        ];

        final providentFund = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 3000,
            principal: 2000,
            interest: 1000,
            loanType: LoanType.providentFund,
          ),
          _payment(
            id: 2,
            date: DateTime(2024, 2),
            monthlyPayment: 3000,
            principal: 2010,
            interest: 990,
            loanType: LoanType.providentFund,
          ),
        ];

        final result =
            LoanComparisonService.mergeMonthlyPayments(commercial, providentFund);

        expect(result.length, equals(2));

        expect(result[0].id, equals(1));
        expect(result[0].date, equals(DateTime(2024, 1)));
        expect(result[0].commercialPayment, equals(5000));
        expect(result[0].commercialPrincipal, equals(3000));
        expect(result[0].commercialInterest, equals(2000));
        expect(result[0].providentFundPayment, equals(3000));
        expect(result[0].providentFundPrincipal, equals(2000));
        expect(result[0].providentFundInterest, equals(1000));

        expect(result[1].id, equals(2));
        expect(result[1].commercialPayment, equals(5000));
        expect(result[1].providentFundPayment, equals(3000));
      });

      test('commercial shorter - commercial fields null after payoff', () {
        final commercial = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
        ];

        final providentFund = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 3000,
            principal: 2000,
            interest: 1000,
            loanType: LoanType.providentFund,
          ),
          _payment(
            id: 2,
            date: DateTime(2024, 2),
            monthlyPayment: 3000,
            principal: 2010,
            interest: 990,
            loanType: LoanType.providentFund,
          ),
          _payment(
            id: 3,
            date: DateTime(2024, 3),
            monthlyPayment: 3000,
            principal: 2020,
            interest: 980,
            loanType: LoanType.providentFund,
          ),
        ];

        final result =
            LoanComparisonService.mergeMonthlyPayments(commercial, providentFund);

        expect(result.length, equals(3));

        // Month 1: both non-null
        expect(result[0].commercialPayment, equals(5000));
        expect(result[0].providentFundPayment, equals(3000));

        // Month 2: commercial null
        expect(result[1].commercialPayment, isNull);
        expect(result[1].commercialPrincipal, isNull);
        expect(result[1].commercialInterest, isNull);
        expect(result[1].providentFundPayment, equals(3000));

        // Month 3: commercial null
        expect(result[2].commercialPayment, isNull);
        expect(result[2].providentFundPayment, equals(3000));
      });

      test('single loan (commercial only) - provident fund all null', () {
        final commercial = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
          _payment(
            id: 2,
            date: DateTime(2024, 2),
            monthlyPayment: 5000,
            principal: 3010,
            interest: 1990,
            loanType: LoanType.commercial,
          ),
        ];

        final result = LoanComparisonService.mergeMonthlyPayments(
          commercial,
          const [],
        );

        expect(result.length, equals(2));

        expect(result[0].commercialPayment, equals(5000));
        expect(result[0].providentFundPayment, isNull);
        expect(result[0].providentFundPrincipal, isNull);
        expect(result[0].providentFundInterest, isNull);

        expect(result[1].commercialPayment, equals(5000));
        expect(result[1].providentFundPayment, isNull);
      });

      test('single loan (provident fund only) - commercial all null', () {
        final providentFund = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 3000,
            principal: 2000,
            interest: 1000,
            loanType: LoanType.providentFund,
          ),
          _payment(
            id: 2,
            date: DateTime(2024, 2),
            monthlyPayment: 3000,
            principal: 2010,
            interest: 990,
            loanType: LoanType.providentFund,
          ),
        ];

        final result = LoanComparisonService.mergeMonthlyPayments(
          const [],
          providentFund,
        );

        expect(result.length, equals(2));

        expect(result[0].commercialPayment, isNull);
        expect(result[0].commercialPrincipal, isNull);
        expect(result[0].commercialInterest, isNull);
        expect(result[0].providentFundPayment, equals(3000));

        expect(result[1].commercialPayment, isNull);
        expect(result[1].providentFundPayment, equals(3000));
      });

      test('empty lists - returns empty', () {
        final result = LoanComparisonService.mergeMonthlyPayments(
          const [],
          const [],
        );

        expect(result, isEmpty);
      });

      test('sequential ids start at 1', () {
        final commercial = [
          _payment(
            id: 10,
            date: DateTime(2024, 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
          _payment(
            id: 20,
            date: DateTime(2024, 2),
            monthlyPayment: 5000,
            principal: 3010,
            interest: 1990,
            loanType: LoanType.commercial,
          ),
        ];

        final result = LoanComparisonService.mergeMonthlyPayments(
          commercial,
          const [],
        );

        expect(result[0].id, equals(1));
        expect(result[1].id, equals(2));
      });
    });

    group('compare', () {
      test('identical results - savedInterest equals 0', () {
        final payments = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
        ];

        final result = LoanCalculationResult(
          commercialLoan: LoanInfo(
            id: 'c1',
            loanType: LoanType.commercial,
            principal: 500000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          commercialMonthlyPayments: payments,
          totalCommercialInterest: 2000,
        );

        final comparison = LoanComparisonService.compare(result, result);

        expect(comparison.savedInterest, equals(0.0));
        expect(comparison.savedFirstMonthPayment, equals(0.0));
        expect(comparison.shortenedMonths, equals(0));
        expect(comparison.hasPrepayment, isFalse);
      });

      test('with prepayment - positive savedInterest', () {
        final originalPayments = List.generate(
          240,
          (i) => _payment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
        );

        final currentPayments = List.generate(
          200,
          (i) => _payment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            monthlyPayment: 4800,
            principal: 3200,
            interest: 1600,
            loanType: LoanType.commercial,
          ),
        );

        final original = LoanCalculationResult(
          commercialLoan: LoanInfo(
            id: 'c1',
            loanType: LoanType.commercial,
            principal: 500000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          commercialMonthlyPayments: originalPayments,
          totalCommercialInterest: 480000,
        );

        final current = LoanCalculationResult(
          commercialLoan: LoanInfo(
            id: 'c1',
            loanType: LoanType.commercial,
            principal: 500000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          commercialMonthlyPayments: currentPayments,
          totalCommercialInterest: 320000,
          prepaymentNodes: [
            PrepaymentNode(
              id: 'p1',
              prepaymentDate: DateTime(2024, 6),
              prepaymentAmount: 100000,
              prepaymentType: PrepaymentType.reducePayment,
            ),
          ],
        );

        final comparison = LoanComparisonService.compare(original, current);

        expect(comparison.savedInterest, equals(160000.0));
        expect(comparison.hasPrepayment, isTrue);
        expect(comparison.shortenedMonths, equals(40));
      });

      test('compare includes merged monthly payments', () {
        final originalCommercial = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
        ];

        final currentCommercial = [
          _payment(
            id: 1,
            date: DateTime(2024, 1),
            monthlyPayment: 4500,
            principal: 3000,
            interest: 1500,
            loanType: LoanType.commercial,
          ),
        ];

        final original = LoanCalculationResult(
          commercialLoan: LoanInfo(
            id: 'c1',
            loanType: LoanType.commercial,
            principal: 500000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          commercialMonthlyPayments: originalCommercial,
          totalCommercialInterest: 2000,
        );

        final current = LoanCalculationResult(
          commercialLoan: LoanInfo(
            id: 'c1',
            loanType: LoanType.commercial,
            principal: 500000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          commercialMonthlyPayments: currentCommercial,
          totalCommercialInterest: 1500,
        );

        final comparison = LoanComparisonService.compare(original, current);

        // The merged payments should come from the current result
        expect(comparison.mergedMonthlyPayments.length, equals(1));
        expect(comparison.mergedMonthlyPayments[0].commercialPayment, equals(4500));
      });
    });
  });
}
