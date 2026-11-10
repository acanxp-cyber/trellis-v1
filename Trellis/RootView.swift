import SwiftUI

private enum AppSection: Hashable {
    case today
    case records
    case review
    case year
    case more
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: AppSection = .today

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem {
                    Label("今天", systemImage: "circle")
                }
                .tag(AppSection.today)

            RecordsView()
                .tabItem {
                    Label("记录", systemImage: "text.quote")
                }
                .tag(AppSection.records)

            ReviewView()
                .tabItem {
                    Label("回顾", systemImage: "checklist")
                }
                .tag(AppSection.review)

            YearView()
                .tabItem {
                    Label("年轮", systemImage: "circle.dashed")
                }
                .tag(AppSection.year)

            MoreView()
                .tabItem {
                    Label("更多", systemImage: "ellipsis")
                }
                .tag(AppSection.more)
        }
        .tint(.trellisBrass)
        .preferredColorScheme(.dark)
        .overlay {
            if model.isLoading {
                ProgressView("正在读取本地数据")
                    .padding(20)
                    .background(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .bottom) {
            if let message = model.errorMessage {
                HStack(alignment: .top, spacing: 12) {
                    Text(message)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        Button("重试") {
                            Task {
                                await model.bootstrap()
                            }
                        }

                        Button("关闭") {
                            model.clearError()
                        }
                    }
                    .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.trellisBone)
                .padding(14)
                .background(Color.trellisDanger)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
            }
        }
    }
}

