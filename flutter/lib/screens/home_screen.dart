import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_manager.dart';
import '../services/loan_comparison_service.dart';
import '../services/mortgage_calculator_service.dart';
import 'loan_input_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  LoanCalculationResult? _calculationResult;
  LoanComparisonResult? _comparisonResult;

  @override
  void initState() {
    super.initState();
    // 在下一帧执行初始计算，确保 context 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateLoan();
    });
  }

  void _calculateLoan() {
    final data = context.read<DataManager>();

    // Original calculation without prepayments (baseline for comparison)
    final originalResult = MortgageCalculatorService.calculateLoan(
      commercial: data.commercialLoan,
      providentFund: data.providentFundLoan,
      prepayments: const [],
    );

    // Current calculation with actual prepayments
    final currentResult = MortgageCalculatorService.calculateLoan(
      commercial: data.commercialLoan,
      providentFund: data.providentFundLoan,
      prepayments: data.prepayments.toList(),
    );

    final comparison = LoanComparisonService.compare(
      originalResult,
      currentResult,
    );

    setState(() {
      _calculationResult = currentResult;
      _comparisonResult = comparison;
    });
  }

  void _onCalculate() {
    _calculateLoan();
    // 切换到结果页
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _onRecalculate() {
    _calculateLoan();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 DataManager 变化，提前还款变化时自动重新计算
    context.watch<DataManager>();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LoanInputScreen(onCalculate: _onCalculate),
          ResultScreen(
            result: _calculationResult,
            comparisonResult: _comparisonResult,
            onRecalculate: _onRecalculate,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: '贷款输入',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '计算结果',
          ),
        ],
      ),
    );
  }
}
