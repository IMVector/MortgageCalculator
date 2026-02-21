import SwiftUI

struct LoanInputView: View {
    @Binding var commercialLoan: LoanInfo?
    @Binding var providentFundLoan: LoanInfo?
    @Binding var prepayments: [PrepaymentNode]

    let onCalculate: () -> Void

    @State private var showCommercialInput = false
    @State private var showProvidentFundInput = false
    @State private var hasLoadedData = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 欢迎提示（无贷款时显示）
                    if commercialLoan == nil && providentFundLoan == nil {
                        WelcomeCardView()
                    }

                    // 商业贷款卡片
                    LoanCard(
                        title: "商业贷款",
                        icon: "building.2.fill",
                        color: .blue,
                        subtitle: "商业住房贷款",
                        loan: $commercialLoan,
                        isExpanded: $showCommercialInput,
                        onDelete: { commercialLoan = nil; onCalculate() },
                        onCalculate: onCalculate
                    )

                    // 公积金贷款卡片
                    LoanCard(
                        title: "公积金贷款",
                        icon: "house.fill",
                        color: .green,
                        subtitle: "住房公积金贷款",
                        loan: $providentFundLoan,
                        isExpanded: $showProvidentFundInput,
                        isProvidentFund: true,
                        onDelete: { providentFundLoan = nil; onCalculate() },
                        onCalculate: onCalculate
                    )

                    // 计算按钮
                    if commercialLoan != nil || providentFundLoan != nil {
                        Button(action: onCalculate) {
                            HStack(spacing: 8) {
                                Image(systemName: "calculator.fill")
                                    .font(.headline)
                                Text("计算还款")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }

                    // 提前还款提示
                    if !prepayments.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("已添加 \(prepayments.count) 条提前还款记录，在「计算结果」页查看")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("房贷计算器")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if commercialLoan != nil || providentFundLoan != nil {
                        Menu {
                            Button(role: .destructive, action: clearAll) {
                                Label("清除所有贷款", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }

    private func clearAll() {
        commercialLoan = nil
        providentFundLoan = nil
        prepayments = []
        showCommercialInput = false
        showProvidentFundInput = false
    }
}

// MARK: - 贷款卡片

struct LoanCard: View {
    let title: String
    let icon: String
    let color: Color
    var subtitle: String = ""
    @Binding var loan: LoanInfo?
    @Binding var isExpanded: Bool
    var isProvidentFund: Bool = false
    let onDelete: () -> Void
    let onCalculate: () -> Void

    @State private var principal: String = ""
    @State private var annualRate: String = "3.1"
    @State private var loanTermYears: String = "30"
    @State private var startDate: Date = Date()
    @State private var repaymentType: RepaymentType = .equalPrincipalAndInterest

    // 预设利率
    private let defaultRates: [String: String] = [
        "commercial": "4.2",
        "providentFund": "2.85"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 卡片头部
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // 图标
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.title3)
                        }

                    // 标题和摘要
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.headline)

                        if let loan = loan {
                            HStack(spacing: 4) {
                                Text("\(MortgageCalculatorService.formatCurrency(loan.principal)) 万")
                                Text("·")
                                Text("\(loan.loanTermMonths)期")
                                Text("·")
                                Text("\(String(format: "%.2f", loan.annualRate))%")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        } else if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // 操作按钮
                    HStack(spacing: 12) {
                        if loan != nil {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            // 展开的输入表单
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()

                    // 贷款金额
                    InputField(
                        title: "贷款金额",
                        unit: "万元",
                        placeholder: "如 100",
                        text: $principal,
                        keyboardType: .decimalPad
                    )

                    // 年利率
                    InputField(
                        title: "年利率",
                        unit: "%",
                        placeholder: isProvidentFund ? "如 2.85" : "如 4.2",
                        text: $annualRate,
                        keyboardType: .decimalPad
                    )

                    // 贷款期限
                    InputField(
                        title: "贷款期限",
                        unit: "年",
                        placeholder: "如 30",
                        text: $loanTermYears,
                        keyboardType: .numberPad
                    )

                    // 贷款开始日期
                    HStack {
                        Text("开始日期")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    // 还款方式
                    VStack(alignment: .leading, spacing: 8) {
                        Text("还款方式")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("", selection: $repaymentType) {
                            ForEach(RepaymentType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        // 还款方式说明
                        Text(repaymentType == .equalPrincipalAndInterest
                             ? "每月还款金额相同，适合收入稳定的人群"
                             : "每月本金相同，利息递减，总利息较少")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    // 保存按钮
                    Button(action: saveLoan) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("保存并计算")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(color)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onAppear {
            // 设置默认利率
            if annualRate == "3.1" {
                annualRate = isProvidentFund ? "2.85" : "4.2"
            }
        }
    }

    private func saveLoan() {
        guard let principalValue = Double(principal),
              let rateValue = Double(annualRate),
              let termValue = Int(loanTermYears),
              principalValue > 0,
              rateValue > 0,
              termValue > 0 else {
            return
        }

        let loanType: LoanType = isProvidentFund ? .providentFund : .commercial

        loan = LoanInfo(
            loanType: loanType,
            principal: principalValue * 10000, // 万元转元
            annualRate: rateValue,
            loanTermMonths: termValue * 12,
            startDate: startDate,
            repaymentType: repaymentType
        )

        onCalculate()
        withAnimation(.easeInOut(duration: 0.25)) {
            isExpanded = false
        }
    }
}

// MARK: - 输入字段组件

struct InputField: View {
    let title: String
    let unit: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .decimalPad

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)

            Text(unit)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    LoanInputView(
        commercialLoan: .constant(nil),
        providentFundLoan: .constant(nil),
        prepayments: .constant([]),
        onCalculate: {}
    )
}
