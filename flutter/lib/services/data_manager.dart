import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

const _uuid = Uuid();

/// 数据管理器 - 负责数据的保存和读取
///
/// 使用 SharedPreferences 持久化贷款和提前还款数据。
/// 所有变更自动保存并通知监听者。
class DataManager extends ChangeNotifier {
  // SharedPreferences keys
  static const _commercialLoanKey = 'commercialLoan';
  static const _providentFundLoanKey = 'providentFundLoan';
  static const _prepaymentsKey = 'prepayments';

  final SharedPreferences _prefs;

  LoanInfo? _commercialLoan;
  LoanInfo? _providentFundLoan;
  List<PrepaymentNode> _prepayments = [];

  DataManager._(this._prefs) {
    _loadData();
  }

  /// 异步工厂构造函数
  static Future<DataManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DataManager._(prefs);
  }

  // MARK: - 公开属性（不可变视图）

  /// 商业贷款信息
  LoanInfo? get commercialLoan => _commercialLoan;

  /// 公积金贷款信息
  LoanInfo? get providentFundLoan => _providentFundLoan;

  /// 提前还款节点列表（不可变视图）
  List<PrepaymentNode> get prepayments =>
      List<PrepaymentNode>.unmodifiable(_prepayments);

  // MARK: - 公开方法

  /// 生成唯一 ID (UUID v4)
  static String newId() => _uuid.v4();

  /// 设置商业贷款
  void setCommercialLoan(LoanInfo? loan) {
    _commercialLoan = loan;
    _saveCommercialLoan();
    notifyListeners();
  }

  /// 设置公积金贷款
  void setProvidentFundLoan(LoanInfo? loan) {
    _providentFundLoan = loan;
    _saveProvidentFundLoan();
    notifyListeners();
  }

  /// 添加提前还款节点
  void addPrepayment(PrepaymentNode node) {
    _prepayments = List<PrepaymentNode>.of(_prepayments)..add(node);
    _savePrepayments();
    notifyListeners();
  }

  /// 删除提前还款节点
  void removePrepayment(String id) {
    _prepayments = List<PrepaymentNode>.of(_prepayments)
      ..removeWhere((n) => n.id == id);
    _savePrepayments();
    notifyListeners();
  }

  /// 更新提前还款节点
  void updatePrepayment(PrepaymentNode node) {
    _prepayments = List<PrepaymentNode>.of(_prepayments);
    final index = _prepayments.indexWhere((n) => n.id == node.id);
    if (index != -1) {
      _prepayments[index] = node;
    }
    _savePrepayments();
    notifyListeners();
  }

  /// 清除所有数据
  void clearAll() {
    _commercialLoan = null;
    _providentFundLoan = null;
    _prepayments = [];
    _saveCommercialLoan();
    _saveProvidentFundLoan();
    _savePrepayments();
    notifyListeners();
  }

  // MARK: - 加载数据

  void _loadData() {
    _loadCommercialLoan();
    _loadProvidentFundLoan();
    _loadPrepayments();
  }

  void _loadCommercialLoan() {
    final jsonStr = _prefs.getString(_commercialLoanKey);
    if (jsonStr == null) return;
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      _commercialLoan = LoanInfo.fromJson(json);
    } catch (_) {
      // 解析失败时忽略
    }
  }

  void _loadProvidentFundLoan() {
    final jsonStr = _prefs.getString(_providentFundLoanKey);
    if (jsonStr == null) return;
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      _providentFundLoan = LoanInfo.fromJson(json);
    } catch (_) {
      // 解析失败时忽略
    }
  }

  void _loadPrepayments() {
    final jsonStr = _prefs.getString(_prepaymentsKey);
    if (jsonStr == null) return;
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _prepayments = list
          .map((e) => PrepaymentNode.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 解析失败时忽略
    }
  }

  // MARK: - 保存数据

  void _saveCommercialLoan() {
    if (_commercialLoan == null) {
      _prefs.remove(_commercialLoanKey);
    } else {
      _prefs.setString(_commercialLoanKey, jsonEncode(_commercialLoan!.toJson()));
    }
  }

  void _saveProvidentFundLoan() {
    if (_providentFundLoan == null) {
      _prefs.remove(_providentFundLoanKey);
    } else {
      _prefs.setString(
        _providentFundLoanKey,
        jsonEncode(_providentFundLoan!.toJson()),
      );
    }
  }

  void _savePrepayments() {
    final encoded = jsonEncode(_prepayments.map((p) => p.toJson()).toList());
    _prefs.setString(_prepaymentsKey, encoded);
  }
}
