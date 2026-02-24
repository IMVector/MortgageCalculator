import SwiftUI

struct ResultView: View {
    let result: LoanCalculationResult?
    @Binding var prepayments: [PrepaymentNode]
    let commercialLoan: LoanInfo?
    let providentFundLoan: LoanInfo?
    let onRecalculate: () -> Void

    @State private var showingAddPrepayment = false
    @State private var editingPrepayment: PrepaymentNode?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let result = result {
                    VStack(spacing: 16) {
                        // 汇总卡片
                        SummaryCards(result: result)

                        // 提前还款快捷入口
                        if commercialLoan != nil || providentFundLoan != nil {
                            PrepaymentQuickEntry(
                                prepayments: $prepayments,
                                onAdd: { showingAddPrepayment = true },
                                onEdit: { editingPrepayment = $0 },
                                onDelete: { node in
                                    prepayments.removeAll { $0.id == node.id }
                                    onRecalculate()
                                }
                            )
                        }

                        // 商业贷款详情
                        if !result.commercialSegments.isEmpty {
                            LoanDetailSection(
                                title: "商业贷款",
                                color: .blue,
                                segments: result.commercialSegments,
                                monthlyPayments: result.commercialMonthlyPayments
                            )
                        }

                        // 公积金贷款详情
                        if !result.providentFundSegments.isEmpty {
                            LoanDetailSection(
                                title: "公积金贷款",
                                color: .green,
                                segments: result.providentFundSegments,
                                monthlyPayments: result.providentFundMonthlyPayments
                            )
                        }

                        // 底部留白
                        Color.clear.frame(height: 20)
                    }
                    .padding()
                } else {
                    emptyStateView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("计算结果")
            .sheet(isPresented: $showingAddPrepayment) {
                AddPrepaymentSheet(
                    prepayments: $prepayments,
                    commercialLoan: commercialLoan,
                    providentFundLoan: providentFundLoan,
                    onSave: onRecalculate
                )
            }
            .sheet(item: $editingPrepayment) { node in
                EditPrepaymentSheet(
                    node: node,
                    prepayments: $prepayments,
                    commercialLoan: commercialLoan,
                    providentFundLoan: providentFundLoan,
                    onSave: onRecalculate
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "house.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("开始计算您的房贷")
                    .font(.title2.bold())

                Text("请在「贷款输入」页面填写贷款信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 提前还款快捷入口

struct PrepaymentQuickEntry: View {
    @Binding var prepayments: [PrepaymentNode]
    let onAdd: () -> Void
    let onEdit: (PrepaymentNode) -> Void
    let onDelete: (PrepaymentNode) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    Text("添加提前还款")
                        .font(.headline)
                    Spacer()
                    if !prepayments.isEmpty {
                        Text("\(prepayments.count) 条")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            if !prepayments.isEmpty {
                Divider()
                    .padding(.leading)

                // 最多显示3条，用 LazyVStack 优化
                LazyVStack(spacing: 0) {
                    ForEach(Array(prepayments.sorted(by: { $0.prepaymentDate < $1.prepaymentDate }).prefix(3).enumerated()), id: \.element.id) { index, node in
                        VStack(spacing: 0) {
                            PrepaymentMiniCard(
                                node: node,
                                onEdit: { onEdit(node) },
                                onDelete: { onDelete(node) }
                            )
                            if index < min(prepayments.count, 3) - 1 {
                                Divider().padding(.leading)
                            }
                        }
                    }

                    if prepayments.count > 3 {
                        Text("还有 \(prepayments.count - 3) 条记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct PrepaymentMiniCard: View {
    let node: PrepaymentNode
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(formatDate(node.prepaymentDate))
                            .font(.subheadline.weight(.medium))

                        Text(node.targetLoanType.rawValue)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(node.targetLoanType == .commercial ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                            .foregroundColor(node.targetLoanType == .commercial ? .blue : .green)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    HStack(spacing: 12) {
                        Text("\(MortgageCalculatorService.formatCurrency(node.prepaymentAmount)) 元")
                            .foregroundColor(.orange)
                        Text(node.prepaymentType.rawValue)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // 删除按钮
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 汇总卡片

struct SummaryCards: View {
    let result: LoanCalculationResult

    var body: some View {
        VStack(spacing: 16) {
            // 总贷款金额 & 总利息
            HStack(spacing: 16) {
                SummaryItem(
                    title: "总贷款金额",
                    value: MortgageCalculatorService.formatCurrency(totalPrincipal),
                    subtitle: "元",
                    color: .primary
                )

                Divider()
                    .frame(height: 40)

                SummaryItem(
                    title: "总利息",
                    value: MortgageCalculatorService.formatCurrency(totalInterest),
                    subtitle: "元",
                    color: .orange
                )
            }

            Divider()

            // 月供信息
            HStack(spacing: 16) {
                if let commercialPayment = result.commercialMonthlyPayments.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("商业贷款")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(MortgageCalculatorService.formatCurrency(commercialPayment.monthlyPayment))")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.blue)
                        Text("元/月")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let providentFundPayment = result.providentFundMonthlyPayments.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("公积金贷款")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(MortgageCalculatorService.formatCurrency(providentFundPayment.monthlyPayment))")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.green)
                        Text("元/月")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // 合计月供
            if let commercialPayment = result.commercialMonthlyPayments.first,
               let providentFundPayment = result.providentFundMonthlyPayments.first {
                Divider()

                HStack {
                    Text("合计月供")
                        .font(.headline)
                    Spacer()
                    Text("\(MortgageCalculatorService.formatCurrency(commercialPayment.monthlyPayment + providentFundPayment.monthlyPayment)) 元/月")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var totalPrincipal: Double {
        (result.commercialLoan?.principal ?? 0) + (result.providentFundLoan?.principal ?? 0)
    }

    private var totalInterest: Double {
        result.totalCommercialInterest + result.totalProvidentFundInterest
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 贷款详情区块

struct LoanDetailSection: View {
    let title: String
    let color: Color
    let segments: [RepaymentSegment]
    let monthlyPayments: [MonthlyPayment]

    @State private var isSectionExpanded = true
    @State private var expandedSegments: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSectionExpanded.toggle()
                }
            }) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    Text(title)
                        .font(.headline)

                    Spacer()

                    Text("\(monthlyPayments.count)期")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: isSectionExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(.plain)

            // 内容区
            if isSectionExpanded {
                LazyVStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                        CollapsibleSegmentRow(
                            segment: segment,
                            color: color,
                            monthlyPayments: monthlyPayments.filter {
                                $0.id >= segment.startMonth && $0.id <= segment.endMonth
                            },
                            isExpanded: expandedSegments.contains(segment.id),
                            isLast: index == segments.count - 1,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedSegments.contains(segment.id) {
                                        expandedSegments.remove(segment.id)
                                    } else {
                                        expandedSegments.insert(segment.id)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 可折叠还款段

struct CollapsibleSegmentRow: View {
    let segment: RepaymentSegment
    let color: Color
    let monthlyPayments: [MonthlyPayment]
    let isExpanded: Bool
    let isLast: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 段标题
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("第 \(segment.startMonth)-\(segment.endMonth) 期")
                                .font(.subheadline.weight(.medium))

                            Text("共 \(segment.endMonth - segment.startMonth + 1) 期")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Label(
                                "利息 \(MortgageCalculatorService.formatCurrency(segment.totalInterest))",
                                systemImage: "percent"
                            )
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(MortgageCalculatorService.formatCurrency(segment.monthlyPayment))")
                                .font(.headline)
                                .foregroundColor(color)
                            Text("元/月")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 展开内容 - 使用 LazyVStack 优化性能
            if isExpanded {
                VStack(spacing: 0) {
                    // 表头
                    HStack(spacing: 4) {
                        Text("期数")
                            .frame(width: 40, alignment: .leading)
                        Text("日期")
                            .frame(width: 60, alignment: .leading)
                        Spacer()
                        Text("月供")
                            .frame(width: 60, alignment: .trailing)
                        Text("本金")
                            .frame(width: 55, alignment: .trailing)
                        Text("利息")
                            .frame(width: 50, alignment: .trailing)
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))

                    // 使用 LazyVStack 优化长列表
                    LazyVStack(spacing: 0) {
                        ForEach(monthlyPayments) { payment in
                            CompactMonthlyPaymentRow(payment: payment, color: color)
                        }
                    }
                }
            }

            if !isLast && !isExpanded {
                Divider()
                    .padding(.leading)
            }
        }
    }
}

struct CompactMonthlyPaymentRow: View {
    let payment: MonthlyPayment
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(payment.id)")
                .font(.caption)
                .frame(width: 40, alignment: .leading)

            Text(formatDate(payment.date))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Text(formatAmount(payment.monthlyPayment))
                .font(.caption.weight(.medium))
                .foregroundColor(color)
                .frame(width: 60, alignment: .trailing)

            Text(formatAmount(payment.principal))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .trailing)

            Text(formatAmount(payment.interest))
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))

        Divider()
            .padding(.leading, 10)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Double) -> String {
        MortgageCalculatorService.formatCurrency(amount)
    }
}

#Preview {
    ResultView(
        result: nil,
        prepayments: .constant([]),
        commercialLoan: nil,
        providentFundLoan: nil,
        onRecalculate: {}
    )
}
