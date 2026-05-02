import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_manager.dart';

class AddPrepaymentSheet extends StatefulWidget {
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final VoidCallback onSave;

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
  DateTime _prepaymentDate = DateTime.now();
  final _amountController = TextEditingController();
  LoanType _selectedLoanType = LoanType.commercial;
  PrepaymentType _prepaymentType = PrepaymentType.reducePayment;

  @override
  void initState() {
    super.initState();
    // 默认选中有贷款的类型
    if (widget.commercialLoan == null && widget.providentFundLoan != null) {
      _selectedLoanType = LoanType.providentFund;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;

    final startDate = _selectedLoanType == LoanType.commercial
        ? widget.commercialLoan?.startDate
        : widget.providentFundLoan?.startDate;
    if (startDate != null && !_prepaymentDate.isAfter(startDate)) {
      return false;
    }
    return true;
  }

  void _save() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final data = context.read<DataManager>();
    final canShorten =
        _selectedLoanType == LoanType.commercial &&
        _prepaymentType == PrepaymentType.shortenTerm;

    final node = PrepaymentNode(
      id: DataManager.newId(),
      prepaymentDate: _prepaymentDate,
      prepaymentAmount: amount,
      prepaymentType: _prepaymentType,
      targetLoanType: _selectedLoanType,
      canShortenTerm: canShorten,
    );

    data.addPrepayment(node);
    widget.onSave();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                '添加提前还款',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // 还款日期
              Row(
                children: [
                  Text(
                    '还款日期',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _prepaymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _prepaymentDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_prepaymentDate.year}-'
                      '${_prepaymentDate.month.toString().padLeft(2, '0')}-'
                      '${_prepaymentDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 还款金额
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '还款金额',
                  suffixText: '元',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // 贷款类型
              Text(
                '贷款类型',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<LoanType>(
                segments: [
                  if (widget.commercialLoan != null)
                    const ButtonSegment(
                      value: LoanType.commercial,
                      label: Text('商业贷款'),
                    ),
                  if (widget.providentFundLoan != null)
                    const ButtonSegment(
                      value: LoanType.providentFund,
                      label: Text('公积金贷款'),
                    ),
                ],
                selected: {_selectedLoanType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedLoanType = selected.first;
                    // 公积金贷款不支持缩短期限
                    if (_selectedLoanType == LoanType.providentFund &&
                        _prepaymentType == PrepaymentType.shortenTerm) {
                      _prepaymentType = PrepaymentType.reducePayment;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // 还款方式
              Text(
                '还款方式',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PrepaymentType>(
                segments: [
                  const ButtonSegment(
                    value: PrepaymentType.reducePayment,
                    label: Text('减少月供'),
                  ),
                  if (_selectedLoanType == LoanType.commercial)
                    const ButtonSegment(
                      value: PrepaymentType.shortenTerm,
                      label: Text('缩短期限'),
                    ),
                ],
                selected: {_prepaymentType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _prepaymentType = selected.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isValid ? _save : null,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - 编辑提前还款

class EditPrepaymentSheet extends StatefulWidget {
  final PrepaymentNode node;
  final LoanInfo? commercialLoan;
  final LoanInfo? providentFundLoan;
  final VoidCallback onSave;

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
  late DateTime _prepaymentDate;
  late TextEditingController _amountController;
  late LoanType _selectedLoanType;
  late PrepaymentType _prepaymentType;

  @override
  void initState() {
    super.initState();
    _prepaymentDate = widget.node.prepaymentDate;
    _amountController =
        TextEditingController(text: widget.node.prepaymentAmount.toString());
    _selectedLoanType = widget.node.targetLoanType;
    _prepaymentType = widget.node.prepaymentType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;
    return true;
  }

  void _save() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final data = context.read<DataManager>();
    final canShorten =
        _selectedLoanType == LoanType.commercial &&
        _prepaymentType == PrepaymentType.shortenTerm;

    final updatedNode = PrepaymentNode(
      id: widget.node.id,
      prepaymentDate: _prepaymentDate,
      prepaymentAmount: amount,
      prepaymentType: _prepaymentType,
      targetLoanType: _selectedLoanType,
      canShortenTerm: canShorten,
    );

    data.updatePrepayment(updatedNode);
    widget.onSave();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                '编辑提前还款',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // 还款日期
              Row(
                children: [
                  Text(
                    '还款日期',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _prepaymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _prepaymentDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_prepaymentDate.year}-'
                      '${_prepaymentDate.month.toString().padLeft(2, '0')}-'
                      '${_prepaymentDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 还款金额
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '还款金额',
                  suffixText: '元',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // 贷款类型
              Text(
                '贷款类型',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<LoanType>(
                segments: [
                  if (widget.commercialLoan != null)
                    const ButtonSegment(
                      value: LoanType.commercial,
                      label: Text('商业贷款'),
                    ),
                  if (widget.providentFundLoan != null)
                    const ButtonSegment(
                      value: LoanType.providentFund,
                      label: Text('公积金贷款'),
                    ),
                ],
                selected: {_selectedLoanType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedLoanType = selected.first;
                    if (_selectedLoanType == LoanType.providentFund &&
                        _prepaymentType == PrepaymentType.shortenTerm) {
                      _prepaymentType = PrepaymentType.reducePayment;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // 还款方式
              Text(
                '还款方式',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PrepaymentType>(
                segments: [
                  const ButtonSegment(
                    value: PrepaymentType.reducePayment,
                    label: Text('减少月供'),
                  ),
                  if (_selectedLoanType == LoanType.commercial)
                    const ButtonSegment(
                      value: PrepaymentType.shortenTerm,
                      label: Text('缩短期限'),
                    ),
                ],
                selected: {_prepaymentType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _prepaymentType = selected.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isValid ? _save : null,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
