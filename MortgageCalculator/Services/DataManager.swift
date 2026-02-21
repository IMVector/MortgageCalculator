import Foundation

/// 数据管理器 - 负责数据的保存和读取
final class DataManager: ObservableObject {
    static let shared = DataManager()

    // UserDefaults keys
    private let commercialLoanKey = "commercialLoan"
    private let providentFundLoanKey = "providentFundLoan"
    private let prepaymentsKey = "prepayments"

    @Published var commercialLoan: LoanInfo? {
        didSet { saveCommercialLoan() }
    }

    @Published var providentFundLoan: LoanInfo? {
        didSet { saveProvidentFundLoan() }
    }

    @Published var prepayments: [PrepaymentNode] = [] {
        didSet { savePrepayments() }
    }

    private init() {
        loadData()
    }

    // MARK: - 加载数据

    private func loadData() {
        loadCommercialLoan()
        loadProvidentFundLoan()
        loadPrepayments()
    }

    private func loadCommercialLoan() {
        guard let data = UserDefaults.standard.data(forKey: commercialLoanKey) else { return }
        commercialLoan = try? JSONDecoder().decode(LoanInfo.self, from: data)
    }

    private func loadProvidentFundLoan() {
        guard let data = UserDefaults.standard.data(forKey: providentFundLoanKey) else { return }
        providentFundLoan = try? JSONDecoder().decode(LoanInfo.self, from: data)
    }

    private func loadPrepayments() {
        guard let data = UserDefaults.standard.data(forKey: prepaymentsKey) else { return }
        prepayments = (try? JSONDecoder().decode([PrepaymentNode].self, from: data)) ?? []
    }

    // MARK: - 保存数据

    private func saveCommercialLoan() {
        guard let loan = commercialLoan,
              let data = try? JSONEncoder().encode(loan) else {
            UserDefaults.standard.removeObject(forKey: commercialLoanKey)
            return
        }
        UserDefaults.standard.set(data, forKey: commercialLoanKey)
    }

    private func saveProvidentFundLoan() {
        guard let loan = providentFundLoan,
              let data = try? JSONEncoder().encode(loan) else {
            UserDefaults.standard.removeObject(forKey: providentFundLoanKey)
            return
        }
        UserDefaults.standard.set(data, forKey: providentFundLoanKey)
    }

    private func savePrepayments() {
        guard let data = try? JSONEncoder().encode(prepayments) else { return }
        UserDefaults.standard.set(data, forKey: prepaymentsKey)
    }

    // MARK: - 公开方法

    /// 清除所有数据
    func clearAll() {
        commercialLoan = nil
        providentFundLoan = nil
        prepayments = []
    }

    /// 添加提前还款
    func addPrepayment(_ node: PrepaymentNode) {
        prepayments.append(node)
    }

    /// 删除提前还款
    func removePrepayment(_ node: PrepaymentNode) {
        prepayments.removeAll { $0.id == node.id }
    }

    /// 更新提前还款
    func updatePrepayment(_ node: PrepaymentNode) {
        if let index = prepayments.firstIndex(where: { $0.id == node.id }) {
            prepayments[index] = node
        }
    }
}
