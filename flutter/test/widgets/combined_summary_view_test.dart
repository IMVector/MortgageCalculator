import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_calculator/models/loan_comparison_result.dart';
import 'package:mortgage_calculator/widgets/combined_summary_view.dart';

void main() {
  /// Wraps [CombinedSummaryView] in a scrollable MaterialApp for testing.
  ///
  /// A [SingleChildScrollView] prevents RenderFlex overflow when the
  /// payment list is taller than the test surface.
  Widget wrapInApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  /// Sets a large virtual screen size so tall payment lists don't overflow.
  void setLargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
  }

  /// Helper to build a [MergedMonthlyPayment] with sensible defaults.
  MergedMonthlyPayment mergedPayment({
    required int id,
    required DateTime date,
    double? commercialPayment,
    double? commercialPrincipal,
    double? commercialInterest,
    double? providentFundPayment,
    double? providentFundPrincipal,
    double? providentFundInterest,
  }) {
    return MergedMonthlyPayment(
      id: id,
      date: date,
      commercialPayment: commercialPayment,
      commercialPrincipal: commercialPrincipal,
      commercialInterest: commercialInterest,
      providentFundPayment: providentFundPayment,
      providentFundPrincipal: providentFundPrincipal,
      providentFundInterest: providentFundInterest,
    );
  }

  group('CombinedSummaryView', () {
    group('empty state', () {
      testWidgets('renders without crashing when mergedPayments is empty',
          (tester) async {
        await tester.pumpWidget(wrapInApp(
          const CombinedSummaryView(mergedPayments: []),
        ));

        // Should still render the header without throwing.
        expect(find.text('合并还款明细'), findsOneWidget);
        expect(find.text('共 0 期'), findsOneWidget);
      });

      testWidgets('shows empty ListView when expanded with no payments',
          (tester) async {
        await tester.pumpWidget(wrapInApp(
          const CombinedSummaryView(mergedPayments: []),
        ));

        // Tap header to expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // All 9 column headers appear but no payment rows.
        expect(find.text('期数'), findsOneWidget);
        expect(find.text('日期'), findsOneWidget);
        expect(find.text('合计月供'), findsOneWidget);
        expect(find.text('商贷月供'), findsOneWidget);
        expect(find.text('公积金月供'), findsOneWidget);
        expect(find.text('商贷本金'), findsOneWidget);
        expect(find.text('商贷利息'), findsOneWidget);
        expect(find.text('公积金本金'), findsOneWidget);
        expect(find.text('公积金利息'), findsOneWidget);

        // No "显示全部" button since there are 0 payments.
        expect(find.textContaining('显示全部'), findsNothing);
      });
    });

    group('renders payment rows', () {
      testWidgets('displays correct period numbers, dates, and amounts',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
          mergedPayment(
            id: 2,
            date: DateTime(2024, 2),
            commercialPayment: 5010,
            commercialPrincipal: 3010,
            commercialInterest: 2000,
            providentFundPayment: 3010,
            providentFundPrincipal: 2010,
            providentFundInterest: 1000,
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand the view.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // Period numbers.
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Dates formatted as YYYY-MM.
        expect(find.text('2024-01'), findsOneWidget);
        expect(find.text('2024-02'), findsOneWidget);

        // Total payment for row 1: 5000 + 3000 = 8000.
        expect(find.text('8,000.00'), findsOneWidget);

        // Total payment for row 2: 5010 + 3010 = 8020.
        expect(find.text('8,020.00'), findsOneWidget);
      });

      testWidgets('displays principal and interest in inline columns',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand the view.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // Commercial principal: 3,000.00
        expect(find.text('3,000.00'), findsWidgets);

        // Commercial interest: 2,000.00
        expect(find.text('2,000.00'), findsWidgets);

        // Provident fund principal: 2,000.00 (same as comm interest)
        // Provident fund interest: 1,000.00
        expect(find.text('1,000.00'), findsOneWidget);
      });

      testWidgets('shows header with correct payment count', (tester) async {
        final payments = List.generate(
          5,
          (i) => mergedPayment(
            id: i + 1,
            date: DateTime(2024, i + 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        );

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        expect(find.text('共 5 期'), findsOneWidget);
      });
    });

    group('null fields show "已还清"', () {
      testWidgets('shows "已还清" when commercial loan fields are null',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
            // All commercial fields are null
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // "已还清" appears 3 times: 商贷月供, 商贷本金, 商贷利息.
        expect(find.text('已还清'), findsNWidgets(3));

        // Total payment equals provident fund payment (3,000), so "3,000.00"
        // appears in both 合计月供 and 公积金月供 columns.
        expect(find.text('3,000.00'), findsWidgets);
        expect(find.text('2,000.00'), findsOneWidget);
        expect(find.text('1,000.00'), findsOneWidget);
      });

      testWidgets('shows "已还清" when provident fund fields are null',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            // All provident fund fields are null
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // "已还清" appears 3 times: 公积金月供, 公积金本金, 公积金利息.
        expect(find.text('已还清'), findsNWidgets(3));

        // Total payment equals commercial payment (5,000), so "5,000.00"
        // appears in both 合计月供 and 商贷月供 columns.
        expect(find.text('5,000.00'), findsWidgets);
        expect(find.text('3,000.00'), findsOneWidget);
        expect(find.text('2,000.00'), findsOneWidget);
      });

      testWidgets('shows "已还清" for all columns when both loans are null',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            // All payment fields are null
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // 6 "已还清": 商贷月供, 商贷本金, 商贷利息, 公积金月供, 公积金本金, 公积金利息.
        expect(find.text('已还清'), findsNWidgets(6));

        // Total is 0.
        expect(find.text('0.00'), findsOneWidget);
      });

      testWidgets('shows "已还清" when only commercialPrincipal is null',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
            // commercialPrincipal is null
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // Only 1 "已还清" for 商贷本金.
        expect(find.text('已还清'), findsOneWidget);
      });
    });

    group('expand/collapse behavior', () {
      testWidgets('starts collapsed by default', (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Header is visible.
        expect(find.text('合并还款明细'), findsOneWidget);

        // All column headers are NOT visible when collapsed.
        expect(find.text('期数'), findsNothing);
        expect(find.text('商贷本金'), findsNothing);
        expect(find.text('商贷利息'), findsNothing);
        expect(find.text('公积金本金'), findsNothing);
        expect(find.text('公积金利息'), findsNothing);
      });

      testWidgets('expands when header is tapped', (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Tap to expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // All 9 column headers now visible.
        expect(find.text('期数'), findsOneWidget);
        expect(find.text('日期'), findsOneWidget);
        expect(find.text('合计月供'), findsOneWidget);
        expect(find.text('商贷月供'), findsOneWidget);
        expect(find.text('公积金月供'), findsOneWidget);
        expect(find.text('商贷本金'), findsOneWidget);
        expect(find.text('商贷利息'), findsOneWidget);
        expect(find.text('公积金本金'), findsOneWidget);
        expect(find.text('公积金利息'), findsOneWidget);
      });

      testWidgets('collapses when header is tapped again', (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand then collapse.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // Column headers hidden again, including new columns.
        expect(find.text('期数'), findsNothing);
        expect(find.text('商贷本金'), findsNothing);
        expect(find.text('商贷利息'), findsNothing);
        expect(find.text('公积金本金'), findsNothing);
        expect(find.text('公积金利息'), findsNothing);
      });
    });

    group('"显示全部" button', () {
      testWidgets('does not appear when <= 24 payments', (tester) async {
        setLargeSurface(tester);
        final payments = List.generate(
          24,
          (i) => mergedPayment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        );

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        expect(find.textContaining('显示全部'), findsNothing);
      });

      testWidgets('appears when > 24 payments', (tester) async {
        setLargeSurface(tester);
        final payments = List.generate(
          30,
          (i) => mergedPayment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        );

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // "显示全部" button should appear (may be off-screen).
        final showAllFinder = find.textContaining('显示全部');
        expect(showAllFinder, findsOneWidget);
      });

      testWidgets('shows all payments when "显示全部" is tapped',
          (tester) async {
        setLargeSurface(tester);
        final payments = List.generate(
          30,
          (i) => mergedPayment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        );

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // Scroll to make the "显示全部" button visible, then tap it.
        final showAllFinder = find.textContaining('显示全部');
        expect(showAllFinder, findsOneWidget);
        await tester.ensureVisible(showAllFinder);
        await tester.pumpAndSettle();
        await tester.tap(showAllFinder);
        await tester.pumpAndSettle();

        // The "显示全部" button should disappear after tapping.
        expect(find.textContaining('显示全部'), findsNothing);
      });

      testWidgets('shows all payments when exactly 25 payments (one over)',
          (tester) async {
        setLargeSurface(tester);
        final payments = List.generate(
          25,
          (i) => mergedPayment(
            id: i + 1,
            date: DateTime(2024, (i % 12) + 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        );

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // "显示全部" should appear (25 > 24).
        final showAllFinder = find.textContaining('显示全部');
        expect(showAllFinder, findsOneWidget);

        // Scroll to it and tap.
        await tester.ensureVisible(showAllFinder);
        await tester.pumpAndSettle();
        await tester.tap(showAllFinder);
        await tester.pumpAndSettle();

        // The "显示全部" button should disappear.
        expect(find.textContaining('显示全部'), findsNothing);
      });
    });

    group('interest columns use orange color', () {
      testWidgets('commercialInterest and providentFundInterest use orange',
          (tester) async {
        final payments = [
          mergedPayment(
            id: 1,
            date: DateTime(2024, 1),
            commercialPayment: 5000,
            commercialPrincipal: 3000,
            commercialInterest: 2000,
            providentFundPayment: 3000,
            providentFundPrincipal: 2000,
            providentFundInterest: 1000,
          ),
        ];

        await tester.pumpWidget(wrapInApp(
          CombinedSummaryView(mergedPayments: payments),
        ));

        // Expand.
        await tester.tap(find.text('合并还款明细'));
        await tester.pumpAndSettle();

        // Find the interest text widgets and verify orange color.
        // Commercial interest: 2,000.00
        final commInterestText = find.text('2,000.00');
        expect(commInterestText, findsWidgets);
        // At least one of the "2,000.00" texts should be orange
        // (the commercial interest column).
        bool foundOrange = false;
        for (final element in commInterestText.evaluate()) {
          final widget = element.widget;
          if (widget is Text) {
            final style = widget.style;
            if (style?.color == Colors.orange) {
              foundOrange = true;
              break;
            }
          }
        }
        expect(foundOrange, isTrue,
            reason: 'Commercial interest should be orange');

        // Provident fund interest: 1,000.00 should be orange.
        final provInterestText = find.text('1,000.00');
        expect(provInterestText, findsOneWidget);
        final provWidget = provInterestText.evaluate().first.widget;
        expect(provWidget, isA<Text>());
        final provText = provWidget as Text;
        expect(provText.style?.color, Colors.orange);
      });
    });
  });
}
