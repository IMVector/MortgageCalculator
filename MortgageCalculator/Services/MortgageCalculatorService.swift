import Foundation

final class MortgageCalculatorService {

    // MARK: - 等额本息计算

    /// 计算等额本息月供
    /// - Parameters:
    ///   - principal: 贷款本金
    ///   - monthlyRate: 月利率
    ///   - remainingMonths: 剩余期数
    /// - Returns: 月供金额
    static func calculateEqualPaymentMonthly(
        principal: Double,
        monthlyRate: Double,
        remainingMonths: Int
    ) -> Double {
        guard monthlyRate > 0, remainingMonths > 0 else {
            return principal / Double(remainingMonths)
        }

        let factor = pow(1 + monthlyRate, Double(remainingMonths))
        return principal * monthlyRate * factor / (factor - 1)
    }

    /// 生成等额本息还款明细
    static func generateEqualPaymentSchedule(
        loan: LoanInfo,
        prepayments: [PrepaymentNode] = []
    ) -> [MonthlyPayment] {
        var payments: [MonthlyPayment] = []
        var remainingPrincipal = loan.principal
        var currentDate = loan.startDate
        var monthIndex = 1

        // 按日期排序提前还款节点
        let sortedPrepayments = prepayments.sorted { $0.prepaymentDate < $1.prepaymentDate }

        // 找到第一个提前还款日期对应的月次
        var nextPrepaymentIndex = 0

        while remainingPrincipal > 0.01 {
            // 检查是否有提前还款
            var currentPrepayment: PrepaymentNode?
            while nextPrepaymentIndex < sortedPrepayments.count {
                let prepayment = sortedPrepayments[nextPrepaymentIndex]
                if prepayment.prepaymentDate <= currentDate {
                    currentPrepayment = prepayment
                    nextPrepaymentIndex += 1
                } else {
                    break
                }
            }

            // 计算当期月供
            let remainingMonths = loan.loanTermMonths - monthIndex + 1
            var monthlyPayment = calculateEqualPaymentMonthly(
                principal: remainingPrincipal,
                monthlyRate: loan.monthlyRate,
                remainingMonths: remainingMonths
            )

            // 如果是最后一期，调整月供
            if monthlyPayment > remainingPrincipal * (1 + loan.monthlyRate) {
                monthlyPayment = remainingPrincipal * (1 + loan.monthlyRate)
            }

            // 计算利息和本金
            let interest = remainingPrincipal * loan.monthlyRate
            var principalPaid = monthlyPayment - interest

            // 处理提前还款
            if let prepayment = currentPrepayment {
                let totalPayment = prepayment.prepaymentAmount + principalPaid
                if totalPayment >= remainingPrincipal + interest {
                    // 提前还清
                    principalPaid = remainingPrincipal
                    monthlyPayment = principalPaid + interest
                    remainingPrincipal = 0
                } else {
                    // 部分提前还款
                    principalPaid = min(totalPayment - interest, remainingPrincipal)
                    remainingPrincipal -= principalPaid

                    // 处理提前还款后的还款方式
                    if prepayment.prepaymentType == .shortenTerm {
                        // 缩短期限：保持月供不变，减少期数
                        // 期数已经在循环中自然减少
                    } else {
                        // 减少月供：保持期数不变，减少月供
                        // 循环将继续，但每月还款额会重新计算
                    }
                }
            } else {
                remainingPrincipal -= principalPaid
            }

            let payment = MonthlyPayment(
                id: monthIndex,
                date: currentDate,
                monthlyPayment: monthlyPayment,
                principal: principalPaid,
                interest: interest,
                remainingPrincipal: max(0, remainingPrincipal),
                loanType: loan.loanType
            )
            payments.append(payment)

            // 月次递增
            monthIndex += 1
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!

            // 防止无限循环
            if monthIndex > loan.loanTermMonths * 2 {
                break
            }
        }

        return payments
    }

    // MARK: - 等额本金计算

    /// 计算等额本金月供
    static func calculateEqualPrincipalMonthly(
        principal: Double,
        monthlyRate: Double,
        monthIndex: Int,
        totalMonths: Int
    ) -> Double {
        let monthlyPrincipal = principal / Double(totalMonths)
        let remainingPrincipal = principal - monthlyPrincipal * Double(monthIndex - 1)
        let interest = remainingPrincipal * monthlyRate
        return monthlyPrincipal + interest
    }

    /// 生成等额本金还款明细
    static func generateEqualPrincipalSchedule(
        loan: LoanInfo,
        prepayments: [PrepaymentNode] = []
    ) -> [MonthlyPayment] {
        var payments: [MonthlyPayment] = []
        var remainingPrincipal = loan.principal
        var currentDate = loan.startDate
        var monthIndex = 1
        var remainingMonths = loan.loanTermMonths
        // 每月偿还本金 = 总本金 / 总期数
        var monthlyPrincipal = loan.principal / Double(loan.loanTermMonths)

        let sortedPrepayments = prepayments.sorted { $0.prepaymentDate < $1.prepaymentDate }
        var nextPrepaymentIndex = 0

        while remainingPrincipal > 0.01 && monthIndex <= loan.loanTermMonths * 2 {
            var currentPrepayment: PrepaymentNode?
            while nextPrepaymentIndex < sortedPrepayments.count {
                let prepayment = sortedPrepayments[nextPrepaymentIndex]
                if prepayment.prepaymentDate <= currentDate {
                    currentPrepayment = prepayment
                    nextPrepaymentIndex += 1
                } else {
                    break
                }
            }

            // 当期利息 = 剩余本金 × 月利率
            let interest = remainingPrincipal * loan.monthlyRate
            var principalPaid = min(monthlyPrincipal, remainingPrincipal)

            // 处理提前还款
            if let prepayment = currentPrepayment {
                let prepaymentPrincipal = min(prepayment.prepaymentAmount, remainingPrincipal - principalPaid)

                if prepayment.prepaymentType == .shortenTerm {
                    // 缩短期限：保持每月本金不变，减少期数
                    principalPaid += prepaymentPrincipal
                    remainingPrincipal -= principalPaid
                    // 月供本金不变，期数自动减少
                } else {
                    // 减少月供：保持期数不变，减少每月本金
                    remainingPrincipal -= principalPaid + prepaymentPrincipal
                    // 重新计算剩余期数的每月本金
                    remainingMonths = max(1, remainingMonths - monthIndex + 1)
                    monthlyPrincipal = remainingPrincipal / Double(remainingMonths)
                }
            } else {
                remainingPrincipal -= principalPaid
            }

            // 最后一期调整
            if remainingPrincipal < 0.01 {
                principalPaid += remainingPrincipal
                remainingPrincipal = 0
            }

            let monthlyPayment = principalPaid + interest
            let payment = MonthlyPayment(
                id: monthIndex,
                date: currentDate,
                monthlyPayment: monthlyPayment,
                principal: principalPaid,
                interest: interest,
                remainingPrincipal: max(0, remainingPrincipal),
                loanType: loan.loanType
            )
            payments.append(payment)

            monthIndex += 1
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!
        }

        return payments
    }

    // MARK: - 完整贷款计算

    /// 计算完整贷款（含提前还款）
    static func calculateLoan(
        commercial: LoanInfo?,
        providentFund: LoanInfo?,
        prepayments: [PrepaymentNode]
    ) -> LoanCalculationResult {
        var result = LoanCalculationResult()
        result.commercialLoan = commercial
        result.providentFundLoan = providentFund
        result.prepaymentNodes = prepayments

        // 商业贷款 - 只处理目标为商业贷款的提前还款
        if let commercialLoan = commercial {
            let commercialPrepayments = prepayments.filter { $0.targetLoanType == .commercial }
            switch commercialLoan.repaymentType {
            case .equalPrincipalAndInterest:
                result.commercialMonthlyPayments = generateEqualPaymentSchedule(
                    loan: commercialLoan,
                    prepayments: commercialPrepayments
                )
            case .equalPrincipal:
                result.commercialMonthlyPayments = generateEqualPrincipalSchedule(
                    loan: commercialLoan,
                    prepayments: commercialPrepayments
                )
            }
            result.totalCommercialInterest = result.commercialMonthlyPayments.reduce(0) { $0 + $1.interest }
            result.commercialSegments = generateSegments(from: result.commercialMonthlyPayments, loanType: .commercial)
        }

        // 公积金贷款 - 只处理目标为公积金贷款的提前还款
        if let providentFundLoan = providentFund {
            let providentFundPrepayments = prepayments.filter { $0.targetLoanType == .providentFund }
            switch providentFundLoan.repaymentType {
            case .equalPrincipalAndInterest:
                result.providentFundMonthlyPayments = generateEqualPaymentSchedule(
                    loan: providentFundLoan,
                    prepayments: providentFundPrepayments
                )
            case .equalPrincipal:
                result.providentFundMonthlyPayments = generateEqualPrincipalSchedule(
                    loan: providentFundLoan,
                    prepayments: providentFundPrepayments
                )
            }
            result.totalProvidentFundInterest = result.providentFundMonthlyPayments.reduce(0) { $0 + $1.interest }
            result.providentFundSegments = generateSegments(from: result.providentFundMonthlyPayments, loanType: .providentFund)
        }

        return result
    }

    /// 生成还款计划段
    private static func generateSegments(
        from payments: [MonthlyPayment],
        loanType: LoanType
    ) -> [RepaymentSegment] {
        guard !payments.isEmpty else { return [] }

        var segments: [RepaymentSegment] = []
        var currentSegmentPayments: [MonthlyPayment] = []
        var lastPayment: MonthlyPayment?

        for payment in payments {
            if let last = lastPayment {
                // 检查是否应该开始新段
                // 如果月供金额变化超过1元（等额本金每月递减或提前还款后变化）
                let paymentDiff = abs(payment.monthlyPayment - last.monthlyPayment)
                let isNewSegment = paymentDiff > 1.0

                if isNewSegment {
                    // 保存当前段
                    if !currentSegmentPayments.isEmpty {
                        let segment = createSegment(from: currentSegmentPayments, loanType: loanType)
                        segments.append(segment)
                    }
                    currentSegmentPayments = [payment]
                } else {
                    currentSegmentPayments.append(payment)
                }
            } else {
                currentSegmentPayments.append(payment)
            }
            lastPayment = payment
        }

        // 添加最后一个段
        if !currentSegmentPayments.isEmpty {
            let segment = createSegment(from: currentSegmentPayments, loanType: loanType)
            segments.append(segment)
        }

        return segments
    }

    private static func createSegment(
        from payments: [MonthlyPayment],
        loanType: LoanType
    ) -> RepaymentSegment {
        let totalInterest = payments.reduce(0) { $0 + $1.interest }
        let avgPayment = payments.reduce(0.0) { $0 + $1.monthlyPayment } / Double(payments.count)

        return RepaymentSegment(
            startMonth: payments.first?.id ?? 1,
            endMonth: payments.last?.id ?? 1,
            monthlyPayment: avgPayment,
            totalInterest: totalInterest,
            remainingPrincipal: payments.last?.remainingPrincipal ?? 0
        )
    }

    // MARK: - 简化计算（用于展示每月还款变化）

    /// 计算提前还款后的新月供
    static func calculateNewMonthlyPayment(
        loan: LoanInfo,
        prepaymentDate: Date,
        prepaymentAmount: Double,
        prepaymentType: PrepaymentType
    ) -> Double {
        // 计算提前还款时已还期数
        let monthsPassed = monthsBetween(loan.startDate, and: prepaymentDate)
        guard monthsPassed < loan.loanTermMonths else { return 0 }

        // 计算剩余本金
        var remainingPrincipal = calculateRemainingPrincipal(
            loan: loan,
            monthsPassed: monthsPassed
        )

        // 减去提前还款金额
        remainingPrincipal = max(0, remainingPrincipal - prepaymentAmount)

        // 计算剩余期数
        let remainingMonths = loan.loanTermMonths - monthsPassed

        guard remainingMonths > 0 else { return 0 }

        switch prepaymentType {
        case .reducePayment:
            // 减少月供：重新计算月供
            return calculateEqualPaymentMonthly(
                principal: remainingPrincipal,
                monthlyRate: loan.monthlyRate,
                remainingMonths: remainingMonths
            )

        case .shortenTerm:
            // 缩短期限：月供不变，期数减少
            // 计算新期数
            let newTermMonths = calculateNewTerm(
                originalPrincipal: remainingPrincipal + prepaymentAmount,
                monthlyPayment: calculateEqualPaymentMonthly(
                    principal: remainingPrincipal + prepaymentAmount,
                    monthlyRate: loan.monthlyRate,
                    remainingMonths: remainingMonths
                ),
                monthlyRate: loan.monthlyRate
            )
            let adjustedMonths = min(newTermMonths, remainingMonths)
            return calculateEqualPaymentMonthly(
                principal: remainingPrincipal,
                monthlyRate: loan.monthlyRate,
                remainingMonths: adjustedMonths
            )
        }
    }

    /// 计算剩余本金
    private static func calculateRemainingPrincipal(loan: LoanInfo, monthsPassed: Int) -> Double {
        switch loan.repaymentType {
        case .equalPrincipalAndInterest:
            return calculateRemainingPrincipalEqualPayment(loan: loan, monthsPassed: monthsPassed)
        case .equalPrincipal:
            let monthlyPrincipal = loan.principal / Double(loan.loanTermMonths)
            return max(0, loan.principal - monthlyPrincipal * Double(monthsPassed))
        }
    }

    private static func calculateRemainingPrincipalEqualPayment(loan: LoanInfo, monthsPassed: Int) -> Double {
        let monthlyPayment = calculateEqualPaymentMonthly(
            principal: loan.principal,
            monthlyRate: loan.monthlyRate,
            remainingMonths: loan.loanTermMonths
        )

        var remaining = loan.principal
        for _ in 0..<monthsPassed {
            let interest = remaining * loan.monthlyRate
            let principal = monthlyPayment - interest
            remaining -= principal
        }

        return max(0, remaining)
    }

    /// 计算新期限
    private static func calculateNewTerm(
        originalPrincipal: Double,
        monthlyPayment: Double,
        monthlyRate: Double
    ) -> Int {
        guard monthlyRate > 0 else {
            return Int(ceil(originalPrincipal / monthlyPayment))
        }

        let factor = monthlyPayment / (monthlyPayment - originalPrincipal * monthlyRate)
        let months = log(factor) / log(1 + monthlyRate)
        return Int(ceil(months))
    }

    /// 计算两个日期间的月数
    static func monthsBetween(_ start: Date, and end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: start, to: end)
        return max(0, components.month ?? 0)
    }

    /// 格式化金额
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "0.00"
    }
}
