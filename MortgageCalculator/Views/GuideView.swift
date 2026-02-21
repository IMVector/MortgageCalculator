import SwiftUI

struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    let pages: [GuidePage] = [
        GuidePage(
            icon: "doc.text.fill",
            title: "添加贷款信息",
            description: "点击「商业贷款」或「公积金贷款」卡片，填写贷款金额、利率、期限等信息",
            tips: ["支持组合贷款（商业+公积金）", "金额单位为万元", "可选择等额本息或等额本金"]
        ),
        GuidePage(
            icon: "calculator.fill",
            title: "计算还款计划",
            description: "填写完成后点击「保存并计算」，系统会自动跳转到结果页面",
            tips: ["等额本息：每月还款相同", "等额本金：每月递减，总利息少", "结果会自动保存"]
        ),
        GuidePage(
            icon: "dollarsign.circle.fill",
            title: "提前还款模拟",
            description: "在结果页面点击「添加提前还款」，可以模拟提前还款后的新还款计划",
            tips: ["选择还款的商业或公积金贷款", "选择缩短期限或减少月供", "可添加多条提前还款记录"]
        ),
        GuidePage(
            icon: "chart.bar.fill",
            title: "查看还款明细",
            description: "在结果页面展开贷款卡片，可以查看每一期的还款详情",
            tips: ["点击还款段展开查看明细", "包含本金、利息、剩余本金", "可折叠方便查看"]
        ),
        GuidePage(
            icon: "square.and.arrow.up.fill",
            title: "分享计算结果",
            description: "点击右上角菜单，选择「分享结果」可以导出还款计划",
            tips: ["支持分享文本文件", "可用于对比不同方案", "数据保存在本地"]
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        GuidePageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))

                // 底部按钮
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("上一步") {
                            withAnimation { currentPage -= 1 }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(currentPage == pages.count - 1 ? "开始使用" : "下一步") {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
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
                .padding()
                .background(Color(.systemBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("使用指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳过") { dismiss() }
                }
            }
        }
    }
}

struct GuidePage {
    let icon: String
    let title: String
    let description: String
    let tips: [String]
}

struct GuidePageView: View {
    let page: GuidePage

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 图标
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .teal.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: page.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                // 标题
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                // 描述
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // 提示卡片
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.subheadline)

                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
        }
    }
}

// MARK: - 欢迎卡片（更新版）

struct WelcomeCardView: View {
    @State private var showGuide = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                Text("欢迎使用房贷计算器")
                    .font(.headline)

                Text("点击下方卡片添加贷款信息\n支持商业贷款、公积金贷款或组合贷款")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 使用指南按钮
            Button(action: { showGuide = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                    Text("查看使用指南")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showGuide) {
            GuideView()
        }
    }
}

#Preview("GuideView") {
    GuideView()
}

#Preview("WelcomeCard") {
    WelcomeCardView()
        .padding()
}
