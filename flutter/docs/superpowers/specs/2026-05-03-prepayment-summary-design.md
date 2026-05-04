# 提前还款结果展示优化设计

## 背景

当前提前还款计算结果页面存在两个问题：
1. 缺少汇总视角——用户无法直观看到每月两种贷款的合计还款情况
2. 顶部汇总信息（总利息、月供等）在提前还款后不会更新，始终显示原始数据

## 目标

1. 在「计算结果」页顶部新增汇总视角，展示每月合计月供及各贷款明细
2. 顶部汇总卡片动态反映提前还款后的实际数据，并展示节省对比

## 方案概述

采用方案 C：新增 `LoanComparisonService` + `LoanComparisonResult`，职责清晰，可测试。

---

## 数据模型

### 新增文件：`lib/models/loan_comparison_result.dart`

```dart
class LoanComparisonResult {
  final LoanCalculationResult originalResult;   // 无提前还款的原始方案
  final LoanCalculationResult currentResult;    // 当前提前还款方案
  final List<MergedMonthlyPayment> mergedMonthlyPayments; // 合并月供列表

  double get savedInterest =>
      originalResult.totalInterest - currentResult.totalInterest;

  /// 首月节省月供 = 原始首月合计 - 当前首月合计
  double get savedFirstMonthPayment {
    final orig = _firstMonthTotal(originalResult);
    final curr = _firstMonthTotal(currentResult);
    return orig - curr;
  }

  /// 缩短期数 = 原始总期数 - 当前总期数
  int get shortenedMonths {
    final origMonths = _totalMonths(originalResult);
    final currMonths = _totalMonths(currentResult);
    return origMonths - currMonths;
  }

  bool get hasPrepayment =>
      currentResult.prepaymentNodes.isNotEmpty;

  // 辅助方法：计算首月合计月供
  static double _firstMonthTotal(LoanCalculationResult r) {
    final c = r.commercialMonthlyPayments.isNotEmpty
        ? r.commercialMonthlyPayments.first.monthlyPayment : 0;
    final p = r.providentFundMonthlyPayments.isNotEmpty
        ? r.providentFundMonthlyPayments.first.monthlyPayment : 0;
    return c + p;
  }

  // 辅助方法：计算总期数（取两种贷款中较长的）
  static int _totalMonths(LoanCalculationResult r) {
    final c = r.commercialMonthlyPayments.length;
    final p = r.providentFundMonthlyPayments.length;
    return c > p ? c : p;
  }
}

class MergedMonthlyPayment {
  final int id;
  final DateTime date;

  // 商贷（null 表示该月无此贷款或已还清）
  final double? commercialPayment;    // 当月商贷月供（含提前还款金额）
  final double? commercialPrincipal;  // 当月商贷本金部分
  final double? commercialInterest;   // 当月商贷利息部分

  // 公积金（null 表示该月无此贷款或已还清）
  final double? providentFundPayment;
  final double? providentFundPrincipal;
  final double? providentFundInterest;

  // 合计
  double get totalPayment =>
      (commercialPayment ?? 0) + (providentFundPayment ?? 0);
}
```

---

## 服务层

### 新增文件：`lib/services/loan_comparison_service.dart`

职责：
- `compare(original, current)` → 返回 `LoanComparisonResult`
- `mergeMonthlyPayments(commercial, providentFund)` → 按日期对齐合并

合并逻辑：
1. 遍历两个 `MonthlyPayment` 列表
2. 按月份（`date.year * 12 + date.month`）匹配
3. 缺失月份的字段设为 `null`
4. 以较长列表为准，短列表还清后后续月份对应字段为 `null`

### 修改文件：`lib/screens/home_screen.dart`

`_calculateLoan()` 改动：
1. 执行两次 `MortgageCalculatorService.calculateLoan()`：
   - 无提前还款 → `originalResult`
   - 有提前还款 → `currentResult`
2. 调用 `LoanComparisonService.compare()` 生成 `comparisonResult`
3. 将 `comparisonResult` 传递给 `ResultScreen`

---

## UI 层

### 页面结构（从上到下）

```
ResultScreen
├── _SummaryCards（改造：显示提前还款后数据）
├── _SavingsCard（新增：节省对比，仅提前还款时显示）
├── _CombinedSummaryView（新增：汇总视角月供明细）
├── _PrepaymentSection（保持不变）
├── 商业贷款详情（保持不变）
└── 公积金贷款详情（保持不变）
```

### `_SummaryCards` 改造

- **总贷款金额**：保持显示原始本金（不变）
- **总利息**：显示提前还款后的值，旁边标注节省金额（绿色文字，如 `省 12,345 元`）
- **各贷款月供**：显示提前还款后的首月月供
- **合计月供**：显示提前还款后的首月合计

### 新增 `_SavingsCard`

仅在 `comparisonResult.hasPrepayment == true` 时显示。

展示三个指标：
- **节省利息**：`savedInterest` 元
- **节省月供**：`savedFirstMonthPayment` 元/月（首月）
- **缩短期数**：`shortenedMonths` 个月

使用绿色主题色突出显示。

### 新增 `_CombinedSummaryView`

表格形式展示每月明细：

| 期数 | 日期 | 合计月供 | 商贷月供 | 公积金月供 |
|------|------|----------|----------|------------|
| 1 | 2025-01 | 8,500.00 | 5,200.00 | 3,300.00 |
| 2 | 2025-02 | 8,480.00 | 5,180.00 | 3,300.00 |
| ... | ... | ... | ... | ... |
| 120 | 2034-12 | 3,300.00 | 已还清 | 3,300.00 |

- 可展开行查看本金/利息拆分
- `null` 字段显示「已还清」占位符
- 支持折叠/展开整个区块
- 默认折叠（避免页面过长）

---

## 边界情况

1. **只有单一贷款**：汇总视角仍显示，空列用「-」占位
2. **贷款期限不同**：以较长的为准，短的还清后显示「已还清」
3. **无提前还款**：不显示 `_SavingsCard`，`_SummaryCards` 保持原始行为，`originalResult` 与 `currentResult` 相同
4. **提前还款导致某贷款立即还清**：当月标记为还清，后续月份该列显示「已还清」
5. **性能**：合并月供列表在 service 层计算一次，不在 UI 层重复计算
6. **汇总视角数据源**：`_CombinedSummaryView` 基于 `currentResult`（含提前还款）的月供数据，展示实际还款计划

---

## 涉及文件清单

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/models/loan_comparison_result.dart` |
| 新增 | `lib/services/loan_comparison_service.dart` |
| 修改 | `lib/screens/home_screen.dart` |
| 修改 | `lib/screens/result_screen.dart` |
| 新增 | `test/services/loan_comparison_service_test.dart` |
