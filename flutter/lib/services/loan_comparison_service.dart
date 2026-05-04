import '../models/models.dart';

/// Service for comparing two loan calculation results.
class LoanComparisonService {
  LoanComparisonService._();

  /// Compare two loan calculation results and produce a [LoanComparisonResult].
  static LoanComparisonResult compare(
    LoanCalculationResult original,
    LoanCalculationResult current,
  ) {
    final merged = mergeMonthlyPayments(
      current.commercialMonthlyPayments,
      current.providentFundMonthlyPayments,
    );

    return LoanComparisonResult(
      originalResult: original,
      currentResult: current,
      mergedMonthlyPayments: merged,
    );
  }

  /// Merge commercial and provident fund monthly payments by date.
  ///
  /// Payments are keyed by (year * 12 + month). When both lists have a
  /// payment for the same month, both sets of fields are populated.
  /// When only one list has a payment, the other side is null.
  /// Result ids are sequential starting at 1.
  static List<MergedMonthlyPayment> mergeMonthlyPayments(
    List<MonthlyPayment> commercial,
    List<MonthlyPayment> providentFund,
  ) {
    if (commercial.isEmpty && providentFund.isEmpty) {
      return const [];
    }

    // Build lookup maps keyed by year*12+month
    final commercialMap = <int, MonthlyPayment>{};
    for (final p in commercial) {
      final key = _dateKey(p.date);
      commercialMap[key] = p;
    }

    final providentFundMap = <int, MonthlyPayment>{};
    for (final p in providentFund) {
      final key = _dateKey(p.date);
      providentFundMap[key] = p;
    }

    // Collect and sort all unique date keys
    final allKeys = <int>{...commercialMap.keys, ...providentFundMap.keys}
        .toList()
      ..sort();

    // Build merged list
    final merged = <MergedMonthlyPayment>[];
    for (var i = 0; i < allKeys.length; i++) {
      final key = allKeys[i];
      final c = commercialMap[key];
      final p = providentFundMap[key];

      // Use date from whichever payment exists
      final date = c?.date ?? p?.date!;

      merged.add(MergedMonthlyPayment(
        id: i + 1,
        date: date!,
        commercialPayment: c?.monthlyPayment,
        commercialPrincipal: c?.principal,
        commercialInterest: c?.interest,
        providentFundPayment: p?.monthlyPayment,
        providentFundPrincipal: p?.principal,
        providentFundInterest: p?.interest,
      ));
    }

    return merged;
  }

  /// Generate a comparable integer key from a date (year * 12 + month).
  static int _dateKey(DateTime date) => date.year * 12 + date.month;
}
