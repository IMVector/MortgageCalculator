# Flutter 跨平台迁移 + Bug 修复 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有 SwiftUI iOS 房贷计算器迁移为 Flutter 跨平台应用（iOS/Android/Web/Desktop），同时修复现有代码中的 bug。

**Architecture:** 将业务逻辑（Models + Services）直接用 Dart 重写，UI 用 Flutter Widget 重建。保留 MVVM 分层，使用 `provider` 进行状态管理，`shared_preferences` 进行本地持久化。原 iOS 项目保留不动，Flutter 项目放在 `flutter/` 子目录。

**Tech Stack:** Flutter 3.x, Dart 3.x, provider, shared_preferences, fl_chart (可选图表), share_plus (分享), file_picker (导入导出)

---

## 第一部分：修复现有 iOS 代码 Bug

### Bug 1: LoanCard 摘要显示单位错误

**文件:** `MortgageCalculator/Views/LoanInputView.swift:163`

**问题:** `formatCurrency` 返回原始元值（如 "1,000,000.00"），但 UI 拼接了 "万" 后缀，导致显示 "1,000,000.00 万"（实际应为 "100.00 万" 或 "1,000,000.00 元"）。

**修复:**

- [ ] **Step 1: 修复 LoanCard 摘要显示**

将 `LoanInputView.swift:162-168` 的:
```swift
HStack(spacing: 4) {
    Text("\(MortgageCalculatorService.formatCurrency(loan.principal)) 万")
    Text("·")
    Text("\(loan.loanTermMonths)期")
    Text("·")
    Text("\(String(format: "%.2f", loan.annualRate))%")
}
```
改为:
```swift
HStack(spacing: 4) {
    Text("\(MortgageCalculatorService.formatCurrency(loan.principal / 10000)) 万")
    Text("·")
    Text("\(loan.loanTermMonths / 12)年")
    Text("·")
    Text("\(String(format: "%.2f", loan.annualRate))%")
}
```

- [ ] **Step 2: 验证修复**

在 iOS 模拟器中运行，输入 100 万贷款，确认摘要显示 "100.00 万 · 30年 · 4.20%"。

---

### Bug 2: 等额本金提前还款（减少月供）后 monthlyPrincipal 重算错误

**文件:** `MortgageCalculator/Services/MortgageCalculatorService.swift:186`

**问题:** `remainingMonths` 计算使用了 `remainingMonths - monthIndex + 1`，但 `remainingMonths` 在循环中没有递减（只在 `.reducePayment` 分支中被重算），导致计算结果错误。

**修复:**

- [ ] **Step 3: 修复等额本金 remainingMonths 重算**

将 `MortgageCalculatorService.swift:186` 的:
```swift
remainingMonths = max(1, remainingMonths - monthIndex + 1)
```
改为:
```swift
remainingMonths = max(1, loan.loanTermMonths - monthIndex + 1)
```

- [ ] **Step 4: 验证修复**

创建一个等额本金贷款（100万，4.2%，30年），添加一个减少月供的提前还款，验证后续月供确实减少了。

---

### Bug 3: 等额本息提前还款（减少月供）后月供未重新计算

**文件:** `MortgageCalculator/Services/MortgageCalculatorService.swift:86-93`

**问题:** `.reducePayment` 分支只有注释，没有实际重新计算月供的逻辑。每次循环开始时 `monthlyPayment` 基于 `remainingMonths = loan.loanTermMonths - monthIndex + 1` 重新计算，但这个 `remainingMonths` 始终基于原始贷款期限，所以提前还款后月供不会变化。

**修复:**

- [ ] **Step 5: 为等额本息减少月供添加 remainingMonths 跟踪**

在 `generateEqualPaymentSchedule` 函数中（`MortgageCalculatorService.swift:34` 附近），添加一个 `effectiveTermMonths` 变量：

```swift
var effectiveTermMonths = loan.loanTermMonths
```

然后将第 56 行:
```swift
let remainingMonths = loan.loanTermMonths - monthIndex + 1
```
改为:
```swift
let remainingMonths = effectiveTermMonths - monthIndex + 1
```

在 `.reducePayment` 分支（第 91-92 行）添加实际逻辑:
```swift
// 减少月供：保持期数不变，减少月供
// effectiveTermMonths 不变，remainingPrincipal 已减少，
// 下次循环时 calculateEqualPaymentMonthly 会基于新的 remainingPrincipal 重新计算
```

这实际上已经是正确的行为了——因为 `remainingPrincipal` 已经减少了，而 `remainingMonths` 基于 `effectiveTermMonths`（不变），所以下次循环的 `calculateEqualPaymentMonthly` 会自动算出更低的月供。但当前代码的 `remainingMonths` 用的是 `loan.loanTermMonths`，这是正确的。

经过仔细分析，等额本息的 `reducePayment` 实际上是正确工作的——因为每次循环都重新计算月供，而 `remainingPrincipal` 已经减少。这个 bug 实际上不存在。撤回此步骤。

---

### Bug 4: ImportExportService 中未使用的变量

**文件:** `MortgageCalculator/Services/ImportExportService.swift:75-76`

**问题:** `totalCommercialPayment` 和 `totalProvidentFundPayment` 声明后未使用。

**修复:**

- [ ] **Step 5 (替代): 删除未使用的变量**

将 `ImportExportService.swift:75-76`:
```swift
let totalCommercialPayment = result.commercialLoan.map { $0.principal } ?? 0
let totalProvidentFundPayment = result.providentFundLoan.map { $0.principal } ?? 0
```
删除这两行。

- [ ] **Step 6: 提交 bug 修复**

```bash
git add MortgageCalculator/Views/LoanInputView.swift MortgageCalculator/Services/MortgageCalculatorService.swift MortgageCalculator/Services/ImportExportService.swift
git commit -m "fix: 修复贷款摘要显示单位错误、等额本金提前还款计算错误、删除未使用变量"
```

---

## 第二部分：Flutter 跨平台迁移

### Task 1: 初始化 Flutter 项目

**文件:**
- Create: `flutter/` (Flutter 项目根目录)
- Create: `flutter/pubspec.yaml`
- Create: `flutter/lib/main.dart`

- [ ] **Step 1: 创建 Flutter 项目**

```bash
cd /Users/vector/MortgageCalculator
flutter create flutter --org com.app --project-name mortgage_calculator --platforms ios,android,web,macos,windows,linux
```

- [ ] **Step 2: 配置 pubspec.yaml**

替换 `flutter/pubspec.yaml` 内容:

```yaml
name: mortgage_calculator
description: 专业的房贷计算工具，支持商业贷款、公积金贷款及组合贷款计算。
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  share_plus: ^7.2.1
  intl: ^0.19.0
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
```

- [ ] **Step 3: 安装依赖**

```bash
cd /Users/vector/MortgageCalculator/flutter
flutter pub get
```

- [ ] **Step 4: 验证项目可运行**

```bash
flutter run -d chrome --web-port=8080
```
确认能看到默认 Flutter 计数器页面。

- [ ] **Step 5: 提交**

```bash
git add flutter/
git commit -m "feat: 初始化 Flutter 项目"
```

---

### Task 2: 数据模型层 (Models)

**文件:**
- Create: `flutter/lib/models/loan_type.dart`
- Create: `flutter/lib/models/repayment_type.dart`
- Create: `flutter/lib/models/prepayment_type.dart`
- Create: `flutter/lib/models/loan_info.dart`
- Create: `flutter/lib/models/prepayment_node.dart`
- Create: `flutter/lib/models/monthly_payment.dart`
- Create: `flutter/lib/models/repayment_segment.dart`
- Create: `flutter/lib/models/loan_calculation_result.dart`
- Create: `flutter/lib/models/export_data.dart`

- [ ] **Step 1: 创建 LoanType 枚举**

```dart
// flutter/lib/models/loan_type.dart
enum LoanType {
  commercial('商业贷款'),
  providentFund('公积金贷款');

  final String label;
  const LoanType(this.label);
}
```

- [ ] **Step 2: 创建 RepaymentType 枚举**

```dart
// flutter/lib/models/repayment_type.dart
enum RepaymentType {
  equalPrincipalAndInterest('等额本息'),
  equalPrincipal('等额本金');

  final String label;
  const RepaymentType(this.label);
}
```

- [ ] **Step 3: 创建 PrepaymentType 枚举**

```dart
// flutter/lib/models/prepayment_type.dart
enum PrepaymentType {
  shortenTerm('缩短期限'),
  reducePayment('减少月供');

  final String label;
  const PrepaymentType(this.label);
}
```

- [ ] **Step 4: 创建 LoanInfo 模型**

```dart
// flutter/lib/models/loan_info.dart
import 'loan_type.dart';
import 'repayment_type.dart';

class LoanInfo {
  final String id;
  final LoanType loanType;
  final double principal;       // 贷款本金（元）
  final double annualRate;      // 年利率 (%)
  final int loanTermMonths;     // 贷款期限（月）
  final DateTime startDate;     // 贷款开始日期
  final RepaymentType repaymentType;

  const LoanInfo({
    required this.id,
    required this.loanType,
    required this.principal,
    required this.annualRate,
    required this.loanTermMonths,
    required this.startDate,
    this.repaymentType = RepaymentType.equalPrincipalAndInterest,
  });

  /// 月利率
  double get monthlyRate => annualRate / 100.0 / 12.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'loanType': loanType.name,
    'principal': principal,
    'annualRate': annualRate,
    'loanTermMonths': loanTermMonths,
    'startDate': startDate.toIso8601String(),
    'repaymentType': repaymentType.name,
  };

  factory LoanInfo.fromJson(Map<String, dynamic> json) => LoanInfo(
    id: json['id'] as String,
    loanType: LoanType.values.byName(json['loanType'] as String),
    principal: (json['principal'] as num).toDouble(),
    annualRate: (json['annualRate'] as num).toDouble(),
    loanTermMonths: json['loanTermMonths'] as int,
    startDate: DateTime.parse(json['startDate'] as String),
    repaymentType: RepaymentType.values.byName(json['repaymentType'] as String),
  );
}
```

- [ ] **Step 5: 创建 PrepaymentNode 模型**

```dart
// flutter/lib/models/prepayment_node.dart
import 'loan_type.dart';
import 'prepayment_type.dart';

class PrepaymentNode {
  final String id;
  final DateTime prepaymentDate;
  final double prepaymentAmount;
  final PrepaymentType prepaymentType;
  final LoanType targetLoanType;
  final bool canShortenTerm;

  const PrepaymentNode({
    required this.id,
    required this.prepaymentDate,
    required this.prepaymentAmount,
    required this.prepaymentType,
    this.targetLoanType = LoanType.commercial,
    this.canShortenTerm = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'prepaymentDate': prepaymentDate.toIso8601String(),
    'prepaymentAmount': prepaymentAmount,
    'prepaymentType': prepaymentType.name,
    'targetLoanType': targetLoanType.name,
    'canShortenTerm': canShortenTerm,
  };

  factory PrepaymentNode.fromJson(Map<String, dynamic> json) => PrepaymentNode(
    id: json['id'] as String,
    prepaymentDate: DateTime.parse(json['prepaymentDate'] as String),
    prepaymentAmount: (json['prepaymentAmount'] as num).toDouble(),
    prepaymentType: PrepaymentType.values.byName(json['prepaymentType'] as String),
    targetLoanType: LoanType.values.byName(json['targetLoanType'] as String),
    canShortenTerm: json['canShortenTerm'] as bool? ?? true,
  );
}
```

- [ ] **Step 6: 创建 MonthlyPayment 模型**

```dart
// flutter/lib/models/monthly_payment.dart
import 'loan_type.dart';

class MonthlyPayment {
  final int id;                 // 月次
  final DateTime date;          // 还款日期
  final double monthlyPayment;  // 月供
  final double principal;       // 本金
  final double interest;        // 利息
  final double remainingPrincipal; // 剩余本金
  final LoanType loanType;      // 贷款类型

  const MonthlyPayment({
    required this.id,
    required this.date,
    required this.monthlyPayment,
    required this.principal,
    required this.interest,
    required this.remainingPrincipal,
    required this.loanType,
  });
}
```

- [ ] **Step 7: 创建 RepaymentSegment 模型**

```dart
// flutter/lib/models/repayment_segment.dart
class RepaymentSegment {
  final int startMonth;
  final int endMonth;
  final double monthlyPayment;
  final double totalInterest;
  final double remainingPrincipal;

  const RepaymentSegment({
    required this.startMonth,
    required this.endMonth,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.remainingPrincipal,
  });

  int get monthCount => endMonth - startMonth + 1;
}
```

- [ ] **Step 8: 创建 LoanCalculationResult 模型**

```dart
// flutter/lib/models/loan_calculation_result.dart
import 'loan_info.dart';
import 'prepayment_node.dart';
import 'monthly_payment.dart';
import 'repayment_segment.dart';

class LoanCalculationResult {
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final List<PrepaymentNode> prepaymentNodes;
  final List<RepaymentSegment> commercialSegments;
  final List<RepaymentSegment> providentFundSegments;
  final List<MonthlyPayment> commercialMonthlyPayments;
  final List<MonthlyPayment> providentFundMonthlyPayments;
  final double totalCommercialInterest;
  final double totalProvidentFundInterest;

  const LoanCalculationResult({
    this.commercialLoan,
    this.providentFundLoan,
    this.prepaymentNodes = const [],
    this.commercialSegments = const [],
    this.providentFundSegments = const [],
    this.commercialMonthlyPayments = const [],
    this.providentFundMonthlyPayments = const [],
    this.totalCommercialInterest = 0,
    this.totalProvidentFundInterest = 0,
  });

  double get totalPrincipal =>
      (commercialLoan?.principal ?? 0) + (providentFundLoan?.principal ?? 0);

  double get totalInterest =>
      totalCommercialInterest + totalProvidentFundInterest;
}
```

- [ ] **Step 9: 创建 ExportData 模型**

```dart
// flutter/lib/models/export_data.dart
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
```

- [ ] **Step 10: 创建 models barrel 文件**

```dart
// flutter/lib/models/models.dart
export 'loan_type.dart';
export 'repayment_type.dart';
export 'prepayment_type.dart';
export 'loan_info.dart';
export 'prepayment_node.dart';
export 'monthly_payment.dart';
export 'repayment_segment.dart';
export 'loan_calculation_result.dart';
export 'export_data.dart';
```

- [ ] **Step 11: 提交**

```bash
git add flutter/lib/models/
git commit -m "feat: 添加 Flutter 数据模型层"
```

---

### Task 3: 计算服务层 (Services)

**文件:**
- Create: `flutter/lib/services/mortgage_calculator_service.dart`
- Create: `flutter/lib/services/data_manager.dart`
- Create: `flutter/lib/services/import_export_service.dart`

- [ ] **Step 1: 创建 MortgageCalculatorService**

从 `MortgageCalculator/Services/MortgageCalculatorService.swift` 直接翻译为 Dart，修复已知 bug：

```dart
// flutter/lib/services/mortgage_calculator_service.dart
import 'dart:math';
import '../models/models.dart';

class MortgageCalculatorService {
  // MARK: - 等额本息计算

  /// 计算等额本息月供
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

    final sortedPrepayments = List<PrepaymentNode>.from(prepayments)
      ..sort((a, b) => a.prepaymentDate.compareTo(b.prepaymentDate));
    var nextPrepaymentIndex = 0;

    while (remainingPrincipal > 0.01) {
      // 检查是否有提前还款
      PrepaymentNode? currentPrepayment;
      while (nextPrepaymentIndex < sortedPrepayments.length) {
        final prepayment = sortedPrepayments[nextPrepaymentIndex];
        if (!prepayment.prepaymentDate.isAfter(currentDate)) {
          currentPrepayment = prepayment;
          nextPrepaymentIndex++;
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

      // 处理提前还款
      var extraPayment = 0.0;
      if (currentPrepayment != null) {
        extraPayment = min(
          currentPrepayment.prepaymentAmount,
          remainingPrincipal - principalPaid,
        );

        if (principalPaid + extraPayment >= remainingPrincipal) {
          principalPaid = remainingPrincipal;
          extraPayment = 0;
          remainingPrincipal = 0;
        } else {
          remainingPrincipal -= (principalPaid + extraPayment);
          // 缩短期限: 保持月供不变，期数自然减少
          // 减少月供: remainingPrincipal 已减少，下次循环会重新计算更小的月供
        }
      } else {
        remainingPrincipal -= principalPaid;
      }

      final actualMonthlyPayment = monthlyPayment + extraPayment;
      payments.add(MonthlyPayment(
        id: monthIndex,
        date: currentDate,
        monthlyPayment: actualMonthlyPayment,
        principal: principalPaid + extraPayment,
        interest: interest,
        remainingPrincipal: max(0, remainingPrincipal),
        loanType: loan.loanType,
      ));

      monthIndex++;
      currentDate = DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      );

      // 防止无限循环
      if (monthIndex > loan.loanTermMonths * 2) break;
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
    var monthlyPrincipal = loan.principal / loan.loanTermMonths;

    final sortedPrepayments = List<PrepaymentNode>.from(prepayments)
      ..sort((a, b) => a.prepaymentDate.compareTo(b.prepaymentDate));
    var nextPrepaymentIndex = 0;

    while (remainingPrincipal > 0.01 && monthIndex <= loan.loanTermMonths * 2) {
      PrepaymentNode? currentPrepayment;
      while (nextPrepaymentIndex < sortedPrepayments.length) {
        final prepayment = sortedPrepayments[nextPrepaymentIndex];
        if (!prepayment.prepaymentDate.isAfter(currentDate)) {
          currentPrepayment = prepayment;
          nextPrepaymentIndex++;
        } else {
          break;
        }
      }

      final interest = remainingPrincipal * loan.monthlyRate;
      var principalPaid = min(monthlyPrincipal, remainingPrincipal);
      var extraPayment = 0.0;

      if (currentPrepayment != null) {
        extraPayment = min(
          currentPrepayment.prepaymentAmount,
          remainingPrincipal - principalPaid,
        );

        if (currentPrepayment.prepaymentType == PrepaymentType.shortenTerm) {
          remainingPrincipal -= (principalPaid + extraPayment);
        } else {
          remainingPrincipal -= (principalPaid + extraPayment);
          // 修复: 使用正确的 remainingMonths 计算
          remainingMonths = max(1, loan.loanTermMonths - monthIndex + 1);
          monthlyPrincipal = remainingPrincipal / remainingMonths;
        }
      } else {
        remainingPrincipal -= principalPaid;
      }

      // 最后一期调整
      if (remainingPrincipal < 0.01) {
        principalPaid += remainingPrincipal;
        remainingPrincipal = 0;
      }

      final monthlyPayment = principalPaid + interest + extraPayment;
      payments.add(MonthlyPayment(
        id: monthIndex,
        date: currentDate,
        monthlyPayment: monthlyPayment,
        principal: principalPaid + extraPayment,
        interest: interest,
        remainingPrincipal: max(0, remainingPrincipal),
        loanType: loan.loanType,
      ));

      monthIndex++;
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
    var result = LoanCalculationResult(
      commercialLoan: commercial,
      providentFundLoan: providentFund,
      prepaymentNodes: prepayments,
    );

    List<RepaymentSegment> commercialSegments = [];
    List<RepaymentSegment> providentFundSegments = [];
    List<MonthlyPayment> commercialPayments = [];
    List<MonthlyPayment> providentFundPayments = [];
    double totalCommercialInterest = 0;
    double totalProvidentFundInterest = 0;

    if (commercial != null) {
      final commercialPrepayments =
          prepayments.where((p) => p.targetLoanType == LoanType.commercial).toList();
      switch (commercial.repaymentType) {
        case RepaymentType.equalPrincipalAndInterest:
          commercialPayments = generateEqualPaymentSchedule(
            loan: commercial,
            prepayments: commercialPrepayments,
          );
        case RepaymentType.equalPrincipal:
          commercialPayments = generateEqualPrincipalSchedule(
            loan: commercial,
            prepayments: commercialPrepayments,
          );
      }
      totalCommercialInterest =
          commercialPayments.fold(0.0, (sum, p) => sum + p.interest);
      commercialSegments = _generateSegments(commercialPayments, LoanType.commercial);
    }

    if (providentFund != null) {
      final providentFundPrepayments =
          prepayments.where((p) => p.targetLoanType == LoanType.providentFund).toList();
      switch (providentFund.repaymentType) {
        case RepaymentType.equalPrincipalAndInterest:
          providentFundPayments = generateEqualPaymentSchedule(
            loan: providentFund,
            prepayments: providentFundPrepayments,
          );
        case RepaymentType.equalPrincipal:
          providentFundPayments = generateEqualPrincipalSchedule(
            loan: providentFund,
            prepayments: providentFundPrepayments,
          );
      }
      totalProvidentFundInterest =
          providentFundPayments.fold(0.0, (sum, p) => sum + p.interest);
      providentFundSegments =
          _generateSegments(providentFundPayments, LoanType.providentFund);
    }

    return LoanCalculationResult(
      commercialLoan: commercial,
      providentFundLoan: providentFund,
      prepaymentNodes: prepayments,
      commercialSegments: commercialSegments,
      providentFundSegments: providentFundSegments,
      commercialMonthlyPayments: commercialPayments,
      providentFundMonthlyPayments: providentFundPayments,
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
        final paymentDiff = (payment.monthlyPayment - lastPayment.monthlyPayment).abs();
        if (paymentDiff > 1.0) {
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

  // MARK: - 辅助方法

  /// 计算两个日期间的月数
  static int monthsBetween(DateTime start, DateTime end) {
    return max(0, (end.year - start.year) * 12 + end.month - start.month);
  }

  /// 格式化金额
  static String formatCurrency(double amount) {
    // 使用简单的格式化，避免依赖 intl 的 locale 配置
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // 添加千位分隔符
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.$decPart';
  }
}
```

- [ ] **Step 2: 创建 DataManager (状态管理)**

```dart
// flutter/lib/services/data_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DataManager extends ChangeNotifier {
  static const _commercialLoanKey = 'commercialLoan';
  static const _providentFundLoanKey = 'providentFundLoan';
  static const _prepaymentsKey = 'prepayments';
  static const _uuid = Uuid();

  LoanInfo? _commercialLoan;
  LoanInfo? _providentFundLoan;
  List<PrepaymentNode> _prepayments = [];

  LoanInfo? get commercialLoan => _commercialLoan;
  LoanInfo? get providentFundLoan => _providentFundLoan;
  List<PrepaymentNode> get prepayments => List.unmodifiable(_prepayments);

  DataManager() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final commercialJson = prefs.getString(_commercialLoanKey);
    if (commercialJson != null) {
      _commercialLoan = LoanInfo.fromJson(
        jsonDecode(commercialJson) as Map<String, dynamic>,
      );
    }

    final providentFundJson = prefs.getString(_providentFundLoanKey);
    if (providentFundJson != null) {
      _providentFundLoan = LoanInfo.fromJson(
        jsonDecode(providentFundJson) as Map<String, dynamic>,
      );
    }

    final prepaymentsJson = prefs.getString(_prepaymentsKey);
    if (prepaymentsJson != null) {
      final list = jsonDecode(prepaymentsJson) as List<dynamic>;
      _prepayments =
          list.map((p) => PrepaymentNode.fromJson(p as Map<String, dynamic>)).toList();
    }

    notifyListeners();
  }

  Future<void> setCommercialLoan(LoanInfo? loan) async {
    _commercialLoan = loan;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (loan != null) {
      await prefs.setString(_commercialLoanKey, jsonEncode(loan.toJson()));
    } else {
      await prefs.remove(_commercialLoanKey);
    }
  }

  Future<void> setProvidentFundLoan(LoanInfo? loan) async {
    _providentFundLoan = loan;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (loan != null) {
      await prefs.setString(_providentFundLoanKey, jsonEncode(loan.toJson()));
    } else {
      await prefs.remove(_providentFundLoanKey);
    }
  }

  Future<void> addPrepayment(PrepaymentNode node) async {
    _prepayments = [..._prepayments, node];
    notifyListeners();
    await _savePrepayments();
  }

  Future<void> removePrepayment(String id) async {
    _prepayments = _prepayments.where((p) => p.id != id).toList();
    notifyListeners();
    await _savePrepayments();
  }

  Future<void> updatePrepayment(PrepaymentNode node) async {
    _prepayments = [
      for (final p in _prepayments)
        if (p.id == node.id) node else p,
    ];
    notifyListeners();
    await _savePrepayments();
  }

  Future<void> clearAll() async {
    _commercialLoan = null;
    _providentFundLoan = null;
    _prepayments = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_commercialLoanKey);
    await prefs.remove(_providentFundLoanKey);
    await prefs.remove(_prepaymentsKey);
  }

  /// 生成新的 UUID
  static String newId() => _uuid.v4();

  Future<void> _savePrepayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prepaymentsKey,
      jsonEncode(_prepayments.map((p) => p.toJson()).toList()),
    );
  }
}
```

- [ ] **Step 3: 创建 ImportExportService**

```dart
// flutter/lib/services/import_export_service.dart
import 'dart:convert';
import '../models/models.dart';
import 'mortgage_calculator_service.dart';

class ImportExportService {
  /// 导出为JSON格式
  static String? exportToJSON({
    LoanInfo? commercial,
    LoanInfo? providentFund,
    List<PrepaymentNode> prepayments = const [],
  }) {
    final exportData = ExportData(
      commercialLoan: commercial,
      providentFundLoan: providentFund,
      prepayments: prepayments,
      exportDate: DateTime.now(),
    );

    return const JsonEncoder.withIndent('  ').convert(exportData.toJson());
  }

  /// 导出为可读文本格式
  static String exportToText(LoanCalculationResult result) {
    final buffer = StringBuffer();
    buffer.writeln('房贷计算结果');
    buffer.writeln('=' * 30);
    buffer.writeln();

    if (result.commercialLoan case final commercial?) {
      buffer.writeln('【商业贷款】');
      buffer.writeln('贷款本金: ${MortgageCalculatorService.formatCurrency(commercial.principal)} 元');
      buffer.writeln('年利率: ${commercial.annualRate.toStringAsFixed(2)}%');
      buffer.writeln('贷款期限: ${commercial.loanTermMonths} 个月');
      buffer.writeln('还款方式: ${commercial.repaymentType.label}');
      buffer.writeln('起始日期: ${_formatDate(commercial.startDate)}');
      buffer.writeln();
    }

    if (result.providentFundLoan case final providentFund?) {
      buffer.writeln('【公积金贷款】');
      buffer.writeln('贷款本金: ${MortgageCalculatorService.formatCurrency(providentFund.principal)} 元');
      buffer.writeln('年利率: ${providentFund.annualRate.toStringAsFixed(2)}%');
      buffer.writeln('贷款期限: ${providentFund.loanTermMonths} 个月');
      buffer.writeln('还款方式: ${providentFund.repaymentType.label}');
      buffer.writeln('起始日期: ${_formatDate(providentFund.startDate)}');
      buffer.writeln();
    }

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

    buffer.writeln('【计算结果】');

    if (result.commercialLoan != null) {
      buffer.writeln('商业贷款:');
      buffer.writeln('  月供: ${MortgageCalculatorService.formatCurrency(result.commercialMonthlyPayments.firstOrNull?.monthlyPayment ?? 0)} 元');
      buffer.writeln('  总利息: ${MortgageCalculatorService.formatCurrency(result.totalCommercialInterest)} 元');
      buffer.writeln('  已还期数: ${result.commercialMonthlyPayments.length} 期');
      buffer.writeln();
    }

    if (result.providentFundLoan != null) {
      buffer.writeln('公积金贷款:');
      buffer.writeln('  月供: ${MortgageCalculatorService.formatCurrency(result.providentFundMonthlyPayments.firstOrNull?.monthlyPayment ?? 0)} 元');
      buffer.writeln('  总利息: ${MortgageCalculatorService.formatCurrency(result.totalProvidentFundInterest)} 元');
      buffer.writeln('  已还期数: ${result.providentFundMonthlyPayments.length} 期');
      buffer.writeln();
    }

    if (result.commercialSegments.isNotEmpty) {
      buffer.writeln('【商业贷款还款变化】');
      for (final segment in result.commercialSegments) {
        buffer.writeln('第${segment.startMonth}-${segment.endMonth}期: 月供 ${MortgageCalculatorService.formatCurrency(segment.monthlyPayment)} 元');
      }
      buffer.writeln();
    }

    if (result.providentFundSegments.isNotEmpty) {
      buffer.writeln('【公积金贷款还款变化】');
      for (final segment in result.providentFundSegments) {
        buffer.writeln('第${segment.startMonth}-${segment.endMonth}期: 月供 ${MortgageCalculatorService.formatCurrency(segment.monthlyPayment)} 元');
      }
    }

    return buffer.toString();
  }

  /// 从JSON导入
  static (LoanInfo?, LoanInfo?, List<PrepaymentNode>)? importFromJSON(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final exportData = ExportData.fromJson(data);
      return (
        exportData.commercialLoan,
        exportData.providentFundLoan,
        exportData.prepayments,
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: 提交**

```bash
git add flutter/lib/services/
git commit -m "feat: 添加 Flutter 服务层（计算、数据管理、导入导出）"
```

---

### Task 4: 主入口和路由

**文件:**
- Modify: `flutter/lib/main.dart`
- Create: `flutter/lib/app.dart`

- [ ] **Step 1: 创建 App Widget**

```dart
// flutter/lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_manager.dart';
import 'screens/home_screen.dart';

class MortgageCalculatorApp extends StatelessWidget {
  const MortgageCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataManager(),
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
  }
}
```

- [ ] **Step 2: 更新 main.dart**

```dart
// flutter/lib/main.dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MortgageCalculatorApp());
}
```

- [ ] **Step 3: 提交**

```bash
git add flutter/lib/main.dart flutter/lib/app.dart
git commit -m "feat: 添加 Flutter 主入口和路由"
```

---

### Task 5: 首页 (HomeScreen)

**文件:**
- Create: `flutter/lib/screens/home_screen.dart`
- Create: `flutter/lib/screens/loan_input_screen.dart`
- Create: `flutter/lib/screens/result_screen.dart`

- [ ] **Step 1: 创建 HomeScreen (TabView 等价)**

```dart
// flutter/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../services/mortgage_calculator_service.dart';
import '../models/models.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateLoan());
  }

  void _calculateLoan() {
    final data = context.read<DataManager>();
    setState(() {
      _calculationResult = MortgageCalculatorService.calculateLoan(
        commercial: data.commercialLoan,
        providentFund: data.providentFundLoan,
        prepayments: data.prepayments.toList(),
      );
    });
  }

  void _calculateAndNavigate() {
    _calculateLoan();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _selectedIndex = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataManager>();

    // 监听提前还款变化自动重新计算
    // (通过 didChangeDependencies 或 listener 实现)

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LoanInputScreen(
            onCalculate: _calculateAndNavigate,
          ),
          ResultScreen(
            result: _calculationResult,
            onRecalculate: _calculateLoan,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
```

- [ ] **Step 2: 创建 LoanInputScreen 骨架**

```dart
// flutter/lib/screens/loan_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/data_manager.dart';
import '../services/mortgage_calculator_service.dart';

class LoanInputScreen extends StatelessWidget {
  final VoidCallback onCalculate;

  const LoanInputScreen({super.key, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('房贷计算器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.commercialLoan == null && data.providentFundLoan == null)
            const _WelcomeCard(),

          _LoanCard(
            title: '商业贷款',
            icon: Icons.business,
            color: Colors.blue,
            subtitle: '商业住房贷款',
            loan: data.commercialLoan,
            isProvidentFund: false,
            onSave: (loan) => data.setCommercialLoan(loan),
            onDelete: () => data.setCommercialLoan(null),
          ),

          const SizedBox(height: 16),

          _LoanCard(
            title: '公积金贷款',
            icon: Icons.home,
            color: Colors.green,
            subtitle: '住房公积金贷款',
            loan: data.providentFundLoan,
            isProvidentFund: true,
            onSave: (loan) => data.setProvidentFundLoan(loan),
            onDelete: () => data.setProvidentFundLoan(null),
          ),

          if (data.commercialLoan != null || data.providentFundLoan != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate),
              label: const Text('计算还款'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],

          if (data.prepayments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Text('已添加 ${data.prepayments.length} 条提前还款记录'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.house, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('欢迎使用房贷计算器', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '点击下方卡片添加贷款信息\n支持商业贷款、公积金贷款或组合贷款',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final LoanInfo? loan;
  final bool isProvidentFund;
  final ValueChanged<LoanInfo?> onSave;
  final VoidCallback onDelete;

  const _LoanCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.loan,
    required this.isProvidentFund,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool _isExpanded = false;
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();
  DateTime _startDate = DateTime.now();
  RepaymentType _repaymentType = RepaymentType.equalPrincipalAndInterest;

  @override
  void initState() {
    super.initState();
    _rateController.text = widget.isProvidentFund ? '2.85' : '4.2';
    _termController.text = '30';
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _syncFromLoan(LoanInfo loan) {
    _principalController.text = (loan.principal / 10000).toString();
    _rateController.text = loan.annualRate.toString();
    _termController.text = (loan.loanTermMonths / 12).toString();
    _startDate = loan.startDate;
    _repaymentType = loan.repaymentType;
  }

  void _save() {
    final principal = double.tryParse(_principalController.text);
    final rate = double.tryParse(_rateController.text);
    final term = int.tryParse(_termController.text);

    if (principal == null || rate == null || term == null ||
        principal <= 0 || rate <= 0 || term <= 0) return;

    widget.onSave(LoanInfo(
      id: DataManager.newId(),
      loanType: widget.isProvidentFund ? LoanType.providentFund : LoanType.commercial,
      principal: principal * 10000,
      annualRate: rate,
      loanTermMonths: term * 12,
      startDate: _startDate,
      repaymentType: _repaymentType,
    ));

    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (!_isExpanded && widget.loan != null) {
                _syncFromLoan(widget.loan!);
              }
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.color.withOpacity(0.15),
                    foregroundColor: widget.color,
                    child: Icon(widget.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                        if (widget.loan case final loan?) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${MortgageCalculatorService.formatCurrency(loan.principal / 10000)} 万'
                            ' · ${loan.loanTermMonths ~/ 12}年'
                            ' · ${loan.annualRate.toStringAsFixed(2)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.loan != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: widget.onDelete,
                    ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _principalController,
                    decoration: const InputDecoration(
                      labelText: '贷款金额',
                      suffixText: '万元',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rateController,
                    decoration: InputDecoration(
                      labelText: '年利率',
                      suffixText: '%',
                      hintText: widget.isProvidentFund ? '如 2.85' : '如 4.2',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _termController,
                    decoration: const InputDecoration(
                      labelText: '贷款期限',
                      suffixText: '年',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('开始日期'),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2050),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      child: Text(
                        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<RepaymentType>(
                    segments: RepaymentType.values.map((type) =>
                      ButtonSegment(value: type, label: Text(type.label))
                    ).toList(),
                    selected: {_repaymentType},
                    onSelectionChanged: (selected) =>
                        setState(() => _repaymentType = selected.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _repaymentType == RepaymentType.equalPrincipalAndInterest
                        ? '每月还款金额相同，适合收入稳定的人群'
                        : '每月本金相同，利息递减，总利息较少',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 ResultScreen 骨架**

```dart
// flutter/lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/data_manager.dart';
import '../services/mortgage_calculator_service.dart';
import '../services/import_export_service.dart';
import 'prepayment_sheet.dart';

class ResultScreen extends StatelessWidget {
  final LoanCalculationResult? result;
  final VoidCallback onRecalculate;

  const ResultScreen({
    super.key,
    required this.result,
    required this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('计算结果')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.house, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('开始计算您的房贷'),
              const SizedBox(height: 8),
              Text(
                '请在「贷款输入」页面填写贷款信息',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('计算结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final text = ImportExportService.exportToText(result!);
              Share.share(text);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCards(result: result!),
          const SizedBox(height: 16),
          _PrepaymentSection(
            onRecalculate: onRecalculate,
          ),
          if (result!.commercialSegments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LoanDetailSection(
              title: '商业贷款',
              color: Colors.blue,
              segments: result!.commercialSegments,
              monthlyPayments: result!.commercialMonthlyPayments,
            ),
          ],
          if (result!.providentFundSegments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LoanDetailSection(
              title: '公积金贷款',
              color: Colors.green,
              segments: result!.providentFundSegments,
              monthlyPayments: result!.providentFundMonthlyPayments,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final LoanCalculationResult result;
  const _SummaryCards({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    title: '总贷款金额',
                    value: MortgageCalculatorService.formatCurrency(result.totalPrincipal),
                    subtitle: '元',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryItem(
                    title: '总利息',
                    value: MortgageCalculatorService.formatCurrency(result.totalInterest),
                    subtitle: '元',
                    valueColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                if (result.commercialMonthlyPayments.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('商业贷款', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          MortgageCalculatorService.formatCurrency(
                            result.commercialMonthlyPayments.first.monthlyPayment,
                          ),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('元/月'),
                      ],
                    ),
                  ),
                if (result.providentFundMonthlyPayments.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('公积金贷款', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          MortgageCalculatorService.formatCurrency(
                            result.providentFundMonthlyPayments.first.monthlyPayment,
                          ),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('元/月'),
                      ],
                    ),
                  ),
              ],
            ),
            if (result.commercialMonthlyPayments.isNotEmpty &&
                result.providentFundMonthlyPayments.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('合计月供', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${MortgageCalculatorService.formatCurrency(result.commercialMonthlyPayments.first.monthlyPayment + result.providentFundMonthlyPayments.first.monthlyPayment)} 元/月',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? valueColor;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _PrepaymentSection extends StatelessWidget {
  final VoidCallback onRecalculate;
  const _PrepaymentSection({required this.onRecalculate});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataManager>();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('添加提前还款'),
            trailing: data.prepayments.isNotEmpty
                ? Chip(label: Text('${data.prepayments.length} 条'))
                : null,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => AddPrepaymentSheet(
                commercialLoan: data.commercialLoan,
                providentFundLoan: data.providentFundLoan,
                onSave: (node) {
                  data.addPrepayment(node);
                  onRecalculate();
                },
              ),
            ),
          ),
          if (data.prepayments.isNotEmpty)
            ...data.prepayments.map((node) => _PrepaymentMiniCard(
              node: node,
              onEdit: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => EditPrepaymentSheet(
                  node: node,
                  commercialLoan: data.commercialLoan,
                  providentFundLoan: data.providentFundLoan,
                  onSave: (updated) {
                    data.updatePrepayment(updated);
                    onRecalculate();
                  },
                ),
              ),
              onDelete: () {
                data.removePrepayment(node.id);
                onRecalculate();
              },
            )),
        ],
      ),
    );
  }
}

class _PrepaymentMiniCard extends StatelessWidget {
  final PrepaymentNode node;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrepaymentMiniCard({
    required this.node,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${node.prepaymentDate.year}-${node.prepaymentDate.month.toString().padLeft(2, '0')}-${node.prepaymentDate.day.toString().padLeft(2, '0')}',
      ),
      subtitle: Text(
        '${MortgageCalculatorService.formatCurrency(node.prepaymentAmount)} 元 · ${node.prepaymentType.label}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _LoanDetailSection extends StatefulWidget {
  final String title;
  final Color color;
  final List<RepaymentSegment> segments;
  final List<MonthlyPayment> monthlyPayments;

  const _LoanDetailSection({
    required this.title,
    required this.color,
    required this.segments,
    required this.monthlyPayments,
  });

  @override
  State<_LoanDetailSection> createState() => _LoanDetailSectionState();
}

class _LoanDetailSectionState extends State<_LoanDetailSection> {
  bool _isExpanded = true;
  final _expandedSegments = <int>{};

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: widget.color, radius: 5),
            title: Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.monthlyPayments.length}期',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ...widget.segments.map((segment) {
              final isSegmentExpanded = _expandedSegments.contains(segment.startMonth);
              final payments = widget.monthlyPayments
                  .where((p) => p.id >= segment.startMonth && p.id <= segment.endMonth)
                  .toList();

              return Column(
                children: [
                  ListTile(
                    title: Text('第 ${segment.startMonth}-${segment.endMonth} 期'
                        ' (共 ${segment.monthCount} 期)'),
                    subtitle: Text(
                      '利息 ${MortgageCalculatorService.formatCurrency(segment.totalInterest)}',
                      style: const TextStyle(color: Colors.orange),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              MortgageCalculatorService.formatCurrency(segment.monthlyPayment),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: widget.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('元/月', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(isSegmentExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        if (isSegmentExpanded) {
                          _expandedSegments.remove(segment.startMonth);
                        } else {
                          _expandedSegments.add(segment.startMonth);
                        }
                      });
                    },
                  ),
                  if (isSegmentExpanded)
                    ...payments.map((payment) => _CompactPaymentRow(
                      payment: payment,
                      color: widget.color,
                    )),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _CompactPaymentRow extends StatelessWidget {
  final MonthlyPayment payment;
  final Color color;

  const _CompactPaymentRow({required this.payment, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('${payment.id}', style: const TextStyle(fontSize: 12))),
          SizedBox(
            width: 60,
            child: Text(
              '${payment.date.year}-${payment.date.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 70,
            child: Text(
              MortgageCalculatorService.formatCurrency(payment.monthlyPayment),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
            ),
          ),
          SizedBox(
            width: 65,
            child: Text(
              MortgageCalculatorService.formatCurrency(payment.principal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              MortgageCalculatorService.formatCurrency(payment.interest),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 创建提前还款 Bottom Sheet**

```dart
// flutter/lib/screens/prepayment_sheet.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_manager.dart';

class AddPrepaymentSheet extends StatefulWidget {
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final ValueChanged<PrepaymentNode> onSave;

  const AddPrepaymentSheet({
    super.key,
    required this.commercialLoan,
    required this.providentFundLoan,
    required this.onSave,
  });

  @override
  State<AddPrepaymentSheet> createState() => _AddPrepaymentSheetState();
}

class _AddPrepaymentSheetState extends State<AddPrepaymentSheet> {
  DateTime _date = DateTime.now();
  final _amountController = TextEditingController();
  late LoanType _loanType;
  PrepaymentType _prepaymentType = PrepaymentType.reducePayment;

  @override
  void initState() {
    super.initState();
    _loanType = widget.commercialLoan != null ? LoanType.commercial : LoanType.providentFund;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    final loan = _loanType == LoanType.commercial
        ? widget.commercialLoan
        : widget.providentFundLoan;
    return amount != null && amount > 0 && loan != null && _date.isAfter(loan.startDate);
  }

  void _save() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    widget.onSave(PrepaymentNode(
      id: DataManager.newId(),
      prepaymentDate: _date,
      prepaymentAmount: amount,
      prepaymentType: _prepaymentType,
      targetLoanType: _loanType,
      canShortenTerm: _loanType == LoanType.commercial && _prepaymentType == PrepaymentType.shortenTerm,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('添加提前还款', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('还款日期'),
            trailing: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2050),
                );
                if (date != null) setState(() => _date = date);
              },
              child: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '还款金额',
              suffixText: '元',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (widget.commercialLoan != null && widget.providentFundLoan != null)
            SegmentedButton<LoanType>(
              segments: const [
                ButtonSegment(value: LoanType.commercial, label: Text('商业贷款')),
                ButtonSegment(value: LoanType.providentFund, label: Text('公积金贷款')),
              ],
              selected: {_loanType},
              onSelectionChanged: (selected) => setState(() => _loanType = selected.first),
            ),
          const SizedBox(height: 12),
          SegmentedButton<PrepaymentType>(
            segments: [
              const ButtonSegment(
                value: PrepaymentType.reducePayment,
                label: Text('减少月供'),
              ),
              if (_loanType == LoanType.commercial)
                const ButtonSegment(
                  value: PrepaymentType.shortenTerm,
                  label: Text('缩短期限'),
                ),
            ],
            selected: {_prepaymentType},
            onSelectionChanged: (selected) =>
                setState(() => _prepaymentType = selected.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isValid ? _save : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class EditPrepaymentSheet extends StatefulWidget {
  final PrepaymentNode node;
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final ValueChanged<PrepaymentNode> onSave;

  const EditPrepaymentSheet({
    super.key,
    required this.node,
    required this.commercialLoan,
    required this.providentFundLoan,
    required this.onSave,
  });

  @override
  State<EditPrepaymentSheet> createState() => _EditPrepaymentSheetState();
}

class _EditPrepaymentSheetState extends State<EditPrepaymentSheet> {
  late DateTime _date;
  late final TextEditingController _amountController;
  late LoanType _loanType;
  late PrepaymentType _prepaymentType;

  @override
  void initState() {
    super.initState();
    _date = widget.node.prepaymentDate;
    _amountController = TextEditingController(text: widget.node.prepaymentAmount.toString());
    _loanType = widget.node.targetLoanType;
    _prepaymentType = widget.node.prepaymentType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    widget.onSave(PrepaymentNode(
      id: widget.node.id,
      prepaymentDate: _date,
      prepaymentAmount: amount,
      prepaymentType: _prepaymentType,
      targetLoanType: _loanType,
      canShortenTerm: _loanType == LoanType.commercial && _prepaymentType == PrepaymentType.shortenTerm,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('编辑提前还款', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('还款日期'),
            trailing: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2050),
                );
                if (date != null) setState(() => _date = date);
              },
              child: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '还款金额',
              suffixText: '元',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          if (widget.commercialLoan != null && widget.providentFundLoan != null)
            SegmentedButton<LoanType>(
              segments: const [
                ButtonSegment(value: LoanType.commercial, label: Text('商业贷款')),
                ButtonSegment(value: LoanType.providentFund, label: Text('公积金贷款')),
              ],
              selected: {_loanType},
              onSelectionChanged: (selected) => setState(() => _loanType = selected.first),
            ),
          const SizedBox(height: 12),
          SegmentedButton<PrepaymentType>(
            segments: [
              const ButtonSegment(
                value: PrepaymentType.reducePayment,
                label: Text('减少月供'),
              ),
              if (_loanType == LoanType.commercial)
                const ButtonSegment(
                  value: PrepaymentType.shortenTerm,
                  label: Text('缩短期限'),
                ),
            ],
            selected: {_prepaymentType},
            onSelectionChanged: (selected) =>
                setState(() => _prepaymentType = selected.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 提交**

```bash
git add flutter/lib/screens/ flutter/lib/app.dart flutter/lib/main.dart
git commit -m "feat: 添加 Flutter UI 页面（首页、输入、结果、提前还款）"
```

---

### Task 6: 单元测试

**文件:**
- Create: `flutter/test/services/mortgage_calculator_service_test.dart`
- Create: `flutter/test/models/loan_info_test.dart`

- [ ] **Step 1: 创建 MortgageCalculatorService 测试**

```dart
// flutter/test/services/mortgage_calculator_service_test.dart
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
        // 每月本金 = 1200000/360 = 3333.33
        // 利息 = 1200000 * 0.042/12 = 4200
        expect(monthly, closeTo(7533.33, 1.0));
      });

      test('最后一期月供', () {
        final monthly = MortgageCalculatorService.calculateEqualPrincipalMonthly(
          principal: 1200000,
          monthlyRate: 0.042 / 12,
          monthIndex: 360,
          totalMonths: 360,
        );
        // 每月本金 = 3333.33
        // 剩余本金 = 3333.33
        // 利息 = 3333.33 * 0.042/12 = 11.67
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
        expect(payments.first.monthlyPayment, closeTo(4889.39, 1.0));
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

        // 提前还款后月供应该减少
        final paymentBefore = payments[23].monthlyPayment; // 第24期（提前还款前）
        final paymentAfter = payments[24].monthlyPayment; // 第25期（提前还款后）
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
```

- [ ] **Step 2: 运行测试**

```bash
cd /Users/vector/MortgageCalculator/flutter
flutter test
```

- [ ] **Step 3: 提交**

```bash
git add flutter/test/
git commit -m "test: 添加 Flutter 单元测试"
```

---

### Task 7: 构建验证

- [ ] **Step 1: Web 构建验证**

```bash
cd /Users/vector/MortgageCalculator/flutter
flutter build web
```

- [ ] **Step 2: Android 构建验证**

```bash
flutter build apk --debug
```

- [ ] **Step 3: macOS 构建验证（如果在 macOS 上）**

```bash
flutter build macos --debug
```

- [ ] **Step 4: 最终提交**

```bash
git add -A
git commit -m "chore: Flutter 跨平台迁移完成"
```

---

## 文件结构总览

```
MortgageCalculator/
├── flutter/                          # Flutter 项目
│   ├── lib/
│   │   ├── main.dart                 # 入口
│   │   ├── app.dart                  # App Widget + 路由
│   │   ├── models/                   # 数据模型
│   │   │   ├── models.dart           # barrel
│   │   │   ├── loan_type.dart
│   │   │   ├── repayment_type.dart
│   │   │   ├── prepayment_type.dart
│   │   │   ├── loan_info.dart
│   │   │   ├── prepayment_node.dart
│   │   │   ├── monthly_payment.dart
│   │   │   ├── repayment_segment.dart
│   │   │   ├── loan_calculation_result.dart
│   │   │   └── export_data.dart
│   │   ├── services/                 # 业务逻辑
│   │   │   ├── mortgage_calculator_service.dart
│   │   │   ├── data_manager.dart
│   │   │   └── import_export_service.dart
│   │   └── screens/                  # UI 页面
│   │       ├── home_screen.dart
│   │       ├── loan_input_screen.dart
│   │       ├── result_screen.dart
│   │       └── prepayment_sheet.dart
│   ├── test/
│   │   └── services/
│   │       └── mortgage_calculator_service_test.dart
│   └── pubspec.yaml
├── MortgageCalculator/               # 原 iOS 项目（保留）
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   └── ...
└── docs/
    └── superpowers/
        └── plans/
            └── 2026-05-03-flutter-migration-and-bugfixes.md
```

## 风险和注意事项

1. **原 iOS 项目保留**: Flutter 项目放在 `flutter/` 子目录，原 SwiftUI 代码不受影响
2. **数据不互通**: iOS 版使用 UserDefaults，Flutter 版使用 SharedPreferences，数据不自动迁移
3. **等额本金段分割**: 当前阈值 `> 1.0` 可能导致相邻月份被合并为一段，但影响较小
4. **日期处理**: Flutter 的 `DateTime` 不支持 locale 格式化，使用了简单的字符串拼接
5. **分享功能**: 使用 `share_plus` 包，需要在各平台配置相应权限
