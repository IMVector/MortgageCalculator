import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    @State private var calculationResult: LoanCalculationResult?

    // 分享功能
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            // 贷款输入页面
            LoanInputView(
                commercialLoan: $dataManager.commercialLoan,
                providentFundLoan: $dataManager.providentFundLoan,
                prepayments: $dataManager.prepayments,
                onCalculate: calculateAndNavigate
            )
            .tabItem {
                Label("贷款输入", systemImage: "doc.text.fill")
            }
            .tag(0)

            // 计算结果页面（含提前还款功能）
            ResultView(
                result: calculationResult,
                prepayments: $dataManager.prepayments,
                commercialLoan: dataManager.commercialLoan,
                providentFundLoan: dataManager.providentFundLoan,
                onRecalculate: calculateLoan
            )
            .tabItem {
                Label("计算结果", systemImage: "chart.bar.fill")
            }
            .tag(1)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { calculateLoan() }) {
                        Label("重新计算", systemImage: "arrow.clockwise")
                    }
                    .disabled(dataManager.commercialLoan == nil && dataManager.providentFundLoan == nil)

                    Divider()

                    Button(action: { exportData() }) {
                        Label("分享结果", systemImage: "square.and.arrow.up")
                    }
                    .disabled(calculationResult == nil)

                    Divider()

                    Button(role: .destructive, action: { clearAllData() }) {
                        Label("清除所有数据", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .onAppear {
            calculateLoan()
        }
        .onChange(of: dataManager.prepayments) { _, _ in
            // 提前还款变化时自动重新计算
            calculateLoan()
        }
    }

    // MARK: - 计算逻辑

    private func calculateLoan() {
        calculationResult = MortgageCalculatorService.calculateLoan(
            commercial: dataManager.commercialLoan,
            providentFund: dataManager.providentFundLoan,
            prepayments: dataManager.prepayments
        )
    }

    private func calculateAndNavigate() {
        calculateLoan()
        // 延迟跳转，让用户看到保存成功的反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                selectedTab = 1
            }
        }
    }

    // MARK: - 导出分享

    private func exportData() {
        guard let result = calculationResult else { return }

        let text = ImportExportService.exportToText(result: result)
        let filename = "房贷计算结果_\(formatDate(Date())).txt"

        if let url = ImportExportService.saveToFile(text, filename: filename) {
            shareItems = [url, text]
            showingShareSheet = true
        }
    }

    private func clearAllData() {
        dataManager.clearAll()
        calculationResult = nil
        selectedTab = 0
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
