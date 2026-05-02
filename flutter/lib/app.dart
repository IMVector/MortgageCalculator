import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/data_manager.dart';

class MortgageCalculatorApp extends StatefulWidget {
  const MortgageCalculatorApp({super.key});

  @override
  State<MortgageCalculatorApp> createState() => _MortgageCalculatorAppState();
}

class _MortgageCalculatorAppState extends State<MortgageCalculatorApp> {
  late Future<DataManager> _dataManagerFuture;

  @override
  void initState() {
    super.initState();
    _dataManagerFuture = DataManager.create();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataManager>(
      future: _dataManagerFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return ChangeNotifierProvider.value(
          value: snapshot.data!,
          child: MaterialApp(
            title: '房贷计算器',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
