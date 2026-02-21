import Foundation

/// 贷款类型
enum LoanType: String, Codable, CaseIterable {
    case commercial = "商业贷款"
    case providentFund = "公积金贷款"
}

/// 还款方式
enum RepaymentType: String, Codable, CaseIterable {
    case equalPrincipalAndInterest = "等额本息"
    case equalPrincipal = "等额本金"
}

/// 提前还款方式
enum PrepaymentType: String, Codable, CaseIterable {
    case shortenTerm = "缩短期限"
    case reducePayment = "减少月供"
}

/// 基础贷款信息
struct LoanInfo: Codable, Identifiable {
    var id: UUID = UUID()
    var loanType: LoanType
    var principal: Double       // 贷款本金
    var annualRate: Double      // 年利率 (%)
    var loanTermMonths: Int     // 贷款期限（月）
    var startDate: Date         // 贷款开始日期
    var repaymentType: RepaymentType

    init(
        id: UUID = UUID(),
        loanType: LoanType,
        principal: Double,
        annualRate: Double,
        loanTermMonths: Int,
        startDate: Date,
        repaymentType: RepaymentType = .equalPrincipalAndInterest
    ) {
        self.id = id
        self.loanType = loanType
        self.principal = principal
        self.annualRate = annualRate
        self.loanTermMonths = loanTermMonths
        self.startDate = startDate
        self.repaymentType = repaymentType
    }

    /// 月利率
    var monthlyRate: Double {
        return annualRate / 100.0 / 12.0
    }
}

/// 提前还款节点
struct PrepaymentNode: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var prepaymentDate: Date    // 提前还款日期
    var prepaymentAmount: Double // 提前还款金额
    var prepaymentType: PrepaymentType // 提前还款方式
    var targetLoanType: LoanType // 目标贷款类型（商业贷款或公积金贷款）
    var canShortenTerm: Bool    // 是否允许缩短期限

    init(
        id: UUID = UUID(),
        prepaymentDate: Date,
        prepaymentAmount: Double,
        prepaymentType: PrepaymentType,
        targetLoanType: LoanType = .commercial,
        canShortenTerm: Bool = true
    ) {
        self.id = id
        self.prepaymentDate = prepaymentDate
        self.prepaymentAmount = prepaymentAmount
        self.prepaymentType = prepaymentType
        self.targetLoanType = targetLoanType
        self.canShortenTerm = canShortenTerm
    }
}

/// 月供明细
struct MonthlyPayment: Identifiable, Codable {
    var id: Int                 // 月次
    var date: Date              // 还款日期
    var monthlyPayment: Double   // 月供
    var principal: Double       // 本金
    var interest: Double        // 利息
    var remainingPrincipal: Double // 剩余本金
    var loanType: LoanType      // 贷款类型
}

/// 还款计划段
struct RepaymentSegment: Identifiable, Codable {
    var id: UUID = UUID()
    var startMonth: Int          // 起始月次
    var endMonth: Int            // 结束月次
    var monthlyPayment: Double   // 月供
    var totalInterest: Double    // 总利息
    var remainingPrincipal: Double // 剩余本金
    var prepaymentNodeId: UUID?  // 关联的提前还款节点
}

/// 完整贷款计算结果
struct LoanCalculationResult: Codable {
    var commercialLoan: LoanInfo?
    var providentFundLoan: LoanInfo?
    var prepaymentNodes: [PrepaymentNode]
    var commercialSegments: [RepaymentSegment]
    var providentFundSegments: [RepaymentSegment]
    var commercialMonthlyPayments: [MonthlyPayment]
    var providentFundMonthlyPayments: [MonthlyPayment]
    var totalCommercialInterest: Double
    var totalProvidentFundInterest: Double

    init() {
        self.prepaymentNodes = []
        self.commercialSegments = []
        self.providentFundSegments = []
        self.commercialMonthlyPayments = []
        self.providentFundMonthlyPayments = []
        self.totalCommercialInterest = 0
        self.totalProvidentFundInterest = 0
    }
}
