import SwiftUI

struct PrepaymentView: View {
    @Binding var prepayments: [PrepaymentNode]
    let commercialLoan: LoanInfo?
    let providentFundLoan: LoanInfo?
    let onUpdate: () -> Void

    @State private var showingAddSheet = false
    @State private var editingNode: PrepaymentNode?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 提示信息
                    if commercialLoan == nil && providentFundLoan == nil {
                        VStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("请先在贷款输入页面添加贷款信息")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                    } else {
                        // 现有提前还款节点列表
                        if prepayments.isEmpty {
                            emptyStateView
                        } else {
                            prepaymentListView
                        }

                        // 添加按钮
                        Button(action: { showingAddSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("添加提前还款")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("提前还款")
            .sheet(isPresented: $showingAddSheet) {
                AddPrepaymentSheet(
                    prepayments: $prepayments,
                    commercialLoan: commercialLoan,
                    providentFundLoan: providentFundLoan,
                    onSave: onUpdate
                )
            }
            .sheet(item: $editingNode) { node in
                EditPrepaymentSheet(
                    node: node,
                    prepayments: $prepayments,
                    commercialLoan: commercialLoan,
                    providentFundLoan: providentFundLoan,
                    onSave: onUpdate
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无提前还款记录")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("点击下方按钮添加提前还款节点")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var prepaymentListView: some View {
        VStack(spacing: 12) {
            ForEach(prepayments.sorted(by: { $0.prepaymentDate < $1.prepaymentDate })) { node in
                PrepaymentCard(
                    node: node,
                    commercialLoan: commercialLoan,
                    providentFundLoan: providentFundLoan,
                    onEdit: { editingNode = node },
                    onDelete: {
                        prepayments.removeAll { $0.id == node.id }
                        onUpdate()
                    }
                )
            }
        }
    }
}

struct PrepaymentCard: View {
    let node: PrepaymentNode
    let commercialLoan: LoanInfo?
    let providentFundLoan: LoanInfo?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(formatDate(node.prepaymentDate))
                            .font(.headline)

                        Text(node.targetLoanType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(node.targetLoanType == .commercial ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                            .foregroundColor(node.targetLoanType == .commercial ? .blue : .green)
                            .cornerRadius(4)
                    }

                    Text("\(MortgageCalculatorService.formatCurrency(node.prepaymentAmount)) 元")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(node.prepaymentType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(node.prepaymentType == .shortenTerm ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(node.prepaymentType == .shortenTerm ? .blue : .green)
                        .cornerRadius(4)

                    if !node.canShortenTerm {
                        Text("不可缩期")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                // 计算新月供
                if let newPayment = calculateNewPayment() {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("新月供")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(MortgageCalculatorService.formatCurrency(newPayment)) 元")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func calculateNewPayment() -> Double? {
        // 根据目标贷款类型选择对应的贷款
        let loan: LoanInfo? = node.targetLoanType == .commercial ? commercialLoan : providentFundLoan
        guard let targetLoan = loan else { return nil }

        let monthsPassed = MortgageCalculatorService.monthsBetween(targetLoan.startDate, and: node.prepaymentDate)
        guard monthsPassed > 0 && monthsPassed < targetLoan.loanTermMonths else { return nil }

        return MortgageCalculatorService.calculateNewMonthlyPayment(
            loan: targetLoan,
            prepaymentDate: node.prepaymentDate,
            prepaymentAmount: node.prepaymentAmount,
            prepaymentType: node.prepaymentType
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct AddPrepaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var prepayments: [PrepaymentNode]
    let commercialLoan: LoanInfo?
    let providentFundLoan: LoanInfo?
    let onSave: () -> Void

    @State private var prepaymentDate: Date = Date()
    @State private var prepaymentAmount: String = ""
    @State private var selectedLoanType: LoanType = .commercial
    @State private var prepaymentType: PrepaymentType = .reducePayment
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("提前还款信息") {
                    DatePicker("还款日期", selection: $prepaymentDate, displayedComponents: .date)

                    TextField("还款金额 (元)", text: $prepaymentAmount)
                        .keyboardType(.decimalPad)

                    Picker("贷款类型", selection: $selectedLoanType) {
                        if commercialLoan != nil {
                            Text("商业贷款").tag(LoanType.commercial)
                        }
                        if providentFundLoan != nil {
                            Text("公积金贷款").tag(LoanType.providentFund)
                        }
                    }

                    Picker("还款方式", selection: $prepaymentType) {
                        Text("减少月供").tag(PrepaymentType.reducePayment)
                        if selectedLoanType == .commercial && (commercialLoan != nil) {
                            Text("缩短期限").tag(PrepaymentType.shortenTerm)
                        }
                    }
                }
            }
            .navigationTitle("添加提前还款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { savePrepayment() }
                        .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("请填写完整的提前还款信息")
            }
        }
    }

    private var isValid: Bool {
        guard let amount = Double(prepaymentAmount), amount > 0 else { return false }
        return prepaymentDate > (selectedLoanType == .commercial ? commercialLoan?.startDate ?? Date() : providentFundLoan?.startDate ?? Date())
    }

    private func savePrepayment() {
        guard let amount = Double(prepaymentAmount) else {
            showError = true
            return
        }

        let canShorten = selectedLoanType == .commercial && prepaymentType == .shortenTerm

        let node = PrepaymentNode(
            prepaymentDate: prepaymentDate,
            prepaymentAmount: amount,
            prepaymentType: prepaymentType,
            targetLoanType: selectedLoanType,
            canShortenTerm: canShorten
        )

        prepayments.append(node)
        onSave()
        dismiss()
    }
}

struct EditPrepaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let node: PrepaymentNode
    @Binding var prepayments: [PrepaymentNode]
    let commercialLoan: LoanInfo?
    let providentFundLoan: LoanInfo?
    let onSave: () -> Void

    @State private var prepaymentDate: Date
    @State private var prepaymentAmount: String
    @State private var prepaymentType: PrepaymentType
    @State private var targetLoanType: LoanType

    init(node: PrepaymentNode, prepayments: Binding<[PrepaymentNode]>, commercialLoan: LoanInfo?, providentFundLoan: LoanInfo?, onSave: @escaping () -> Void) {
        self.node = node
        self._prepayments = prepayments
        self.commercialLoan = commercialLoan
        self.providentFundLoan = providentFundLoan
        self.onSave = onSave

        _prepaymentDate = State(initialValue: node.prepaymentDate)
        _prepaymentAmount = State(initialValue: String(node.prepaymentAmount))
        _prepaymentType = State(initialValue: node.prepaymentType)
        _targetLoanType = State(initialValue: node.targetLoanType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("提前还款信息") {
                    DatePicker("还款日期", selection: $prepaymentDate, displayedComponents: .date)

                    TextField("还款金额 (元)", text: $prepaymentAmount)
                        .keyboardType(.decimalPad)

                    Picker("贷款类型", selection: $targetLoanType) {
                        if commercialLoan != nil {
                            Text("商业贷款").tag(LoanType.commercial)
                        }
                        if providentFundLoan != nil {
                            Text("公积金贷款").tag(LoanType.providentFund)
                        }
                    }

                    Picker("还款方式", selection: $prepaymentType) {
                        Text("减少月供").tag(PrepaymentType.reducePayment)
                        if targetLoanType == .commercial {
                            Text("缩短期限").tag(PrepaymentType.shortenTerm)
                        }
                    }
                }
            }
            .navigationTitle("编辑提前还款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveChanges() }
                }
            }
        }
    }

    private func saveChanges() {
        guard let amount = Double(prepaymentAmount) else { return }

        // 创建新的 PrepaymentNode 来替换旧的，确保触发 @Binding 更新
        let updatedNode = PrepaymentNode(
            id: node.id,
            prepaymentDate: prepaymentDate,
            prepaymentAmount: amount,
            prepaymentType: prepaymentType,
            targetLoanType: targetLoanType,
            canShortenTerm: targetLoanType == .commercial && prepaymentType == .shortenTerm
        )

        if let index = prepayments.firstIndex(where: { $0.id == node.id }) {
            prepayments[index] = updatedNode
        }

        onSave()
        dismiss()
    }
}

#Preview {
    PrepaymentView(
        prepayments: .constant([]),
        commercialLoan: LoanInfo(
            loanType: .commercial,
            principal: 1000000,
            annualRate: 3.1,
            loanTermMonths: 360,
            startDate: Date()
        ),
        providentFundLoan: nil,
        onUpdate: {}
    )
}
