import Foundation

final class ImportExportService {

    // MARK: - 导出数据

    /// 导出为JSON格式
    static func exportToJSON(
        commercial: LoanInfo?,
        providentFund: LoanInfo?,
        prepayments: [PrepaymentNode]
    ) -> String? {
        let exportData = ExportData(
            commercialLoan: commercial,
            providentFundLoan: providentFund,
            prepayments: prepayments,
            exportDate: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(exportData),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }

    /// 导出为可读文本格式
    static func exportToText(
        result: LoanCalculationResult
    ) -> String {
        var text = "房贷计算结果\n"
        text += "=" .padding(toLength: 30, withPad: "=", startingAt: 0) + "\n\n"

        // 商业贷款信息
        if let commercial = result.commercialLoan {
            text += "【商业贷款】\n"
            text += "贷款本金: \(MortgageCalculatorService.formatCurrency(commercial.principal)) 元\n"
            text += "年利率: \(String(format: "%.2f", commercial.annualRate))%\n"
            text += "贷款期限: \(commercial.loanTermMonths) 个月\n"
            text += "还款方式: \(commercial.repaymentType.rawValue)\n"
            text += "起始日期: \(formatDate(commercial.startDate))\n"
            text += "\n"
        }

        // 公积金贷款信息
        if let providentFund = result.providentFundLoan {
            text += "【公积金贷款】\n"
            text += "贷款本金: \(MortgageCalculatorService.formatCurrency(providentFund.principal)) 元\n"
            text += "年利率: \(String(format: "%.2f", providentFund.annualRate))%\n"
            text += "贷款期限: \(providentFund.loanTermMonths) 个月\n"
            text += "还款方式: \(providentFund.repaymentType.rawValue)\n"
            text += "起始日期: \(formatDate(providentFund.startDate))\n"
            text += "\n"
        }

        // 提前还款节点
        if !result.prepaymentNodes.isEmpty {
            text += "【提前还款记录】\n"
            for (index, node) in result.prepaymentNodes.enumerated() {
                text += "\(index + 1). \(formatDate(node.prepaymentDate))\n"
                text += "   金额: \(MortgageCalculatorService.formatCurrency(node.prepaymentAmount)) 元\n"
                text += "   方式: \(node.prepaymentType.rawValue)\n"
            }
            text += "\n"
        }

        // 计算结果汇总
        text += "【计算结果】\n"

        let totalCommercialPayment = result.commercialLoan.map { $0.principal } ?? 0
        let totalProvidentFundPayment = result.providentFundLoan.map { $0.principal } ?? 0

        if let commercial = result.commercialLoan {
            text += "商业贷款:\n"
            text += "  月供: \(MortgageCalculatorService.formatCurrency(result.commercialMonthlyPayments.first?.monthlyPayment ?? 0)) 元\n"
            text += "  总利息: \(MortgageCalculatorService.formatCurrency(result.totalCommercialInterest)) 元\n"
            text += "  已还期数: \(result.commercialMonthlyPayments.count) 期\n"
            text += "\n"
        }

        if let providentFund = result.providentFundLoan {
            text += "公积金贷款:\n"
            text += "  月供: \(MortgageCalculatorService.formatCurrency(result.providentFundMonthlyPayments.first?.monthlyPayment ?? 0)) 元\n"
            text += "  总利息: \(MortgageCalculatorService.formatCurrency(result.totalProvidentFundInterest)) 元\n"
            text += "  已还期数: \(result.providentFundMonthlyPayments.count) 期\n"
            text += "\n"
        }

        // 还款变化节点
        if !result.commercialSegments.isEmpty {
            text += "【商业贷款还款变化】\n"
            for segment in result.commercialSegments {
                text += "第\(segment.startMonth)-\(segment.endMonth)期: 月供 \(MortgageCalculatorService.formatCurrency(segment.monthlyPayment)) 元\n"
            }
            text += "\n"
        }

        if !result.providentFundSegments.isEmpty {
            text += "【公积金贷款还款变化】\n"
            for segment in result.providentFundSegments {
                text += "第\(segment.startMonth)-\(segment.endMonth)期: 月供 \(MortgageCalculatorService.formatCurrency(segment.monthlyPayment)) 元\n"
            }
        }

        return text
    }

    // MARK: - 导入数据

    /// 从JSON导入
    static func importFromJSON(_ jsonString: String) -> (LoanInfo?, LoanInfo?, [PrepaymentNode])? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let exportData = try? decoder.decode(ExportData.self, from: data) else {
            return nil
        }

        return (exportData.commercialLoan, exportData.providentFundLoan, exportData.prepayments)
    }

    // MARK: - 文件操作

    /// 保存到文件
    static func saveToFile(_ content: String, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("保存文件失败: \(error)")
            return nil
        }
    }

    /// 从文件读取
    static func loadFromFile(_ url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("读取文件失败: \(error)")
            return nil
        }
    }

    // MARK: - 辅助函数

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 导出数据结构

struct ExportData: Codable {
    var commercialLoan: LoanInfo?
    var providentFundLoan: LoanInfo?
    var prepayments: [PrepaymentNode]
    var exportDate: Date
    var version: String = "1.0"
}
