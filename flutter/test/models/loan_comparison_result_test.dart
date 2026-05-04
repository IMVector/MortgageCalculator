import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_calculator/models/models.dart';

void main() {
  group('MergedMonthlyPayment', () {
    test('totalPayment sums commercial and provident fund payments', () {
      final merged = MergedMonthlyPayment(
        id: 1,
        date: DateTime(2024, 1),
        commercialPayment: 5000.0,
        providentFundPayment: 3000.0,
      );

      expect(merged.totalPayment, equals(8000.0));
    });

    test('totalPayment handles null commercial payment', () {
      final merged = MergedMonthlyPayment(
        id: 1,
        date: DateTime(2024, 1),
        providentFundPayment: 3000.0,
      );

      expect(merged.totalPayment, equals(3000.0));
    });

    test('totalPayment handles null provident fund payment', () {
      final merged = MergedMonthlyPayment(
        id: 1,
        date: DateTime(2024, 1),
        commercialPayment: 5000.0,
      );

      expect(merged.totalPayment, equals(5000.0));
    });

    test('totalPayment returns 0 when both are null', () {
      final merged = MergedMonthlyPayment(
        id: 1,
        date: DateTime(2024, 1),
      );

      expect(merged.totalPayment, equals(0.0));
    });
  });

  group('LoanComparisonResult', () {
    LoanInfo _createLoanInfo({
      required LoanType loanType,
      required double principal,
      required double annualRate,
      required int loanTermMonths,
      required DateTime startDate,
    }) {
      return LoanInfo(
        id: 'test-${loanType.name}',
        loanType: loanType,
        principal: principal,
        annualRate: annualRate,
        loanTermMonths: loanTermMonths,
        startDate: startDate,
      );
    }

    MonthlyPayment _createPayment({
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

    group('savedInterest', () {
      test('returns difference between original and current total interest', () {
        final original = LoanCalculationResult(
          commercialLoan: _createLoanInfo(
            loanType: LoanType.commercial,
            principal: 100000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          totalCommercialInterest: 50000,
          totalProvidentFundInterest: 30000,
        );

        final current = LoanCalculationResult(
          commercialLoan: _createLoanInfo(
            loanType: LoanType.commercial,
            principal: 100000,
            annualRate: 4.9,
            loanTermMonths: 240,
            startDate: DateTime(2024, 1),
          ),
          totalCommercialInterest: 40000,
          totalProvidentFundInterest: 20000,
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        // (50000 + 30000) - (40000 + 20000) = 20000
        expect(comparison.savedInterest, equals(20000.0));
      });

      test('returns zero when interests are equal', () {
        final result = LoanCalculationResult(
          totalCommercialInterest: 50000,
          totalProvidentFundInterest: 30000,
        );

        final comparison = LoanComparisonResult(
          originalResult: result,
          currentResult: result,
        );

        expect(comparison.savedInterest, equals(0.0));
      });
    });

    group('savedFirstMonthPayment', () {
      test('returns difference of first month total payments', () {
        final original = LoanCalculationResult(
          commercialMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 5000,
              principal: 3000,
              interest: 2000,
              loanType: LoanType.commercial,
            ),
          ],
          providentFundMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 3000,
              principal: 2000,
              interest: 1000,
              loanType: LoanType.providentFund,
            ),
          ],
        );

        final current = LoanCalculationResult(
          commercialMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 4500,
              principal: 3000,
              interest: 1500,
              loanType: LoanType.commercial,
            ),
          ],
          providentFundMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 2500,
              principal: 2000,
              interest: 500,
              loanType: LoanType.providentFund,
            ),
          ],
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        // Original: 5000 + 3000 = 8000
        // Current: 4500 + 2500 = 7000
        // Saved: 8000 - 7000 = 1000
        expect(comparison.savedFirstMonthPayment, equals(1000.0));
      });

      test('handles empty commercial payments', () {
        final original = LoanCalculationResult(
          providentFundMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 3000,
              principal: 2000,
              interest: 1000,
              loanType: LoanType.providentFund,
            ),
          ],
        );

        final current = LoanCalculationResult(
          providentFundMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 2500,
              principal: 2000,
              interest: 500,
              loanType: LoanType.providentFund,
            ),
          ],
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        // Original: 0 + 3000 = 3000
        // Current: 0 + 2500 = 2500
        expect(comparison.savedFirstMonthPayment, equals(500.0));
      });

      test('handles empty provident fund payments', () {
        final original = LoanCalculationResult(
          commercialMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 5000,
              principal: 3000,
              interest: 2000,
              loanType: LoanType.commercial,
            ),
          ],
        );

        final current = LoanCalculationResult(
          commercialMonthlyPayments: [
            _createPayment(
              id: 1,
              date: DateTime(2024, 1),
              monthlyPayment: 4000,
              principal: 3000,
              interest: 1000,
              loanType: LoanType.commercial,
            ),
          ],
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        // Original: 5000 + 0 = 5000
        // Current: 4000 + 0 = 4000
        expect(comparison.savedFirstMonthPayment, equals(1000.0));
      });

      test('handles both empty payment lists', () {
        final original = LoanCalculationResult();
        final current = LoanCalculationResult();

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        expect(comparison.savedFirstMonthPayment, equals(0.0));
      });
    });

    group('shortenedMonths', () {
      test('returns difference in total months', () {
        final original = LoanCalculationResult(
          commercialMonthlyPayments: List.generate(
            240,
            (i) => _createPayment(
              id: i + 1,
              date: DateTime(2024, (i % 12) + 1),
              monthlyPayment: 5000,
              principal: 3000,
              interest: 2000,
              loanType: LoanType.commercial,
            ),
          ),
          providentFundMonthlyPayments: List.generate(
            240,
            (i) => _createPayment(
              id: i + 1,
              date: DateTime(2024, (i % 12) + 1),
              monthlyPayment: 3000,
              principal: 2000,
              interest: 1000,
              loanType: LoanType.providentFund,
            ),
          ),
        );

        final current = LoanCalculationResult(
          commercialMonthlyPayments: List.generate(
            200,
            (i) => _createPayment(
              id: i + 1,
              date: DateTime(2024, (i % 12) + 1),
              monthlyPayment: 5000,
              principal: 3000,
              interest: 2000,
              loanType: LoanType.commercial,
            ),
          ),
          providentFundMonthlyPayments: List.generate(
            220,
            (i) => _createPayment(
              id: i + 1,
              date: DateTime(2024, (i % 12) + 1),
              monthlyPayment: 3000,
              principal: 2000,
              interest: 1000,
              loanType: LoanType.providentFund,
            ),
          ),
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        // Original: max(240, 240) = 240
        // Current: max(200, 220) = 220
        // Shortened: 240 - 220 = 20
        expect(comparison.shortenedMonths, equals(20));
      });

      test('picks longer list when one is empty', () {
        final original = LoanCalculationResult(
          commercialMonthlyPayments: List.generate(
            240,
            (i) => _createPayment(
              id: i + 1,
              date: DateTime(2024, (i % 12) + 1),
              monthlyPayment: 5000,
              principal: 3000,
              interest: 2000,
              loanType: LoanType.commercial,
            ),
          ),
        );

        final current = LoanCalculationResult(
          commercialMonthlyPayments: List.generate(
            200,
            (i) => _createPayment(
              id: i + 1,
              date: DateTime(2024, (i % 12) + 1),
              monthlyPayment: 5000,
              principal: 3000,
              interest: 2000,
              loanType: LoanType.commercial,
            ),
          ),
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        // Original: max(240, 0) = 240
        // Current: max(200, 0) = 200
        expect(comparison.shortenedMonths, equals(40));
      });

      test('returns zero when both have same months', () {
        final payments = List.generate(
          240,
          (i) => _createPayment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            monthlyPayment: 5000,
            principal: 3000,
            interest: 2000,
            loanType: LoanType.commercial,
          ),
        );

        final result = LoanCalculationResult(
          commercialMonthlyPayments: payments,
        );

        final comparison = LoanComparisonResult(
          originalResult: result,
          currentResult: result,
        );

        expect(comparison.shortenedMonths, equals(0));
      });
    });

    group('hasPrepayment', () {
      test('returns true when currentResult has prepayment nodes', () {
        final original = LoanCalculationResult();
        final current = LoanCalculationResult(
          prepaymentNodes: [
            PrepaymentNode(
              id: '1',
              prepaymentDate: DateTime(2024, 6),
              prepaymentAmount: 50000,
              prepaymentType: PrepaymentType.reducePayment,
            ),
          ],
        );

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        expect(comparison.hasPrepayment, isTrue);
      });

      test('returns false when currentResult has no prepayment nodes', () {
        final original = LoanCalculationResult();
        final current = LoanCalculationResult();

        final comparison = LoanComparisonResult(
          originalResult: original,
          currentResult: current,
        );

        expect(comparison.hasPrepayment, isFalse);
      });
    });

    group('mergedMonthlyPayments', () {
      test('defaults to empty list', () {
        final comparison = LoanComparisonResult(
          originalResult: LoanCalculationResult(),
          currentResult: LoanCalculationResult(),
        );

        expect(comparison.mergedMonthlyPayments, isEmpty);
      });

      test('can be provided', () {
        final merged = [
          MergedMonthlyPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            providentFundPayment: 3000,
          ),
        ];

        final comparison = LoanComparisonResult(
          originalResult: LoanCalculationResult(),
          currentResult: LoanCalculationResult(),
          mergedMonthlyPayments: merged,
        );

        expect(comparison.mergedMonthlyPayments.length, equals(1));
      });
    });
  });
}
