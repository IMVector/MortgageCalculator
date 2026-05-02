import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_manager.dart';

class LoanInputScreen extends StatelessWidget {
  final VoidCallback onCalculate;

  const LoanInputScreen({super.key, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataManager>();
    final hasCommercial = data.commercialLoan != null;
    final hasProvidentFund = data.providentFundLoan != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('房贷计算器'),
        actions: [
          if (hasCommercial || hasProvidentFund)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  data.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('清除所有贷款'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 欢迎提示（无贷款时显示）
            if (!hasCommercial && !hasProvidentFund)
              const _WelcomeCard(),

            // 商业贷款卡片
            const _LoanCard(
              title: '商业贷款',
              icon: Icons.business,
              color: Colors.blue,
              subtitle: '商业住房贷款',
              loanType: LoanType.commercial,
            ),

            const SizedBox(height: 16),

            // 公积金贷款卡片
            const _LoanCard(
              title: '公积金贷款',
              icon: Icons.home,
              color: Colors.green,
              subtitle: '住房公积金贷款',
              loanType: LoanType.providentFund,
            ),

            // 计算按钮
            if (hasCommercial || hasProvidentFund) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCalculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  '计算还款',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            // 提前还款提示
            if (data.prepayments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已添加 ${data.prepayments.length} 条提前还款记录，在「计算结果」页查看',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// MARK: - 欢迎卡片

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.house_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '欢迎使用房贷计算器',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方卡片展开，填写贷款信息后即可计算还款计划',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - 贷款卡片

class _LoanCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final LoanType loanType;

  const _LoanCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.loanType,
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

  bool _initialized = false;

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  LoanInfo? get _currentLoan {
    final data = context.read<DataManager>();
    return widget.loanType == LoanType.commercial
        ? data.commercialLoan
        : data.providentFundLoan;
  }

  void _syncFromExisting() {
    final loan = _currentLoan;
    if (loan != null) {
      _principalController.text = (loan.principal / 10000).toString();
      _rateController.text = loan.annualRate.toString();
      _termController.text = (loan.loanTermMonths ~/ 12).toString();
      _startDate = loan.startDate;
      _repaymentType = loan.repaymentType;
    } else if (!_initialized) {
      // 设置默认利率
      _rateController.text =
          widget.loanType == LoanType.providentFund ? '2.85' : '4.2';
      _termController.text = '30';
    }
    _initialized = true;
  }

  void _saveLoan() {
    final principal = double.tryParse(_principalController.text);
    final rate = double.tryParse(_rateController.text);
    final term = int.tryParse(_termController.text);

    if (principal == null || principal <= 0) {
      _showError('请输入有效的贷款金额');
      return;
    }
    if (rate == null || rate <= 0) {
      _showError('请输入有效的年利率');
      return;
    }
    if (term == null || term <= 0) {
      _showError('请输入有效的贷款期限');
      return;
    }

    final data = context.read<DataManager>();
    final existingLoan = _currentLoan;

    final loan = LoanInfo(
      id: existingLoan?.id ?? DataManager.newId(),
      loanType: widget.loanType,
      principal: principal * 10000, // 万元转元
      annualRate: rate,
      loanTermMonths: term * 12, // 年转月
      startDate: _startDate,
      repaymentType: _repaymentType,
    );

    if (widget.loanType == LoanType.commercial) {
      data.setCommercialLoan(loan);
    } else {
      data.setProvidentFundLoan(loan);
    }

    setState(() {
      _isExpanded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保存成功'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _deleteLoan() {
    final data = context.read<DataManager>();
    if (widget.loanType == LoanType.commercial) {
      data.setCommercialLoan(null);
    } else {
      data.setProvidentFundLoan(null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loan = _currentLoan;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 卡片头部
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _syncFromExisting();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // 标题和摘要
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (loan != null)
                          Text(
                            '${_formatWan(loan.principal)} 万 · '
                            '${loan.loanTermMonths ~/ 12}年 · '
                            '${loan.annualRate.toStringAsFixed(2)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(
                            widget.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 操作按钮
                  if (loan != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                      ),
                      onPressed: _deleteLoan,
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // 展开的输入表单
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildForm(context),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),

          // 贷款金额
          _InputField(
            controller: _principalController,
            title: '贷款金额',
            unit: '万元',
            placeholder: '如 100',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 12),

          // 年利率
          _InputField(
            controller: _rateController,
            title: '年利率',
            unit: '%',
            placeholder: widget.loanType == LoanType.providentFund ? '如 2.85' : '如 4.2',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 12),

          // 贷款期限
          _InputField(
            controller: _termController,
            title: '贷款期限',
            unit: '年',
            placeholder: '如 30',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          // 贷款开始日期
          Row(
            children: [
              Text(
                '开始日期',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 还款方式
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '还款方式',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<RepaymentType>(
                segments: const [
                  ButtonSegment(
                    value: RepaymentType.equalPrincipalAndInterest,
                    label: Text('等额本息'),
                  ),
                  ButtonSegment(
                    value: RepaymentType.equalPrincipal,
                    label: Text('等额本金'),
                  ),
                ],
                selected: {_repaymentType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _repaymentType = selected.first;
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                _repaymentType == RepaymentType.equalPrincipalAndInterest
                    ? '每月还款金额相同，适合收入稳定的人群'
                    : '每月本金相同，利息递减，总利息较少',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 保存按钮
          FilledButton.icon(
            onPressed: _saveLoan,
            icon: const Icon(Icons.check),
            label: const Text('保存'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: widget.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWan(double principalInYuan) {
    final wan = principalInYuan / 10000;
    if (wan == wan.roundToDouble()) {
      return wan.toStringAsFixed(0);
    }
    return wan.toStringAsFixed(2);
  }
}

// MARK: - 输入字段组件

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String unit;
  final String placeholder;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.title,
    required this.unit,
    required this.placeholder,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
